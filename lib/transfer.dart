import 'package:flutter/material.dart';
import 'peer_finder.dart' show PeerInfoHolder;
import 'package:flutter/services.dart' show MethodChannel;
import 'server.dart';
import 'client.dart';
import 'dart:io' show File, InternetAddress;
import 'package:path/path.dart' as pathHandler;
import 'dart:io';

class Sender extends StatefulWidget {
  final MethodChannel methodChannel;
  final PeerInfoHolder peerInfoHolder;

  Sender({Key key, @required this.methodChannel, @required this.peerInfoHolder})
      : super(key: key);

  @override
  _SenderState createState() => _SenderState();
}

class _SenderState extends State<Sender> implements ServerStatusCallBack {
  Map<String, int>
      _filteredPeers; // PEERs which are going to take part in transfer
  Map<String, int> _filesToBeTransferred; // files to be transferred
  Server _server; // server object
  Client _client; // client Object
  Map<String, List<Map<String, double>>>
      _peerStatus; // keeps track of status of PEER
  String
      _targetHomeDir; // gets directory path, where to store files, fetched from PEER
  bool _isFileChosen; // helps to update UI
  bool _isTransferOn; // helps to update UI
  int _serverSideDownloadCount;

  @override
  void initState() {
    super.initState();
    _filesToBeTransferred = <String, int>{};
    _serverSideDownloadCount = 0;
    _isFileChosen = false; // at first no file chosen
    _isTransferOn = false; // at first, transfer not started
    _peerStatus = {};
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
        if (widget.peerInfoHolder.getSelectedPeers()[key]) {
          _peerStatus[key] = [];
          return MapEntry(key, val);
        }
      });

  @override
  updateServerStatus(Map<String, String> msg) {
    // mostly lets user know about PEER's activity
    msg.forEach((key, val) {
      setState(() {
        _peerStatus[key].add(val);
      });
      _serverSideDownloadCount += val.startsWith('Fetched ') ? 1 : 0;
    });
    if (_serverSideDownloadCount ==
        _filteredPeers.length * _filesToBeTransferred.length) {
      setState(() {
        // indicates completion of full transfer, when working as Server
        _isTransferOn = false;
        _isFileChosen = false;
        _filesToBeTransferred = {};
      });
      vibrateDevice();
    }
  }

  @override
  generalUpdate(String msg) =>
      // in case of general update, this callback is mostly invoked to let user know about SELF status, when device is in `send` mode.
      showToast(msg, 'short');

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
          title: Text('transferZ'),
          backgroundColor: Colors.tealAccent,
          elevation: 16,
        ),
        body: Container(
          padding: EdgeInsets.only(
            top: 16,
            bottom: 16,
          ),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              gradient: LinearGradient(
            colors: [Colors.tealAccent, Colors.cyanAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, indexP) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: 12,
                        bottom: 12,
                        left: 12,
                        right: 12,
                      ),
                      child: Card(
                        color: Colors.white54,
                        elevation: 16,
                        child: Column(
                          children: <Widget>[
                            Padding(
                              child: Text(
                                '\u{1f4f1} ${_filteredPeers.keys.toList()[indexP]}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textScaleFactor: 1.5,
                              ),
                              padding: EdgeInsets.only(
                                  top: 16, bottom: 16, left: 8, right: 8),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 4.5,
                              width: MediaQuery.of(context).size.width * .9,
                              child: _peerStatus[
                                          _filteredPeers.keys.toList()[indexP]]
                                      .isEmpty
                                  ? Center(
                                      child: Icon(
                                        IconData(128564),
                                        size: 75,
                                      ),
                                    )
                                  : ListView.builder(
                                      itemBuilder: (context, indexC) {
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            left: 12,
                                            right: 12,
                                            top: 8,
                                            bottom: 8,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(18),
                                            ),
                                            child: Card(
                                              elevation: 12,
                                              color: Color(745822),
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: 16,
                                                    bottom: 16,
                                                    left: 6,
                                                    right: 6),
                                                child: Text(
                                                  _peerStatus[_filteredPeers
                                                          .keys
                                                          .toList()[indexP]]
                                                      [indexC],
                                                  style: TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 6,
                                                  softWrap: true,
                                                  overflow: TextOverflow.fade,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      itemCount: _peerStatus[_filteredPeers.keys
                                              .toList()[indexP]]
                                          .length,
                                    ),
                            ),
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                      ),
                    );
                  },
                  itemCount: _filteredPeers.length,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: RaisedButton(
                  textColor: Colors.white,
                  // well this place is pretty complicated, cause it uses nested ternary expressions
                  onPressed: widget.peerInfoHolder.type == 'send'
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
                                      setState(() {
                                        _isTransferOn = true;
                                        _peerStatus.forEach((key, val) =>
                                            _peerStatus[key] = []);
                                      });
                                      _server.init();
                                    }
                                  }
                                }
                          // or not, select files
                          : () {
                              initFileChooser().then((filePaths) {
                                _filesToBeTransferred = Map.fromEntries(
                                    filePaths
                                        .map((elem) {
                                          if (File(elem).existsSync())
                                            return elem;
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
                                _client = Client(key, val);
                                //_peerPort = val;
                              });
                              setState(() {
                                _isTransferOn = true;
                                _peerStatus[_peerIP] = [
                                  'Connecting to Peer ...'
                                ];
                              });
                              _client.fetchFileNames().then(
                                (Map<String, int> fileNames) {
                                  _filesToBeTransferred = fileNames;
                                  if (_filesToBeTransferred.isEmpty) {
                                    setState(() {
                                      _isTransferOn = false;
                                      _peerStatus[_peerIP]
                                          .add('Nothing to fetch');
                                    });
                                  } else
                                    _filesToBeTransferred
                                        .forEach((String file, int fileSize) {
                                      setState(() {
                                        _peerStatus[_peerIP].add(
                                            'Fetching ${pathHandler.basename(file)}');
                                      });
                                      _client
                                          .fetchFile(
                                              file, fileSize, _targetHomeDir)
                                          .then(
                                            (bool success) => setState(() {
                                                  _peerStatus[_peerIP].add(success
                                                      ? 'Fetched ${pathHandler.basename(file)}'
                                                      : 'Failed to fetch ${pathHandler.basename(file)}');
                                                  if (file ==
                                                      _filesToBeTransferred.keys
                                                          .toList()
                                                          .last) {
                                                    setState(() {
                                                      _isTransferOn = false;
                                                      _peerStatus[_peerIP].add(
                                                          'Transfer Complete');
                                                    });
                                                  }
                                                }),
                                          );
                                    });
                                },
                                onError: (e) => setState(() {
                                      _peerStatus[_peerIP]
                                          .add('Something went wrong');
                                    }),
                              );
                            },
                  child: Text(widget.peerInfoHolder.type == 'send'
                      ? _isFileChosen
                          ? _isTransferOn ? 'Abort Transfer' : 'Init Transfer'
                          : 'Choose File(s)'
                      : _isTransferOn
                          ? 'Abort Transfer'
                          : 'Request File(s) from Peer'),
                  color: _isTransferOn ? Colors.red : Colors.teal,
                  elevation: 20,
                  padding: EdgeInsets.all(6),
                ),
              ),
            ],
          ),
        ),
      );
}
