import 'package:flutter/material.dart';
import 'home.dart' show MyHome;

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
