import 'dart:io';
import 'dart:convert' show utf8, json;

class Server {
  String _host;
  int _port;
  int progressListenerPort;
  List<String> _filteredPeers;
  Map<String, int> filesToBeShared;
  ServerStatusCallBack _serverStatusCallBack;
  bool isStopped = true;

  Server(this._host, this._port, this.progressListenerPort, this._filteredPeers,
      this.filesToBeShared, this._serverStatusCallBack);

  ServerSocket _server;

  init() => ServerSocket.bind(_host, _port).then(
        (ServerSocket server) {
          _server = server;
          isStopped = false;
          _serverStatusCallBack.generalUpdate('Ready to Transfer');
          server.listen(
            (Socket socket) {
              String remote = socket.remoteAddress.address;
              if (isAccessGranted(remote)) {
                _serverStatusCallBack.updatePeerStatus({
                  socket.remoteAddress.address: 'Connected'
                }); // updates status of PEER, now PEER is connected
                socket.listen(
                  (List<int> data) {
                    var decodedData = utf8.decode(data);
                    if (decodedData == '/file') {
                      socket
                        ..write(json.encode(filesToBeShared))
                        ..close();
                      _serverStatusCallBack
                          .updatePeerStatus({remote: 'Fetched File List'});
                    } else if (decodedData == '/progressListener')
                      socket
                        ..write(utf8.encode(progressListenerPort.toString()))
                        ..close(); // informs other end about on which port it will listen using UDP for transfer status update
                    else if (filesToBeShared.keys
                        .toList()
                        .contains(decodedData)) {
                      _serverStatusCallBack
                          .updateTransferStatus(<String, Map<String, double>>{
                        remote: {
                          decodedData: 0
                        } // 0 denotes transfer has started
                      });
                      _serverStatusCallBack
                          .updatePeerStatus({remote: 'Fetching File ...'});
                      socket
                        ..addStream(File(decodedData).openRead()).then((val) {
                          _serverStatusCallBack
                              .updatePeerStatus({remote: 'Fetched File'});
                          _serverStatusCallBack.updateTransferStatus(<String,
                              Map<String, double>>{
                            remote: {
                              decodedData: 100
                            } // 100 denotes, it's complete
                          })
                            ..close();
                        }, onError: (e) {
                          _serverStatusCallBack
                              .updatePeerStatus({remote: 'Failed to Fetch'});
                          _serverStatusCallBack.updateTransferStatus({
                            remote: {decodedData: -1}
                          }); // -1 denotes, file transfer has failed
                        });
                    } else {
                      socket
                        ..write('Bad Request')
                        ..destroy();
                      _serverStatusCallBack
                          .updatePeerStatus({remote: 'Bad Request'});
                    }
                  },
                  onError: (e) {
                    _serverStatusCallBack
                        .updatePeerStatus({remote: 'Disconnected'});
                    socket.destroy();
                  },
                  cancelOnError: true,
                );
              } else {
                socket
                  ..write('Access not Granted')
                  ..destroy();
                _serverStatusCallBack
                    .generalUpdate('Denied Unauthorized Access from $remote');
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
          _serverStatusCallBack.generalUpdate('Failed to Init Transfer');
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
