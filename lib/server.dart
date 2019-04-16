import 'dart:io';

class Server {
  String host;
  int port;

  Server(this.host, this.port);

  HttpServer _httpServer;

  Future initServer() async {
    _httpServer = await HttpServer.bind(this.host, this.port);
    print('Server listening ...');
    await for (HttpRequest request in _httpServer) {
      handleRequest(request);
    }
  }

  handleRequest(HttpRequest request) {
    print(
        'Incoming request from ${request.connectionInfo.remoteAddress}:${request.connectionInfo.remotePort}');
    if (request.method == 'GET')
      handleGETRequest(request);
    else
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..headers.contentType = ContentType.text
        ..writeln('GET only')
        ..close();
  }

  handleGETRequest(HttpRequest getRequest) {
    getRequest.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.text
      ..writeln("hello")
      ..close();
  }

  Future<dynamic> stopServer() {
    return _httpServer.close(force: true);
  }
}
