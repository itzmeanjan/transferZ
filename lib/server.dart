import 'dart:io';
import 'dart:convert' show utf8, json;

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
                _serverStatusCallBack.updatePeerStatus({
                  socket.remoteAddress.address: 'Connected'
                }); // updates status of PEER, now PEER is connected
                socket.listen(
                  (List<int> data) {
                    var decodedData = utf8.decode(data);
                    if (decodedData == '/file') {
                      socket.write(json.encode(filesToBeShared));
                      _serverStatusCallBack.updatePeerStatus(
                          {socket.remoteAddress.address: 'Fetched File Names'});
                      socket.close();
                    } else if (filesToBeShared.keys
                        .toList()
                        .contains(decodedData)) {
                      _serverStatusCallBack
                          .updateTransferStatus(<String, Map<String, double>>{
                        socket.remoteAddress.address: {
                          decodedData: 0
                        } // 0 denotes transfer has started
                      });
                      _serverStatusCallBack.updatePeerStatus(
                          {socket.remoteAddress.address: 'Fetching Files'});
                      socket.addStream(File(decodedData).openRead()).then(
                        (val) {
                          _serverStatusCallBack.updateTransferStatus(<String,
                              Map<String, double>>{
                            socket.remoteAddress.address: {
                              decodedData: 1
                            } // 1 denotes, it's complete
                          });
                          socket.close();
                        },
                        onError: (e) =>
                            _serverStatusCallBack.updateTransferStatus({
                              socket.remoteAddress.address: {decodedData: -1}
                            }), // -1 denotes, file transfer has failed
                      );
                    } else {
                      socket.write('Bad Request');
                      _serverStatusCallBack.updatePeerStatus(
                          {socket.remoteAddress.address: 'Bad Request'});
                      socket.close();
                    }
                  },
                  onError: (e) {
                    _serverStatusCallBack.updatePeerStatus(
                        {socket.remoteAddress.address: 'Disconnected'});
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
            onError: (e) {
              isStopped = true;
              _serverStatusCallBack.generalUpdate('Server Failed');
            },
            onDone: () {
              isStopped = true;
              _serverStatusCallBack.generalUpdate('Stopped Server');
            },
            cancelOnError: true,
          );
        },
        onError: (e) {
          isStopped = true;
          _serverStatusCallBack.generalUpdate('Failed to Start Server');
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
  updateTransferStatus(Map<String, Map<String, double>> stat);

  updatePeerStatus(Map<String, String> stat);

  generalUpdate(String msg);
}
