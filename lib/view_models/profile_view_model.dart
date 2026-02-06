import 'package:flutter/foundation.dart';
import '../core/auth_service.dart';

/// ViewModel for Profile / Settings screen.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _dailyReminder = false;
  bool _isDeleteLoading = false;
  String? _deleteErrorMessage;
  bool _isChangePasswordLoading = false;
  String? _changePasswordErrorMessage;

  bool get dailyReminder => _dailyReminder;
  bool get isDeleteLoading => _isDeleteLoading;
  String? get deleteErrorMessage => _deleteErrorMessage;
  bool get isChangePasswordLoading => _isChangePasswordLoading;
  String? get changePasswordErrorMessage => _changePasswordErrorMessage;

  String get displayName =>
      _authService.currentUser?.displayName ?? 'Utilisateur';
  String get email =>
      _authService.currentUser?.email ?? 'email@exemple.com';

  void setDailyReminder(bool value) {
    if (_dailyReminder != value) {
      _dailyReminder = value;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    notifyListeners();
  }

  void clearDeleteError() {
    if (_deleteErrorMessage != null) {
      _deleteErrorMessage = null;
      notifyListeners();
    }
  }

  void clearChangePasswordError() {
    if (_changePasswordErrorMessage != null) {
      _changePasswordErrorMessage = null;
      notifyListeners();
    }
  }

  /// Change password (current + new). Returns true on success.
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (newPassword.length < 6) {
      _changePasswordErrorMessage = 'Le mot de passe doit faire au moins 6 caractères';
      notifyListeners();
      return false;
    }
    _isChangePasswordLoading = true;
    _changePasswordErrorMessage = null;
    notifyListeners();
    try {
      await _authService.changePassword(currentPassword, newPassword);
      _isChangePasswordLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _changePasswordErrorMessage = e.toString();
      _isChangePasswordLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request verification code for account deletion. Returns true on success.
  Future<bool> requestDeleteAccountCode() async {
    _isDeleteLoading = true;
    _deleteErrorMessage = null;
    notifyListeners();
    try {
      await _authService.requestDeleteAccountCode();
      _isDeleteLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _deleteErrorMessage = e.toString();
      _isDeleteLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Confirm account deletion with code. Returns true on success (session is cleared).
  Future<bool> confirmDeleteAccount(String code) async {
    if (code.trim().length != 6) {
      _deleteErrorMessage = 'Code must be 6 digits';
      notifyListeners();
      return false;
    }
    _isDeleteLoading = true;
    _deleteErrorMessage = null;
    notifyListeners();
    try {
      await _authService.confirmDeleteAccount(code.trim());
      _isDeleteLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _deleteErrorMessage = e.toString();
      _isDeleteLoading = false;
      notifyListeners();
      return false;
    }
  }
}
