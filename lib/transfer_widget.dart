import 'package:flutter/material.dart';

class TransferProgressWidget extends StatefulWidget {
  String peerName;
  Map<String, String> fileStat;
  TransferProgressWidget({Key key, this.peerName}) : super(key: key);
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
                child: widget.fileStat.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Colors.teal,
                          strokeWidth: 2,
                        ),
                      )
                    : ListView.builder(
                        itemBuilder: (context, index) => Padding(
                              padding: EdgeInsets.only(
                                left: 12,
                                right: 12,
                                top: 8,
                                bottom: 8,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  LinearProgressIndicator(
                                    backgroundColor: Colors.lightBlueAccent,
                                  ),
                                  Text(
                                      '${widget.fileStat.keys.toList()[index]}'),
                                ],
                              ),
                            ),
                        itemCount: widget.fileStat.length,
                      ),
              ),
            ],
          ),
        ),
      );
}
