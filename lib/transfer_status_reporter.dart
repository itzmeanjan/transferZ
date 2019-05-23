import 'dart:io' show InternetAddress, RawDatagramSocket;
import 'dart:convert' show utf8, json;

/// this class helps to send file transfer progress back to server, actually that's from where we're bringing file in
class TransferStatusReporter {
  String _listenOnIP;
  int _listenOnPort;
  TransferStatusReporter(
    this._listenOnIP,
    this._listenOnPort,
  );
  RawDatagramSocket _rawDatagramSocket;

  /// initializes UDP socket and uses same socket for sending update to PEER
  init() => RawDatagramSocket.bind(_listenOnIP, _listenOnPort).then(
        (socket) => _rawDatagramSocket = socket,
        onError: (e) => print(e),
      );

  /// sends tranfer status to PEER
  /// data is first json encoded and then utf8 encoded
  /// take required steps, so that data can be properly unpacked at TransferStatusListener side
  send(String targetIP, int targetPort, Map<String, String> data) =>
      _rawDatagramSocket.send(utf8.encode(json.encode(data)),
          InternetAddress(targetIP), targetPort);

  /// closes connection
  stop() => _rawDatagramSocket.close();
}
