import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/google_calendar_tokens.dart';

/// Service for storing and retrieving Google Calendar tokens locally
/// 
/// This service uses SharedPreferences to persist OAuth tokens
/// so users don't have to reconnect every time they open the app.
class GoogleCalendarStorageService {
  static const String _tokensKey = 'google_calendar_tokens';

  /// Save Google Calendar tokens to local storage
  /// 
  /// Example:
  /// ```dart
  /// await GoogleCalendarStorageService.saveTokens(tokens);
  /// ```
  static Future<bool> saveTokens(GoogleCalendarTokens tokens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(tokens.toJson());
      return await prefs.setString(_tokensKey, jsonString);
    } catch (e) {
      print('Error saving Google Calendar tokens: $e');
      return false;
    }
  }

  /// Retrieve Google Calendar tokens from local storage
  /// 
  /// Returns null if no tokens are stored or if they're invalid.
  /// 
  /// Example:
  /// ```dart
  /// final tokens = await GoogleCalendarStorageService.getTokens();
  /// if (tokens != null && !tokens.isExpired) {
  ///   // Use tokens
  /// }
  /// ```
  static Future<GoogleCalendarTokens?> getTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_tokensKey);
      
      if (jsonString == null) return null;
      
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return GoogleCalendarTokens.fromJson(jsonData);
    } catch (e) {
      print('Error retrieving Google Calendar tokens: $e');
      return null;
    }
  }

  /// Check if Google Calendar is connected (tokens exist and are valid)
  /// 
  /// Example:
  /// ```dart
  /// final isConnected = await GoogleCalendarStorageService.isConnected();
  /// if (isConnected) {
  ///   // Show sync button
  /// } else {
  ///   // Show connect button
  /// }
  /// ```
  static Future<bool> isConnected() async {
    final tokens = await getTokens();
    return tokens != null && !tokens.isExpired;
  }

  /// Clear stored Google Calendar tokens
  /// 
  /// Use this when the user disconnects their Google Calendar
  /// or when tokens are no longer valid.
  /// 
  /// Example:
  /// ```dart
  /// await GoogleCalendarStorageService.clearTokens();
  /// ```
  static Future<bool> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_tokensKey);
    } catch (e) {
      print('Error clearing Google Calendar tokens: $e');
      return false;
    }
  }

  /// Update only the access token (useful after token refresh)
  /// 
  /// Example:
  /// ```dart
  /// await GoogleCalendarStorageService.updateAccessToken(newAccessToken);
  /// ```
  static Future<bool> updateAccessToken(String newAccessToken) async {
    try {
      final tokens = await getTokens();
      if (tokens == null) return false;

      final updatedTokens = tokens.copyWith(
        accessToken: newAccessToken,
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      return await saveTokens(updatedTokens);
    } catch (e) {
      print('Error updating access token: $e');
      return false;
    }
  }
}
