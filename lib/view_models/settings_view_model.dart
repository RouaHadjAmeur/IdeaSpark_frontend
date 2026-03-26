import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyVoiceInput = 'voice_input_enabled';
const String _keyVoiceMode = 'voice_mode_enabled';

/// Manages app-wide feature toggles persisted via SharedPreferences.
///
/// Currently handles:
///   • `voiceInputEnabled` — opt-in Speech-to-Text (default: **false**).
///   • `voiceModeEnabled` — global floating mic and command mode (default: **false**).
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel() {
    _load();
  }

  bool _voiceInputEnabled = false;
  bool get voiceInputEnabled => _voiceInputEnabled;

  bool _voiceModeEnabled = false;
  bool get voiceModeEnabled => _voiceModeEnabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _voiceInputEnabled = prefs.getBool(_keyVoiceInput) ?? false;
    _voiceModeEnabled = prefs.getBool(_keyVoiceMode) ?? false;
    notifyListeners();
  }

  Future<void> setVoiceInputEnabled(bool value) async {
    if (_voiceInputEnabled == value) return;
    _voiceInputEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceInput, value);
    notifyListeners();
  }

  Future<void> setVoiceModeEnabled(bool value) async {
    if (_voiceModeEnabled == value) return;
    _voiceModeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVoiceMode, value);
    notifyListeners();
  }
}
