// submission.dart
// Model for content submissions from Collaborator

enum SubmissionStatus {
  submitted,
  approved,
  rejected,
  changesRequested,
  published,
  shortlisted,
  winner,
  revisionRequested,
}

enum MediaType {
  video,
  image,
  carousel,
  document,
}

extension SubmissionStatusExt on SubmissionStatus {
  String get label {
    switch (this) {
      case SubmissionStatus.submitted:
        return 'Submitted';
      case SubmissionStatus.approved:
        return 'Approved';
      case SubmissionStatus.rejected:
        return 'Rejected';
      case SubmissionStatus.changesRequested:
        return 'Changes Requested';
      case SubmissionStatus.published:
        return 'Published';
      case SubmissionStatus.shortlisted:
        return 'Shortlisted';
      case SubmissionStatus.winner:
        return 'Winner';
      case SubmissionStatus.revisionRequested:
        return 'Revision Requested';
    }
  }

  String get toJson {
    switch (this) {
      case SubmissionStatus.submitted:
        return 'submitted';
      case SubmissionStatus.approved:
        return 'approved';
      case SubmissionStatus.rejected:
        return 'rejected';
      case SubmissionStatus.changesRequested:
        return 'changes_requested';
      case SubmissionStatus.published:
        return 'published';
      case SubmissionStatus.shortlisted:
        return 'shortlisted';
      case SubmissionStatus.winner:
        return 'winner';
      case SubmissionStatus.revisionRequested:
        return 'revision_requested';
    }
  }

  static SubmissionStatus fromString(String value) {
    switch (value) {
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'approved':
        return SubmissionStatus.approved;
      case 'rejected':
        return SubmissionStatus.rejected;
      case 'changes_requested':
        return SubmissionStatus.changesRequested;
      case 'published':
        return SubmissionStatus.published;
      case 'shortlisted':
        return SubmissionStatus.shortlisted;
      case 'winner':
        return SubmissionStatus.winner;
      case 'revision_requested':
        return SubmissionStatus.revisionRequested;
      default:
        return SubmissionStatus.submitted;
    }
  }
}

extension MediaTypeExt on MediaType {
  String get label {
    switch (this) {
      case MediaType.video:
        return 'Video';
      case MediaType.image:
        return 'Image';
      case MediaType.carousel:
        return 'Carousel';
      case MediaType.document:
        return 'Document';
    }
  }

  String get toJson {
    switch (this) {
      case MediaType.video:
        return 'video';
      case MediaType.image:
        return 'image';
      case MediaType.carousel:
        return 'carousel';
      case MediaType.document:
        return 'document';
    }
  }

  static MediaType fromString(String value) {
    switch (value) {
      case 'video':
        return MediaType.video;
      case 'image':
        return MediaType.image;
      case 'carousel':
        return MediaType.carousel;
      case 'document':
        return MediaType.document;
      default:
        return MediaType.video;
    }
  }
}

class SubmissionMedia {
  final String url;
  final MediaType type;
  final String? thumbnail;
  final int? duration; // in seconds for videos

  SubmissionMedia({
    required this.url,
    required this.type,
    this.thumbnail,
    this.duration,
  });

