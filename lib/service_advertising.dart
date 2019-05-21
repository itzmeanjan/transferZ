import 'dart:io';
import 'dart:async' show Timer;

class AdvertiseService {
  // this is a UDP server
  int _port;
  bool isStopped = true;
  FoundClientCallBack _foundClientCallBack;
  RawDatagramSocket _rawDatagramSocket;
  Map<String, int> _clients = {};
  Timer _timer;
  AdvertiseService(this._port, this._foundClientCallBack);
  advertise() async {
    // will be used in near future
    /*
    RawDatagramSocket.bind(InternetAddress.anyIPv6, _port).then((socket) {
      _rawDatagramSocket = socket;
      _rawDatagramSocket.readEventsEnabled = true;
      _rawDatagramSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram datagram = _rawDatagramSocket.receive();
          if (datagram != null) {
            _clients[datagram.address.address] = datagram.port;
            _foundClientCallBack.foundClient(
              datagram.address.address,
              datagram.port,
            );
          }
        }
      });
      Timer.periodic(
          Duration(
            seconds: 1,
          ), (timer) {
        if (timer.isActive)
          _rawDatagramSocket.send(
            'io.github.itzmeanjan.transferZ'.codeUnits,
            InternetAddress('224.0.0.1'), // sends data to multicast address
            8000,
          );
      });
    });*/
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
    _timer.cancel();
    if (_rawDatagramSocket != null) {
      _rawDatagramSocket.close();
      isStopped = true;
    }
  }
}

abstract class FoundClientCallBack {
  foundClient(String host, int port);
}
