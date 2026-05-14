// lib/utils/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const green = Color(0xFF0F5132);
  static const greenLight = Color(0xFF14563A);
  static const burgundy = Color(0xFF7B1023);
  static const cream = Color(0xFFF7EFE5);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF1A1A1A);
  static const textGrey = Color(0xFF6B7280);
  static const chipGreen = Color(0xFFE9F6F0);
  static const chipRed = Color(0xFFF5E7E9);
  static const inputFill = Color(0xFFF5F2EE);
}

class AppTheme {
  AppTheme._();
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.burgundy,
    ),
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.green,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.burgundy,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.green, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
  );
}
