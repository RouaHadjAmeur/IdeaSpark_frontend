import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'google_calendar_storage_service.dart';
import '../models/google_calendar_tokens.dart';

/// Service to handle deep links for OAuth callbacks
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription? _sub;

  // Callback when Google Calendar tokens are received
  Function(GoogleCalendarTokens)? onGoogleCalendarConnected;

  /// Initialize deep link listening
  Future<void> init() async {
    // Handle initial link (app opened via deep link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error getting initial link: $e');
    }

    // Listen for subsequent links (app already open)
    _sub = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _handleLink(uri);
      },
      onError: (err) {
        debugPrint('DeepLinkService: Stream error: $err');
      },
    );
  }

  Future<void> _handleLink(Uri uri) async {
    debugPrint('DeepLinkService: Received link: $uri');

    // Handle Google Calendar OAuth callback
    // ideaspark://google-calendar/callback?accessToken=...&refreshToken=...
    if (uri.scheme == 'ideaspark' &&
        uri.host == 'google-calendar' &&
        uri.path == '/callback') {
      await _handleGoogleCalendarCallback(uri);
    }
  }

  Future<void> _handleGoogleCalendarCallback(Uri uri) async {
    final error = uri.queryParameters['error'];
    if (error != null) {
      debugPrint('DeepLinkService: Google Calendar OAuth error: $error');
      return;
    }

    final accessToken = uri.queryParameters['accessToken'];
    final refreshToken = uri.queryParameters['refreshToken'];

    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('DeepLinkService: No access token in callback');
      return;
    }

    debugPrint('DeepLinkService: Saving Google Calendar tokens...');

    final tokens = GoogleCalendarTokens(
      accessToken: Uri.decodeComponent(accessToken),
      refreshToken: refreshToken != null ? Uri.decodeComponent(refreshToken) : null,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );

    final saved = await GoogleCalendarStorageService.saveTokens(tokens);

    if (saved) {
      debugPrint('DeepLinkService: ✅ Google Calendar tokens saved!');
      onGoogleCalendarConnected?.call(tokens);
    } else {
      debugPrint('DeepLinkService: ❌ Failed to save tokens');
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
