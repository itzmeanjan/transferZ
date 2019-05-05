import 'dart:io';
import 'dart:convert' show utf8, json;
import 'package:path/path.dart' as pathHandler;

class Server {
  String _host;
  int _port;
  List<String> _filteredPeers;
  Map<String, int> filesToBeShared;
  ServerStatusCallBack _serverStatusCallBack;
  bool isStopped = true;

  Server(this._host, this._port, this._filteredPeers, this.filesToBeShared,
      this._serverStatusCallBack);

  ServerSocket _server;

  init() => ServerSocket.bind(_host, _port).then(
        (ServerSocket server) {
          _server = server;
          isStopped = false;
          _serverStatusCallBack.generalUpdate('Server Listening');
          server.listen(
            (Socket socket) {
              if (isAccessGranted(socket.remoteAddress.address)) {
                socket.listen(
                  (List<int> data) {
                    var decodedData = utf8.decode(data);
                    if (decodedData == '/file') {
                      socket.write(json.encode(filesToBeShared));
                      socket.close();
                    } else if (filesToBeShared.keys
                        .toList()
                        .contains(decodedData)) {
                      _serverStatusCallBack
                          .updateServerStatus(<String, Map<String, double>>{
                        socket.remoteAddress.address: {decodedData: 1}
                      });
                      socket.addStream(File(decodedData).openRead()).then(
                        (val) {
                          _serverStatusCallBack
                              .updateServerStatus(<String, Map<String, double>>{
                            socket.remoteAddress.address: {decodedData: 100}
                          });
                          socket.close();
                        },
                        onError: (e) => _serverStatusCallBack
                                .updateServerStatus(<String,
                                    Map<String, double>>{
                              socket.remoteAddress.address: {decodedData: -1}
                            }),
                      );
                    } else {
                      socket.write('Bad Request');
                      _serverStatusCallBack
                          .updateServerStatus(<String, Map<String, double>>{
                        socket.remoteAddress.address: {decodedData: -1}
                      });
                      socket.close();
                    }
                  },
                  onError: (e) {
                    _serverStatusCallBack
                        .updateServerStatus(<String, Map<String, double>>{
                      socket.remoteAddress.address: {'': -1}
                    });
                    socket.close();
                  },
                  cancelOnError: true,
                );
              } else {
                socket.write('Access not Granted');
                _serverStatusCallBack.generalUpdate(
                    'Denied Unauthorized Access from ${socket.remoteAddress.address}');
                socket.close();
              }
            },
            onError: (e) =>
                _serverStatusCallBack.generalUpdate('Server Failed :/'),
            onDone: () =>
                _serverStatusCallBack.generalUpdate('Stopped Server :/'),
            cancelOnError: true,
          );
        },
        onError: (e) {
          isStopped = true;
          _serverStatusCallBack.generalUpdate('Failed to Start Server :/');
        },
      );

  bool isAccessGranted(String remoteAddress) =>
      // checks whether IP address of incoming request is with in user selected IP-list or not
      this._filteredPeers.contains(remoteAddress);

  stop() {
    if (!isStopped)
      _server.close().then((ServerSocket socket) {
        isStopped = true;
      });
  }
}

abstract class ServerStatusCallBack {
  updateServerStatus(Map<String, Map<String, double>> msg);

  generalUpdate(String msg);
}
