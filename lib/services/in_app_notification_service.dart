import 'package:flutter/foundation.dart';

class AppNotification {
  final int id;
  final String title;
  final String body;
  final DateTime time;
  final String type;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class InAppNotificationService extends ChangeNotifier {
  static final InAppNotificationService _instance =
      InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  final List<AppNotification> _notifications = [];

  List<AppNotification> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void add(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markRead(int id) {
    final n = _notifications.firstWhere((n) => n.id == id,
        orElse: () => _notifications.first);
    n.isRead = true;
    notifyListeners();
  }

  void clear() {
    _notifications.clear();
    notifyListeners();
  }
}
