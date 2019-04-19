import 'dart:io';
import 'dart:convert' show json, utf8;

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
          ..close()
              .whenComplete(() => _serverStatusCallBack.updateServerStatus({
                    request.connectionInfo.remoteAddress.host: 'get method only'
                  }))
              .catchError((e) {
            _serverStatusCallBack.updateServerStatus({
              request.connectionInfo.remoteAddress.host:
                  'Something went wrong while handling request'
            });
            stopServer();
          });
      }
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(json.encode(<String, String>{'status': 'Access Denied'}))
        ..close()
            .whenComplete(() => _serverStatusCallBack.updateServerStatus(
                {request.connectionInfo.remoteAddress.host: 'access denied'}))
            .catchError((e) {
          _serverStatusCallBack.updateServerStatus({
            request.connectionInfo.remoteAddress.host:
                'Something went wrong while handling request'
          });
          stopServer();
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
        ..close()
            .whenComplete(() => _serverStatusCallBack.updateServerStatus({
                  getRequest.connectionInfo.remoteAddress.host:
                      'Permitted file list sent'
                }))
            .catchError((e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                'Something went wrong while handling request'
          });
          stopServer();
        });
    } else {
      if (this._files.contains(getRequest.uri.path)) {
        getRequest.response.statusCode = HttpStatus.ok;
        _serverStatusCallBack.updateServerStatus({
          getRequest.connectionInfo.remoteAddress.host:
              'Sending file ${getRequest.uri.path}'
        });
        getRequest.response
            .addStream(File(getRequest.uri.path).openRead())
            .then((val) {
          getRequest.response.close();
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host:
                'Sent file ${getRequest.uri.path}'
          });
        }, onError: (e) {
          _serverStatusCallBack.updateServerStatus({
            getRequest.connectionInfo.remoteAddress.host: 'Transfer Failed'
          });
        });
      }
    }
  }

  Future<dynamic> stopServer() {
    isStopped = true;
    return _httpServer?.close(force: true);
  }
}

abstract class ServerStatusCallBack {
  updateServerStatus(Map<String, String> msg);
  generalUpdate(String msg);
}
