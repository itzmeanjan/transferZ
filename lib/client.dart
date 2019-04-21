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
