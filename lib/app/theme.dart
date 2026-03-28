import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF1A237E);     // Koyu lacivert
  static const _secondary = Color(0xFFFF6D00);   // Turuncu vurgu
  static const _surface = Color(0xFF121212);
  static const _card = Color(0xFF1E1E2E);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _surface,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
    ),
    cardTheme: const CardThemeData(
      color: _card,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: Colors.white70,
        height: 1.6,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white60,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _surface,
      selectedItemColor: _secondary,
      unselectedItemColor: Colors.white38,
    ),
  );
}
