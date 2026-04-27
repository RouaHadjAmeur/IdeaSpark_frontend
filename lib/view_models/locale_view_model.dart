import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyLocale = 'app_locale';

class LocaleViewModel extends ChangeNotifier {
  LocaleViewModel() {
    _load();
  }

  String _locale = 'fr';
  String get locale => _locale;
  Locale get flutterLocale => _locale == 'en' ? const Locale('en') : const Locale('fr');

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString(_keyLocale) ?? 'fr';
    notifyListeners();
  }

  Future<void> setLocale(String value) async {
    if (_locale == value) return;
    _locale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, value);
    notifyListeners();
  }
}
