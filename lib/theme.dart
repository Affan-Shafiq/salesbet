import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0A84FF); // Vibrant blue
  static const Color accent = Color(0xFFFFC300); // Energetic yellow
  static const Color background = Color(0xFF181A20); // Dark background
  static const Color card = Color(0xFF23263A); // Card background
  static const Color success = Color(0xFF00E676); // Green for wins
  static const Color danger = Color(0xFFFF1744); // Red for losses
  static const Color info = Color(0xFF00B8D4); // Cyan for info
}

final ThemeData salesBetsTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  cardColor: AppColors.card,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.accent,
    background: AppColors.background,
    surface: AppColors.card,
  ),
  fontFamily: 'Roboto',
  /*textTheme: const TextTheme(
    headline1: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
    headline2: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
    bodyText1: TextStyle(fontSize: 16, color: Colors.white70),
    bodyText2: TextStyle(fontSize: 14, color: Colors.white60),
  ),*/
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.card,
    elevation: 0,
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
); 