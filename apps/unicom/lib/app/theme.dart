import 'package:flutter/material.dart';

class UnicomTheme {
  // Brand Tokens
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF60A5FA);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFEF4444);

  // Surface Tokens - Dark
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Surface Tokens - Light
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlueLight,
        secondary: accentCyan,
        surface: darkSurface,
        error: dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: darkTextPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkSurfaceVariant, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: darkTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 32,
            letterSpacing: -1.0),
        headlineMedium: TextStyle(
            color: darkTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5),
        titleLarge: TextStyle(
            color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(
            color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 16, height: 1.5),
        bodyMedium:
            TextStyle(color: darkTextSecondary, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: accentCyan,
        surface: lightSurface,
        error: dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: lightTextPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightSurfaceVariant, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: lightTextPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 32,
            letterSpacing: -1.0),
        headlineMedium: TextStyle(
            color: lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 24,
            letterSpacing: -0.5),
        titleLarge: TextStyle(
            color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: TextStyle(
            color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge:
            TextStyle(color: lightTextPrimary, fontSize: 16, height: 1.5),
        bodyMedium:
            TextStyle(color: lightTextSecondary, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(color: lightTextSecondary, fontSize: 12),
      ),
    );
  }
}
