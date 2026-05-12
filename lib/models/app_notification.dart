// app_notification.dart
// Model for in-app notifications

enum NotificationType {
  assignmentCreated,
  assignmentAccepted,
  assignmentDeclined,
  submissionCreated,
  submissionApproved,
  submissionRejected,
  changesRequested,
  noteAdded,
  noteSeen,
  deadlineReminder,
  taskLate,
  collaboratorInvited,
  collaboratorAccepted,
  collaboratorDeclined,
}

extension NotificationTypeExt on NotificationType {
  String get label {
    switch (this) {
      case NotificationType.assignmentCreated:
        return 'New Assignment';
      case NotificationType.assignmentAccepted:
        return 'Assignment Accepted';
      case NotificationType.assignmentDeclined:
        return 'Assignment Declined';
      case NotificationType.submissionCreated:
        return 'New Submission';
      case NotificationType.submissionApproved:
        return 'Submission Approved';
      case NotificationType.submissionRejected:
        return 'Submission Rejected';
      case NotificationType.changesRequested:
        return 'Changes Requested';
      case NotificationType.noteAdded:
        return 'New Note';
      case NotificationType.noteSeen:
        return 'Note Seen';
      case NotificationType.deadlineReminder:
        return 'Deadline Reminder';
      case NotificationType.taskLate:
        return 'Task Late';
      case NotificationType.collaboratorInvited:
        return 'Collaborator Invited';
      case NotificationType.collaboratorAccepted:
        return 'Collaborator Accepted';
      case NotificationType.collaboratorDeclined:
        return 'Collaborator Declined';
    }
  }

  String get toJson {
    switch (this) {
      case NotificationType.assignmentCreated:
        return 'assignment_created';
      case NotificationType.assignmentAccepted:
        return 'assignment_accepted';
      case NotificationType.assignmentDeclined:
        return 'assignment_declined';
      case NotificationType.submissionCreated:
        return 'submission_created';
      case NotificationType.submissionApproved:
        return 'submission_approved';
      case NotificationType.submissionRejected:
        return 'submission_rejected';
      case NotificationType.changesRequested:
        return 'changes_requested';
      case NotificationType.noteAdded:
        return 'note_added';
      case NotificationType.noteSeen:
        return 'note_seen';
      case NotificationType.deadlineReminder:
        return 'deadline_reminder';
      case NotificationType.taskLate:
        return 'task_late';
      case NotificationType.collaboratorInvited:
        return 'collaborator_invited';
      case NotificationType.collaboratorAccepted:
        return 'collaborator_accepted';
      case NotificationType.collaboratorDeclined:
        return 'collaborator_declined';
    }
  }

  static NotificationType fromString(String value) {
    switch (value) {
      case 'assignment_created':
        return NotificationType.assignmentCreated;
      case 'assignment_accepted':
        return NotificationType.assignmentAccepted;
      case 'assignment_declined':
        return NotificationType.assignmentDeclined;
      case 'submission_created':
        return NotificationType.submissionCreated;
      case 'submission_approved':
        return NotificationType.submissionApproved;
      case 'submission_rejected':
        return NotificationType.submissionRejected;
      case 'changes_requested':
        return NotificationType.changesRequested;
      case 'note_added':
        return NotificationType.noteAdded;
      case 'note_seen':
        return NotificationType.noteSeen;
      case 'deadline_reminder':
        return NotificationType.deadlineReminder;
      case 'task_late':
        return NotificationType.taskLate;
      case 'collaborator_invited':
        return NotificationType.collaboratorInvited;
      case 'collaborator_accepted':
        return NotificationType.collaboratorAccepted;
      case 'collaborator_declined':
        return NotificationType.collaboratorDeclined;
      default:
        return NotificationType.assignmentCreated;
    }
  }
}

class AppNotification {
  final String? id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  AppNotification({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  bool get isUnread => !isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      type: NotificationTypeExt.fromString(json['type'] ?? 'assignment_created'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      relatedEntityType: json['relatedEntityType'],
      relatedEntityId: json['relatedEntityId'],
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      readAt: json['readAt'] != null ? DateTime.tryParse(json['readAt']) : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'type': type.toJson,
        'title': title,
        'message': message,
        'relatedEntityType': relatedEntityType,
        'relatedEntityId': relatedEntityId,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'data': data,
      };

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedEntityType,
    String? relatedEntityId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }
}
