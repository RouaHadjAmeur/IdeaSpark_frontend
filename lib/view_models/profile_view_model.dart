import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/auth_service.dart';
import '../models/persona_model.dart';
import '../services/persona_service.dart';
import '../services/social_service.dart';
import '../services/youtube_upload_service.dart';
import '../services/instagram_upload_service.dart';

/// ViewModel for Profile / Settings screen.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    AuthService? authService,
    PersonaService? personaService,
    SocialService? socialService,
    YoutubeUploadService? youtubeUploadService,
    InstagramUploadService? instagramUploadService,
  })
      : _authService = authService ?? AuthService(),
        _personaService = personaService ?? PersonaService(),
        _socialService = socialService ?? SocialService(),
        _youtubeUploadService = youtubeUploadService ?? YoutubeUploadService(),
        _instagramUploadService =
            instagramUploadService ?? InstagramUploadService() {
    _loadPersona();
    _loadSocialStats();
    checkYouTubeConnection();
    checkInstagramConnection();
  }

  final AuthService _authService;
  final PersonaService _personaService;
  final SocialService _socialService;
  final YoutubeUploadService _youtubeUploadService;
  final InstagramUploadService _instagramUploadService;

  // Persona state
  PersonaModel? _persona;
  bool _isPersonaLoading = true;
  bool _isPersonaUpdating = false;
  String? _personaUpdateError;

  // Social stats
  int _followersCount = 0;
  int _followingCount = 0;

  // Linked account state
  bool _isYoutubeChecking = true;
  bool _isYoutubeConnecting = false;
  bool _isYoutubeDisconnecting = false;
  bool _isYoutubeConnected = false;
  String? _youtubeErrorMessage;

  bool _isInstagramChecking = true;
  bool _isInstagramConnecting = false;
  bool _isInstagramDisconnecting = false;
  bool _isInstagramConnected = false;
  bool _isInstagramPublishing = false;
  String? _instagramErrorMessage;

  PersonaModel? get persona => _persona;
  bool get isPersonaLoading => _isPersonaLoading;
  bool get hasPersona => _persona != null;
  bool get isPersonaUpdating => _isPersonaUpdating;
  String? get personaUpdateError => _personaUpdateError;
  int get followersCount => _followersCount;
  int get followingCount => _followingCount;
  bool get isYoutubeChecking => _isYoutubeChecking;
  bool get isYoutubeConnecting => _isYoutubeConnecting;
  bool get isYoutubeDisconnecting => _isYoutubeDisconnecting;
  bool get isYoutubeConnected => _isYoutubeConnected;
  String? get youtubeErrorMessage => _youtubeErrorMessage;
  bool get isInstagramChecking => _isInstagramChecking;
  bool get isInstagramConnecting => _isInstagramConnecting;
  bool get isInstagramDisconnecting => _isInstagramDisconnecting;
  bool get isInstagramConnected => _isInstagramConnected;
  bool get isInstagramPublishing => _isInstagramPublishing;
  String? get instagramErrorMessage => _instagramErrorMessage;

  Future<void> _loadSocialStats() async {
    try {
      final following = await _socialService.getFollowing();
      final followers = await _socialService.getFollowers();
      _followingCount = following.length;
      _followersCount = followers.length;
      notifyListeners();
    } catch (_) {}
  }

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
  bool _isUpgradeLoading = false;
  String? _upgradeErrorMessage;
  
  File? _selectedImage;
  File? get selectedImage => _selectedImage;

  bool get dailyReminder => _dailyReminder;
  bool get isDeleteLoading => _isDeleteLoading;
  String? get deleteErrorMessage => _deleteErrorMessage;
  bool get isChangePasswordLoading => _isChangePasswordLoading;
  String? get changePasswordErrorMessage => _changePasswordErrorMessage;
  bool get isUpdateProfileLoading => _isUpdateProfileLoading;
  String? get updateProfileErrorMessage => _updateProfileErrorMessage;
  bool get isUpgradeLoading => _isUpgradeLoading;
  String? get upgradeErrorMessage => _upgradeErrorMessage;

  String get displayName =>
      _authService.currentUser?.displayName ?? 'Utilisateur';
  String get email =>
      _authService.currentUser?.email ?? 'email@exemple.com';
  String get phone => _authService.currentUser?.phone ?? '';
  String? get profilePicture => _authService.currentUser?.profilePicture;
  String? get username => _authService.currentUser?.username;
  List<String> get skills => _authService.currentUser?.skills ?? [];
  String? get role => _authService.currentUser?.role.name;
  List<String> get interests => _authService.currentUser?.interests ?? [];
  bool get isPremium => false;

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

  // Premium upgrade flow is not enabled in this branch.

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

  void clearYoutubeError() {
    if (_youtubeErrorMessage != null) {
      _youtubeErrorMessage = null;
      notifyListeners();
    }
  }

  void clearInstagramError() {
    if (_instagramErrorMessage != null) {
      _instagramErrorMessage = null;
      notifyListeners();
    }
  }

  Future<void> checkYouTubeConnection() async {
    _isYoutubeChecking = true;
    _youtubeErrorMessage = null;
    notifyListeners();

    try {
      _isYoutubeConnected = await _youtubeUploadService.isConnected();
    } catch (e) {
      _isYoutubeConnected = false;
      _youtubeErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isYoutubeChecking = false;
      notifyListeners();
    }
  }

  Future<String?> startYouTubeConnect() async {
    _isYoutubeConnecting = true;
    _youtubeErrorMessage = null;
    notifyListeners();

    try {
      return await _youtubeUploadService.createConnectUrl();
    } catch (e) {
      _youtubeErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isYoutubeConnecting = false;
      notifyListeners();
    }
  }

  Future<bool> disconnectYouTube() async {
    _isYoutubeDisconnecting = true;
    _youtubeErrorMessage = null;
    notifyListeners();

    try {
      await _youtubeUploadService.disconnect();
      _isYoutubeConnected = false;
      return true;
    } catch (e) {
      _youtubeErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isYoutubeDisconnecting = false;
      notifyListeners();
    }
  }

  Future<void> checkInstagramConnection() async {
    _isInstagramChecking = true;
    _instagramErrorMessage = null;
    notifyListeners();

    try {
      _isInstagramConnected = await _instagramUploadService.isConnected();
    } catch (e) {
      _isInstagramConnected = false;
      _instagramErrorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isInstagramChecking = false;
      notifyListeners();
    }
  }

  Future<String?> startInstagramConnect() async {
    _isInstagramConnecting = true;
    _instagramErrorMessage = null;
    notifyListeners();

    try {
      return await _instagramUploadService.createConnectUrl();
    } catch (e) {
      _instagramErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isInstagramConnecting = false;
      notifyListeners();
    }
  }

  Future<bool> disconnectInstagram() async {
    _isInstagramDisconnecting = true;
    _instagramErrorMessage = null;
    notifyListeners();

    try {
      await _instagramUploadService.disconnect();
      _isInstagramConnected = false;
      return true;
    } catch (e) {
      _instagramErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isInstagramDisconnecting = false;
      notifyListeners();
    }
  }

  Future<String?> publishInstagramFromUrl({
    required String mediaType,
    required String mediaUrl,
    String? caption,
    bool? shareToFeed,
    String? audioUrl,
  }) async {
    _isInstagramPublishing = true;
    _instagramErrorMessage = null;
    notifyListeners();

    try {
      return await _instagramUploadService.publishFromUrl(
        mediaType: mediaType,
        mediaUrl: mediaUrl,
        caption: caption,
        shareToFeed: shareToFeed,
        audioUrl: audioUrl,
      );
    } catch (e) {
      _instagramErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isInstagramPublishing = false;
      notifyListeners();
    }
  }

  Future<String?> publishInstagramUpload({
    required String filePath,
    required String mediaType,
    String? caption,
    bool? shareToFeed,
    String? audioUrl,
  }) async {
    _isInstagramPublishing = true;
    _instagramErrorMessage = null;
    notifyListeners();

    try {
      return await _instagramUploadService.publishUpload(
        filePath: filePath,
        mediaType: mediaType,
        caption: caption,
        shareToFeed: shareToFeed,
        audioUrl: audioUrl,
      );
    } catch (e) {
      _instagramErrorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isInstagramPublishing = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? username,
    List<String>? skills,
    String? role,
    List<String>? interests,
  }) async {
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
      
      await _authService.updateProfile(
        name: name,
        phone: phone,
        profilePicture: imageUrl,
        username: username,
        skills: skills,
        role: role,
        interests: interests,
      );
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
