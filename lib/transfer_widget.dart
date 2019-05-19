import 'package:flutter/material.dart';
import 'package:path/path.dart' as pathHandler;

class TransferProgressWidget extends StatefulWidget {
  String peerName;
  String peerStat;
  Map<String, double> transferStat;
  TransferProgressWidget(
      {Key key, this.peerName, this.peerStat, this.transferStat})
      : super(key: key);
  @override
  _TransferProgressWidget createState() => _TransferProgressWidget();
}

class _TransferProgressWidget extends State<TransferProgressWidget>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(12),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
            side: BorderSide(
              color: Colors.cyanAccent,
              style: BorderStyle.solid,
              width: .5,
            ),
          ),
          elevation: 16,
          color: Colors.black,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                child: Chip(
                  avatar: Icon(
                    Icons.devices_other,
                  ),
                  backgroundColor: Colors.tealAccent,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 4,
                    bottom: 4,
                  ),
                  label: Text(
                    widget.peerName,
                  ),
                ),
                padding:
                    EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 8),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height / 4.5,
                width: MediaQuery.of(context).size.width * .9,
                child: widget.transferStat.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: Tween<Color>(
                            begin: Colors.lightGreenAccent,
                            end: Colors.lightGreen,
                          ).animate(
                            AnimationController(
                              vsync: this,
                              duration: Duration(
                                microseconds: 100,
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemBuilder: (context, index) => Padding(
                              padding: EdgeInsets.only(
                                left: 6,
                                right: 6,
                                top: 5,
                                bottom: 5,
                              ),
                              child: Card(
                                color: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.cyanAccent,
                                    style: BorderStyle.solid,
                                    width: .15,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    top: 5,
                                    bottom: 5,
                                  ),
                                  child: Column(
                                    children: <Widget>[
                                      Divider(
                                        height: 12,
                                        color: Colors.black,
                                      ),
                                      Text(
                                        pathHandler.basename(
                                          widget.transferStat.keys
                                              .toList()[index],
                                        ),
                                        overflow: TextOverflow.fade,
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      Divider(
                                        height: 12,
                                        color: Colors.black,
                                      ),
                                      LinearProgressIndicator(
                                        backgroundColor: Colors.white,
                                        valueColor: Tween<Color>(
                                          begin: Colors.cyanAccent,
                                          end: Colors.cyan,
                                        ).animate(
                                          AnimationController(
                                            vsync: this,
                                          ),
                                        ),
                                        value: widget.transferStat.values
                                                    .toList()[index] ==
                                                -1
                                            ? null
                                            : widget.transferStat.values
                                                        .toList()[index] ==
                                                    0
                                                ? null
                                                : widget.transferStat.values
                                                    .toList()[index],
                                      ),
                                      Divider(
                                        height: 12,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        itemCount: widget.transferStat.keys.length,
                      ),
              ),
              Padding(
                child: Chip(
                  elevation: 16,
                  shadowColor: Colors.white54,
                  backgroundColor: Colors.black,
                  labelStyle: TextStyle(
                    color: Colors.cyanAccent,
                  ),
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 4,
                    bottom: 4,
                  ),
                  avatar: Icon(
                    Icons.new_releases,
                    color: Colors.cyanAccent,
                  ),
                  label: Text(
                    widget.peerStat,
                  ),
                ),
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: 8,
                  left: 16,
                  right: 16,
                ),
              ),
            ],
          ),
        ),
      );
}
