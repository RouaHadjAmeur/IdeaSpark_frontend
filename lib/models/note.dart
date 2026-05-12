// note.dart
// Model for notes/feedback from Brand Owner to Collaborator

enum NoteStatus {
  unread,
  seen,
}

enum NoteTarget {
  campaign,
  phase,
  contentBlock,
  submission,
  assignment,
  plan,
}

extension NoteStatusExt on NoteStatus {
  String get label {
    switch (this) {
      case NoteStatus.unread:
        return 'Unread';
      case NoteStatus.seen:
        return 'Seen';
    }
  }

  String get toJson {
    switch (this) {
      case NoteStatus.unread:
        return 'unread';
      case NoteStatus.seen:
        return 'seen';
    }
  }

  static NoteStatus fromString(String value) {
    switch (value) {
      case 'seen':
        return NoteStatus.seen;
      case 'unread':
      default:
        return NoteStatus.unread;
    }
  }
}

extension NoteTargetExt on NoteTarget {
  String get label {
    switch (this) {
      case NoteTarget.campaign:
        return 'Campaign';
      case NoteTarget.phase:
        return 'Phase';
      case NoteTarget.contentBlock:
        return 'Content Block';
      case NoteTarget.submission:
        return 'Submission';
      case NoteTarget.assignment:
        return 'Assignment';
      case NoteTarget.plan:
        return 'Plan';
    }
  }

  String get toJson {
    switch (this) {
      case NoteTarget.campaign:
        return 'campaign';
      case NoteTarget.phase:
        return 'phase';
      case NoteTarget.contentBlock:
        return 'content_block';
      case NoteTarget.submission:
        return 'submission';
      case NoteTarget.assignment:
        return 'assignment';
      case NoteTarget.plan:
        return 'plan';
    }
  }

  static NoteTarget fromString(String value) {
    switch (value) {
      case 'campaign':
        return NoteTarget.campaign;
      case 'phase':
        return NoteTarget.phase;
      case 'content_block':
        return NoteTarget.contentBlock;
      case 'submission':
        return NoteTarget.submission;
      case 'assignment':
        return NoteTarget.assignment;
      case 'plan':
        return NoteTarget.plan;
      default:
        return NoteTarget.campaign;
    }
  }
}

class Note {
  final String? id;
  final String brandOwnerId;
  final String collaboratorId;
  final String campaignId;
  final String? phaseId;
  final String? contentBlockId;
  final String? assignmentId;
  final String? submissionId;
  final String message;
  final NoteStatus status;
  final NoteTarget target;
  final DateTime createdAt;
  final DateTime? seenAt;
  final DateTime? updatedAt;

  Note({
    this.id,
    required this.brandOwnerId,
    required this.collaboratorId,
    required this.campaignId,
    this.phaseId,
    this.contentBlockId,
    this.assignmentId,
    this.submissionId,
    required this.message,
    required this.status,
    required this.target,
    required this.createdAt,
    this.seenAt,
    this.updatedAt,
  });

  bool get isUnread => status == NoteStatus.unread;
  bool get isSeen => status == NoteStatus.seen;

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['_id'] ?? json['id'],
      brandOwnerId: json['brandOwnerId'] ?? '',
      collaboratorId: json['collaboratorId'] ?? '',
      campaignId: json['campaignId'] ?? '',
      phaseId: json['phaseId'],
      contentBlockId: json['contentBlockId'],
      assignmentId: json['assignmentId'],
      submissionId: json['submissionId'],
      message: json['message'] ?? '',
      status: NoteStatusExt.fromString(json['status'] ?? 'unread'),
      target: NoteTargetExt.fromString(json['target'] ?? 'campaign'),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      seenAt: json['seenAt'] != null ? DateTime.tryParse(json['seenAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'brandOwnerId': brandOwnerId,
        'collaboratorId': collaboratorId,
        'campaignId': campaignId,
        'phaseId': phaseId,
        'contentBlockId': contentBlockId,
        'assignmentId': assignmentId,
        'submissionId': submissionId,
        'message': message,
        'status': status.toJson,
        'target': target.toJson,
        'createdAt': createdAt.toIso8601String(),
      };

  Note copyWith({
    String? id,
    String? brandOwnerId,
    String? collaboratorId,
    String? campaignId,
    String? phaseId,
    String? contentBlockId,
    String? assignmentId,
    String? submissionId,
    String? message,
    NoteStatus? status,
    NoteTarget? target,
    DateTime? createdAt,
    DateTime? seenAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      brandOwnerId: brandOwnerId ?? this.brandOwnerId,
      collaboratorId: collaboratorId ?? this.collaboratorId,
      campaignId: campaignId ?? this.campaignId,
      phaseId: phaseId ?? this.phaseId,
      contentBlockId: contentBlockId ?? this.contentBlockId,
      assignmentId: assignmentId ?? this.assignmentId,
      submissionId: submissionId ?? this.submissionId,
      message: message ?? this.message,
      status: status ?? this.status,
      target: target ?? this.target,
      createdAt: createdAt ?? this.createdAt,
      seenAt: seenAt ?? this.seenAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
