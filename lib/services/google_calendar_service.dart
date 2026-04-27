import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/google_calendar_tokens.dart';
import '../core/api_config.dart';

/// Result wrapper for Google Calendar operations
class GoogleCalendarResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const GoogleCalendarResult.success(this.data)
      : error = null,
        isSuccess = true;

  const GoogleCalendarResult.error(this.error)
      : data = null,
        isSuccess = false;
}

/// Sync result for plan synchronization
class SyncResult {
  final int total;
  final int synced;
  final int failed;
  final List<String> errors;

  const SyncResult({
    required this.total,
    required this.synced,
    required this.failed,
    this.errors = const [],
  });

  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      total: json['total'] as int? ?? 0,
      synced: json['synced'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      errors: (json['errors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool get hasErrors => failed > 0;
  bool get isFullSuccess => synced == total && failed == 0;
}

/// Service for Google Calendar integration
class GoogleCalendarService {
  final http.Client _client;
  final String _baseUrl;

  GoogleCalendarService({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Get the Google OAuth authorization URL
  /// 
  /// Returns the URL to redirect the user for Google Calendar authorization.
  /// 
  /// Parameters:
  /// - [authToken]: JWT token for authentication
  /// 
  /// Example:
  /// ```dart
  /// final result = await service.getAuthUrl(userToken);
  /// if (result.isSuccess) {
  ///   // Open result.data in browser
  ///   launchUrl(Uri.parse(result.data!));
  /// }
  /// ```
  Future<GoogleCalendarResult<String>> getAuthUrl(String authToken) async {
    try {
      final url = Uri.parse('$_baseUrl/google-calendar/auth-url');
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final authUrl = data['authUrl'] as String;
        return GoogleCalendarResult.success(authUrl);
      } else if (response.statusCode == 401) {
        return const GoogleCalendarResult.error(
          'Non authentifié. Veuillez vous reconnecter.',
        );
      } else {
        return GoogleCalendarResult.error(
          'Erreur lors de la récupération de l\'URL d\'autorisation (${response.statusCode})',
        );
      }
    } catch (e) {
      return GoogleCalendarResult.error(
        'Erreur de connexion: ${e.toString()}',
      );
    }
  }

  /// Exchange authorization code for tokens
  /// 
  /// This is typically called from the OAuth callback.
  /// 
  /// Parameters:
  /// - [code]: Authorization code from Google OAuth callback
  /// - [authToken]: JWT token for authentication
  Future<GoogleCalendarResult<GoogleCalendarTokens>> exchangeCode(
    String code,
    String authToken,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/google-calendar/callback?code=$code');
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tokens = GoogleCalendarTokens.fromJson(data);
        return GoogleCalendarResult.success(tokens);
      } else if (response.statusCode == 401) {
        return const GoogleCalendarResult.error(
          'Non authentifié. Veuillez vous reconnecter.',
        );
      } else {
        return GoogleCalendarResult.error(
          'Erreur lors de l\'échange du code (${response.statusCode})',
        );
      }
    } catch (e) {
      return GoogleCalendarResult.error(
        'Erreur de connexion: ${e.toString()}',
      );
    }
  }

  /// Synchronize a single calendar entry with Google Calendar
  /// 
  /// Parameters:
  /// - [calendarEntryId]: ID of the calendar entry to sync
  /// - [tokens]: Google Calendar OAuth tokens
  /// - [authToken]: JWT token for authentication
  /// 
  /// Example:
  /// ```dart
  /// final result = await service.syncEntry(
  ///   entryId,
  ///   googleTokens,
  ///   userToken,
  /// );
  /// 
  /// if (result.isSuccess) {
  ///   print('Entry synchronized successfully');
  /// }
  /// ```
  Future<GoogleCalendarResult<void>> syncEntry({
    required String calendarEntryId,
    required GoogleCalendarTokens tokens,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/google-calendar/sync-entry');
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'calendarEntryId': calendarEntryId,
          'accessToken': tokens.accessToken,
          if (tokens.refreshToken != null)
            'refreshToken': tokens.refreshToken,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const GoogleCalendarResult.success(null);
      } else if (response.statusCode == 401) {
        return const GoogleCalendarResult.error(
          'Non authentifié. Veuillez vous reconnecter.',
        );
      } else if (response.statusCode == 403) {
        return const GoogleCalendarResult.error(
          'Accès refusé. Veuillez reconnecter votre compte Google Calendar.',
        );
      } else {
        final errorData = _tryParseError(response.body);
        return GoogleCalendarResult.error(
          errorData ?? 'Erreur lors de la synchronisation (${response.statusCode})',
        );
      }
    } catch (e) {
      return GoogleCalendarResult.error(
        'Erreur de connexion: ${e.toString()}',
      );
    }
  }

  /// Synchronize an entire plan with Google Calendar
  /// 
  /// This will sync all calendar entries associated with the plan.
  /// 
  /// Parameters:
  /// - [planId]: ID of the plan to sync
  /// - [tokens]: Google Calendar OAuth tokens
  /// - [authToken]: JWT token for authentication
  /// 
  /// Example:
  /// ```dart
  /// final result = await service.syncPlan(
  ///   planId,
  ///   googleTokens,
  ///   userToken,
  /// );
  /// 
  /// if (result.isSuccess) {
  ///   final syncResult = result.data!;
  ///   print('Synced ${syncResult.synced}/${syncResult.total} entries');
  /// }
  /// ```
  Future<GoogleCalendarResult<SyncResult>> syncPlan({
    required String planId,
    required GoogleCalendarTokens tokens,
    required String authToken,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/google-calendar/sync-plan');
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'planId': planId,
          'accessToken': tokens.accessToken,
          if (tokens.refreshToken != null)
            'refreshToken': tokens.refreshToken,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final syncResult = SyncResult.fromJson(data);
        return GoogleCalendarResult.success(syncResult);
      } else if (response.statusCode == 401) {
        return const GoogleCalendarResult.error(
          'Non authentifié. Veuillez vous reconnecter.',
        );
      } else if (response.statusCode == 403) {
        return const GoogleCalendarResult.error(
          'Accès refusé. Veuillez reconnecter votre compte Google Calendar.',
        );
      } else {
        final errorData = _tryParseError(response.body);
        return GoogleCalendarResult.error(
          errorData ?? 'Erreur lors de la synchronisation du plan (${response.statusCode})',
        );
      }
    } catch (e) {
      return GoogleCalendarResult.error(
        'Erreur de connexion: ${e.toString()}',
      );
    }
  }

  /// Try to parse error message from response body
  String? _tryParseError(String body) {
    try {
      final data = json.decode(body) as Map<String, dynamic>;
      return data['error'] as String? ?? data['message'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
