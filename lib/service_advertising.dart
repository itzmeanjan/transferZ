import 'dart:io';

class AdvertiseService {
  // this is a UDP server
  int _port;
  bool isStopped = true;
  FoundClientCallBack _foundClientCallBack;
  RawDatagramSocket _rawDatagramSocket;
  List<String> _clients = [];
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
          if (!_clients.contains(datagram.address.host)) {
            _clients.add(datagram.address.host);
            _foundClientCallBack.foundClient(datagram.address.host);
          }
          _rawDatagramSocket.send(
              datagram.data, datagram.address, datagram.port);
        }
      }
    });
  }

  List<String> stop() {
    if (_rawDatagramSocket != null) {
      _rawDatagramSocket.close();
      isStopped = true;
    }
    return _clients;
  }
}

abstract class FoundClientCallBack {
  foundClient(String host);
}
