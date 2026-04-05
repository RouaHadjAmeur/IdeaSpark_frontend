import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyVoiceInput = 'voice_input_enabled';
const String _keyVoiceMode = 'voice_mode_enabled';
const String _keyHandsFreeEnabled = 'hands_free_mode_enabled';
const String _keyHandsFreeOnboardingCompleted = 'hands_free_onboarding_completed';

/// Manages app-wide feature toggles persisted via SharedPreferences.
///
/// Handles:
///   • `voiceInputEnabled`              — opt-in STT mic input (default: false).
///   • `voiceModeEnabled`               — global floating mic & command mode (default: false).
///   • `handsFreeEnabled`               — foreground hands-free wake-loop mode (default: false).
///   • `handsFreeOnboardingCompleted`   — whether the user has seen the onboarding prompt (default: false).
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel() {
    _load();
  }

  bool _voiceInputEnabled = false;
  bool get voiceInputEnabled => _voiceInputEnabled;

  bool _voiceModeEnabled = false;
  bool get voiceModeEnabled => _voiceModeEnabled;

  bool _handsFreeEnabled = false;
  bool get handsFreeEnabled => _handsFreeEnabled;

  bool _handsFreeOnboardingCompleted = false;
  bool get handsFreeOnboardingCompleted => _handsFreeOnboardingCompleted;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _voiceInputEnabled = prefs.getBool(_keyVoiceInput) ?? false;
    _voiceModeEnabled = prefs.getBool(_keyVoiceMode) ?? false;
    _handsFreeEnabled = prefs.getBool(_keyHandsFreeEnabled) ?? false;
    _handsFreeOnboardingCompleted = prefs.getBool(_keyHandsFreeOnboardingCompleted) ?? false;
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

  Future<void> setHandsFreeEnabled(bool value) async {
    if (_handsFreeEnabled == value) return;
    _handsFreeEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHandsFreeEnabled, value);
    notifyListeners();
  }

  Future<void> setHandsFreeOnboardingCompleted(bool value) async {
    if (_handsFreeOnboardingCompleted == value) return;
    _handsFreeOnboardingCompleted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHandsFreeOnboardingCompleted, value);
    notifyListeners();
  }
}
