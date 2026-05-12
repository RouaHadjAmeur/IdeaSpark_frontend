// assignment.dart
// Model for work assignments from Brand Owner to Collaborator

enum AssignmentStatus {
  assigned,
  accepted,
  declined,
  inProgress,
  submitted,
  approved,
  rejected,
  changesRequested,
}

enum AssignmentPriority {
  low,
  medium,
  high,
  urgent,
}

extension AssignmentStatusExt on AssignmentStatus {
  String get label {
    switch (this) {
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.accepted:
        return 'Accepted';
      case AssignmentStatus.declined:
        return 'Declined';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.submitted:
        return 'Submitted';
      case AssignmentStatus.approved:
        return 'Approved';
      case AssignmentStatus.rejected:
        return 'Rejected';
      case AssignmentStatus.changesRequested:
        return 'Changes Requested';
    }
  }

  String get toJson {
    switch (this) {
      case AssignmentStatus.assigned:
        return 'assigned';
      case AssignmentStatus.accepted:
        return 'accepted';
      case AssignmentStatus.declined:
        return 'declined';
      case AssignmentStatus.inProgress:
        return 'in_progress';
      case AssignmentStatus.submitted:
        return 'submitted';
      case AssignmentStatus.approved:
        return 'approved';
      case AssignmentStatus.rejected:
        return 'rejected';
      case AssignmentStatus.changesRequested:
        return 'changes_requested';
    }
  }

  static AssignmentStatus fromString(String value) {
    switch (value) {
      case 'assigned':
        return AssignmentStatus.assigned;
      case 'accepted':
        return AssignmentStatus.accepted;
      case 'declined':
        return AssignmentStatus.declined;
      case 'in_progress':
        return AssignmentStatus.inProgress;
      case 'submitted':
        return AssignmentStatus.submitted;
      case 'approved':
        return AssignmentStatus.approved;
      case 'rejected':
        return AssignmentStatus.rejected;
      case 'changes_requested':
        return AssignmentStatus.changesRequested;
      default:
        return AssignmentStatus.assigned;
    }
  }
}

extension AssignmentPriorityExt on AssignmentPriority {
  String get label {
    switch (this) {
      case AssignmentPriority.low:
        return 'Low';
      case AssignmentPriority.medium:
        return 'Medium';
      case AssignmentPriority.high:
        return 'High';
      case AssignmentPriority.urgent:
        return 'Urgent';
    }
  }

  String get toJson {
    switch (this) {
      case AssignmentPriority.low:
        return 'low';
      case AssignmentPriority.medium:
        return 'medium';
      case AssignmentPriority.high:
        return 'high';
      case AssignmentPriority.urgent:
        return 'urgent';
    }
  }

  static AssignmentPriority fromString(String value) {
    switch (value) {
      case 'low':
        return AssignmentPriority.low;
      case 'medium':
        return AssignmentPriority.medium;
      case 'high':
        return AssignmentPriority.high;
      case 'urgent':
        return AssignmentPriority.urgent;
      default:
        return AssignmentPriority.medium;
    }
  }
}

class Assignment {
  final String? id;
  final String campaignId;
  final String phaseId;
  final String contentBlockId;
  final String brandOwnerId;
  final String collaboratorId;
  final List<String> productIds;
  final String title;
  final String instructions;
  final AssignmentPriority priority;
  final DateTime deadline;
  final AssignmentStatus status;
  final List<String>? references;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? submittedAt;

  Assignment({
    this.id,
    required this.campaignId,
    required this.phaseId,
    required this.contentBlockId,
    required this.brandOwnerId,
    required this.collaboratorId,
    required this.productIds,
    required this.title,
    required this.instructions,
    required this.priority,
    required this.deadline,
    required this.status,
    this.references,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.submittedAt,
  });

  bool get isLate => DateTime.now().isAfter(deadline) && 
      status != AssignmentStatus.approved && 
      status != AssignmentStatus.rejected;

  bool get isOverdue => DateTime.now().isAfter(deadline);

  Duration get timeRemaining => deadline.difference(DateTime.now());

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['_id'] ?? json['id'],
      campaignId: json['campaignId'] ?? '',
      phaseId: json['phaseId'] ?? '',
      contentBlockId: json['contentBlockId'] ?? '',
      brandOwnerId: json['brandOwnerId'] ?? '',
      collaboratorId: json['collaboratorId'] ?? '',
      productIds: List<String>.from(json['productIds'] ?? []),
      title: json['title'] ?? '',
      instructions: json['instructions'] ?? '',
      priority: AssignmentPriorityExt.fromString(json['priority'] ?? 'medium'),
      deadline: DateTime.tryParse(json['deadline'] ?? '') ?? DateTime.now(),
      status: AssignmentStatusExt.fromString(json['status'] ?? 'assigned'),
      references: (json['references'] as List<dynamic>?)?.cast<String>(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      acceptedAt: json['acceptedAt'] != null ? DateTime.tryParse(json['acceptedAt']) : null,
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'phaseId': phaseId,
        'contentBlockId': contentBlockId,
        'brandOwnerId': brandOwnerId,
        'collaboratorId': collaboratorId,
        'productIds': productIds,
        'title': title,
        'instructions': instructions,
        'priority': priority.toJson,
        'deadline': deadline.toIso8601String(),
        'status': status.toJson,
        'references': references,
      };

  Assignment copyWith({
    String? id,
    String? campaignId,
    String? phaseId,
    String? contentBlockId,
    String? brandOwnerId,
    String? collaboratorId,
    List<String>? productIds,
    String? title,
    String? instructions,
    AssignmentPriority? priority,
    DateTime? deadline,
    AssignmentStatus? status,
    List<String>? references,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? submittedAt,
  }) {
    return Assignment(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      phaseId: phaseId ?? this.phaseId,
      contentBlockId: contentBlockId ?? this.contentBlockId,
      brandOwnerId: brandOwnerId ?? this.brandOwnerId,
      collaboratorId: collaboratorId ?? this.collaboratorId,
      productIds: productIds ?? this.productIds,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      references: references ?? this.references,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }
}
