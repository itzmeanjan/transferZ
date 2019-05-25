import 'dart:io';
import 'dart:convert' show utf8, json;
import 'dart:async' show Completer, Timer;
import 'package:path/path.dart' as pathHandler;

class Client {
  String _peerIP;
  int _peerPort;
  ClientStatusCallBack _clientStatusCallBack;

  Socket _socket;

  Client(this._peerIP, this._peerPort, this._clientStatusCallBack);

  Future<Map<String, int>> fetchFileNames() {
    var completer = Completer<Map<String, int>>();
    Socket.connect(_peerIP, _peerPort).then(
      (Socket socket) {
        _socket = socket;
        socket.listen(
          (List<int> data) {
            socket.close();
            completer.complete(
                Map<String, int>.from(json.decode(utf8.decode(data))));
          },
          onError: (e) {
            socket.close();
            completer.complete({});
          },
          cancelOnError: true,
        );
        socket.write('/file');
      },
      onError: (e) => completer.complete({}),
    );
    return completer.future;
  }

  /// asks remote where does it want to listen for transfer progress update
  /// if remote is not interested in listening in any update, it will simply respond with -1, which is not a valid port number
  /// else it will return port number on which peer will listen using UDP
  Future<int> fetchProgressListenerPort() {
    var completer = Completer<int>();
    Socket.connect(_peerIP, _peerPort).then(
      (Socket socket) {
        socket.listen(
          (data) => socket.close().then(
                (val) => completer.complete(int.parse(utf8.decode(data))),
                onError: (e) => completer.complete(-1),
              ),
          cancelOnError: true,
          onError: (e) => socket.close().then(
                (val) => completer.complete(-1),
                onError: (e) => completer.complete(-1),
              ),
        );
        socket.write('/progressListener');
      },
      onError: (e) => completer.complete(-1),
    );
    return completer.future;
  }

  Future<bool> fetchFile(String fileName, int fileSize, String targetPath) {
    var completer = Completer<bool>();
    var file =
        File(pathHandler.join(targetPath, pathHandler.basename(fileName)));
    var timer = Timer.periodic(
        Duration(
          seconds: 1,
        ), (_timer) {
      if (_timer.isActive)
        file.exists().then((bool existence) {
          if (existence)
            file.length().then((int length) {
              if (fileFetchedRatio(fileSize, length).toInt() == 1)
                _timer.cancel();
              _clientStatusCallBack.updateTransferStatusClientSide(
                  {fileName: fileFetchedRatio(fileSize, length)});
              _clientStatusCallBack
                  .updateTransferStatusTimeSpent({fileName: _timer.tick});
            });
          else
            _clientStatusCallBack.updateTransferStatusClientSide({fileName: 0});
        });
    });
    Socket.connect(_peerIP, _peerPort).then(
      (Socket socket) {
        _socket = socket;
        File(pathHandler.join(targetPath, pathHandler.basename(fileName)))
            .openWrite(mode: FileMode.write)
            .addStream(_socket)
            .then(
          (val) {
            _socket.close();
            timer.cancel();
            completer.complete(true);
          },
          onError: (e) {
            _socket.close();
            timer.cancel();
            completer.complete(false);
          },
        );
        socket.write(fileName);
      },
      onError: (e) => completer.complete(false),
    );
    return completer.future;
  }

  double fileFetchedRatio(int totalSize, int fetchedSize) =>
      fetchedSize / totalSize;

  disconnect() => _socket?.destroy();
}

abstract class ClientStatusCallBack {
  updateTransferStatusClientSide(Map<String, double> stat);
  updateTransferStatusTimeSpent(Map<String, int> stat);
}
