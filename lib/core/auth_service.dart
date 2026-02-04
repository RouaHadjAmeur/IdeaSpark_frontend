import 'dart:convert';

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
    this.profilePicture,
  });

  final String id;
  final String email;
  final String displayName;
  final String? profilePicture;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: (json['name'] as String?) ?? (json['email'] as String?).toString().split('@').first,
      profilePicture: json['profilePicture'] as String?,
    );
  }
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

  /// Sign in with Google: get idToken from google_sign_in, then POST /auth/google.
  Future<AppUser?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: null, // optional: use if you have a web client ID for server
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
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['accessToken'] as String? ?? '';
    await _saveSession(token, user);
    return _currentUser;
  }

  /// Sign in with Facebook: get accessToken from flutter_facebook_auth, then POST /auth/facebook.
  Future<AppUser?> signInWithFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success || result.accessToken == null) {
      return null;
    }
    final accessToken = result.accessToken!.tokenString;
    final uri = Uri.parse('${ApiConfig.authBase}/facebook');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessToken': accessToken}),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    final data = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['accessToken'] as String? ?? '';
    await _saveSession(token, user);
    return _currentUser;
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

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
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
