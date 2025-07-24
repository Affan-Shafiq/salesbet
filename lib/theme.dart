import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1976D2); // Modern blue
  static const Color accent = Color(0xFFFFC107); // Amber
  static const Color background = Color(0xFFF5F6FA); // Very light gray
  static const Color card = Color(0xFFFFFFFF); // White
  static const Color success = Color(0xFF43A047); // Green
  static const Color danger = Color(0xFFE53935); // Red
  static const Color info = Color(0xFF039BE5); // Light blue
  static const Color text = Color(0xFF222222); // Dark text
  static const Color subtitle = Color(0xFF666666); // Subtle text
}

final ThemeData salesBetsTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  cardColor: AppColors.card,
  colorScheme: const ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.background,
    surface: AppColors.card,
  ),
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text),
    titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.text),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.subtitle),
    bodySmall: TextStyle(fontSize: 12, color: AppColors.subtitle),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.card,
    elevation: 0,
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
    iconTheme: IconThemeData(color: AppColors.primary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF0F1F6),
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.subtitle)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 2)),
    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    labelStyle: TextStyle(color: AppColors.text),
    floatingLabelStyle: TextStyle(color: AppColors.text),
    hintStyle: TextStyle(color: AppColors.text),
    suffixIconColor: AppColors.subtitle,
  ),
  cardTheme: const CardThemeData(
    color: AppColors.card,
    elevation: 2,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  dividerTheme: const DividerThemeData(
    color: Color(0xFFE0E0E0),
    thickness: 1,
    space: 24,
  ),
); 