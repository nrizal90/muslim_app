import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0D7C66),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7F6),
  );
}