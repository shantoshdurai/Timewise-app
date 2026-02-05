import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String? _customBackgroundPath;
  double _glassBlur = 25.0; // Default UI glass blur
  double _backgroundBlur = 0.0; // Default background blur (no blur)

  ThemeMode get themeMode => _themeMode;
  String? get customBackgroundPath => _customBackgroundPath;
  double get glassBlur => _glassBlur;
  double get backgroundBlur => _backgroundBlur;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme') ?? 'dark';
    _customBackgroundPath = prefs.getString('custom_background');
    _glassBlur = prefs.getDouble('glass_blur') ?? 25.0;
    _backgroundBlur = prefs.getDouble('background_blur') ?? 0.0;
    if (themeString == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', isDark ? 'dark' : 'light');
  }

  Future<void> setCustomBackground(String path) async {
    _customBackgroundPath = path;
    _themeMode =
        ThemeMode.dark; // Force dark mode when custom background is set
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_background', path);
    await prefs.setString('theme', 'dark');
  }

  Future<void> clearCustomBackground() async {
    _customBackgroundPath = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('custom_background');
  }

  Future<void> setGlassBlur(double value) async {
    _glassBlur = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('glass_blur', value);
  }

  Future<void> setBackgroundBlur(double value) async {
    _backgroundBlur = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('background_blur', value);
  }
}
