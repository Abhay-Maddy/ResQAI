import 'package:flutter/material.dart';
import 'app_colors.dart';

/**
 * ResQAI Theme Definition
 * Strictly aligned with PRD v3.0 UX-10 to UX-13:
 * - 12 px card radius, 8 px input radius (UX-10)
 * - 48 px minimum button touch targets (UX-13)
 * - Contrast ratios >= 4.5:1 text, >= 3:1 icons (UX-1 to UX-5)
 * - Typography: body 16px, secondary minimum 14px, line-height 1.5 (UX-11)
 */
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkWarning,
        surface: AppColors.darkSurface,
        error: AppColors.darkDanger,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 28, height: 1.3),
        headlineMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700, fontSize: 22, height: 1.3),
        titleMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600, fontSize: 16, height: 1.4),
        bodyLarge: TextStyle(color: AppColors.darkText, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: AppColors.darkTextMuted, fontSize: 14, height: 1.5),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: AppColors.lightPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightWarning,
        surface: AppColors.lightSurface,
        error: AppColors.lightDanger,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold, fontSize: 28, height: 1.3),
        headlineMedium: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.w700, fontSize: 22, height: 1.3),
        titleMedium: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.w600, fontSize: 16, height: 1.4),
        bodyLarge: TextStyle(color: AppColors.lightText, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: AppColors.lightTextMuted, fontSize: 14, height: 1.5),
      ),
      useMaterial3: true,
    );
  }
}
