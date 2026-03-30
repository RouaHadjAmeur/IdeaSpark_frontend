import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart';

class CollaborationService {
  final AuthService _authService = AuthService();

  Map<String, String> get _headers {
    final token = _authService.accessToken;
    if (token == null) throw Exception('Not authenticated — please log in again');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Extracts a human-readable message from the backend error response body.
  String _parseError(http.Response res, String fallback) {
    try {
      final body = jsonDecode(res.body);
      final msg = body['message'];
      if (msg is String) return msg;
      if (msg is List) return msg.join(', ');
    } catch (_) {}
    return '$fallback (HTTP ${res.statusCode})';
  }

  Future<List<AppUser>> searchUsers(String query) async {
    final res = await http.get(
      Uri.parse(ApiConfig.searchUsersUrl(query)),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(_parseError(res, 'Failed to search users'));
    final List data = jsonDecode(res.body);
    return data.map((item) => AppUser.fromJson(item)).toList();
  }

  Future<void> inviteCollaborator(String planId, String inviteeId, {String role = 'collaborator'}) async {
    final res = await http.post(
      Uri.parse(ApiConfig.inviteUrl),
      headers: _headers,
      body: jsonEncode({
        'planId': planId,
        'inviteeId': inviteeId,
        'role': role,
      }),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(_parseError(res, 'Failed to send invitation'));
    }
  }

  Future<List<dynamic>> getCollaborators(String planId) async {
    final res = await http.get(
      Uri.parse(ApiConfig.listCollaboratorsUrl(planId)),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(_parseError(res, 'Failed to get collaborators'));
    return jsonDecode(res.body);
  }

  Future<void> removeCollaborator(String planId, String userId) async {
    final res = await http.delete(
      Uri.parse(ApiConfig.removeCollaboratorUrl(planId, userId)),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(_parseError(res, 'Failed to remove collaborator'));
  }

  Future<List<dynamic>> getActivityLog(String planId) async {
    final res = await http.get(
      Uri.parse(ApiConfig.getActivityLogUrl(planId)),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(_parseError(res, 'Failed to get activity log'));
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getNotifications() async {
    final res = await http.get(
      Uri.parse(ApiConfig.notificationsUrl),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(_parseError(res, 'Failed to get notifications'));
    return jsonDecode(res.body);
  }

  Future<void> acceptInvitation(String invitationId) async {
    final res = await http.post(
      Uri.parse(ApiConfig.acceptInviteUrl(invitationId)),
      headers: _headers,
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(_parseError(res, 'Failed to accept invitation'));
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    final res = await http.post(
      Uri.parse(ApiConfig.declineInviteUrl(invitationId)),
      headers: _headers,
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(_parseError(res, 'Failed to decline invitation'));
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    final res = await http.patch(
      Uri.parse(ApiConfig.markNotificationReadUrl(notificationId)),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(_parseError(res, 'Failed to mark notification as read'));
  }

  Future<List<dynamic>> getSharedPlans(String targetId) async {
    final res = await http.get(
      Uri.parse(ApiConfig.sharedPlansUrl(targetId)),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception(_parseError(res, 'Failed to fetch shared plans'));
    return jsonDecode(res.body);
  }
}
