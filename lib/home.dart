import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';
import 'dart:math' show min;
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
    SystemChrome.setEnabledSystemUIOverlays([]);
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
    directory.exists().then((val) => !val ? directory.create() : null);
  }

  @override
  Widget build(BuildContext context) {
    return !_isPermissionAvailable
        ? Scaffold(
            appBar: AppBar(
              title: Image.asset(
                'logo/logotype-horizontal.png',
              ),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    child: Icon(
                      Icons.airplanemode_active,
                      color: Colors.red,
                      size: min(
                            MediaQuery.of(context).size.height,
                            MediaQuery.of(context).size.width,
                          ) *
                          .5,
                      semanticLabel: 'Blocked',
                    ),
                    padding: EdgeInsets.all(
                      12,
                    ),
                  ),
                  Text(
                    _initText,
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: floatingActionButtonCallBack,
              child: Icon(Icons.sd_storage),
              tooltip: 'Grant Storage Access',
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Image.asset(
                'logo/logotype-horizontal.png',
              ),
              centerTitle: true,
            ),
            body: Container(
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
                        color: Colors.cyanAccent,
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
                        color: Colors.tealAccent,
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
