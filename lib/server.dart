import 'dart:io';
import 'dart:convert' show utf8;
import 'package:path/path.dart' as pathHandler;

class Server {
  String _host;
  int _port;
  List<String> _filteredPeers;
  List<String> filesToBeShared;
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
                _serverStatusCallBack.updateServerStatus(<String, String>{
                  socket.remoteAddress.address: 'Connected'
                });
                socket.listen(
                  (List<int> data) {
                    var decodedData = utf8.decode(data);
                    if (decodedData == '/file') {
                      socket.write(filesToBeShared.join(';'));
                      /*_serverStatusCallBack.updateServerStatus(<String, String>{
                      socket.remoteAddress.address: 'Fetched Sharable File Names'
                    });*/
                      socket.close();
                    } else if (filesToBeShared.contains(decodedData)) {
                      _serverStatusCallBack.updateServerStatus(<String, String>{
                        socket.remoteAddress.address:
                            'Fetching ${pathHandler.basename(decodedData)}'
                      });
                      socket.addStream(File(decodedData).openRead()).then(
                        (val) {
                          _serverStatusCallBack
                              .updateServerStatus(<String, String>{
                            socket.remoteAddress.address:
                                'Fetched ${pathHandler.basename(decodedData)}'
                          });
                          socket.close();
                        },
                        onError: (e) => _serverStatusCallBack
                                .updateServerStatus(<String, String>{
                              socket.remoteAddress.address:
                                  'Failed to Fetch ${pathHandler.basename(decodedData)}'
                            }),
                      );
                    } else {
                      socket.write('Bad Request');
                      _serverStatusCallBack.updateServerStatus(<String, String>{
                        socket.remoteAddress.address: 'Bad Request'
                      });
                      socket.close();
                    }
                  },
                  onError: (e) {
                    _serverStatusCallBack.updateServerStatus(<String, String>{
                      socket.remoteAddress.address: 'Critical Error :/'
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
  updateServerStatus(Map<String, String> msg);

  generalUpdate(String msg);
}
