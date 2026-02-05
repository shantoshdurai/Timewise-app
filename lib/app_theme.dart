import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor
  AppTheme._();

  // --- Premium Apple-Inspired Colors ---
  // Vibrant primary colors with depth
  static const Color _primaryBlue = Color(0xFF007AFF); // iOS Blue
  static const Color _accentPurple = Color(0xFF5E5CE6); // iOS Purple
  static const Color _accentPink = Color(0xFFFF2D55); // iOS Pink
  static const Color _accentOrange = Color(0xFFFF9500); // iOS Orange
  static const Color _accentGreen = Color(0xFF34C759); // iOS Green

  // Light Theme Colors - Pristine and Clean
  static const Color _lightBackground = Color(0xFFF2F2F7); // iOS Light Gray
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF000000);
  static const Color _lightSecondaryText = Color(0xFF8E8E93);

  // Dark Theme Colors - Deep and Rich
  static const Color _darkBackground = Color(0xFF000000); // True Black OLED
  static const Color _darkSurface = Color(0xFF1C1C1E); // iOS Dark Gray
  static const Color _darkElevated = Color(0xFF2C2C2E); // Elevated surface
  static const Color _darkText = Color(0xFFFFFFFF);
  static const Color _darkSecondaryText = Color(0xFF8E8E93);

  // --- Text Theme ---
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57.0,
      fontWeight: FontWeight.bold,
      color: _lightText,
    ),
    displayMedium: TextStyle(
      fontSize: 45.0,
      fontWeight: FontWeight.bold,
      color: _lightText,
    ),
    displaySmall: TextStyle(
      fontSize: 36.0,
      fontWeight: FontWeight.bold,
      color: _lightText,
    ),

    headlineLarge: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: _lightText,
    ),
    headlineMedium: TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: _lightText,
    ),
    headlineSmall: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
      color: _lightText,
    ),

    titleLarge: TextStyle(
      fontSize: 22.0,
      fontWeight: FontWeight.w600,
      color: _lightText,
    ),
    titleMedium: TextStyle(
      fontSize: 16.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      color: _lightText,
    ),
    titleSmall: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: _lightText,
    ),

    bodyLarge: TextStyle(fontSize: 16.0, color: _lightText),
    bodyMedium: TextStyle(fontSize: 14.0, color: _lightText),
    bodySmall: TextStyle(fontSize: 12.0, color: _lightText),

    labelLarge: TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: _lightText,
    ),
    labelMedium: TextStyle(
      fontSize: 12.0,
      fontWeight: FontWeight.w500,
      color: _lightText,
    ),
    labelSmall: TextStyle(
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
      color: _lightText,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryBlue,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: ColorScheme.light(
      primary: _primaryBlue,
      secondary: _accentPurple,
      surface: _lightSurface,
      background: _lightBackground,
      surfaceVariant: const Color(0xFFF2F2F7),
      error: _accentPink,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lightText,
      onBackground: _lightText,
      onError: Colors.white,
    ),
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryBlue),
      titleTextStyle: _textTheme.headlineSmall?.copyWith(
        color: _lightText,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        shadowColor: _primaryBlue.withOpacity(0.3),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    cardTheme: const CardThemeData(
      color: _lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightSecondaryText.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lightSecondaryText.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      labelStyle: _textTheme.bodyMedium,
      hintStyle: TextStyle(color: _lightSecondaryText),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryBlue,
    scaffoldBackgroundColor: _darkBackground,
    colorScheme: ColorScheme.dark(
      primary: _primaryBlue,
      secondary: _accentPurple,
      surface: _darkSurface,
      background: _darkBackground,
      surfaceVariant: _darkElevated,
      error: _accentPink,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkText,
      onBackground: _darkText,
      onError: Colors.white,
    ),
    textTheme: _textTheme.apply(displayColor: _darkText, bodyColor: _darkText),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryBlue),
      titleTextStyle: _textTheme.headlineSmall?.copyWith(
        color: _darkText,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        shadowColor: _primaryBlue.withOpacity(0.4),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    cardTheme: const CardThemeData(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _darkSecondaryText.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _darkSecondaryText.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      labelStyle: _textTheme.bodyMedium?.copyWith(color: _darkText),
      hintStyle: TextStyle(color: _darkSecondaryText),
    ),
  );

  // MARK: - Premium Color Getters (for use in widgets)
  static Color get accentOrange => _accentOrange;
  static Color get accentGreen => _accentGreen;
  static Color get primaryBlue => _primaryBlue;
  static Color get accentPurple => _accentPurple;
  static Color get accentPink => _accentPink;
}
