enum DeliverableStatus { pending, approved, rejected }

class Deliverable {
  final String id;
  final String taskId;
  final String contentUrl;
  final String? comment;
  final DeliverableStatus status;
  final DateTime? createdAt;

  const Deliverable({
    required this.id,
    required this.taskId,
    required this.contentUrl,
    this.comment,
    this.status = DeliverableStatus.pending,
    this.createdAt,
  });

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    DeliverableStatus parseStatus(String? status) {
      switch (status) {
        case 'approved':
          return DeliverableStatus.approved;
        case 'rejected':
          return DeliverableStatus.rejected;
        default:
          return DeliverableStatus.pending;
      }
    }

    return Deliverable(
      id: json['_id'] ?? json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      contentUrl: json['contentUrl'] ?? '',
      comment: json['comment'],
      status: parseStatus(json['status']),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    String statusString(DeliverableStatus s) {
      switch (s) {
        case DeliverableStatus.approved:
          return 'approved';
        case DeliverableStatus.rejected:
          return 'rejected';
        default:
          return 'pending';
      }
    }

    return {
      'id': id,
      'taskId': taskId,
      'contentUrl': contentUrl,
      'comment': comment,
      'status': statusString(status),
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
