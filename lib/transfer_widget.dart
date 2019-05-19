import 'package:flutter/material.dart';

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
              width: .25,
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
                            begin: Colors.greenAccent,
                            end: Colors.green,
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
                                top: 4,
                                bottom: 4,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  LinearProgressIndicator(
                                    backgroundColor: Colors.lightBlueAccent,
                                    value: widget.transferStat.values
                                                .toList()[index] ==
                                            -1
                                        ? null
                                        : widget.transferStat.values
                                                    .toList()[index] ==
                                                1
                                            ? null
                                            : widget.transferStat.values
                                                .toList()[index],
                                  ),
                                  Text(
                                    '${widget.transferStat.keys.toList()[index]}',
                                    overflow: TextOverflow.fade,
                                  ),
                                ],
                              ),
                            ),
                        itemCount: widget.transferStat.keys.length,
                      ),
              ),
              Padding(
                child: Chip(
                  backgroundColor: Colors.limeAccent,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 4,
                    bottom: 4,
                  ),
                  avatar: Icon(
                    Icons.new_releases,
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
