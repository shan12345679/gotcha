// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF0A192F);
  static const Color navyLight = Color(0xFF1E3A5F);

  // 🌊 New accent colour: #00BCD4 (Cyan / Electric Blue)
  static const Color gold = Color(0xFF00BCD4);      // main accent
  static const Color goldLight = Color(0xFF80DEEA); // lighter cyan

  static const Color whiteSoft = Color(0xFFF5F5F5);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: navy,
    colorScheme: const ColorScheme.dark(
      primary: gold,
      secondary: goldLight,
      surface: navyLight,
      background: navy,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      color: navyLight.withOpacity(0.7),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
      labelSmall: TextStyle(fontSize: 12, color: Colors.white60),
    ),
  );
}