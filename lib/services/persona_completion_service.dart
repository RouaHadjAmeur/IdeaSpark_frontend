import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage persona onboarding completion status
class PersonaCompletionService {
  static const String _personaCompletedKey = 'persona_completed';
  
  /// Check if the user has completed the persona onboarding
  static Future<bool> isPersonaCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_personaCompletedKey) ?? false;
  }
  
  /// Mark the persona onboarding as completed
  static Future<void> markPersonaCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_personaCompletedKey, true);
  }
  
  /// Reset the persona completion status (useful for testing or re-onboarding)
  static Future<void> resetPersonaCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_personaCompletedKey);
  }
  
  /// Check if user needs to complete persona (not completed)
  static Future<bool> needsPersonaCompletion() async {
    return !(await isPersonaCompleted());
  }
}
