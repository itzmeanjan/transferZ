import 'dart:io';
import 'dart:async' show Timer;

class AdvertiseService {
  // this service writes on a MultiCast Address
  String _targetIP;
  int _targetPort;
  String _multicastMessage;
  FoundPeerCallBack _foundPeerCallBack;
  RawDatagramSocket _rawDatagramSocket;
  Timer _timer;
  AdvertiseService(this._targetIP, this._targetPort, this._multicastMessage,
      this._foundPeerCallBack);
  advertise() {
    RawDatagramSocket.bind(
      InternetAddress.anyIPv6,
      0,
    ).then((socket) {
      _rawDatagramSocket = socket;
      _rawDatagramSocket.readEventsEnabled = true;
      _rawDatagramSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram datagram = _rawDatagramSocket.receive();
          if (datagram != null)
            _foundPeerCallBack.foundPeer(
              datagram.address.address,
              datagram.port,
            );
        }
      });
      _timer = Timer.periodic(
          Duration(
            seconds: 1,
          ), (timer) {
        if (timer.isActive)
          _rawDatagramSocket.send(
            _multicastMessage.codeUnits,
            InternetAddress(
              _targetIP,
            ), // sends data to multicast address
            _targetPort,
          );
      });
    });
  }

  stopService() {
    _timer.cancel();
    _rawDatagramSocket?.close();
  }
}

abstract class FoundPeerCallBack {
  foundPeer(String host, int port);
}
