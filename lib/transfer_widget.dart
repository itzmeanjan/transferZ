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

class _TransferProgressWidget extends State<TransferProgressWidget> {
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(12),
        child: Card(
          elevation: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                child: Text(
                  '\u{1f4f1} ${widget.peerName}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textScaleFactor: 1.5,
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
                          backgroundColor: Colors.teal,
                          strokeWidth: 2,
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
                child: Text(
                  '${widget.peerStat}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textScaleFactor: 1.2,
                ),
                padding:
                    EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 8),
              ),
            ],
          ),
        ),
      );
}
