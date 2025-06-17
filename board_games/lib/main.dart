import 'package:flutter/material.dart';
import 'screens/games_home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Games Page',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: GamesHomePage(),
    );
  }
}
