import 'dart:io';

class AdvertiseService {
  // this is a UDP server
  int _port;
  bool isStopped = true;
  FoundClientCallBack _foundClientCallBack;
  RawDatagramSocket _rawDatagramSocket;
  Map<String, int> _clients = {};
  AdvertiseService(this._port, this._foundClientCallBack);
  advertise() async {
    _rawDatagramSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port)
          ..readEventsEnabled = true;
    isStopped = false;
    _rawDatagramSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram datagram = _rawDatagramSocket.receive();
        if (datagram != null) {
          _clients[datagram.address.host] = datagram.port;
          _foundClientCallBack.foundClient(
              datagram.address.host, datagram.port);
          _rawDatagramSocket.send(
              datagram.data, datagram.address, datagram.port);
        }
      }
    });
  }

  stop() {
    if (_rawDatagramSocket != null) {
      _rawDatagramSocket.close();
      isStopped = true;
    }
  }
}

abstract class FoundClientCallBack {
  foundClient(String host, int port);
}
