import 'dart:io';
import 'dart:convert' show json, utf8;
import 'package:path/path.dart' as pathHandler;
import 'transfer_status.dart';

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
                  {_targetHost: TransferStatus.connectionFailed}))
          .then((HttpClientResponse resp) {
        String msg;
        if (resp.statusCode == 200) {
          if (path == '/') {
            // accessible file list being fetched from PEER
            resp.listen((List<int> data) {
              msg = utf8.decode(data);
            }, onDone: () {
              _httpClient.close();
              _clientStatusCallBack
                  .onFileListFound(serializeJSONResponse(msg)['files']);
            },
                onError: (e) => _clientStatusCallBack.updateClientStatus(
                    {_targetHost: TransferStatus.transferError}));
          } else if (path == '/done') {
            resp.listen((List<int> data) {
              msg = utf8.decode(data);
            }, onDone: () {
              _httpClient.close();
              _clientStatusCallBack.updateClientStatus(
                  {_targetHost: TransferStatus.transferComplete});
            },
                onError: () => _clientStatusCallBack.updateClientStatus(
                    {_targetHost: TransferStatus.transferError}));
          } else if (path == '/undone') {
            resp.listen((List<int> data) {
              msg = utf8.decode(data);
            }, onDone: () {
              _httpClient.close();
              _clientStatusCallBack.updateClientStatus(
                  {_targetHost: TransferStatus.transferIncomplete});
            },
                onError: () => _clientStatusCallBack.updateClientStatus(
                    {_targetHost: TransferStatus.transferError}));
          } else {
            _clientStatusCallBack.updateClientStatus(
                {_targetHost: TransferStatus.fileFetchInProgress});
            File(pathHandler.join(_storagePath, pathHandler.basename(path)))
                .openWrite(mode: FileMode.write)
                .addStream(resp)
                .then((val) {
              _httpClient.close();
              _clientStatusCallBack.updateClientStatus(
                  {_targetHost: TransferStatus.fileFetched});
            }, onError: (e) {
              _clientStatusCallBack.updateClientStatus(
                  {_targetHost: TransferStatus.transferError});
            });
          }
        } else {
          resp.listen((List<int> data) {
            msg = utf8.decode(data);
          }, onDone: () {
            _httpClient.close();
            _clientStatusCallBack.updateClientStatus({
              _targetHost: Map<String, int>.from(json.decode(msg))['status']
            });
          },
              onError: (e) => _clientStatusCallBack.updateClientStatus(
                  {_targetHost: TransferStatus.transferError}));
        }
      }).catchError((e) {
        _clientStatusCallBack
            .updateClientStatus({_targetHost: TransferStatus.transferError});
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
  updateClientStatus(Map<String, int> msg);
  onFileListFound(List<String> files);
}
