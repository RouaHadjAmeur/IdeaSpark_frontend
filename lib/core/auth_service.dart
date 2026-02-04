import 'package:shared_preferences/shared_preferences.dart';

/// Simple user model for static/demo auth (no Firebase).
class AppUser {
  AppUser({required this.displayName, required this.email});
  final String displayName;
  final String email;
}

/// Static auth service: no Firebase, Google, or Facebook.
/// Uses SharedPreferences for persistence. All auth is local/demo.
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  AuthService._();

  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyLoggedIn = 'logged_in';
  static const _keyUserEmail = 'user_email';
  static const _keyUserDisplayName = 'user_display_name';

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Future<void> _loadStoredUser() async {
    if (_currentUser != null) return;
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    if (!loggedIn) return;
    final email = prefs.getString(_keyUserEmail) ?? 'email@exemple.com';
    final displayName = prefs.getString(_keyUserDisplayName) ?? 'Utilisateur';
    _currentUser = AppUser(displayName: displayName, email: email);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  Future<bool> isLoggedIn() async {
    await _loadStoredUser();
    return _currentUser != null;
  }

  Future<AppUser?> signInWithGoogle() async {
    await _saveUser(
      displayName: 'Google User',
      email: 'google@demo.ideaspark.app',
    );
    return _currentUser;
  }

  Future<AppUser?> signInWithFacebook() async {
    await _saveUser(
      displayName: 'Facebook User',
      email: 'facebook@demo.ideaspark.app',
    );
    return _currentUser;
  }

  Future<void> signInWithEmail(String email, String password) async {
    final name = email.split('@').first;
    await _saveUser(displayName: name.isNotEmpty ? name : 'User', email: email);
  }

  Future<void> signUpWithEmail(String email, String password) async {
    final name = email.split('@').first;
    await _saveUser(displayName: name.isNotEmpty ? name : 'User', email: email);
  }

  Future<void> _saveUser({
    required String displayName,
    required String email,
  }) async {
    _currentUser = AppUser(displayName: displayName, email: email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserDisplayName, displayName);
  }

  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, false);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserDisplayName);
  }
}
