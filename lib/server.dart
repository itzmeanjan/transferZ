import 'dart:io';
import 'dart:convert' show json;
import 'package:path/path.dart' as pathHandler;
import 'dart:async' show Completer;

class Server {
  String _host;
  int _port;
  List<String> _filteredPeers;
  List<String> filesToBeShared;
  ServerStatusCallBack _serverStatusCallBack;
  bool isStopped = true;

  Server(this._host, this._port, this._filteredPeers, this.filesToBeShared,
      this._serverStatusCallBack);

  HttpServer _httpServer;

  Future<HttpServer> initServer() async {
    var completer = Completer<HttpServer>();
    await HttpServer.bind(this._host, this._port).then(
      (HttpServer server) {
        _httpServer = server;
        isStopped = false;
        _serverStatusCallBack.generalUpdate('Listening for Request');
        completer.complete(_httpServer);
      },
      onError: (e) {
        isStopped = true;
        _serverStatusCallBack.generalUpdate('Failed to start Server');
        completer.complete(null);
      },
    );
    return completer.future;
  }

  handleRequest(HttpRequest request) {
    if (isAccessGranted(request.connectionInfo.remoteAddress.address)) {
      if (request.method == 'GET')
        handleGETRequest(request);
      else {
        String remoteHost = request.connectionInfo.remoteAddress.host;
        request.response
          ..statusCode = HttpStatus.methodNotAllowed
          ..headers.contentType = ContentType.json
          ..write(json
              .encode(<String, String>{'status': 'Only GET method allowed'}))
          ..close().then(
            (val) => _serverStatusCallBack
                .updateServerStatus({remoteHost: 'Only GET method allowed'}),
            onError: (e) => _serverStatusCallBack
                .updateServerStatus({remoteHost: 'Transfer Error'}),
          );
      }
    } else {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..headers.contentType = ContentType.json
        ..write(json.encode(<String, String>{'status': 'Device not allowed'}))
        ..close().then(
          (val) => _serverStatusCallBack.generalUpdate('Device not allowed'),
          onError: (e) => _serverStatusCallBack.generalUpdate('Transfer Error'),
        );
    }
  }

  bool isAccessGranted(String remoteAddress) =>
      // checks whether IP address of incoming request is with in user selected IP-list or not
      this._filteredPeers.contains(remoteAddress);

  handleGETRequest(HttpRequest getRequest) {
    String remoteAddress = getRequest.connectionInfo.remoteAddress.host;
    String requestedPath = getRequest.uri.path;
    if (requestedPath == '/')
      getRequest.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
            json.encode(<String, List<String>>{"files": this.filesToBeShared}))
        ..close().then(
          (val) => _serverStatusCallBack.updateServerStatus(
              {remoteAddress: 'Retrived accessible File List'}),
          onError: (e) => _serverStatusCallBack
              .updateServerStatus({remoteAddress: 'Transfer Error'}),
        );
    else {
      if (this.filesToBeShared.contains(requestedPath)) {
        getRequest.response.statusCode = HttpStatus.ok;
        _serverStatusCallBack.updateServerStatus(
            {remoteAddress: 'Fetching ${pathHandler.basename(requestedPath)}'});
        getRequest.response.addStream(File(requestedPath).openRead()).then(
          (val) {
            getRequest.response.close();
            _serverStatusCallBack.updateServerStatus({
              remoteAddress: 'Fetched ${pathHandler.basename(requestedPath)}'
            });
          },
          onError: (e) => _serverStatusCallBack
              .updateServerStatus({remoteAddress: 'Transfer Error'}),
        );
      }
    }
  }

  stopServer() {
    isStopped = true;
    _httpServer?.close(force: true);
    _serverStatusCallBack.generalUpdate('Stopped Server');
  }
}

abstract class ServerStatusCallBack {
  updateServerStatus(Map<String, String> msg);

  generalUpdate(String msg);
}
