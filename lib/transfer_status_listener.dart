import 'dart:io' show RawDatagramSocket, RawSocketEvent;
import 'dart:convert' show utf8, json;

/// this class helps us to listen for transfer progress, using UDP socket
class TransferStatusListener {
  String _listenOnIP;
  int _listenOnPort; // try keeping it 0, to give OS an opportunity to choose one for us
  List<String> _allowedPeers;
  TransferStatusCallback _transferStatusCallback;
  TransferStatusListener(
    this._listenOnIP,
    this._listenOnPort,
    this._allowedPeers,
    this._transferStatusCallback,
  );
  RawDatagramSocket _rawDatagramSocket;
  init() => RawDatagramSocket.bind(_listenOnIP, _listenOnPort).then(
        (RawDatagramSocket socket) {
          _rawDatagramSocket =
              socket; // storing this reference will help us to close socket
          _rawDatagramSocket.readEventsEnabled = true;
          _rawDatagramSocket.listen(
            (RawSocketEvent event) {
              if (event == RawSocketEvent.read) {
                var dg = _rawDatagramSocket.receive();
                if (dg != null &&
                    _isAllowedPeer(dg.address
                        .address)) // data received to be considered if and only if it's from one of the allowed peers
                  _transferStatusCallback.send(
                      dg.address.address,
                      dg.port,
                      Map<String, String>.from(json.decode(utf8.decode(dg
                          .data)))); // notifies backend using callback, so that UI can be updated
              }
            },
          );
        },
        onError: (e) => print(e),
      );

  /// checks whether incoming connection is from one of allowed peers or not
  bool _isAllowedPeer(String host) => _allowedPeers.contains(host);

  /// returns port number on which server is running
  int getPortNumber() => _rawDatagramSocket?.port;

  /// closes socket, doesn't anymore accept connections
  stop() => _rawDatagramSocket.close();
}

abstract class TransferStatusCallback {
  send(String host, int port, Map<String, String> progress);
}
