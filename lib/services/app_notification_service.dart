// app_notification_service.dart
// Service for managing in-app notifications

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/app_notification.dart';
import 'auth_service.dart';

class AppNotificationService {
  static final AppNotificationService _instance = AppNotificationService._();
  factory AppNotificationService() => _instance;
  AppNotificationService._();

  Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Get Notifications ────────────────────────────────────────────────────

  Future<List<AppNotification>> getNotifications({int limit = 50, int offset = 0}) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notifications?limit=$limit&offset=$offset';

    debugPrint('[AppNotificationService] GET $url');

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    debugPrint('[AppNotificationService] getNotifications status=${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load notifications: ${response.statusCode}');
  }

  Future<List<AppNotification>> getUnreadNotifications() async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notifications/unread';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load unread notifications: ${response.statusCode}');
  }

  Future<int> getUnreadCount() async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notifications/unread/count';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    }

    throw Exception('Failed to get unread count: ${response.statusCode}');
  }

  // ─── Mark Notification as Read ────────────────────────────────────────────

  Future<AppNotification> markAsRead(String notificationId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notifications/$notificationId/mark-read';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return AppNotification.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to mark notification as read: ${response.statusCode}');
  }

  Future<void> markAllAsRead() async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notifications/mark-all-read';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to mark all notifications as read: ${response.statusCode}');
    }
  }

  // ─── Delete Notification ──────────────────────────────────────────────────

  Future<void> deleteNotification(String notificationId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notifications/$notificationId';

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete notification: ${response.statusCode}');
    }
  }

  Future<void> deleteAllNotifications() async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notifications/delete-all';

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete all notifications: ${response.statusCode}');
    }
  }
}
