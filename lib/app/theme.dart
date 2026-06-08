import 'package:flutter/material.dart';

/// Profesyonel, sade ve okunaklı koyu tema.
class AppTheme {
  AppTheme._();

  // Çekirdek renkler – derin "slate/indigo" tonları
  static const Color bg = Color(0xFF0B0E14); // arka plan
  static const Color bgElevated = Color(0xFF11151F); // yükseltilmiş yüzey
  static const Color surface = Color(0xFF161B27); // kart
  static const Color surfaceHigh = Color(0xFF1E2433); // kart (vurgulu)
  static const Color border = Color(0xFF2A3142);
  static const Color accent = Color(0xFF6C8CFF); // ana vurgu (mavi)
  static const Color textPrimary = Color(0xFFEDF1F8);
  static const Color textSecondary = Color(0xFF9AA6BE);
  static const Color textMuted = Color(0xFF5E6A82);
  static const Color success = Color(0xFF34D399);
  static const Color danger = Color(0xFFF87171);

  /// Arka plan degradesi (sayfa zemini)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0E1320), Color(0xFF0A0C12)],
  );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: textPrimary,
        ),
        splashColor: accent.withValues(alpha: 0.08),
        highlightColor: accent.withValues(alpha: 0.04),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            height: 1.5,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            height: 1.55,
            color: textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: textSecondary,
          ),
        ),
      );
}
