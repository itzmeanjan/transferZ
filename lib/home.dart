import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  MethodChannel _methodChannel;
  String _methodChannelName;
  bool _isPermissionAvailable;
  String _homeDir;

  @override
  void initState() {
    super.initState();
    _isPermissionAvailable = false;
    _methodChannelName = 'io.github.itzmeanjan.transferz';
    _methodChannel = MethodChannel(_methodChannelName);
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

  Future<bool> isPermissionAvailable() async {
    return await _methodChannel
        .invokeMethod('isPermissionAvailable')
        .then((val) => val);
  }

  Future<bool> requestPermission() async {
    return await _methodChannel
        .invokeMethod('requestPermission')
        .then((val) => val);
  }

  Future<String> getHomeDir() async {
    return await _methodChannel.invokeMethod('getHomeDir',
        <String, String>{'dirName': 'transferZ'}).then((val) => val);
  }

  Future<List<String>> initFileChooser() async {
    return await _methodChannel
        .invokeMethod('initFileChooser')
        .then((val) => List<String>.from(val));
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
                    color: Colors.white,
                  ),
                  Text(
                    'Storage Access Permission Required',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                requestPermission().then((res) {
                  setState(() {
                    _isPermissionAvailable = res;
                  });
                });
              },
              child: Icon(Icons.sd_storage),
              tooltip: 'Grant Storage Access',
              elevation: 16,
              backgroundColor: Colors.tealAccent,
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
                      iconSize: 60,
                      splashColor: Colors.white,
                      icon: Icon(
                        Icons.file_upload,
                        color: Colors.cyan,
                      ),
                      onPressed: () {
                        initFileChooser().then((filePaths) {
                          filePaths.forEach((file) => print(file));
                        });
                      },
                      tooltip: 'Send File',
                    ),
                    IconButton(
                      splashColor: Colors.white,
                      iconSize: 60,
                      icon: Icon(
                        Icons.file_download,
                        color: Colors.teal,
                      ),
                      onPressed: () {},
                      tooltip: 'Receive File',
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
