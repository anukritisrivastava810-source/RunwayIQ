import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF22C55E); // Emerald Green
  static const Color secondaryColor = Color(0xFF111111); // Black
  static const Color backgroundColor = Color(0xFFFFFFFF); // White
  static const Color surfaceColor = Color(0xFFF8F9FB); // Off White Surface
  static const Color accentColor = Color(0xFF3B82F6); // Blue Accent
  static const Color errorColor = Color(0xFFEF4444); // Soft Red
  static const Color successColor = Color(0xFF10B981); // Success Green
  static const Color textColor = Color(0xFF111111); // Black Text
  static const Color textMutedColor = Color(0xFF6B7280); // Gray Text

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        headlineLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: textColor, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: textColor, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: textMutedColor, fontWeight: FontWeight.w400),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: textMutedColor),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textMutedColor,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }
}
