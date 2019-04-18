import 'package:flutter/material.dart';
import 'service_advertising.dart';
import 'service_discovery.dart';

class PeerFinder extends StatefulWidget {
  final String type;
  PeerFinder({Key key, @required this.type}) : super(key: key);
  @override
  _PeerFinderState createState() => _PeerFinderState();
}

class _PeerFinderState extends State<PeerFinder>
    implements FoundClientCallBack, FoundServiceCallBack {
  PeerInfoHolder _peerInfoHolder;
  bool _foundServer;
  AdvertiseService _advertiseService;
  DiscoverService _discoverService;

  @override
  void initState() {
    super.initState();
    _foundServer = false;
    _peerInfoHolder = PeerInfoHolder(widget.type);
    if (widget.type == 'receive') {
      _discoverService = DiscoverService(
          0, 'io.github.itzmeanjan.transferz', '255.255.255.255', 8000, this);
      _discoverService.discoverAndReport();
    } else {
      _advertiseService = AdvertiseService(8000, this);
      _advertiseService.advertise();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _advertiseService?.stop();
  }

  @override
  foundClient(String host) {
    if (!_peerInfoHolder._targetPeers.contains(host))
      setState(() {
        _peerInfoHolder._targetPeers.add(host);
      });
  }

  @override
  foundService(String host, int port) {
    _peerInfoHolder._targetIP = host;
    _peerInfoHolder._targetPort = port;
    setState(() {
      _foundServer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('transferZ'),
        backgroundColor: Colors.tealAccent,
        elevation: 16,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [Colors.tealAccent, Colors.cyanAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: Center(
          child: widget.type == 'send'
              ? _peerInfoHolder._targetPeers.length == 0
                  ? CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    )
                  : Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Peer(s)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 3,
                              shadows: <Shadow>[
                                Shadow(
                                  color: Colors.black38,
                                  offset: Offset(1.6, 1.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 2,
                          width: MediaQuery.of(context).size.width,
                          child: ListView.builder(
                            itemBuilder: (context, index) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 10,
                                        right: 4,
                                      ),
                                      child: Text(
                                        _peerInfoHolder._targetPeers[index],
                                      ),
                                    ),
                                    flex: 1,
                                  ),
                                  IconButton(
                                    tooltip: 'Connect to Peer',
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    tooltip: 'Don\'t Connect to Peer',
                                    icon: Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
                              );
                            },
                            itemCount: _peerInfoHolder._targetPeers.length,
                          ),
                        ),
                      ],
                      mainAxisSize: MainAxisSize.min,
                    )
              : !_foundServer
                  ? CircularProgressIndicator(
                      backgroundColor: Colors.white,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Peer(s)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 3,
                              shadows: <Shadow>[
                                Shadow(
                                  color: Colors.black38,
                                  offset: Offset(1.6, 1.8),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 10,
                                  right: 4,
                                ),
                                child: Text(_peerInfoHolder._targetIP),
                              ),
                              flex: 1,
                            ),
                            IconButton(
                              tooltip: 'Connect to Peer',
                              icon: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () {},
                            ),
                            IconButton(
                              tooltip: 'Don\'t Connect to Peer',
                              icon: Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: widget.type == 'send'
            ? () {
                _peerInfoHolder._targetPeers = [];
                if (_advertiseService.isStopped) {
                  _advertiseService = AdvertiseService(8000, this);
                  _advertiseService.advertise();
                }
              }
            : () {
                setState(() {
                  _foundServer = false;
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
  PeerInfoHolder(this.type);
  String _targetIP;
  int _targetPort;
  List<String> _targetPeers = [];
}
