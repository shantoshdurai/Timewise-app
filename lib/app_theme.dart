import 'package:flutter/material.dart';

class AppTheme {
  // Private constructor
  AppTheme._();

  // --- Colors ---
  static const Color _primaryColor = Color(0xFF4A90E2);
  static const Color _accentColor = Color(0xFF50E3C2);
  
  // Light Theme Colors
  static const Color _lightBackground = Color(0xFFF7F9FC);
  static const Color _lightSurface = Colors.white;
  static const Color _lightText = Color(0xFF2D3748);

  // Dark Theme Colors
  static const Color _darkBackground = Color(0xFF1A202C);
  static const Color _darkSurface = Color(0xFF2D3748);
  static const Color _darkText = Color(0xFFEDF2F7);

  // --- Text Theme ---
  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: _lightText),
    displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold, color: _lightText),
    displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: _lightText),
    
    headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: _lightText),
    headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: _lightText),
    headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600, color: _lightText),
    
    titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.w600, color: _lightText),
    titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500, letterSpacing: 0.15, color: _lightText),
    titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: _lightText),
    
    bodyLarge: TextStyle(fontSize: 16.0, color: _lightText),
    bodyMedium: TextStyle(fontSize: 14.0, color: _lightText),
    bodySmall: TextStyle(fontSize: 12.0, color: _lightText),
    
    labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: _lightText),
    labelMedium: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500, color: _lightText),
    labelSmall: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500, color: _lightText),
  );
  
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _lightBackground,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: _lightSurface,
      background: _lightBackground,
      error: Colors.red,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: _lightText,
      onBackground: _lightText,
      onError: Colors.white,
    ),
    textTheme: _textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: _textTheme.headlineSmall?.copyWith(color: _lightText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      labelStyle: _textTheme.bodyMedium,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: _primaryColor,
      secondary: _accentColor,
      surface: _darkSurface,
      background: _darkBackground,
      error: Colors.redAccent,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: _darkText,
      onBackground: _darkText,
      onError: Colors.white,
    ),
    textTheme: _textTheme.apply(
      displayColor: _darkText,
      bodyColor: _darkText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkBackground,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: _textTheme.headlineSmall?.copyWith(color: _darkText),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: _textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[600]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      labelStyle: _textTheme.bodyMedium?.copyWith(color: _darkText),
      hintStyle: _textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
    ),
  );
}
