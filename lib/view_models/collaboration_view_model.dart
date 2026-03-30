import 'package:flutter/foundation.dart';
import '../services/collaboration_service.dart';
import '../services/auth_service.dart';

class CollaborationViewModel extends ChangeNotifier {
  final CollaborationService _service = CollaborationService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<AppUser> _searchResults = [];
  List<AppUser> get searchResults => _searchResults;
  
  List<dynamic> _collaborators = [];
  List<dynamic> get collaborators => _collaborators;
  
  List<dynamic> _activityLog = [];
  List<dynamic> get activityLog => _activityLog;
  
  List<dynamic> _notifications = [];
  List<dynamic> get notifications => _notifications;
  
  int get unreadNotificationsCount => _notifications.where((n) => n['read'] == false).length;

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      _searchResults = await _service.searchUsers(query);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> inviteCollaborator(String planId, String inviteeId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.inviteCollaborator(planId, inviteeId);
      // Refresh collaborators if needed, though they're only confirmed after acceptance
    } catch (e) {
      debugPrint('Invite error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCollaborators(String planId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _collaborators = await _service.getCollaborators(planId);
    } catch (e) {
      debugPrint('Load collaborators error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeCollaborator(String planId, String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.removeCollaborator(planId, userId);
      _collaborators.removeWhere((c) => (c['userId']['_id'] ?? c['userId']['id']) == userId);
    } catch (e) {
      debugPrint('Remove collaborator error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadActivityLog(String planId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _activityLog = await _service.getActivityLog(planId);
    } catch (e) {
      debugPrint('Load activity log error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final allNotifications = await _service.getNotifications();
      
      // De-duplicate follow_request notifications by relatedUserId
      final Map<String, dynamic> uniqueFollowRequests = {};
      final List<dynamic> otherNotifications = [];
      
      for (var n in allNotifications) {
        if (n['type'] == 'follow_request' && n['relatedUserId'] != null) {
          final userId = n['relatedUserId']['_id'] ?? n['relatedUserId']['id'];
          if (!uniqueFollowRequests.containsKey(userId)) {
            uniqueFollowRequests[userId] = n;
          }
        } else {
          otherNotifications.add(n);
        }
      }
      
      _notifications = [...uniqueFollowRequests.values, ...otherNotifications];
      // Sort by date descending
      _notifications.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
    } catch (e) {
      debugPrint('Load notifications error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.acceptInvitation(invitationId);
      await loadNotifications();
    } catch (e) {
      debugPrint('Accept error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.declineInvitation(invitationId);
      await loadNotifications();
    } catch (e) {
      debugPrint('Decline error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _service.markNotificationRead(notificationId);
      final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
      if (index != -1) {
        _notifications[index]['read'] = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark read error: $e');
    }
  }
}
