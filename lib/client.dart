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
}
