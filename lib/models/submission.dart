class Submission {
  final String id;
  final String challengeId;
  final String challengeTitle;
  final String challengeReward;
  final String creatorId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String status;
  final int? rating;
  final String? feedback;
  final List<dynamic> revisions;
  final DateTime createdAt;

  Submission({
    required this.id,
    required this.challengeId,
    this.challengeTitle = '',
    this.challengeReward = '',
    required this.creatorId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.status,
    this.rating,
    this.feedback,
    this.revisions = const [],
    required this.createdAt,
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    final rewardRaw = json['challengeReward'];
    final rewardStr = rewardRaw is num
        ? '${rewardRaw.toInt()} TND'
        : (rewardRaw?.toString() ?? '');

    return Submission(
      id: json['_id'] ?? json['id'] ?? '',
      challengeId: json['challengeId'] is Map
          ? json['challengeId']['_id'] ?? ''
          : (json['challengeId']?.toString() ?? ''),
      challengeTitle: json['challengeTitle'] ?? '',
      challengeReward: rewardStr,
      creatorId: json['creatorId'] is Map
          ? json['creatorId']['_id'] ?? ''
          : (json['creatorId']?.toString() ?? ''),
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      status: json['status'] ?? 'pending',
      rating: json['rating'],
      feedback: json['feedback'],
      revisions: json['revisionHistory'] ?? json['revisions'] ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
