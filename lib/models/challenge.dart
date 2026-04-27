class Challenge {
  final String id;
  final String brandId;
  final String title;
  final String description;
  final String brief;
  final String reward;
  final String runnerUpReward;
  final DateTime deadline;
  final String status; // draft, live, review, closed
  final String videoType;
  final String language;
  final String targetAudience;
  final List<String> criteria;
  final int minDuration;
  final int maxDuration;
  final int maxParticipants; // maps from submissionCap
  final List<String> shortlistedCreators;
  final int shortlistedCount;
  final String? winnerId;
  final DateTime createdAt;
  final int submissionsCount; // maps from submissionCount

  Challenge({
    required this.id,
    required this.brandId,
    required this.title,
    required this.description,
    this.brief = '',
    required this.reward,
    this.runnerUpReward = '',
    required this.deadline,
    required this.status,
    this.videoType = 'UGC',
    this.language = '',
    this.targetAudience = '',
    this.criteria = const [],
    required this.minDuration,
    required this.maxDuration,
    required this.maxParticipants,
    this.shortlistedCreators = const [],
    this.shortlistedCount = 0,
    this.winnerId,
    required this.createdAt,
    this.submissionsCount = 0,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    final rewardRaw = json['reward'];
    final rewardStr = rewardRaw is num
        ? '${rewardRaw.toInt()} TND'
        : (rewardRaw?.toString() ?? '');

    final runnerUpRaw = json['runnerUpReward'];
    final runnerUpStr = runnerUpRaw is num
        ? '${runnerUpRaw.toInt()} TND'
        : (runnerUpRaw?.toString() ?? '');

    return Challenge(
      id: json['_id'] ?? json['id'] ?? '',
      brandId: json['brandId'] is Map
          ? json['brandId']['_id'] ?? ''
          : (json['brandId'] ?? ''),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      brief: json['brief'] ?? '',
      reward: rewardStr,
      runnerUpReward: runnerUpStr,
      deadline: DateTime.tryParse(json['deadline'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'live',
      videoType: json['videoType'] ?? 'UGC',
      language: json['language'] ?? '',
      targetAudience: json['targetAudience'] ?? '',
      criteria: List<String>.from(json['criteria'] ?? []),
      minDuration: json['minDuration'] ?? 15,
      maxDuration: json['maxDuration'] ?? 60,
      maxParticipants: json['submissionCap'] ?? json['maxParticipants'] ?? 30,
      shortlistedCreators: List<String>.from(json['shortlistedCreators'] ?? []),
      shortlistedCount: json['shortlistedCount'] ?? 0,
      winnerId: json['winnerSubmissionId']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      submissionsCount: json['submissionCount'] ?? json['submissionsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'reward': reward,
    'deadline': deadline.toIso8601String(),
    'minDuration': minDuration,
    'maxDuration': maxDuration,
    'maxParticipants': maxParticipants,
  };
}
