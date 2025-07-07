import 'package:flutter/material.dart';

class AppTheme {
  static final darkTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.green,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
          color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
  );
}
