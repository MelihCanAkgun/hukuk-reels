import 'package:flutter/material.dart';

/// Tozpembe / koyu mor-pembe tema.
class AppTheme {
  AppTheme._();

  // Çekirdek renkler – koyu "plum/tozpembe" tonları
  static const Color bg = Color(0xFF170B12); // arka plan
  static const Color bgElevated = Color(0xFF1F0F19); // yükseltilmiş yüzey
  static const Color surface = Color(0xFF291521); // kart
  static const Color surfaceHigh = Color(0xFF35212E); // kart (vurgulu)
  static const Color border = Color(0xFF48293C);
  static const Color accent = Color(0xFFFF80AB); // ana vurgu (toz pembe)
  static const Color textPrimary = Color(0xFFF8EBF2);
  static const Color textSecondary = Color(0xFFC8A9B9);
  static const Color textMuted = Color(0xFF8E6C7E);
  static const Color success = Color(0xFF45D6A0);
  static const Color danger = Color(0xFFFB7193);

  /// Arka plan degradesi (sayfa zemini)
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E0F18), Color(0xFF12080F)],
  );

  /// Butonlarda kullanılan pembe degrade
  static const LinearGradient pinkGradient = LinearGradient(
    colors: [Color(0xFFFF8FB6), Color(0xFFFF5C95)],
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
