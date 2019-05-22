import 'dart:io';
import 'dart:convert' show utf8;

class DiscoverService {
  // this service joins a MultiCast Group and writes back to certain Peer on reception of message
  String _targetIP;
  int _targetPort;
  String
      _multicastMessage; // this one tries to put a very light bound on which devices are getting considered as peers
  FoundServiceCallBack _foundServiceCallBack;
  RawDatagramSocket _rawDatagramSocket;
  DiscoverService(this._targetIP, this._targetPort, this._multicastMessage,
      this._foundServiceCallBack);
  discoverAndReport() => RawDatagramSocket.bind(
        InternetAddress.anyIPv6,
        _targetPort,
      ).then((socket) {
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
            if (datagram != null &&
                utf8.decode(datagram.data) == _multicastMessage) {
              _rawDatagramSocket.send(
                datagram.data,
                datagram.address,
                datagram.port,
              );
              _foundServiceCallBack.foundService(
                datagram.address.address,
                datagram.port,
              );
            }
          }
        });
      });

  stopService() {
    _rawDatagramSocket?.leaveMulticast(
      InternetAddress(
        _targetIP,
      ),
    );
    _rawDatagramSocket?.close();
  }
}

abstract class FoundServiceCallBack {
  foundService(String host, int port);
}
