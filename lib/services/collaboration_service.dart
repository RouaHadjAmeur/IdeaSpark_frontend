import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collaboration.dart';

class CollaborationService {
  static final CollaborationService _instance = CollaborationService._();
  factory CollaborationService() => _instance;
  CollaborationService._();

  // ── Members ──────────────────────────────────────────────────────────────

  Future<List<CollabMember>> getMembers(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('collab_members_$planId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => CollabMember.fromJson(e)).toList();
  }

  Future<void> inviteMember(String planId, CollabMember member) async {
    final members = await getMembers(planId);
    if (members.any((m) => m.email == member.email)) return;
    members.add(member);
    await _saveMembers(planId, members);
    await addHistory(planId, HistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      planId: planId,
      authorName: 'Vous',
      action: 'invitation',
      description: '${member.email} invité comme ${member.roleLabel}',
      createdAt: DateTime.now(),
    ));
  }

  Future<void> updateRole(String planId, String memberId, CollabRole role) async {
    final members = await getMembers(planId);
    final idx = members.indexWhere((m) => m.id == memberId);
    if (idx < 0) return;
    final old = members[idx];
    members[idx] = CollabMember(
      id: old.id, email: old.email, name: old.name,
      role: role, status: old.status, invitedAt: old.invitedAt,
    );
    await _saveMembers(planId, members);
  }

  Future<void> removeMember(String planId, String memberId) async {
    final members = await getMembers(planId);
    members.removeWhere((m) => m.id == memberId);
    await _saveMembers(planId, members);
  }

  Future<void> _saveMembers(String planId, List<CollabMember> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('collab_members_$planId',
        jsonEncode(members.map((m) => m.toJson()).toList()));
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<List<PostComment>> getComments(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('comments_$postId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => PostComment.fromJson(e)).toList();
  }

  Future<void> addComment(PostComment comment) async {
    final comments = await getComments(comment.postId);
    comments.add(comment);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comments_${comment.postId}',
        jsonEncode(comments.map((c) => c.toJson()).toList()));

    // Also save in plan-level index for the collaboration tab
    final planKey = 'plan_comment_ids_${comment.planId}';
    final existing = prefs.getStringList(planKey) ?? [];
    if (!existing.contains(comment.postId)) {
      existing.add(comment.postId);
      await prefs.setStringList(planKey, existing);
    }
  }

  Future<List<String>> getCommentedPostIds(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('plan_comment_ids_$planId') ?? [];
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final comments = await getComments(postId);
    comments.removeWhere((c) => c.id == commentId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('comments_$postId',
        jsonEncode(comments.map((c) => c.toJson()).toList()));
  }

  // ── History ───────────────────────────────────────────────────────────────

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

  // ── Stub methods for collaboration_view_model compatibility ──────────────

  Future<List<dynamic>> searchUsers(String query) async => [];

  Future<void> inviteCollaborator(String planId, String inviteeId) async {}

  Future<List<dynamic>> getCollaborators(String planId) async => [];

  Future<void> removeCollaborator(String planId, String userId) async {}

  Future<List<dynamic>> getActivityLog(String planId) async => [];

  Future<List<dynamic>> getNotifications() async => [];

  Future<void> acceptInvitation(String invitationId) async {}

  Future<void> declineInvitation(String invitationId) async {}

  Future<void> markNotificationRead(String notificationId) async {}

  Future<List<dynamic>> getSharedPlans(String targetId) async => [];
}
