import 'dart:io';
import 'dart:convert' show json, utf8;
import 'dart:async' show Completer;

class Client {
  String _peerIP;
  int _peerPort;

  HttpClient _httpClient;

  Client(this._peerIP, this._peerPort) {
    _httpClient = HttpClient();
  }

  Future<HttpClientRequest> connect(String path) async => await _httpClient
      .get(this._peerIP, this._peerPort, path)
      .catchError((e) => null);

  Future<List<String>> fetchFileNames(HttpClientRequest req) async {
    var fileNames = <String, List<String>>{};
    var completer = Completer<List<String>>();
    await req.close().then((HttpClientResponse resp) {
      if (resp.statusCode == 200)
        resp.listen((data) => fileNames = serializeJSON(utf8.decode(data)),
            onDone: () => completer.complete(fileNames['files']),
            onError: (e) => completer.complete(<String>[]),
            cancelOnError: true);
      else
        resp.listen(
          (data) {}, // just listen for data stream, and simply send a blank list of Strings
          onDone: () => completer.complete(<String>[]),
          onError: (e) => completer.complete(<String>[]),
          cancelOnError: true,
        );
    });
    return completer.future;
  }

  Map<String, List<String>> serializeJSON(String data) {
    return Map<String, dynamic>.from(json.decode(data))
        .map((key, val) => MapEntry(key, List<String>.from(val)));
  }

  Future<bool> fetchFile(HttpClientRequest req, String targetPath) async {
    var completer = Completer<bool>();
    await req.close().then((HttpClientResponse resp) {
      if (resp.statusCode == 200)
        File(targetPath).openWrite(mode: FileMode.write).addStream(resp).then(
              (val) => completer.complete(true),
              onError: (e) => completer.complete(false),
            );
      else
        resp.listen(
          (data) {},
          onDone: () => completer.complete(false),
          onError: (e) => completer.complete(false),
          cancelOnError: true,
        );
    });
    return completer.future;
  }

  disconnect() =>
      // never force close a http connection, by passing force attribute's value true, which might lead to inconsistent connection state
      _httpClient?.close();
}

/*
import 'dart:io';
import 'dart:convert' show utf8;
import 'dart:async' show Completer;

main() => fetchFileNames().then(
      (List<String> fileNames) {
        if (fileNames.isEmpty)
          print('[!]No files to fetch');
        else
          fileNames.forEach((String file) {
            print('Fetching $file ...');
            fetchFile(file).then(
              (bool success) =>
                  print(success ? 'Fetched $file' : 'Failed to fetch $file'),
            );
          });
      },
      onError: (e) => print(e),
    );

Future<List<String>> fetchFileNames() {
  var completer = Completer<List<String>>();
  Socket.connect(InternetAddress.anyIPv6, 8000).then(
    (Socket socket) {
      socket.listen(
        (List<int> data) {
          socket.close();
          print('Fetched filenames');
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

Future<bool> fetchFile(String fileName) {
  var completer = Completer<bool>();
  Socket.connect(InternetAddress.anyIPv6, 8000).then(
    (Socket socket) {
      File(fileName.split('/').last)
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

 */
