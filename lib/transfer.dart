import 'package:flutter/material.dart';
import 'peer_finder.dart' show PeerInfoHolder;
import 'package:flutter/services.dart' show MethodChannel;
import 'server.dart';
import 'client.dart';
import 'package:path/path.dart' as pathHandler;
import 'dart:io' show File;

class Sender extends StatefulWidget {
  final MethodChannel methodChannel;
  final PeerInfoHolder peerInfoHolder;

  Sender({Key key, @required this.methodChannel, @required this.peerInfoHolder})
      : super(key: key);

  @override
  _SenderState createState() => _SenderState();
}

class _SenderState extends State<Sender>
    implements ServerStatusCallBack, ClientStatusCallBack {
  Map<String, int> _filteredPeers;
  List<String> _filesToBeTransferred;
  Server _server;
  Client _client;
  Map<String, String> _peerStatus;
  bool _isFileChosen;
  bool _isTransferOn;
  String _homeDir;

  Future<List<String>> initFileChooser() async {
    return await widget.methodChannel
        .invokeMethod('initFileChooser')
        .then((val) => List<String>.from(val));
  }

  @override
  void initState() {
    super.initState();
    _filesToBeTransferred = [];
    _isFileChosen = false;
    _isTransferOn = false;
    _peerStatus = {};
    _filteredPeers = filterEligiblePeers();
    if (widget.peerInfoHolder.type == 'send')
      _server = Server('0.0.0.0', 8000, _filteredPeers.keys.toList(),
          _filesToBeTransferred, this);
    else
      getHomeDir().then((val) {
        _homeDir = val;
        _client = Client(_filteredPeers.keys.toList()[0],
            _filteredPeers.values.toList()[0], _homeDir, this);
      });
  }

  Map<String, int> filterEligiblePeers() {
    // As user has to explicitly select certain device identifier(s), it passes them, otherwise gets discarded
    return widget.peerInfoHolder.getPeers().map((key, val) {
      if (widget.peerInfoHolder.getSelectedPeers()[key]) {
        _peerStatus[key] = 'NA';
        return MapEntry(key, val);
      }
    });
  }

  @override
  updateServerStatus(Map<String, String> msg) {
    setState(() {
      if (msg.values.toList()[0] == 'done') {
        _isTransferOn = false;
        _isFileChosen = false;
      }
      _peerStatus[msg.keys.toList()[0]] = msg.values.toList()[0];
    });
  }

  @override
  generalUpdate(String msg) {
    print(msg);
  }

  @override
  updateClientStatus(Map<String, String> msg) {
    setState(() {
      if (msg.values.toList()[0] == 'failed') {
        _isTransferOn = false;
        _peerStatus[msg.keys.toList()[0]] = 'It didn\'t work';
      } else
        _peerStatus[msg.keys.toList()[0]] = msg.values.toList()[0];
    });
  }

  @override
  onFileListFound(Map<String, List<String>> files) {
    // this is the list of files which are going to be downloaded by client from server( Peer )
    // client keeps sending requests for those file and fetches them
    // when this process completes, client sends final confirmation to server, that completion was successful
    files.forEach((key, val) {
      val.forEach((elem) {
        setState(() => _peerStatus[_filteredPeers.keys.toList()[0]] =
            'Fetching ${pathHandler.basename(elem)}');
        vibrateDevice();
        _client.sendRequest(elem);
      });
      areAllFilesDownloaded(val
              .map((elem) =>
                  pathHandler.join(_homeDir, pathHandler.basename(elem)))
              .toList())
          ? _client.sendRequest('/done')
          : _client.sendRequest('/undone');
      setState(() => _isTransferOn = false);
    });
  }

  bool areAllFilesDownloaded(List<String> files) {
    // checks whether all files, which were supposed to be transferred, are done successfully
    return files.every((file) {
      return File(file).existsSync();
    });
  }

  Future<String> getHomeDir() async {
    // fetches path to homeDir, actually this is the directory where I'm going to store all files fetched from any peers
    return await widget.methodChannel.invokeMethod('getHomeDir',
        <String, String>{'dirName': 'transferZ'}).then((val) => val);
  }

  vibrateDevice({String type: 'tick'}) async {
    // uses platform channel to vibrate device using a certain type of VibrationEffect
    // in this case I'm using a single shot click vibrator
    await widget.methodChannel
        .invokeMethod('vibrateDevice', <String, String>{'type': type});
  }

  showToast(String message, String duration) async {
    await widget.methodChannel.invokeMethod('showToast',
        <String, String>{'message': message, 'duration': duration});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: 12,
                      bottom: 12,
                      left: 10,
                      right: 10,
                    ),
                    child: Card(
                      color: Colors.greenAccent,
                      elevation: 16,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            child: Text(
                              '\u{1f4f1} <--> ${_filteredPeers.keys.toList()[index]}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textScaleFactor: 2,
                            ),
                            padding: EdgeInsets.only(
                                top: 16, bottom: 16, left: 8, right: 8),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: 16, bottom: 16, left: 6, right: 6),
                            child: Text(
                              _peerStatus[_filteredPeers.keys.toList()[index]],
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 10,
                              ),
                              textScaleFactor: 1.3,
                              maxLines: 6,
                              softWrap: true,
                              overflow: TextOverflow.fade,
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
                                  _server.stopServer();
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
                                    _server.initServer();
                                    setState(() => _isTransferOn = true);
                                  }
                                }
                              }
                        // or not, select files
                        : () {
                            initFileChooser().then((filePaths) {
                              _filesToBeTransferred = filePaths.map((elem) {
                                if (File(elem).existsSync()) return elem;
                              }).toList();
                              if (_filesToBeTransferred.isNotEmpty)
                                setState(() => _isFileChosen = true);
                              else
                                showToast('Select onDevice Files', 'short');
                            });
                          }
                    // or receive operation
                    : _isTransferOn
                        // check if user has started transfer
                        ? () {
                            _client.stopClient();
                            setState(() => _isTransferOn = false);
                          }
                        // or not
                        : () {
                            _client.sendRequest('/');
                            setState(() {
                              _isTransferOn = true;
                              _peerStatus[_filteredPeers.keys.toList()[0]] =
                                  'Requesting file list ...';
                            });
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
}
