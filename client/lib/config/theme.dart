import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF00695C);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color primaryLight = Color(0xFF80CBC4);
  static const Color primarySurface = Color(0xFFE0F2F1);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4A4A4A);

  static const Color emergencyRed = Color(0xFFD32F2F);
  static const Color statusAmber = Color(0xFFF57C00);
  static const Color statusGreen = Color(0xFF2E7D32);

  static const double minTouchTarget = 48.0;
  static const double preferredTouchTarget = 56.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 72.0;
  static const double pagePadding = 16.0;
  static const double pagePaddingLarge = 24.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surface,
        error: emergencyRed,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 18, color: textPrimary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 18, color: textPrimary, height: 1.4),
        bodySmall: TextStyle(fontSize: 16, color: textSecondary, height: 1.4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, preferredTouchTarget),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(buttonRadius)),
        hintStyle: const TextStyle(fontSize: 18, color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: TextStyle(fontSize: 14),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}