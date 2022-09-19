import 'package:flutter/material.dart';
import 'screens/home.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.light,
      theme: ThemeData(),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const Home(),
    );
  }
}
