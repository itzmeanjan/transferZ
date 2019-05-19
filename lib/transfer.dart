import 'package:flutter/material.dart';
import 'peer_finder.dart' show PeerInfoHolder;
import 'package:flutter/services.dart' show MethodChannel;
import 'server.dart';
import 'client.dart';
import 'dart:io' show File, InternetAddress;
import 'dart:io';
import 'transfer_widget.dart';

class Transfer extends StatefulWidget {
  final MethodChannel methodChannel;
  final PeerInfoHolder peerInfoHolder;

  Transfer(
      {Key key, @required this.methodChannel, @required this.peerInfoHolder})
      : super(key: key);

  @override
  _TransferState createState() => _TransferState();
}

class _TransferState extends State<Transfer>
    implements ServerStatusCallBack, ClientStatusCallBack {
  Map<String, int>
      _filteredPeers; // PEERs which are going to take part in transfer
  Map<String, int> _filesToBeTransferred; // files to be transferred
  Server _server; // server object
  Client _client; // client Object
  Map<String, Map<String, double>>
      _transferStatus; // keeps track of status of transfer
  Map<String, String> _peerStatus; // keeps track of PEER's status
  String
      _targetHomeDir; // gets directory path, where to store files, fetched from PEER
  bool _isFileChosen; // helps to update UI
  bool _isTransferOn; // helps to update UI
  int _serverSideDownloadCount;
  Map<String, TransferProgressWidget> _transferProgressWidgets;

  @override
  void initState() {
    super.initState();
    _filesToBeTransferred = <String, int>{};
    _serverSideDownloadCount = 0;
    _isFileChosen = false; // at first no file chosen
    _isTransferOn = false; // at first, transfer not started
    _peerStatus = {};
    _transferStatus = {};
    _transferProgressWidgets = {};
    _filteredPeers = filterEligiblePeers();
    if (widget.peerInfoHolder.type == 'send')
      // instance of Server created, which listens on 0.0.0.0:8000
      _server = Server(InternetAddress.anyIPv4.address, 8000,
          _filteredPeers.keys.toList(), _filesToBeTransferred, this);
    else
      getHomeDir().then((String val) {
        _targetHomeDir =
            val; // home directory path, fetched using PlatformChannel
      });
  }

  @override
  void dispose() {
    super.dispose();
    // resource management is important, closes server object, client object etc.
    _server?.stop();
    // null-safe operator is used, to ensure that if server/ client not initialized, then it must not cause any exception
    _client?.disconnect();
  }

  Map<String, int> filterEligiblePeers() =>
      // As user has to explicitly select certain device identifier(s), check performed to test it, otherwise gets discarded
      widget.peerInfoHolder.getPeers().map((key, val) {
        if (widget.peerInfoHolder.getSelectedPeers()[key])
          return MapEntry(key, val);
      });

  /// server side callback starts here
  @override
  updatePeerStatus(Map<String, String> stat) => stat.forEach((key, val) =>
      setState(() => _transferProgressWidgets[key].peerStat = val));

  @override
  updateTransferStatus(Map<String, Map<String, double>> stat) =>
      stat.forEach((key, val) {
        val.forEach((keyInner, valInner) {
          if ([100, -1].contains(valInner.ceil()))
            _serverSideDownloadCount += 1;
          setState(() {
            _transferProgressWidgets[key].transferStat[keyInner] = valInner;
            if (_serverSideDownloadCount == _filesToBeTransferred.length) {
              _isFileChosen = false;
              _isTransferOn = false;
            }
          });
        });
      });

  @override
  generalUpdate(String msg) =>
      // in case of general update, this callback is mostly invoked to let user know about SELF status, when device is in `send` mode.
      showToast(msg, 'short');
  // server side callback ends here

  /// client side callback
  @override
  updateTransferStatusClientSide(Map<String, double> stat) => _filteredPeers
      .forEach((key, val) => stat.forEach((keyInner, valInner) => setState(() =>
          _transferProgressWidgets[key].transferStat[keyInner] = valInner)));

  Future<String> getHomeDir() async =>
      // fetches path to homeDir, actually this is the directory where I'm going to store all files, fetched from any PEER
      await widget.methodChannel.invokeMethod('getHomeDir',
          <String, String>{'dirName': 'transferZ'}).then((val) => val);

  vibrateDevice({String type: 'tick'}) async =>
      // uses platform channel to vibrate device using a certain type of VibrationEffect
      // in this case I'm using a single shot click vibrator
      await widget.methodChannel
          .invokeMethod('vibrateDevice', <String, String>{'type': type});

  showToast(String message, String duration) async =>
      // use platform channel and display a toast message
      await widget.methodChannel.invokeMethod('showToast',
          <String, String>{'message': message, 'duration': duration});

  Future<List<String>> initFileChooser() async {
    return await widget.methodChannel
        .invokeMethod('initFileChooser')
        .then((val) => List<String>.from(val));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'logo/logotype-horizontal.png',
          ),
          centerTitle: true,
        ),
        body: Container(
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16,
          ),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, indexP) {
                    _transferProgressWidgets[_filteredPeers.keys
                        .toList()[indexP]] = TransferProgressWidget(
                      peerName: _filteredPeers.keys.toList()[indexP],
                      peerStat:
                          _peerStatus[_filteredPeers.keys.toList()[indexP]] ??
                              'NA',
                      transferStat: _transferStatus[
                              _filteredPeers.keys.toList()[indexP]] ??
                          {},
                    );
                    return _transferProgressWidgets[_filteredPeers.keys
                            .toList()[
                        indexP]]; // stores a reference to transfer progress widget and returns same reference
                  },
                  itemCount: _filteredPeers.length,
                ),
              ),
              GestureDetector(
                child: Chip(
                  backgroundColor:
                      _isTransferOn ? Colors.redAccent : Colors.tealAccent,
                  labelPadding: EdgeInsets.only(
                    left: 6,
                    right: 12,
                    top: 3,
                    bottom: 3,
                  ),
                  padding: EdgeInsets.only(
                    left: 4,
                    right: 4,
                  ),
                  label: Text(widget.peerInfoHolder.type == 'send'
                      ? _isFileChosen
                          ? _isTransferOn ? 'Abort Transfer' : 'Init Transfer'
                          : 'Choose File(s)'
                      : _isTransferOn
                          ? 'Abort Transfer'
                          : 'Request File(s) from Peer'),
                  avatar: Icon(
                    widget.peerInfoHolder.type == 'send'
                        ? _isFileChosen
                            ? _isTransferOn ? Icons.cancel : Icons.arrow_right
                            : Icons.attach_file
                        : _isTransferOn ? Icons.cancel : Icons.file_download,
                  ),
                ),
                onTap: widget.peerInfoHolder.type == 'send'
                    // first checks whether it's send operation
                    ? _isFileChosen
                        // well if send, then check whether user has selected files
                        ? _isTransferOn
                            // now check if user has started transfer
                            ? () {
                                if (!_server.isStopped) {
                                  _server.stop();
                                  setState(() {
                                    _isTransferOn = false;
                                    _isFileChosen = false;
                                  });
                                }
                              }
                            // or not
                            : () {
                                if (_filesToBeTransferred.isNotEmpty) {
                                  if (_server.isStopped) {
                                    setState(() => _isTransferOn = true);
                                    _server.init();
                                  }
                                }
                              }
                        // or not, select files
                        : () {
                            initFileChooser().then((filePaths) {
                              _filesToBeTransferred = Map.fromEntries(filePaths
                                  .map((elem) {
                                    if (File(elem).existsSync()) return elem;
                                  })
                                  .toList()
                                  .map((e) =>
                                      MapEntry(e, File(e).lengthSync())));
                              if (_filesToBeTransferred.isNotEmpty) {
                                setState(() => _isFileChosen = true);
                                _server.filesToBeShared =
                                    Map.from(_filesToBeTransferred);
                              } else
                                showToast('Select onDevice Files', 'short');
                            });
                          }
                    // or receive operation
                    : _isTransferOn
                        // check if user has started transfer
                        ? () {
                            _client.disconnect();
                            setState(() => _isTransferOn = false);
                          }
                        // or not
                        : () {
                            String _peerIP;
                            //int _peerPort;
                            _filteredPeers.forEach((key, val) {
                              _peerIP = key;
                              _client = Client(key, val, this);
                              //_peerPort = val;
                            });
                            setState(() {
                              _isTransferOn = true;
                              _peerStatus[_peerIP] = 'Connecting to Peer';
                            });
                            _client.fetchFileNames().then(
                              (Map<String, int> fileNames) {
                                _filesToBeTransferred = fileNames;
                                if (_filesToBeTransferred.isEmpty) {
                                  setState(() {
                                    _isTransferOn = false;
                                    _peerStatus[_peerIP] =
                                        'Peer sharing nothing';
                                  });
                                } else
                                  _filesToBeTransferred
                                      .forEach((String file, int fileSize) {
                                    setState(() {
                                      _transferProgressWidgets[_peerIP]
                                          .peerStat = 'Fetching files';
                                    });
                                    _client
                                        .fetchFile(
                                            file, fileSize, _targetHomeDir)
                                        .then(
                                          (bool success) => setState(() {
                                                if (file ==
                                                    _filesToBeTransferred.keys
                                                        .toList()
                                                        .last) {
                                                  setState(() {
                                                    _isTransferOn = false;
                                                    _transferProgressWidgets[
                                                                _peerIP]
                                                            .peerStat =
                                                        'Transfer Complete';
                                                  });
                                                }
                                              }),
                                        );
                                  });
                              },
                              onError: (e) => setState(() {
                                    _transferProgressWidgets[_peerIP].peerStat =
                                        'Transfer Failed';
                                  }),
                            );
                          },
              ),
            ],
          ),
        ),
      );
}
