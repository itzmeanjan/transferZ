import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'peer_finder.dart' show PeerFinder;

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  MethodChannel _methodChannel;
  String _methodChannelName;
  bool _isPermissionAvailable;
  String _homeDir;
  String _initText;

  @override
  void initState() {
    super.initState();
    _methodChannelName = 'io.github.itzmeanjan.transferz';
    _methodChannel = MethodChannel(_methodChannelName);
    _isPermissionAvailable = false;
    _initText = 'Storage Access Permission Required';
    isPermissionAvailable().then((val) {
      if (!val)
        requestPermission().then((res) {
          setState(() {
            _isPermissionAvailable = res;
          });
          if (res)
            getHomeDir().then((value) {
              _homeDir = value;
              createDirectory(_homeDir);
            });
        });
      else {
        setState(() {
          _isPermissionAvailable = true;
        });
        getHomeDir().then((value) {
          _homeDir = value;
          createDirectory(_homeDir);
        });
      }
    });
  }

  Future<bool> isPermissionAvailable() async => await _methodChannel
      .invokeMethod('isPermissionAvailable')
      .then((val) => val);

  Future<bool> requestPermission() async =>
      await _methodChannel.invokeMethod('requestPermission').then((val) => val);

  Future<String> getHomeDir() async => await _methodChannel.invokeMethod(
      'getHomeDir',
      <String, String>{'dirName': 'transferZ'}).then((val) => val);

  Future<List<String>> initFileChooser() async => await _methodChannel
      .invokeMethod('initFileChooser')
      .then((val) => List<String>.from(val));

  Future<void> showToast(String message, String duration) async =>
      // simply show a toast message
      await _methodChannel.invokeMethod('showToast',
          <String, String>{'message': message, 'duration': duration});

  Future<bool> isConnected() async =>
      // checks whether we're connected to internet or not
      await _methodChannel.invokeMethod('isConnected').then((val) => val);

  vibrateDevice({String type: 'tick'}) async =>
      // uses platform channel to vibrate device using a certain type of VibrationEffect
      // in this case I'm using a single shot click vibrator
      await _methodChannel
          .invokeMethod('vibrateDevice', <String, String>{'type': type});

  floatingActionButtonCallBack() {
    requestPermission().then((res) {
      setState(() {
        _isPermissionAvailable = res;
      });
      if (res)
        getHomeDir().then((value) {
          _homeDir = value;
          createDirectory(_homeDir);
        });
    });
  }

  createDirectory(String dirName) {
    Directory directory = Directory(dirName);
    directory.exists().then((val) {
      if (!val) {
        directory.create().then((value) {
          print('directory created -- ${value.path}');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return !_isPermissionAvailable
        ? Scaffold(
            appBar: AppBar(
              title: Text('transferZ'),
              backgroundColor: Colors.tealAccent,
              elevation: 16,
            ),
            backgroundColor: Colors.grey,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.sentiment_dissatisfied,
                    size: 100,
                  ),
                  Text(
                    _initText,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: floatingActionButtonCallBack,
              child: Icon(Icons.sd_storage),
              tooltip: 'Grant Storage Access',
              elevation: 16,
              backgroundColor: Colors.teal,
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Text('transferZ'),
              backgroundColor: Colors.tealAccent,
              elevation: 16,
            ),
            body: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [Colors.tealAccent, Colors.cyanAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      iconSize: 75,
                      splashColor: Colors.white,
                      icon: Icon(
                        Icons.file_upload,
                        color: Colors.cyan,
                      ),
                      onPressed: () => isConnected().then((val) {
                            if (val)
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => PeerFinder(
                                        type: 'send',
                                        methodChannel: _methodChannel,
                                      )));
                            else {
                              vibrateDevice();
                              showToast('Get connected to WIFI', 'short');
                            }
                          }),
                      tooltip: 'Send File',
                    ),
                    IconButton(
                      splashColor: Colors.white,
                      iconSize: 75,
                      icon: Icon(
                        Icons.file_download,
                        color: Colors.teal,
                      ),
                      onPressed: () => isConnected().then((val) {
                            if (val)
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => PeerFinder(
                                        type: 'receive',
                                        methodChannel: _methodChannel,
                                      )));
                            else {
                              vibrateDevice();
                              showToast('Get connected to WIFI', 'short');
                            }
                          }),
                      tooltip: 'Receive File',
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
