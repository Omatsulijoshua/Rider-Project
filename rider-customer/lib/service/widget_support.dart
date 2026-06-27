import 'package:flutter/material.dart';

class AppWidget {
  static TextStyle headlineTextFieldStyle() {
    return const TextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle normalTextFieldStyle() {
    return const TextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle simpleTextFieldStyle() {
    return const TextStyle(
      color: Colors.black,
      fontSize: 15.0,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle slowSimpleTextFieldStyle() {
    return const TextStyle(
      color: Colors.black,
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle whiteTextFieldStyle(double textsize) {
    return TextStyle(
      color: Colors.white,
      fontSize: textsize,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle differentShadeWhiteTextFieldStyle() {
    return const TextStyle(
      color: Colors.white54,
      fontSize: 17.0,
      fontWeight: FontWeight.w500,
    );
  }
}
