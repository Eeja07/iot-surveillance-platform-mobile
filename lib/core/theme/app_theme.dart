import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';
import 'app_radius.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5F9),
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
      surface: Colors.white,
    ),
    textTheme: AppTextTheme.lightTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.dark,
      elevation: 0.5,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: Colors.white,
      elevation: 1.0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF161C24),
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      error: AppColors.danger,
      surface: Color(0xFF25293C),
    ),
    textTheme: AppTextTheme.darkTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF25293C),
      foregroundColor: AppColors.light,
      elevation: 0,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: Color(0xFF25293C),
      elevation: 1.0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF25293C),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
    ),
  );
}
