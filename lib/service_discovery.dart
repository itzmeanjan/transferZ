import 'dart:io';

class DiscoverService {
  // this is a UDP client
  int _port;
  String _broadCastMessage;
  int _targetPort;
  String _targetIP;
  Map<String, int> _peers = <String, int>{};
  FoundServiceCallBack _foundServiceCallBack;
  RawDatagramSocket _rawDatagramSocket;
  DiscoverService(this._port, this._broadCastMessage, this._targetIP,
      this._targetPort, this._foundServiceCallBack);
  discoverAndReport() async {
    /*
    RawDatagramSocket.bind(InternetAddress.anyIPv6, _port).then((socket) {
      // _port should be by default 8000
      _rawDatagramSocket = socket;
      _rawDatagramSocket.readEventsEnabled = true;
      _rawDatagramSocket.joinMulticast(
        // need to acquire wifimulticast lock on android using wifi manager
        InternetAddress(
          _targetIP,
        ),
      ); // _targetIP should point to Multicast IP Address, on which peers are expected to be writing
      _rawDatagramSocket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          Datagram datagram = _rawDatagramSocket.receive();
          if (datagram != null) {
            if (!_peers.keys.contains(datagram.address.address)) {
              _peers[datagram.address.address] = datagram.port;
              _foundServiceCallBack.foundService(
                  datagram.address.host, datagram.port);
            }
          }
        }
      });
    });*/
    _rawDatagramSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port)
          ..broadcastEnabled = true
          ..readEventsEnabled = true;
    _rawDatagramSocket.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram datagram = _rawDatagramSocket.receive();
        if (datagram != null) {
          _foundServiceCallBack.foundService(
              datagram.address.host, datagram.port);
          //_rawDatagramSocket.close();
        }
      }
    });
    _rawDatagramSocket.send(
        _broadCastMessage.codeUnits, InternetAddress(_targetIP), _targetPort);
  }

  /*
  stopService() => _rawDatagramSocket.leaveMulticast(
        InternetAddress(
          _targetIP,
        ),
      ); */
}

abstract class FoundServiceCallBack {
  foundService(String host, int port);
}
