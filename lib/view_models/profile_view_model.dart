import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/auth_service.dart';
import '../models/persona_model.dart';
import '../services/persona_service.dart';

/// ViewModel for Profile / Settings screen.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({AuthService? authService, PersonaService? personaService})
      : _authService = authService ?? AuthService(),
        _personaService = personaService ?? PersonaService() {
    _loadPersona();
  }

  final AuthService _authService;
  final PersonaService _personaService;

  // Persona state
  PersonaModel? _persona;
  bool _isPersonaLoading = true;
  bool _isPersonaUpdating = false;
  String? _personaUpdateError;

  PersonaModel? get persona => _persona;
  bool get isPersonaLoading => _isPersonaLoading;
  bool get hasPersona => _persona != null;
  bool get isPersonaUpdating => _isPersonaUpdating;
  String? get personaUpdateError => _personaUpdateError;

  Future<void> _loadPersona() async {
    _isPersonaLoading = true;
    notifyListeners();
    try {
      final userId = _authService.currentUser?.id ?? '';
      _persona = await _personaService.getPersona(userId);
    } catch (_) {
      _persona = null;
    }
    _isPersonaLoading = false;
    notifyListeners();
  }

  Future<void> refreshPersona() async {
    await _loadPersona();
  }

  /// Update a single persona field via PUT /persona.
  Future<bool> updatePersonaField(PersonaModel updatedPersona) async {
    _isPersonaUpdating = true;
    _personaUpdateError = null;
    notifyListeners();
    try {
      final result = await _personaService.updatePersona(updatedPersona);
      _persona = result;
      _isPersonaUpdating = false;
      notifyListeners();
      return true;
    } catch (e) {
      _personaUpdateError = e.toString();
      _isPersonaUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void clearPersonaUpdateError() {
    if (_personaUpdateError != null) {
      _personaUpdateError = null;
      notifyListeners();
    }
  }

  bool _dailyReminder = false;
  bool _isDeleteLoading = false;
  String? _deleteErrorMessage;
  bool _isChangePasswordLoading = false;
  String? _changePasswordErrorMessage;
  bool _isUpdateProfileLoading = false;
  String? _updateProfileErrorMessage;
  
  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  bool get dailyReminder => _dailyReminder;
  bool get isDeleteLoading => _isDeleteLoading;
  String? get deleteErrorMessage => _deleteErrorMessage;
  bool get isChangePasswordLoading => _isChangePasswordLoading;
  String? get changePasswordErrorMessage => _changePasswordErrorMessage;
  bool get isUpdateProfileLoading => _isUpdateProfileLoading;
  String? get updateProfileErrorMessage => _updateProfileErrorMessage;

  String get displayName =>
      _authService.currentUser?.displayName ?? 'Utilisateur';
  String get email =>
      _authService.currentUser?.email ?? 'email@exemple.com';
  String get phone => _authService.currentUser?.phone ?? '';
  String? get profilePicture => _authService.currentUser?.profilePicture;

  void refresh() {
    _selectedImage = null;
    notifyListeners();
  }

  void setSelectedImage(File? image) {
    _selectedImage = image;
    notifyListeners();
  }

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

  Future<bool> updateProfile({String? name, String? phone}) async {
    _isUpdateProfileLoading = true;
    _updateProfileErrorMessage = null;
    notifyListeners();
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        // Prefix with data URI scheme for base64 images
        imageUrl = 'data:image/jpeg;base64,$base64Image';
      }
      
      await _authService.updateProfile(name: name, phone: phone, profilePicture: imageUrl);
      _isUpdateProfileLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _updateProfileErrorMessage = e.toString();
      _isUpdateProfileLoading = false;
      notifyListeners();
      return false;
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
