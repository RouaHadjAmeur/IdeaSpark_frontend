import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../services/collaboration_service.dart';
import '../services/social_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../models/task.dart';
import '../models/collaboration.dart';
import '../models/brand_collaborator.dart';

class CollaborationViewModel extends ChangeNotifier {
  final CollaborationService _service = CollaborationService();
  final SocketService _socketService = SocketService();
  bool _isSocketInitialized = false;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  final SocialService _socialService = SocialService();
  List<AppUser> _searchResults = [];
  List<AppUser> get searchResults => _searchResults;

  List<Task> _tasks = [];
  List<Task> get tasks => _tasks;

  List<dynamic> _activityLog = [];
  List<dynamic> get activityLog => _activityLog;

  // ── Tasks ──────────────────────────────────────────────────────────────────

  Future<void> loadTasks(String planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _service.getTasks(planId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask(String planId, String title, String description, {String? assignedTo, DateTime? deadline}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createTask(planId, {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        'deadline': deadline?.toIso8601String(),
      });
      await loadTasks(planId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      String statusStr = 'todo';
      if (status == TaskStatus.inProgress) statusStr = 'in_progress';
      if (status == TaskStatus.done) statusStr = 'done';
      
      await _service.updateTask(taskId, {'status': statusStr});
      final idx = _tasks.indexWhere((t) => t.id == taskId);
      if (idx >= 0) {
        _tasks[idx] = await _service.getTasks(_tasks[idx].planId).then((list) => list.firstWhere((t) => t.id == taskId));
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ── Deliverables ───────────────────────────────────────────────────────────

  Future<void> submitDeliverable(String taskId, String contentUrl, {String? comment}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.submitDeliverable(taskId, {
        'contentUrl': contentUrl,
        'comment': comment,
      });
      final task = _tasks.firstWhere((t) => t.id == taskId);
      await loadTasks(task.planId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reviewDeliverable(String deliverableId, String taskId, bool approve, {String? feedback}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final status = approve ? 'approved' : 'rejected';
      await _service.reviewDeliverable(deliverableId, status, feedback: feedback);
      final task = _tasks.firstWhere((t) => t.id == taskId);
      await loadTasks(task.planId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Bridges for other UI (Members, History, Notifications) ─────────────────

  List<CollabMember> _members = [];
  List<CollabMember> get members => _members;

  Future<void> loadMembers(String planId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _members = await _service.getMembers(planId);
    } catch (e) {
      debugPrint('Load members error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActivityLog(String planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activityLog = await _service.getActivityLog(planId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  final Set<String> _handledNotifications = {};
  Set<String> get handledNotifications => _handledNotifications;

  int get unreadNotificationsCount =>
      _notifications.where((n) => n['read'] != true).length;

  Future<void> loadNotifications() async {
    if (!_isSocketInitialized) {
      _initSocket();
    }
    try {
      final fetched = await _service.getNotifications();
      _notifications = fetched;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _initSocket() async {
    if (_isSocketInitialized) return;
    
    final authService = AuthService();
    final token = authService.accessToken;
    
    if (token != null) {
      _socketService.connect(token);
      _socketService.onNotification((notification) {
        // Add new notification to the top of the list
        _notifications.insert(0, notification);
        notifyListeners();
      });
      _isSocketInitialized = true;
    }
  }

  Future<void> acceptInvitation(String invitationId, {String? notificationId}) async {
    if (notificationId != null) _handledNotifications.add(notificationId);
    notifyListeners();
    try {
      await _service.acceptInvitation(invitationId);
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
    }
    await loadNotifications();
  }

  Future<void> declineInvitation(String invitationId, {String? notificationId}) async {
    if (notificationId != null) _handledNotifications.add(notificationId);
    notifyListeners();
    try {
      await _service.declineInvitation(invitationId);
    } catch (e) {
      debugPrint('Error declining invitation: $e');
    }
    await loadNotifications();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _service.markNotificationRead(notificationId);
    // Optimistic update
    final idx = _notifications.indexWhere((n) => n['_id'] == notificationId || n['id'] == notificationId);
    if (idx != -1) {
      final updated = Map<String, dynamic>.from(_notifications[idx]);
      updated['read'] = true;
      _notifications[idx] = updated;
      notifyListeners();
    }
  }
  
  void markNotificationHandled(String notificationId) {
    _handledNotifications.add(notificationId);
    notifyListeners();
  }

  // Other Bridges
  List<dynamic> get collaborators => _members.map((m) => {
    'userId': {
      '_id': m.id,
      'id': m.id,
      'name': m.name,
      'email': m.email,
      'profile_img': null,
    },
    'role': m.role.name,
    'status': m.status.name,
  }).toList();

  Future<void> loadCollaborators(String planId) => loadMembers(planId);
  Future<void> removeCollaborator(String planId, String userId) async {
    await _service.removeMember(planId, userId);
    await loadMembers(planId);
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    try {
      _searchResults = await _socialService.searchUsers(query);
    } catch (e) {
      debugPrint('Search error: $e');
    }
    notifyListeners();
  }

  Future<void> inviteCollaborator(String planId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.inviteByUserId(planId, userId, role: 'editor');
      await loadMembers(planId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Brand Collaboration ───────────────────────────────────────────────────

  List<BrandCollaborator> _brandCollaborators = [];
  List<BrandCollaborator> get brandCollaborators => _brandCollaborators;

  List<BrandCollaborator> _pendingBrandInvitations = [];
  List<BrandCollaborator> get pendingBrandInvitations => _pendingBrandInvitations;

  Future<void> loadBrandCollaborators(String brandId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _brandCollaborators = await _service.getBrandCollaborators(brandId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> inviteToBrand(String brandId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.inviteToBrand(brandId, userId);
      await loadBrandCollaborators(brandId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeBrandCollaborator(String brandId, String userId) async {
    try {
      await _service.removeBrandCollaborator(brandId, userId);
      _brandCollaborators.removeWhere((c) => c.userId == userId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadPendingBrandInvitations() async {
    try {
      _pendingBrandInvitations = await _service.getMyPendingBrandInvitations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> acceptBrandInvitation(String invitationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.acceptBrandInvitation(invitationId);
      _pendingBrandInvitations.removeWhere((i) => i.id == invitationId);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> declineBrandInvitation(String invitationId) async {
    try {
      await _service.declineBrandInvitation(invitationId);
      _pendingBrandInvitations.removeWhere((i) => i.id == invitationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
