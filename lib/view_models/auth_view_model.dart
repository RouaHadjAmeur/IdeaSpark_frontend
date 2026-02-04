import 'package:flutter/foundation.dart';
import '../core/auth_service.dart';

/// ViewModel for authentication (Login, SignUp).
/// Uses static [AuthService] — no Firebase.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.currentUser != null;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> isOnboardingDone() => _authService.isOnboardingDone();

  Future<void> setOnboardingDone() => _authService.setOnboardingDone();

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      _setLoading(false);
      return result != null;
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithFacebook();
      _setLoading(false);
      return result != null;
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _setError('Email et mot de passe requis');
      return false;
    }
    _setLoading(true);
    try {
      await _authService.signInWithEmail(email.trim(), password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      _setError('Email et mot de passe requis');
      return false;
    }
    if (password != confirmPassword) {
      _setError('Les mots de passe ne correspondent pas');
      return false;
    }
    if (password.length < 6) {
      _setError('Le mot de passe doit faire au moins 6 caractères');
      return false;
    }
    _setLoading(true);
    try {
      await _authService.signUpWithEmail(email.trim(), password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  String? get displayName => _authService.currentUser?.displayName;
  String? get email => _authService.currentUser?.email;

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
