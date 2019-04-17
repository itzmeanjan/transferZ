import 'dart:io';

class AdvertiseService {
  // this is a UDP server
  int _port;
  RawDatagramSocket _rawDatagramSocket;
  List<String> _clients = [];
  AdvertiseService(this._port);
  advertise() async {
    _rawDatagramSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port)
          ..readEventsEnabled = true;
    _rawDatagramSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram datagram = _rawDatagramSocket.receive();
        if (datagram != null) {
          print('[+]Got request ${datagram.address}:${datagram.port}');
          _clients.add(datagram.address.host);
          _rawDatagramSocket.send(
              datagram.data, datagram.address, datagram.port);
        }
      }
    });
  }

  List<String> stop() {
    if (_rawDatagramSocket != null) _rawDatagramSocket.close();
    print("closed service");
    return _clients;
  }
}
