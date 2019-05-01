import 'dart:io';
import 'dart:convert' show utf8;
import 'dart:async' show Completer;
import 'package:path/path.dart' as pathHandler;

class Client {
  String _peerIP;
  int _peerPort;

  Socket _socket;

  Client(this._peerIP, this._peerPort);

  Future<List<String>> fetchFileNames() {
    var completer = Completer<List<String>>();
    Socket.connect(_peerIP, _peerPort).then(
      (Socket socket) {
        socket.listen(
          (List<int> data) {
            socket.close();
            completer.complete(utf8.decode(data).split(';'));
          },
          onError: (e) {
            socket.close();
            completer.complete([]);
          },
          cancelOnError: true,
        );
        socket.write('/file');
      },
      onError: (e) => completer.complete([]),
    );
    return completer.future;
  }

  Future<bool> fetchFile(String fileName, String targetPath) {
    var completer = Completer<bool>();
    Socket.connect(_peerIP, _peerPort).then(
      (Socket socket) {
        File(pathHandler.join(targetPath, pathHandler.basename(fileName)))
            .openWrite(mode: FileMode.write)
            .addStream(socket)
            .then(
          (val) {
            socket.close();
            completer.complete(true);
          },
          onError: (e) {
            socket.close();
            completer.complete(false);
          },
        );
        socket.write(fileName);
      },
      onError: (e) => completer.complete(false),
    );
    return completer.future;
  }

  disconnect() => _socket?.close();
}
