import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

import 'api_config.dart';

/// User model matching backend User entity (id, email, name, profilePicture).
class AppUser {
  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.profilePicture,
  });

  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? profilePicture;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: (json['name'] as String?) ?? (json['email'] as String?).toString().split('@').first,
      phone: json['phone'] as String?,
      profilePicture: (json['profile_img'] as String?) ?? (json['profilePicture'] as String?),
    );
  }
}

/// Result of Google sign-in: either logged in or must verify email with code.
class GoogleSignInResult {
  const GoogleSignInResult({this.user, this.emailForVerification})
      : assert(user == null || emailForVerification == null);
  final AppUser? user;
  final String? emailForVerification;
  bool get loggedIn => user != null;
  bool get requiresVerification => emailForVerification != null;
}

/// Result of Facebook sign-in: either logged in or must verify email with code.
class FacebookSignInResult {
  const FacebookSignInResult({this.user, this.emailForVerification})
      : assert(user == null || emailForVerification == null);
  final AppUser? user;
  final String? emailForVerification;
  bool get loggedIn => user != null;
  bool get requiresVerification => emailForVerification != null;
}

/// Auth service that uses the IdeaSpark NestJS backend for login/register and Google/Facebook token exchange.
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;

  static const _keyOnboardingDone = 'onboarding_done';
  static const _keyAccessToken = 'auth_access_token';
  static const _keyUser = 'auth_user';

  AppUser? _currentUser;
  String? _accessToken;
  /// When backend returns requiresVerification for Google, we keep idToken to verify with code.
  String? _pendingGoogleIdToken;
  /// When backend returns requiresVerification for Facebook, we keep accessToken to verify with code.
  String? _pendingFacebookAccessToken;

  AppUser? get currentUser => _currentUser;
  String? get accessToken => _accessToken;

  Future<void> _loadStored() async {
    if (_currentUser != null && _accessToken != null) return;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccessToken);
    final userJson = prefs.getString(_keyUser);
    if (userJson != null && _accessToken != null) {
      try {
        final map = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(map);
      } catch (_) {
        _currentUser = null;
        _accessToken = null;
      }
    }
  }

  Future<void> _saveSession(String token, AppUser user) async {
    _accessToken = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
    await prefs.setString(_keyUser, jsonEncode({
      'id': user.id,
      'email': user.email,
      'name': user.displayName,
      'phone': user.phone,
      'profilePicture': user.profilePicture,
    }));
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyUser);
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
    await _loadStored();
    return _currentUser != null && _accessToken != null;
  }

  /// Login with email and password via backend POST /auth/login.
  /// Throws Exception('EMAIL_NOT_VERIFIED') if user exists but email is not verified.
  Future<void> signInWithEmail(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.authBase}/login');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    if (res.statusCode == 401) {
      final msg = _errorMessage(res);
      if (msg.contains('EMAIL_NOT_VERIFIED') || msg == 'EMAIL_NOT_VERIFIED') {
        throw Exception('EMAIL_NOT_VERIFIED');
      }
    }
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['accessToken'] as String? ?? '';
    await _saveSession(token, user);
  }

  /// Register with email and password via backend POST /auth/register.
  /// User is created with status pending; they must verify email with code.
  Future<void> signUpWithEmail(String email, String password) async {
    final name = email.split('@').first;
    final uri = Uri.parse('${ApiConfig.authBase}/register');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        if (name.isNotEmpty) 'name': name,
      }),
    );
    if (res.statusCode == 409) {
      throw Exception('Email already exists');
    }
    if (res.statusCode != 201) {
      throw Exception(_errorMessage(res));
    }
    // Do not save session until email is verified; user is redirected to verify-email screen.
  }

  /// Verify email with 6-digit code. On success, user becomes active and session is updated.
  Future<void> verifyEmail(String email, String code) async {
    final uri = Uri.parse('${ApiConfig.authBase}/verify-email');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['accessToken'] as String? ?? '';
    await _saveSession(token, user);
  }

  /// Request a password reset code sent to email. Only for email/password accounts.
  Future<void> requestPasswordReset(String email) async {
    final uri = Uri.parse('${ApiConfig.authBase}/forgot-password');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
  }

  /// Reset password with the 6-digit code received by email.
  Future<void> resetPasswordWithCode(String email, String code, String newPassword) async {
    final uri = Uri.parse('${ApiConfig.authBase}/reset-password');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
  }

  /// Change password (authenticated). Requires current password.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _loadStored();
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in');
    }
    final uri = Uri.parse('${ApiConfig.authBase}/change-password');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
  }

  /// Resend verification code to email.
  Future<void> resendVerificationCode(String email) async {
    final uri = Uri.parse('${ApiConfig.authBase}/resend-code');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
  }

  /// Sign in with Google: get idToken, POST /auth/google. Backend may log in immediately or return requiresVerification + send code to email.
  /// serverClientId must be your backend's Web client ID so the id_token audience matches and the backend can verify it.
  Future<GoogleSignInResult?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: ApiConfig.googleWebClientId.isEmpty
            ? null
            : ApiConfig.googleWebClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Could not get Google ID token');
      }
      final uri = Uri.parse('${ApiConfig.authBase}/google');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      if (res.statusCode != 200) {
        throw Exception(_errorMessage(res));
      }
      final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
      if (data['requiresVerification'] == true && data['email'] != null) {
        _pendingGoogleIdToken = idToken;
        return GoogleSignInResult(emailForVerification: data['email'] as String);
      }
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
      final token = data['accessToken'] as String? ?? '';
      await _saveSession(token, user);
      return GoogleSignInResult(user: _currentUser);
    } on PlatformException catch (e) {
      throw Exception('Google Sign-In: ${e.message ?? e.code}');
    } catch (e) {
      rethrow;
    }
  }

  /// Verify Google sign-up with the 6-digit code sent to email. Call after signInWithGoogle() returned requiresVerification.
  Future<void> verifyGoogleWithCode(String code) async {
    final idToken = _pendingGoogleIdToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('No pending Google sign-in');
    }
    final uri = Uri.parse('${ApiConfig.authBase}/google/verify');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken, 'code': code.trim()}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    _pendingGoogleIdToken = null;
    final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['accessToken'] as String? ?? '';
    await _saveSession(token, user);
  }

  /// Resend verification code for pending Google sign-in.
  Future<void> resendGoogleCode() async {
    final idToken = _pendingGoogleIdToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('No pending Google sign-in');
    }
    final uri = Uri.parse('${ApiConfig.authBase}/google/resend-code');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
  }

  /// Sign in with Facebook: get accessToken, POST /auth/facebook. Backend may log in or return requiresVerification + send code to email.
  Future<FacebookSignInResult?> signInWithFacebook() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success || result.accessToken == null) {
        return null;
      }
      final tokenValue = result.accessToken!.tokenString;
      final uri = Uri.parse('${ApiConfig.authBase}/facebook');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': tokenValue}),
      );
      if (res.statusCode != 200) {
        throw Exception(_errorMessage(res));
      }
      final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
      if (data['requiresVerification'] == true && data['email'] != null) {
        _pendingFacebookAccessToken = tokenValue;
        return FacebookSignInResult(emailForVerification: data['email'] as String);
      }
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
      final token = data['accessToken'] as String? ?? '';
      await _saveSession(token, user);
      return FacebookSignInResult(user: _currentUser);
    } on PlatformException catch (e) {
      throw Exception('Facebook: ${e.message ?? e.code}');
    } catch (e) {
      rethrow;
    }
  }

  /// Verify Facebook sign-up with the 6-digit code sent to email.
  Future<void> verifyFacebookWithCode(String code) async {
    final accessToken = _pendingFacebookAccessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No pending Facebook sign-in');
    }
    final uri = Uri.parse('${ApiConfig.authBase}/facebook/verify');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken, 'code': code.trim()}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    _pendingFacebookAccessToken = null;
    final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['accessToken'] as String? ?? '';
    await _saveSession(token, user);
  }

  /// Resend verification code for pending Facebook sign-in.
  Future<void> resendFacebookCode() async {
    final accessToken = _pendingFacebookAccessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No pending Facebook sign-in');
    }
    final uri = Uri.parse('${ApiConfig.authBase}/facebook/resend-code');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
  }

  String _errorMessage(http.Response res) {
    final body = _tryDecode(res.body);
    if (body is Map) {
      final msg = body['message'];
      if (msg is List) return msg.isNotEmpty ? msg.join(' ') : res.body;
      if (msg != null) return msg.toString();
    }
    return res.body.isNotEmpty ? res.body : 'Request failed';
  }

  Future<void> updateProfile({String? name, String? phone, String? profilePicture}) async {
    await _loadStored();
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in');
    }
    final uri = Uri.parse('${ApiConfig.usersBase}/profile');
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (profilePicture != null) body['profile_img'] = profilePicture;

    final res = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    
    // Update local user
    final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    // Backend returns the updated user object
    final updatedUser = AppUser.fromJson(data);
    // Keep existing token
    await _saveSession(_accessToken!, updatedUser);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await _clearSession();
  }

  /// Request a verification code to be sent to the user's email before account deletion.
  /// Requires the user to be logged in (Bearer token).
  Future<void> requestDeleteAccountCode() async {
    await _loadStored();
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in');
    }
    final uri = Uri.parse('${ApiConfig.authBase}/delete-account/send-code');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
  }

  /// Confirm account deletion with the 6-digit code. Clears session on success.
  Future<void> confirmDeleteAccount(String code) async {
    await _loadStored();
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in');
    }
    final uri = Uri.parse('${ApiConfig.authBase}/delete-account/confirm');
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code.trim()}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    await _clearSession();
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }
}
