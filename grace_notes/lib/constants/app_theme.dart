import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFFE8D5F2);
  static const Color ivory = Color(0xFFFDF8F0);
  static const Color sageGreen = Color(0xFFA8C090);
  static const Color lavender = Color(0xFFD4C5E8);
  static const Color cream = Color(0xFFF9F3E8);
  static const Color mint = Color(0xFFB8D4C8);
  static const Color coral = Color(0xFFF2B5A7);
  static const Color softGray = Color(0xFF8B8B8B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF2C2C2C);
  
  // High visibility colors for better contrast
  static const Color darkPurple = Color(0xFF7B2D8E);
  static const Color darkGreen = Color(0xFF4A6741);
  static const Color darkMint = Color(0xFF5A8A6B);
  static const Color deepLavender = Color(0xFF8E5AA8);
  static const Color richPurple = Color(0xFF9B4BAE);

  static ThemeData lightTheme = ThemeData(
    primarySwatch: MaterialColor(
      primaryPurple.value,
      {
        50: primaryPurple.withOpacity(0.1),
        100: primaryPurple.withOpacity(0.2),
        200: primaryPurple.withOpacity(0.3),
        300: primaryPurple.withOpacity(0.4),
        400: primaryPurple.withOpacity(0.5),
        500: primaryPurple,
        600: primaryPurple.withOpacity(0.7),
        700: primaryPurple.withOpacity(0.8),
        800: primaryPurple.withOpacity(0.9),
        900: primaryPurple.withOpacity(1.0),
      },
    ),
    scaffoldBackgroundColor: ivory,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: sageGreen,
      surface: white,
      onPrimary: textDark,
      onSecondary: textDark,
      onSurface: textDark,
    ),
    cardTheme: CardTheme(
      color: white,
      elevation: 4,
      shadowColor: softGray.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: textDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textDark,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textDark,
      ),
      labelSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: softGray,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: ivory,
      foregroundColor: textDark,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textDark,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: white,
      selectedItemColor: primaryPurple,
      unselectedItemColor: softGray,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: softGray.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        primaryPurple.withOpacity(0.8),
        sageGreen.withOpacity(0.6),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
  );
}
