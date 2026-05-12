// activity_log.dart
// Model for tracking all activities in campaigns

enum ActivityAction {
  created,
  updated,
  deleted,
  assigned,
  accepted,
  declined,
  submitted,
  approved,
  rejected,
  commented,
  published,
  scheduled,
  changedStatus,
  addedNote,
  seenNote,
}

enum ActivityEntityType {
  campaign,
  phase,
  contentBlock,
  assignment,
  submission,
  note,
  collaborator,
}

extension ActivityActionExt on ActivityAction {
  String get label {
    switch (this) {
      case ActivityAction.created:
        return 'Created';
      case ActivityAction.updated:
        return 'Updated';
      case ActivityAction.deleted:
        return 'Deleted';
      case ActivityAction.assigned:
        return 'Assigned';
      case ActivityAction.accepted:
        return 'Accepted';
      case ActivityAction.declined:
        return 'Declined';
      case ActivityAction.submitted:
        return 'Submitted';
      case ActivityAction.approved:
        return 'Approved';
      case ActivityAction.rejected:
        return 'Rejected';
      case ActivityAction.commented:
        return 'Commented';
      case ActivityAction.published:
        return 'Published';
      case ActivityAction.scheduled:
        return 'Scheduled';
      case ActivityAction.changedStatus:
        return 'Changed Status';
      case ActivityAction.addedNote:
        return 'Added Note';
      case ActivityAction.seenNote:
        return 'Seen Note';
    }
  }

  String get toJson {
    switch (this) {
      case ActivityAction.created:
        return 'created';
      case ActivityAction.updated:
        return 'updated';
      case ActivityAction.deleted:
        return 'deleted';
      case ActivityAction.assigned:
        return 'assigned';
      case ActivityAction.accepted:
        return 'accepted';
      case ActivityAction.declined:
        return 'declined';
      case ActivityAction.submitted:
        return 'submitted';
      case ActivityAction.approved:
        return 'approved';
      case ActivityAction.rejected:
        return 'rejected';
      case ActivityAction.commented:
        return 'commented';
      case ActivityAction.published:
        return 'published';
      case ActivityAction.scheduled:
        return 'scheduled';
      case ActivityAction.changedStatus:
        return 'changed_status';
      case ActivityAction.addedNote:
        return 'added_note';
      case ActivityAction.seenNote:
        return 'seen_note';
    }
  }

  static ActivityAction fromString(String value) {
    switch (value) {
      case 'created':
        return ActivityAction.created;
      case 'updated':
        return ActivityAction.updated;
      case 'deleted':
        return ActivityAction.deleted;
      case 'assigned':
        return ActivityAction.assigned;
      case 'accepted':
        return ActivityAction.accepted;
      case 'declined':
        return ActivityAction.declined;
      case 'submitted':
        return ActivityAction.submitted;
      case 'approved':
        return ActivityAction.approved;
      case 'rejected':
        return ActivityAction.rejected;
      case 'commented':
        return ActivityAction.commented;
      case 'published':
        return ActivityAction.published;
      case 'scheduled':
        return ActivityAction.scheduled;
      case 'changed_status':
        return ActivityAction.changedStatus;
      case 'added_note':
        return ActivityAction.addedNote;
      case 'seen_note':
        return ActivityAction.seenNote;
      default:
        return ActivityAction.updated;
    }
  }
}

extension ActivityEntityTypeExt on ActivityEntityType {
  String get label {
    switch (this) {
      case ActivityEntityType.campaign:
        return 'Campaign';
      case ActivityEntityType.phase:
        return 'Phase';
      case ActivityEntityType.contentBlock:
        return 'Content Block';
      case ActivityEntityType.assignment:
        return 'Assignment';
      case ActivityEntityType.submission:
        return 'Submission';
      case ActivityEntityType.note:
        return 'Note';
      case ActivityEntityType.collaborator:
        return 'Collaborator';
    }
  }

  String get toJson {
    switch (this) {
      case ActivityEntityType.campaign:
        return 'campaign';
      case ActivityEntityType.phase:
        return 'phase';
      case ActivityEntityType.contentBlock:
        return 'content_block';
      case ActivityEntityType.assignment:
        return 'assignment';
      case ActivityEntityType.submission:
        return 'submission';
      case ActivityEntityType.note:
        return 'note';
      case ActivityEntityType.collaborator:
        return 'collaborator';
    }
  }

  static ActivityEntityType fromString(String value) {
    switch (value) {
      case 'campaign':
        return ActivityEntityType.campaign;
      case 'phase':
        return ActivityEntityType.phase;
      case 'content_block':
        return ActivityEntityType.contentBlock;
      case 'assignment':
        return ActivityEntityType.assignment;
      case 'submission':
        return ActivityEntityType.submission;
      case 'note':
        return ActivityEntityType.note;
      case 'collaborator':
        return ActivityEntityType.collaborator;
      default:
        return ActivityEntityType.campaign;
    }
  }
}

class ActivityLog {
  final String? id;
  final String userId;
  final String? userName;
  final String? userAvatar;
  final String campaignId;
  final ActivityEntityType entityType;
  final String entityId;
  final ActivityAction action;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  ActivityLog({
    this.id,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.campaignId,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      campaignId: json['campaignId'] ?? '',
      entityType: ActivityEntityTypeExt.fromString(json['entityType'] ?? 'campaign'),
      entityId: json['entityId'] ?? '',
      action: ActivityActionExt.fromString(json['action'] ?? 'updated'),
      description: json['description'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'campaignId': campaignId,
        'entityType': entityType.toJson,
        'entityId': entityId,
        'action': action.toJson,
        'description': description,
        'metadata': metadata,
        'createdAt': createdAt.toIso8601String(),
      };
}
