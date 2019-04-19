import 'dart:io';
import 'dart:convert' show json, utf8;
import 'package:path/path.dart' as pathHandler;

class Client {
  String _targetHost;
  int _targetPort;
  String _storagePath;
  ClientStatusCallBack _clientStatusCallBack;

  Client(this._targetHost, this._targetPort, this._storagePath,
      this._clientStatusCallBack);

  HttpClient _httpClient;

  sendRequest(String path) {
    _httpClient = HttpClient()
      ..get(this._targetHost, this._targetPort, path)
          .then((HttpClientRequest req) => req.close(),
              onError: (e) => _clientStatusCallBack.updateClientStatus(
                  {_targetHost: 'Connection Failed \u{1f644}'}))
          .then((HttpClientResponse resp) {
        String msg;
        if (resp.statusCode == 200) {
          if (path == '/') {
            resp.listen((List<int> data) {
              msg = utf8.decode(data);
            }, onDone: () {
              _httpClient.close();
              _clientStatusCallBack.onFileListFound(serializeJSONResponse(msg));
            });
          } else if (path == '/done') {
            resp.listen((List<int> data) {
              msg = utf8.decode(data);
            }, onDone: () {
              _httpClient.close();
              _clientStatusCallBack.updateClientStatus({
                _targetHost:
                    Map<String, String>.from(json.decode(msg))['status']
              });
            },
                onError: () => _clientStatusCallBack
                    .updateClientStatus({_targetHost: 'Transfer failed'}));
          } else if (path == '/undone') {
            resp.listen((List<int> data) {
              msg = utf8.decode(data);
            }, onDone: () {
              _httpClient.close();
              _clientStatusCallBack.updateClientStatus({
                _targetHost:
                    Map<String, String>.from(json.decode(msg))['status']
              });
            },
                onError: () => _clientStatusCallBack
                    .updateClientStatus({_targetHost: 'Transfer failed'}));
          } else {
            File(pathHandler.join(_storagePath, pathHandler.basename(path)))
                .openWrite(mode: FileMode.write)
                .addStream(resp)
                .then((val) {
              _httpClient.close();
              _clientStatusCallBack.updateClientStatus(
                  {_targetHost: 'Fetched ${path.split('/').last}'});
            }, onError: (e) {
              _clientStatusCallBack
                  .updateClientStatus({_targetHost: 'Transfer failed'});
            });
          }
        } else {
          resp.listen((List<int> data) {
            msg = utf8.decode(data);
          }, onDone: () {
            _httpClient.close();
            _clientStatusCallBack.updateClientStatus({
              _targetHost: Map<String, String>.from(json.decode(msg))['status']
            });
          },
              onError: (e) => _clientStatusCallBack
                  .updateClientStatus({_targetHost: 'Transfer failed'}));
        }
      }).catchError((e) {
        _clientStatusCallBack.updateClientStatus({_targetHost: 'failed'});
        _httpClient?.close();
      });
  }

  stopClient() {
    _httpClient?.close(force: true);
  }

  Map<String, List<String>> serializeJSONResponse(String msg) {
    return Map<String, dynamic>.from(json.decode(msg)).map((key, val) {
      return MapEntry(key, List<String>.from(val));
    });
  }
}

abstract class ClientStatusCallBack {
  updateClientStatus(Map<String, String> msg);
  onFileListFound(Map<String, List<String>> files);
}
