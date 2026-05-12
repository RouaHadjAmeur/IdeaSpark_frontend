// app_notification_view_model.dart
// ViewModel for managing in-app notifications

import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/app_notification_service.dart';

class AppNotificationViewModel extends ChangeNotifier {
  final _service = AppNotificationService();

  List<AppNotification> _notifications = [];
  List<AppNotification> _unreadNotifications = [];
  int _unreadCount = 0;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<AppNotification> get notifications => _notifications;
  List<AppNotification> get unreadNotifications => _unreadNotifications;
  int get unreadCount => _unreadCount;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  bool get hasUnread => _unreadCount > 0;

  // ─── Load Notifications ───────────────────────────────────────────────────

  Future<void> loadNotifications({int limit = 50, int offset = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications(limit: limit, offset: offset);
      _unreadNotifications = _notifications.where((n) => n.isUnread).toList();
      _unreadCount = _unreadNotifications.length;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _unreadNotifications = await _service.getUnreadNotifications();
      _unreadCount = _unreadNotifications.length;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ─── Mark Notification as Read ────────────────────────────────────────────

  Future<bool> markAsRead(String notificationId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.markAsRead(notificationId);
      
      // Update in lists
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updated;
      }
      
      final index2 = _unreadNotifications.indexWhere((n) => n.id == notificationId);
      if (index2 != -1) {
        _unreadNotifications.removeAt(index2);
        _unreadCount = _unreadNotifications.length;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  Future<bool> markAllAsRead() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.markAllAsRead();
      
      // Update all notifications
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
      
      _unreadNotifications.clear();
      _unreadCount = 0;

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Delete Notification ──────────────────────────────────────────────────

  Future<bool> deleteNotification(String notificationId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteNotification(notificationId);
      
      _notifications.removeWhere((n) => n.id == notificationId);
      _unreadNotifications.removeWhere((n) => n.id == notificationId);
      _unreadCount = _unreadNotifications.length;

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  Future<bool> deleteAllNotifications() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteAllNotifications();
      
      _notifications.clear();
      _unreadNotifications.clear();
      _unreadCount = 0;

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Clear Error ──────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
