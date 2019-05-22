import 'package:flutter/material.dart';
import 'service_advertising.dart';
import 'service_discovery.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'transfer.dart';

class PeerFinder extends StatefulWidget {
  final String type;
  final MethodChannel methodChannel;

  PeerFinder({Key key, @required this.type, @required this.methodChannel})
      : super(key: key);

  @override
  _PeerFinderState createState() => _PeerFinderState();
}

class _PeerFinderState extends State<PeerFinder>
    with TickerProviderStateMixin
    implements FoundPeerCallBack, FoundServiceCallBack {
  PeerInfoHolder _peerInfoHolder;
  AdvertiseService _advertiseService;
  DiscoverService _discoverService;
  int _targetPort;
  String _targetIP;
  String _multicastMessage;

  @override
  void initState() {
    super.initState();
    _targetIP = '224.0.0.1'; // peers should be joining this multicast group
    _targetPort = 8000;
    _multicastMessage = 'io.github.itzmeanjan.transferZ';
    _peerInfoHolder = PeerInfoHolder(widget.type);
    if (widget.type == 'send')
      _advertiseService = AdvertiseService(
        _targetIP,
        _targetPort,
        _multicastMessage,
        this,
      )..advertise();
    else {
      acquireWifiMultiCastLock();
      _discoverService = DiscoverService(
        _targetIP,
        _targetPort,
        _multicastMessage,
        this,
      )..discoverAndReport();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.type == 'receive') releaseWifiMultiCastLock();
    _advertiseService?.stopService();
    _discoverService?.stopService();
  }

  @override
  foundPeer(String host, int port) {
    if (_peerInfoHolder._peers.containsKey(host) &&
        _peerInfoHolder._peers[host] == port) return;
    setState(() {
      _peerInfoHolder._peers[host] = port;
      _peerInfoHolder._isPeerSelected[host] = false;
    });
    vibrateDevice();
  }

  @override
  foundService(String host, int port) {
    if (_peerInfoHolder._peers.containsKey(host) &&
        _peerInfoHolder._peers[host] == port) return;
    setState(() {
      _peerInfoHolder._peers[host] = port;
      _peerInfoHolder._isPeerSelected[host] = false;
    });
    vibrateDevice();
  }

  /// before starting nearby device discovery service, make sure you acquire this lock
  /// otherwise by default android wifi stack will simply drop all packets not addressed to device
  acquireWifiMultiCastLock() =>
      widget.methodChannel.invokeMethod('acquireWifiMultiCastLock');

  /// after work is done, make sure you release this lock
  releaseWifiMultiCastLock() =>
      widget.methodChannel.invokeMethod('releaseWifiMultiCastLock');

  showToast(String message, String duration) async =>
      await widget.methodChannel.invokeMethod('showToast',
          <String, String>{'message': message, 'duration': duration});

  vibrateDevice({String type: 'default'}) async => await widget.methodChannel
      .invokeMethod('vibrateDevice', <String, String>{'type': type});

  bool checkIfAtLeastOneIsSelected() {
    int count = 0;
    _peerInfoHolder._isPeerSelected.forEach((key, val) {
      count += val ? 1 : 0;
    });
    return count == 0 ? false : true;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'logo/logotype-horizontal.png',
          ),
          centerTitle: true,
        ),
        body: Container(
          padding: EdgeInsets.only(
            top: 12,
            bottom: 12,
          ),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: _peerInfoHolder._peers.length == 0
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: Tween<Color>(
                      begin: Colors.tealAccent,
                      end: Colors.teal,
                    ).animate(
                      AnimationController(vsync: this),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(left: 8, right: 8),
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(top: 12, bottom: 12),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(36),
                                side: BorderSide(
                                  color: Colors.white30,
                                  style: BorderStyle.solid,
                                  width: .5,
                                ),
                              ),
                              color: _peerInfoHolder._isPeerSelected[
                                          _peerInfoHolder._peers.keys
                                              .toList()[index]] ==
                                      true
                                  ? Colors.lightGreen
                                  : Colors.redAccent,
                              elevation: 12,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Expanded(
                                    child: Align(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: 8,
                                          right: 4,
                                        ),
                                        child: Chip(
                                          shadowColor: Colors.red,
                                          elevation: 0,
                                          backgroundColor: _peerInfoHolder
                                                          ._isPeerSelected[
                                                      _peerInfoHolder
                                                          ._peers.keys
                                                          .toList()[index]] ==
                                                  true
                                              ? Colors.lightGreen
                                              : Colors.redAccent,
                                          label: Text(
                                            '${_peerInfoHolder._peers.keys.toList()[index]}:${_peerInfoHolder._peers[_peerInfoHolder._peers.keys.toList()[index]]}',
                                            overflow: TextOverflow.fade,
                                          ),
                                          avatar: Icon(
                                            Icons.devices_other,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                    ),
                                    flex: 1,
                                  ),
                                  IconButton(
                                    tooltip: 'Connect to Peer',
                                    disabledColor: Colors.grey,
                                    color: Colors.green,
                                    icon: Icon(
                                      Icons.check_circle,
                                    ),
                                    onPressed: _peerInfoHolder._isPeerSelected[
                                                _peerInfoHolder._peers.keys
                                                    .toList()[index]] ==
                                            false
                                        ? () {
                                            if (widget.type == 'send')
                                              setState(
                                                () => _peerInfoHolder
                                                            ._isPeerSelected[
                                                        _peerInfoHolder
                                                            ._peers.keys
                                                            .toList()[index]] =
                                                    true,
                                              );
                                            else
                                              setState(
                                                () => _peerInfoHolder
                                                    ._isPeerSelected
                                                    .forEach((key, val) =>
                                                        _peerInfoHolder
                                                                ._isPeerSelected[
                                                            key] = _peerInfoHolder
                                                                        ._peers.keys
                                                                        .toList()[
                                                                    index] ==
                                                                key
                                                            ? true
                                                            : false),
                                              );
                                            showToast(
                                              "Selected ${_peerInfoHolder._peers.keys.toList()[index]}",
                                              "short",
                                            );
                                          }
                                        : null,
                                  ),
                                  IconButton(
                                    tooltip: 'Don\'t Connect to Peer',
                                    disabledColor: Colors.grey,
                                    color: Colors.red,
                                    icon: Icon(
                                      Icons.cancel,
                                    ),
                                    onPressed: _peerInfoHolder._isPeerSelected[
                                                _peerInfoHolder._peers.keys
                                                    .toList()[index]] ==
                                            true
                                        ? () {
                                            setState(() {
                                              _peerInfoHolder._isPeerSelected[
                                                  _peerInfoHolder._peers.keys
                                                      .toList()[index]] = false;
                                            });
                                            showToast(
                                                "Unselected ${_peerInfoHolder._peers.keys.toList()[index]}",
                                                "short");
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        itemCount: _peerInfoHolder._peers.length,
                      ),
                    ),
                    GestureDetector(
                      child: Chip(
                        backgroundColor: checkIfAtLeastOneIsSelected()
                            ? Colors.tealAccent
                            : Colors.grey,
                        labelPadding: EdgeInsets.only(
                          left: 6,
                          right: 12,
                          top: 3,
                          bottom: 3,
                        ),
                        padding: EdgeInsets.only(
                          left: 4,
                          right: 4,
                        ),
                        label: Text(
                          widget.type == 'send'
                              ? 'Send to Peers'
                              : 'Receive from Peer',
                        ),
                        avatar: Icon(
                          widget.type == 'send'
                              ? Icons.cloud_upload
                              : Icons.cloud_download,
                        ),
                      ),
                      onTap: checkIfAtLeastOneIsSelected()
                          ? () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => Transfer(
                                      methodChannel: widget.methodChannel,
                                      peerInfoHolder: _peerInfoHolder)));
                            }
                          : null,
                    ),
                  ],
                ),
        ),
      );
}

class PeerInfoHolder {
  String type;

  PeerInfoHolder(this.type) {
    _peers = {};
    _isPeerSelected = {};
  }

  Map<String, int> _peers;
  Map<String, bool> _isPeerSelected;

  Map<String, int> getPeers() => _peers;
  Map<String, bool> getSelectedPeers() => _isPeerSelected;
}
