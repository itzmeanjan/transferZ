import 'dart:io';

class DiscoverService {
  // this is a UDP client
  int _port;
  String _broadCastMessage;
  int _targetPort;
  String _targetIP;
  FoundServiceCallBack _foundServiceCallBack;
  RawDatagramSocket _rawDatagramSocket;
  DiscoverService(this._port, this._broadCastMessage, this._targetIP,
      this._targetPort, this._foundServiceCallBack);
  discoverAndReport() async {
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
}

abstract class FoundServiceCallBack {
  foundService(String host, int port);
}
