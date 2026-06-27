import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xffea6d35); // Orange from Rider app
  static const Color background = Color(0xFFefeeed); // Light gray background
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;
  static const Color success = Colors.green;
  static const Color error = Colors.red;
}

class AppStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle subHeading = TextStyle(
    fontSize: 16,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w400,
  );
}
