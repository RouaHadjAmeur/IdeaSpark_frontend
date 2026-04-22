import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';
import '../models/task.dart';
import '../models/deliverable.dart';
import '../models/collaboration.dart';
import '../models/brand_collaborator.dart';
import 'auth_service.dart';

class CollaborationService {
  static final CollaborationService _instance = CollaborationService._();
  factory CollaborationService() => _instance;
  CollaborationService._();

  Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── Tasks (Remote API) ──────────────────────────────────────────────────

  Future<List<Task>> getTasks(String planId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.listTasksUrl(planId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Task.fromJson(e)).toList();
    }
    throw Exception('Failed to load tasks');
  }

  Future<Task> createTask(String planId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.createTaskUrl(planId)),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create task');
  }

  Future<Task> updateTask(String taskId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.updateTaskUrl(taskId)),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update task');
  }

  // ── Deliverables (Remote API) ──────────────────────────────────────────────

  Future<Deliverable> submitDeliverable(String taskId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.submitDeliverableUrl(taskId)),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Deliverable.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to submit deliverable');
  }

  Future<Deliverable> reviewDeliverable(String deliverableId, String status, {String? feedback}) async {
    final token = await _getToken();
    final body = <String, dynamic>{'status': status};
    if (feedback != null) body['feedback'] = feedback;
    
    final response = await http.patch(
      Uri.parse(ApiConfig.reviewDeliverableUrl(deliverableId)),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return Deliverable.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to review deliverable');
  }

  // ── Activity Log / History (Remote API) ───────────────────────────────────

  Future<List<dynamic>> getActivityLog(String planId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.getActivityLogUrl(planId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load activity log');
  }

  // ── Member Search (Remote API) ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.searchUsersUrl(Uri.encodeComponent(query.trim()))),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ── Invitations (Remote API) ───────────────────────────────────────────────

  /// Invite a user by their backend user ID.
  Future<void> inviteByUserId(String planId, String inviteeId, {String role = 'editor'}) async {
    debugPrint('[CollaborationService] Inviting $inviteeId to plan $planId with role $role');
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.inviteUrl),
      headers: _headers(token),
      body: jsonEncode({'planId': planId, 'inviteeId': inviteeId, 'role': role}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      debugPrint('[CollaborationService] Invite failed: ${response.statusCode} ${response.body}');
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to send invitation');
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.acceptInviteUrl(invitationId)),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to accept invitation (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) msg = body['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.declineInviteUrl(invitationId)),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Failed to decline invitation (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body['message'] != null) msg = body['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ── Members/Collaborators (Remote API) ────────────────────────────────────

  Future<List<CollabMember>> getMembers(String planId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.listCollaboratorsUrl(planId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => CollabMember.fromJson(_flattenCollaborator(e))).toList();
    }
    return [];
  }

  /// Flatten populated collaborator doc from backend into CollabMember-compatible map.
  Map<String, dynamic> _flattenCollaborator(Map<String, dynamic> e) {
    final user = e['userId'] is Map ? e['userId'] as Map<String, dynamic> : <String, dynamic>{};
    return {
      'id': (user['_id'] ?? user['id'] ?? e['userId'] ?? '').toString(),
      'email': user['email']?.toString() ?? '',
      'name': (user['username'] ?? user['name'] ?? user['email'] ?? 'Unknown').toString(),
      'role': e['role']?.toString() ?? 'editor',
      'status': 'accepted',
      'invitedAt': (e['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
    };
  }

  Future<void> updateRole(String planId, String memberId, CollabRole role) async {
    // Role update via remove + re-invite is not yet in backend controller.
    // Store locally as a workaround until backend supports PATCH collaborator role.
    final prefs = await SharedPreferences.getInstance();
    final key = 'collab_role_override_${planId}_$memberId';
    await prefs.setString(key, role.name);
  }

  Future<void> removeMember(String planId, String memberId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiConfig.removeCollaboratorUrl(planId, memberId)),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove collaborator');
    }
  }

  // ── Notifications (Remote API) ────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.notificationsUrl),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> markNotificationRead(String notificationId) async {
    final token = await _getToken();
    await http.patch(
      Uri.parse(ApiConfig.markNotificationReadUrl(notificationId)),
      headers: _headers(token),
    );
  }


  // ── Comments (Remote API) ────────────────────────────────────────────────

  Future<List<PostComment>> getComments(String postId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.getCommentsUrl(postId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => PostComment.fromJson(e)).toList();
    }
    throw Exception('Failed to load comments');
  }

  Future<void> addComment(PostComment comment) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.addCommentUrl),
      headers: _headers(token),
      body: jsonEncode(comment.toJson()),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add comment');
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final token = await _getToken();
    // Assuming backend has a delete endpoint like /collaboration/comments/:commentId
    final response = await http.delete(
      Uri.parse('${ApiConfig.addCommentUrl}/$commentId'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete comment');
    }
  }

  Future<List<String>> getCommentedPostIds(String planId) async {
    // Note: Temporarily returning an empty list to resolve compilation error.
    // This requires a backend endpoint to fetch all commented post IDs for a given plan.
    return [];
  }


  // ── Restored History (Local Storage for Compatibility) ────────────────────

  Future<List<HistoryEntry>> getHistory(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('history_$planId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return (list.map((e) => HistoryEntry.fromJson(e)).toList())
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> addHistory(String planId, HistoryEntry entry) async {
    final history = await getHistory(planId);
    history.insert(0, entry);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_$planId',
        jsonEncode(history.map((h) => h.toJson()).toList()));
  }

  // ── Brand Collaboration ───────────────────────────────────────────────────

  Future<BrandCollaborator> inviteToBrand(String brandId, String inviteeId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse(ApiConfig.inviteBrandCollaboratorUrl(brandId)),
      headers: _headers(token),
      body: jsonEncode({'inviteeId': inviteeId}),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return BrandCollaborator.fromJson(jsonDecode(res.body));
    }
    final body = jsonDecode(res.body);
    throw Exception(body['message'] ?? 'Failed to invite collaborator');
  }

  Future<List<BrandCollaborator>> getBrandCollaborators(String brandId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse(ApiConfig.listBrandCollaboratorsUrl(brandId)),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => BrandCollaborator.fromJson(e)).toList();
    }
    throw Exception('Failed to load brand collaborators');
  }

  Future<void> removeBrandCollaborator(String brandId, String userId) async {
    final token = await _getToken();
    final res = await http.delete(
      Uri.parse(ApiConfig.removeBrandCollaboratorUrl(brandId, userId)),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to remove collaborator');
    }
  }

  Future<BrandCollaborator> acceptBrandInvitation(String invitationId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse(ApiConfig.acceptBrandInviteUrl(invitationId)),
      headers: _headers(token),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return BrandCollaborator.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to accept invitation');
  }

  Future<void> declineBrandInvitation(String invitationId) async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse(ApiConfig.declineBrandInviteUrl(invitationId)),
      headers: _headers(token),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to decline invitation');
    }
  }

  Future<List<BrandCollaborator>> getMyPendingBrandInvitations() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse(ApiConfig.myPendingBrandInvitationsUrl),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => BrandCollaborator.fromJson(e)).toList();
    }
    return [];
  }
}