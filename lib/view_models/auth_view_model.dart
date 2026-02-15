import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

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

  /// Restore session from storage (SharedPreferences). Call at app startup (e.g. splash).
  /// Returns true if a valid session was restored (user stays logged in).
  Future<bool> restoreSession() async {
    final loggedIn = await _authService.isLoggedIn();
    notifyListeners();
    return loggedIn;
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> isOnboardingDone() => _authService.isOnboardingDone();

  Future<void> setOnboardingDone() => _authService.setOnboardingDone();

  /// Returns null if user cancelled; otherwise either logged in or requires email verification.
  Future<GoogleSignInResult?> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Verify Google sign-up with the 6-digit code. Returns true on success.
  Future<bool> verifyGoogleWithCode(String code) async {
    if (code.trim().length != 6) {
      _setError('Code must be 6 digits');
      return false;
    }
    _setLoading(true);
    try {
      await _authService.verifyGoogleWithCode(code.trim());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Resend verification code for pending Google sign-in. Returns true on success.
  Future<bool> resendGoogleCode() async {
    _setLoading(true);
    try {
      await _authService.resendGoogleCode();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Returns null if user cancelled; otherwise either logged in or requires email verification.
  Future<FacebookSignInResult?> signInWithFacebook() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithFacebook();
      _setLoading(false);
      return result;
    } catch (e) {
      _setError('Erreur: ${e.toString()}');
      _setLoading(false);
      return null;
    }
  }

  /// Verify Facebook sign-up with the 6-digit code. Returns true on success.
  Future<bool> verifyFacebookWithCode(String code) async {
    if (code.trim().length != 6) {
      _setError('Code must be 6 digits');
      return false;
    }
    _setLoading(true);
    try {
      await _authService.verifyFacebookWithCode(code.trim());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Resend verification code for pending Facebook sign-in. Returns true on success.
  Future<bool> resendFacebookCode() async {
    _setLoading(true);
    try {
      await _authService.resendFacebookCode();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
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
      _setLoading(false);
      if (e.toString().contains('EMAIL_NOT_VERIFIED')) {
        rethrow;
      }
      _setError(e.toString());
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

  /// Verify email with the 6-digit code. Returns true on success.
  Future<bool> verifyEmail(String email, String code) async {
    if (code.trim().length != 6) {
      _setError('Code must be 6 digits');
      return false;
    }
    _setLoading(true);
    try {
      await _authService.verifyEmail(email.trim(), code.trim());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Resend verification code to email. Returns true on success.
  Future<bool> resendVerificationCode(String email) async {
    _setLoading(true);
    try {
      await _authService.resendVerificationCode(email.trim());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Request password reset code sent to email. Returns true on success.
  Future<bool> requestPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      _setError('Email requis');
      return false;
    }
    _setLoading(true);
    try {
      await _authService.requestPasswordReset(email.trim());
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Reset password with code and new password. Returns true on success.
  Future<bool> resetPasswordWithCode(String email, String code, String newPassword) async {
    if (code.trim().length != 6) {
      _setError('Code must be 6 digits');
      return false;
    }
    if (newPassword.length < 6) {
      _setError('Le mot de passe doit faire au moins 6 caractères');
      return false;
    }
    _setLoading(true);
    try {
      await _authService.resetPasswordWithCode(email.trim(), code.trim(), newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  String? get displayName => _authService.currentUser?.displayName;
  String? get email => _authService.currentUser?.email;
  String? get userId => _authService.currentUser?.id;

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
