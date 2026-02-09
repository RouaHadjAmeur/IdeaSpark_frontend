import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyDarkMode = 'theme_dark_mode';

/// ViewModel for app theme (dark/light). Persists preference and notifies for MaterialApp.
class ThemeViewModel extends ChangeNotifier {
  ThemeViewModel() {
    _loadTheme();
  }

  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }
}
