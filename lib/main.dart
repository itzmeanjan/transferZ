import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'transferZ',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: MyHome(),
    );
  }
}

class MyHome extends StatefulWidget {
  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('transferZ'),
        backgroundColor: Colors.tealAccent,
        elevation: 16,
      ),
      body: Center(
        child: Text(
          'Hello',
        ),
      ),
    );
  }
}