  factory SubmissionMedia.fromJson(Map<String, dynamic> json) {
    return SubmissionMedia(
      url: json['url'] ?? '',
      type: MediaTypeExt.fromString(json['type'] ?? 'video'),
      thumbnail: json['thumbnail'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type.toJson,
        'thumbnail': thumbnail,
        'duration': duration,
      };
}

class Submission {
  final String? id;
  final String assignmentId;
  final String collaboratorId;
  final String campaignId;
  final String phaseId;
  final String contentBlockId;
  final List<SubmissionMedia> media;
  final String caption;
  final List<String> hashtags;
  final String? script;
  final String? thumbnail;
  final String? thumbnailUrl;
  final SubmissionStatus status;
  final String? feedback;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final DateTime? publishedAt;
  final String? publishedUrl;
  final String? videoUrl;
  final double? rating;
  final String? creatorId;
  final String? challengeId;
  final String? challengeTitle;
  final String? challengeReward;
  final List<String>? revisions;

  Submission({
    this.id,
    required this.assignmentId,
    required this.collaboratorId,
    required this.campaignId,
    required this.phaseId,
    required this.contentBlockId,
    required this.media,
    required this.caption,
    required this.hashtags,
    this.script,
    this.thumbnail,
    this.thumbnailUrl,
    required this.status,
    this.feedback,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.publishedAt,
    this.publishedUrl,
    this.videoUrl,
    this.rating,
    this.creatorId,
    this.challengeId,
    this.challengeTitle,
    this.challengeReward,
    this.revisions,
  });

  bool get isPending => status == SubmissionStatus.submitted;
  bool get isApproved => status == SubmissionStatus.approved;
  bool get isRejected => status == SubmissionStatus.rejected;
  bool get needsChanges => status == SubmissionStatus.changesRequested;
  bool get isPublished => status == SubmissionStatus.published;

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['_id'] ?? json['id'],
      assignmentId: json['assignmentId'] ?? '',
      collaboratorId: json['collaboratorId'] ?? '',
      campaignId: json['campaignId'] ?? '',
      phaseId: json['phaseId'] ?? '',
      contentBlockId: json['contentBlockId'] ?? '',
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => SubmissionMedia.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      caption: json['caption'] ?? '',
      hashtags: List<String>.from(json['hashtags'] ?? []),
      script: json['script'],
      thumbnail: json['thumbnail'],
      thumbnailUrl: json['thumbnailUrl'],
      status: SubmissionStatusExt.fromString(json['status'] ?? 'submitted'),
      feedback: json['feedback'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.tryParse(json['approvedAt']) : null,
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
      publishedUrl: json['publishedUrl'],
      videoUrl: json['videoUrl'],
      rating: (json['rating'] as num?)?.toDouble(),
      creatorId: json['creatorId'],
      challengeId: json['challengeId'],
      challengeTitle: json['challengeTitle'],
      challengeReward: json['challengeReward'],
      revisions: (json['revisions'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'assignmentId': assignmentId,
        'collaboratorId': collaboratorId,
        'campaignId': campaignId,
        'phaseId': phaseId,
        'contentBlockId': contentBlockId,
        'media': media.map((m) => m.toJson()).toList(),
        'caption': caption,
        'hashtags': hashtags,
        'script': script,
        'thumbnail': thumbnail,
        'thumbnailUrl': thumbnailUrl,
        'status': status.toJson,
        'feedback': feedback,
        'videoUrl': videoUrl,
        'rating': rating,
        'creatorId': creatorId,
        'challengeId': challengeId,
        'challengeTitle': challengeTitle,
        'challengeReward': challengeReward,
        'revisions': revisions,
      };

  Submission copyWith({
    String? id,
    String? assignmentId,
    String? collaboratorId,
    String? campaignId,
    String? phaseId,
    String? contentBlockId,
    List<SubmissionMedia>? media,
    String? caption,
    List<String>? hashtags,
    String? script,
    String? thumbnail,
    String? thumbnailUrl,
    SubmissionStatus? status,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? publishedAt,
    String? publishedUrl,
    String? videoUrl,
    double? rating,
    String? creatorId,
    String? challengeId,
    String? challengeTitle,
    String? challengeReward,
    List<String>? revisions,
  }) {
    return Submission(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      collaboratorId: collaboratorId ?? this.collaboratorId,
      campaignId: campaignId ?? this.campaignId,
      phaseId: phaseId ?? this.phaseId,
      contentBlockId: contentBlockId ?? this.contentBlockId,
      media: media ?? this.media,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      script: script ?? this.script,
      thumbnail: thumbnail ?? this.thumbnail,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      publishedUrl: publishedUrl ?? this.publishedUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      rating: rating ?? this.rating,
      creatorId: creatorId ?? this.creatorId,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeReward: challengeReward ?? this.challengeReward,
      revisions: revisions ?? this.revisions,
    );
  }
}
