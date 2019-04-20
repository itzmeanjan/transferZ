import 'dart:io';
import 'dart:convert' show json;
import 'transfer_status.dart';

class Server {
  String _host;
  int _port;
  List<String> _filteredPeers;
  List<String> _files;
  ServerStatusCallBack _serverStatusCallBack;
  bool isStopped = true;

  Server(this._host, this._port, this._filteredPeers, this._files,
      this._serverStatusCallBack);

  HttpServer _httpServer;

  Future initServer() async {
    _httpServer = await HttpServer.bind(this._host, this._port)
        .whenComplete(() =>
            _serverStatusCallBack.generalUpdate(TransferStatus.serverStarted))
        .catchError((e) {
      _serverStatusCallBack.generalUpdate(TransferStatus.serverStartFailed);
      stopServer();
    });
    isStopped = false;
    await for (HttpRequest request in _httpServer) {
      handleRequest(request);
    }
  }

  handleRequest(HttpRequest request) {
    if (isAccessGranted(request.connectionInfo.remoteAddress.address)) {
      if (request.method == 'GET')
        handleGETRequest(request);
      else {
        request.response
          ..statusCode = HttpStatus.methodNotAllowed
          ..headers.contentType = ContentType.json
          ..write(json.encode(
              <String, int>{'status': TransferStatus.fetchMethodNotAllowed}))
          ..close().then(
              (val) => _serverStatusCallBack.updateServerStatus({
                    request.connectionInfo.remoteAddress.host:
                        TransferStatus.fetchMethodNotAllowed
                  }), onError: (e) {
            _serverStatusCallBack.updateServerStatus({
              request.connectionInfo.remoteAddress.host:
                  TransferStatus.transferError
            });
          });
      }
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(
            json.encode(<String, int>{'status': TransferStatus.fetchDenied}))
        ..close().then(
            (val) =>
                _serverStatusCallBack.generalUpdate(TransferStatus.fetchDenied),
            onError: (e) {
          _serverStatusCallBack.generalUpdate(TransferStatus.transferError);
        });
    }
  }

  bool isAccessGranted(String remoteAddress) {
    return this._filteredPeers.contains(remoteAddress);
  }

  handleGETRequest(HttpRequest getRequest) {
    if (getRequest.uri.path == '/') {
      getRequest.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode(<String, List<String>>{"files": this._files}))
        ..close().then(
            (val) => _serverStatusCallBack.updateServerStatus({
                  getRequest.connectionInfo.remoteAddress.host:
                      TransferStatus.accessibleFileListShared
                }), onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                TransferStatus.transferError
          });
        });
    } else if (getRequest.uri.path == '/done') {
      getRequest.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'status': TransferStatus.transferComplete}))
        ..close().then((val) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                TransferStatus.transferComplete
          });
        }, onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                TransferStatus.transferError
          });
        });
    } else if (getRequest.uri.path == '/undone') {
      getRequest.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'status': TransferStatus.transferIncomplete}))
        ..close().then((val) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                TransferStatus.transferIncomplete
          });
        }, onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                TransferStatus.transferError
          });
        });
    } else {
      if (this._files.contains(getRequest.uri.path)) {
        getRequest.response.statusCode = HttpStatus.ok;
        _serverStatusCallBack.updateServerStatus({
          getRequest.connectionInfo.remoteAddress.host:
              TransferStatus.fileFetchInProgress
        });
        getRequest.response
            .addStream(File(getRequest.uri.path).openRead())
            .then((val) {
          getRequest.response.close();
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                TransferStatus.fileFetched
          });
        }, onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                TransferStatus.transferError
          });
        });
      }
    }
  }

  stopServer() {
    isStopped = true;
    _httpServer?.close(force: true);
    _serverStatusCallBack.generalUpdate(TransferStatus.serverStopped);
  }
}

abstract class ServerStatusCallBack {
  updateServerStatus(Map<String, int> msg);

  generalUpdate(int msg);
}
