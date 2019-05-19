import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'home.dart' show MyHome;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'transferZ',
      theme: ThemeData(
        accentColor: Colors.cyanAccent,
        appBarTheme: AppBarTheme(
          color: Colors.black,
          elevation: 16,
          actionsIconTheme: IconThemeData(
            color: Colors.tealAccent,
          ),
          iconTheme: IconThemeData(
            color: Colors.cyanAccent,
          ),
        ),
        scaffoldBackgroundColor: Colors.black,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.tealAccent,
          foregroundColor: Colors.black,
          elevation: 16,
          highlightElevation: 24,
        ),
      ),
      home: MyHome(),
    );
  }
}
