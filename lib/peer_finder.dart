import 'package:flutter/material.dart';
import 'service_advertising.dart';
import 'service_discovery.dart';
import 'package:flutter/services.dart';

class PeerFinder extends StatefulWidget {
  final String type;
  final MethodChannel methodChannel;

  PeerFinder({Key key, @required this.type, @required this.methodChannel})
      : super(key: key);

  @override
  _PeerFinderState createState() => _PeerFinderState();
}

class _PeerFinderState extends State<PeerFinder>
    implements FoundClientCallBack, FoundServiceCallBack {
  PeerInfoHolder _peerInfoHolder;
  AdvertiseService _advertiseService;
  DiscoverService _discoverService;

  @override
  void initState() {
    super.initState();
    _peerInfoHolder = PeerInfoHolder(widget.type);
    if (widget.type == 'send') {
      _advertiseService = AdvertiseService(8000, this);
      _advertiseService.advertise();
    } else {
      _discoverService = DiscoverService(
          0, 'io.github.itzmeanjan.transferz', '255.255.255.255', 8000, this);
      _discoverService.discoverAndReport();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _advertiseService?.stop();
  }

  @override
  foundClient(String host, int port) {
    setState(() {
      _peerInfoHolder._peers[host] = port;
      _peerInfoHolder._isPeerSelected[host] = false;
    });
  }

  @override
  foundService(String host, int port) {
    setState(() {
      _peerInfoHolder._peers[host] = port;
      _peerInfoHolder._isPeerSelected[host] = false;
    });
  }

  Future<void> showToast(String message, String duration) async {
    return await widget.methodChannel.invokeMethod('showToast',
        <String, String>{'message': message, 'duration': duration});
  }

  bool checkIfAtLeastOneIsSelected() {
    int count = 0;
    _peerInfoHolder._isPeerSelected.forEach((key, val) {
      count += val ? 1 : 0;
    });
    return count == 0 ? false : true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finding Peers ...'),
        backgroundColor: Colors.tealAccent,
        elevation: 16,
        actions: <Widget>[
          IconButton(
            tooltip: 'Send Files',
            icon: Icon(
              Icons.send,
              color: Colors.black,
            ),
            onPressed: checkIfAtLeastOneIsSelected() ? () {} : null,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.only(
          top: 12,
          bottom: 12,
        ),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [Colors.tealAccent, Colors.cyanAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: _peerInfoHolder._peers.length == 0
            ? Center(
                child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ))
            : ListView.builder(
                padding: EdgeInsets.only(left: 8, right: 8),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(top: 12, bottom: 12),
                    child: Card(
                      color: _peerInfoHolder._isPeerSelected[_peerInfoHolder
                                  ._peers.keys
                                  .toList()[index]] ==
                              true
                          ? Colors.lightGreen
                          : Colors.redAccent,
                      elevation: 12,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: 10,
                                right: 4,
                              ),
                              child: Text(
                                '${_peerInfoHolder._peers.keys.toList()[index]}:${_peerInfoHolder._peers[_peerInfoHolder._peers.keys.toList()[index]]}',
                              ),
                            ),
                            flex: 1,
                          ),
                          IconButton(
                            tooltip: 'Connect to Peer',
                            disabledColor: Colors.white,
                            color: Colors.green,
                            icon: Icon(
                              Icons.check_circle,
                            ),
                            onPressed: _peerInfoHolder._isPeerSelected[
                                        _peerInfoHolder._peers.keys
                                            .toList()[index]] ==
                                    false
                                ? () {
                                    if (widget.type == 'send') {
                                      setState(() {
                                        _peerInfoHolder._isPeerSelected[
                                            _peerInfoHolder._peers.keys
                                                .toList()[index]] = true;
                                      });
                                    } else {
                                      setState(() {
                                        _peerInfoHolder._isPeerSelected
                                            .forEach((key, val) {
                                          _peerInfoHolder._isPeerSelected[key] =
                                              _peerInfoHolder._peers.keys
                                                          .toList()[index] ==
                                                      key
                                                  ? true
                                                  : false;
                                        });
                                      });
                                    }
                                    showToast(
                                        "Selected ${_peerInfoHolder._peers.keys.toList()[index]}",
                                        "short");
                                  }
                                : null,
                          ),
                          IconButton(
                            tooltip: 'Don\'t Connect to Peer',
                            disabledColor: Colors.white,
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
      floatingActionButton: FloatingActionButton(
        onPressed: widget.type == 'send'
            ? () {
                setState(() {
                  _peerInfoHolder._peers = {};
                });
                if (!_advertiseService.isStopped) _advertiseService.stop();
                _advertiseService = AdvertiseService(8000, this);
                _advertiseService.advertise();
              }
            : () {
                setState(() {
                  _peerInfoHolder._peers = {};
                });
                _discoverService.discoverAndReport();
              },
        backgroundColor: Colors.tealAccent,
        child: Icon(Icons.refresh),
        elevation: 16,
        tooltip: 'Refresh Peer-List',
      ),
    );
  }
}

class PeerInfoHolder {
  String type;

  PeerInfoHolder(this.type) {
    _peers = {};
    _isPeerSelected = {};
  }

  Map<String, int> _peers;
  Map<String, bool> _isPeerSelected;
}
