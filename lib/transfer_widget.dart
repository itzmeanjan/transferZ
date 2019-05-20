import 'package:flutter/material.dart';
import 'package:path/path.dart' as pathHandler;
import 'timestamp_handler.dart';
import 'dart:math' show min;

class TransferProgressWidget extends StatefulWidget {
  String peerName;
  String peerStat;
  Map<String, double> transferStat;
  Map<String, int> transferStatTimeSpent;
  TransferProgressWidget(
      {Key key,
      @required this.peerName,
      @required this.peerStat,
      @required this.transferStat,
      this.transferStatTimeSpent})
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
              width: .2,
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
                        child: Icon(
                          Icons.flight,
                          color: Colors.redAccent,
                          size: min(MediaQuery.of(context).size.width,
                                  MediaQuery.of(context).size.height) *
                              .2,
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
                                    width: .1,
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
                                      Chip(
                                        elevation: 16,
                                        shadowColor: Colors.white30,
                                        backgroundColor: Colors.black,
                                        avatar: Icon(
                                          Icons.compare_arrows,
                                          color: Colors.amberAccent,
                                        ),
                                        label: Text(
                                          pathHandler.basename(
                                            widget.transferStat.keys
                                                .toList()[index],
                                          ),
                                          overflow: TextOverflow.fade,
                                          style: TextStyle(
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                      ),
                                      Divider(
                                        height: 12,
                                        color: Colors.black,
                                      ),
                                      LinearProgressIndicator(
                                        backgroundColor: Colors.black,
                                        valueColor: Tween<Color>(
                                          begin: Colors.green,
                                          end: Colors.greenAccent,
                                        ).animate(
                                          AnimationController(
                                            vsync: this,
                                            duration: Duration(
                                              microseconds: 100,
                                            ),
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
                                                            .toList()[index] ==
                                                        100
                                                    ? 1
                                                    : widget.transferStat.values
                                                        .toList()[index],
                                      ),
                                      Divider(
                                        height: 12,
                                        color: Colors.black,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.max,
                                        children: <Widget>[
                                          // displays time spent, starting from init of transfer
                                          Text(
                                            widget.transferStat.values
                                                        .toList()[index] ==
                                                    -1
                                                ? '+ NA s'
                                                : widget.transferStat.values
                                                            .toList()[index] ==
                                                        0
                                                    ? '+ NA s'
                                                    : widget.transferStat.values
                                                                    .toList()[
                                                                index] ==
                                                            100
                                                        ? '+ NA s'
                                                        : '+ ${TimeStampHandler.getStringFromSecond(widget.transferStatTimeSpent.values.toList()[index].toDouble())}',
                                            style: TextStyle(
                                              color: Colors.amberAccent,
                                            ),
                                            overflow: TextOverflow.fade,
                                          ),
                                          // displays time remaining, before transfer completes
                                          Text(
                                            widget.transferStat.values
                                                        .toList()[index] ==
                                                    -1
                                                ? '- NA s'
                                                : widget.transferStat.values
                                                            .toList()[index] ==
                                                        0
                                                    ? '- NA s'
                                                    : widget.transferStat.values
                                                                    .toList()[
                                                                index] ==
                                                            100
                                                        ? '- NA s'
                                                        : '- ${TimeStampHandler.getStringFromSecond(((widget.transferStatTimeSpent.values.toList()[index] / widget.transferStat.values.toList()[index]) - widget.transferStatTimeSpent.values.toList()[index]))}',
                                            style: TextStyle(
                                              color: Colors.amberAccent,
                                            ),
                                            overflow: TextOverflow.fade,
                                          ),
                                          // displays amount of transfer in percentage
                                          Text(
                                            widget.transferStat.values
                                                        .toList()[index] ==
                                                    -1
                                                ? 'NA %'
                                                : widget.transferStat.values
                                                            .toList()[index] ==
                                                        0
                                                    ? 'NA %'
                                                    : '${(widget.transferStat.values.toList()[index] * 100).toStringAsFixed(2)} %',
                                            style: TextStyle(
                                              color: Colors.amberAccent,
                                            ),
                                            overflow: TextOverflow.fade,
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        height: 6,
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
                    overflow: TextOverflow.fade,
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
