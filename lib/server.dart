import 'dart:io';
import 'dart:convert' show json;
import 'package:path/path.dart' as pathHandler;

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
        .whenComplete(
            () => _serverStatusCallBack.generalUpdate('Server listening ...'))
        .catchError((e) {
      _serverStatusCallBack.generalUpdate('Couldn\'t start Server');
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
          ..write(json.encode(<String, String>{'status': 'GET Method Only'}))
          ..close().then(
              (val) => _serverStatusCallBack.updateServerStatus({
                    request.connectionInfo.remoteAddress.host: 'get method only'
                  }), onError: (e) {
            _serverStatusCallBack.updateServerStatus({
              request.connectionInfo.remoteAddress.host: 'Didn\'t complete'
            });
          });
      }
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(json.encode(<String, String>{'status': 'Access Denied'}))
        ..close().then(
            (val) => _serverStatusCallBack.updateServerStatus(
                {request.connectionInfo.remoteAddress.host: 'access denied'}),
            onError: (e) {
          _serverStatusCallBack.updateServerStatus(
              {request.connectionInfo.remoteAddress.host: 'Didn\'t complete'});
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
                      'Fetching file names ...'
                }), onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host: 'Didn\'t complete'
          });
        });
    } else if (getRequest.uri.path == '/done') {
      getRequest.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'status': 'Transfer Complete'}))
        ..close().then((val) {
          _serverStatusCallBack.updateServerStatus(
              {getRequest.connectionInfo.remoteAddress.host: 'done'});
        }, onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host: 'Didn\'t complete'
          });
        });
    } else if (getRequest.uri.path == '/undone') {
      getRequest.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(json.encode({'status': 'Couldn\'t complete transfer'}))
        ..close().then((val) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                'Couldn\'t complete transfer'
          });
        }, onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host: 'Didn\'t complete'
          });
        });
    } else {
      if (this._files.contains(getRequest.uri.path)) {
        getRequest.response.statusCode = HttpStatus.ok;
        _serverStatusCallBack.updateServerStatus({
          getRequest.connectionInfo.remoteAddress.host:
              'Fetching ${pathHandler.basename(getRequest.uri.path)}'
        });
        getRequest.response
            .addStream(File(getRequest.uri.path).openRead())
            .then((val) {
          getRequest.response.close();
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                'Fetched ${pathHandler.basename(getRequest.uri.path)}'
          });
        }, onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host: 'Didn\'t complete'
          });
        });
      }
    }
  }

  stopServer() {
    isStopped = true;
    _httpServer?.close(force: true);
  }
}

abstract class ServerStatusCallBack {
  updateServerStatus(Map<String, String> msg);

  generalUpdate(String msg);
}
