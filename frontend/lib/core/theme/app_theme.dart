import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get mechaTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0D0D12), // Deep cyberpunk dark
      primaryColor: Colors.cyanAccent,
      colorScheme: const ColorScheme.dark(
        primary: Colors.cyanAccent,
        secondary: Colors.purpleAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.cyan, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(color: Colors.cyanAccent),
      ),
    );
  }
}