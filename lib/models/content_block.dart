// content_block.dart
// Dart model for ContentBlock matching the backend schema

enum ContentBlockStatus {
  idea,
  approved,
  scheduled,
  inProcess,
  terminated;

  static ContentBlockStatus fromString(String value) {
    switch (value) {
      case 'approved':   return ContentBlockStatus.approved;
      case 'scheduled':  return ContentBlockStatus.scheduled;
      case 'in_process': return ContentBlockStatus.inProcess;
      case 'terminated': return ContentBlockStatus.terminated;
      case 'idea':
      default:           return ContentBlockStatus.idea;
    }
  }

  String toJson() {
    switch (this) {
      case ContentBlockStatus.idea:       return 'idea';
      case ContentBlockStatus.approved:   return 'approved';
      case ContentBlockStatus.scheduled:  return 'scheduled';
      case ContentBlockStatus.inProcess:  return 'in_process';
      case ContentBlockStatus.terminated: return 'terminated';
    }
  }

  String get label {
    switch (this) {
      case ContentBlockStatus.idea:       return 'Idea';
      case ContentBlockStatus.approved:   return 'Approved';
      case ContentBlockStatus.scheduled:  return 'Scheduled';
      case ContentBlockStatus.inProcess:  return 'In Process';
      case ContentBlockStatus.terminated: return 'Terminated';
    }
  }
}

enum ContentType {
  educational,
  promo,
  teaser,
  launch,
  socialProof,
  objection,
  behindScenes,
  authority;

  static ContentType fromString(String value) {
    switch (value) {
      case 'promo':          return ContentType.promo;
      case 'teaser':         return ContentType.teaser;
      case 'launch':         return ContentType.launch;
      case 'social_proof':   return ContentType.socialProof;
      case 'objection':      return ContentType.objection;
      case 'behind_scenes':  return ContentType.behindScenes;
      case 'authority':      return ContentType.authority;
      case 'educational':
      default:               return ContentType.educational;
    }
  }

  String toJson() {
    switch (this) {
      case ContentType.educational:  return 'educational';
      case ContentType.promo:        return 'promo';
      case ContentType.teaser:       return 'teaser';
      case ContentType.launch:       return 'launch';
      case ContentType.socialProof:  return 'social_proof';
      case ContentType.objection:    return 'objection';
      case ContentType.behindScenes: return 'behind_scenes';
      case ContentType.authority:    return 'authority';
    }
  }
}

enum ContentPlatform {
  tiktok,
  instagram,
  youtube,
  facebook,
  linkedin;

  static ContentPlatform fromString(String value) {
    switch (value) {
      case 'instagram': return ContentPlatform.instagram;
      case 'youtube':   return ContentPlatform.youtube;
      case 'facebook':  return ContentPlatform.facebook;
      case 'linkedin':  return ContentPlatform.linkedin;
      case 'tiktok':
      default:          return ContentPlatform.tiktok;
    }
  }

  String toJson() => name;
}

enum ContentFormat {
  reel,
  short,
  post,
  carousel,
  story,
  live;

  static ContentFormat fromString(String value) {
    switch (value) {
      case 'short':    return ContentFormat.short;
      case 'post':     return ContentFormat.post;
      case 'carousel': return ContentFormat.carousel;
      case 'story':    return ContentFormat.story;
      case 'live':     return ContentFormat.live;
      case 'reel':
      default:         return ContentFormat.reel;
    }
  }

  String toJson() => name;
}

enum ContentCtaType {
  soft,
  hard,
  educational;

  static ContentCtaType fromString(String value) {
    switch (value) {
      case 'hard':        return ContentCtaType.hard;
      case 'educational': return ContentCtaType.educational;
      case 'soft':
      default:            return ContentCtaType.soft;
    }
  }

  String toJson() => name;
}

// ─── ContentBlock model ───────────────────────────────────────────────────────

class ContentBlock {
  final String id;
  final String userId;
  final String brandId;
  final String? projectId;
  final String? planId;
  final String? planPhaseId;
  final String? phaseLabel;
  final String title;
  final String? description;
  final ContentType contentType;
  final ContentPlatform platform;
  final ContentFormat? format;
  final List<String> hooks;
  final String? scriptOutline;
  final ContentCtaType ctaType;
  final String? productId;
  final List<String> tags;
  final DateTime? scheduledAt;
  final ContentBlockStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentBlock({
    required this.id,
    required this.userId,
    required this.brandId,
    this.projectId,
    this.planId,
    this.planPhaseId,
    this.phaseLabel,
    required this.title,
    this.description,
    required this.contentType,
    required this.platform,
    this.format,
    required this.hooks,
    this.scriptOutline,
    required this.ctaType,
    this.productId,
    required this.tags,
    this.scheduledAt,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      id:           json['id']     ?? json['_id'] ?? '',
      userId:       json['userId'] ?? '',
      brandId:      json['brandId'] ?? '',
      projectId:    json['projectId'],
      planId:       json['planId'],
      planPhaseId:  json['planPhaseId'],
      phaseLabel:   json['phaseLabel'],
      title:        json['title'] ?? '',
      description:  json['description'],
      contentType:  ContentType.fromString(json['contentType'] ?? 'educational'),
      platform:     ContentPlatform.fromString(json['platform'] ?? 'instagram'),
      format:       json['format'] != null ? ContentFormat.fromString(json['format']) : null,
      hooks:        List<String>.from(json['hooks'] ?? []),
      scriptOutline: json['scriptOutline'],
      ctaType:      ContentCtaType.fromString(json['ctaType'] ?? 'soft'),
      productId:    json['productId'],
      tags:         List<String>.from(json['tags'] ?? []),
      scheduledAt:  json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      status:       ContentBlockStatus.fromString(json['status'] ?? 'idea'),
      createdAt:    DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:    DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandId':      brandId,
      'projectId':    projectId,
      'planId':       planId,
      'planPhaseId':  planPhaseId,
      'phaseLabel':   phaseLabel,
      'title':        title,
      'description':  description,
      'contentType':  contentType.toJson(),
      'platform':     platform.toJson(),
      if (format != null) 'format': format!.toJson(),
      'hooks':        hooks,
      'scriptOutline': scriptOutline,
      'ctaType':      ctaType.toJson(),
      'productId':    productId,
      'tags':         tags,
      if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
    };
  }

  ContentBlock copyWith({
    ContentBlockStatus? status,
    String? planId,
    String? planPhaseId,
    String? phaseLabel,
    DateTime? scheduledAt,
  }) {
    return ContentBlock(
      id:           id,
      userId:       userId,
      brandId:      brandId,
      projectId:    projectId,
      planId:       planId       ?? this.planId,
      planPhaseId:  planPhaseId  ?? this.planPhaseId,
      phaseLabel:   phaseLabel   ?? this.phaseLabel,
      title:        title,
      description:  description,
      contentType:  contentType,
      platform:     platform,
      format:       format,
      hooks:        hooks,
      scriptOutline: scriptOutline,
      ctaType:      ctaType,
      productId:    productId,
      tags:         tags,
      scheduledAt:  scheduledAt  ?? this.scheduledAt,
      status:       status       ?? this.status,
      createdAt:    createdAt,
      updatedAt:    DateTime.now(),
    );
  }
}

// ─── ContentBlock Create DTO ──────────────────────────────────────────────────

class CreateContentBlockDto {
  final String brandId;
  final String? projectId;
  final String? planId;
  final String? planPhaseId;
  final String? phaseLabel;
  final String title;
  final String? description;
  final ContentType contentType;
  final ContentPlatform platform;
  final ContentFormat? format;
  final List<String> hooks;
  final String? scriptOutline;
  final ContentCtaType ctaType;
  final String? productId;
  final List<String> tags;
  final DateTime? scheduledAt;

  const CreateContentBlockDto({
    required this.brandId,
    this.projectId,
    this.planId,
    this.planPhaseId,
    this.phaseLabel,
    required this.title,
    this.description,
    required this.contentType,
    required this.platform,
    this.format,
    required this.hooks,
    this.scriptOutline,
    required this.ctaType,
    this.productId,
    this.tags = const [],
    this.scheduledAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'brandId':      brandId,
      if (projectId   != null) 'projectId':   projectId,
      if (planId      != null) 'planId':       planId,
      if (planPhaseId != null) 'planPhaseId':  planPhaseId,
      if (phaseLabel  != null) 'phaseLabel':   phaseLabel,
      'title':        title,
      if (description != null) 'description':  description,
      'contentType':  contentType.toJson(),
      'platform':     platform.toJson(),
      if (format      != null) 'format':       format!.toJson(),
      'hooks':        hooks,
      if (scriptOutline != null) 'scriptOutline': scriptOutline,
      'ctaType':      ctaType.toJson(),
      if (productId   != null) 'productId':    productId,
      'tags':         tags,
      if (scheduledAt != null) 'scheduledAt':  scheduledAt!.toIso8601String(),
    };
  }
}

// ─── AI Generation Result ─────────────────────────────────────────────────────

class ContentBlockGenerationResult {
  final String title;
  final List<String> hooks;
  final String scriptOutline;
  final ContentType contentType;
  final ContentCtaType ctaType;
  final ContentPlatform platform;
  final ContentFormat format;
  final String? description;
  final String? productSuggestion;
  final List<String> tags;

  const ContentBlockGenerationResult({
    required this.title,
    required this.hooks,
    required this.scriptOutline,
    required this.contentType,
    required this.ctaType,
    required this.platform,
    required this.format,
    this.description,
    this.productSuggestion,
    this.tags = const [],
  });

  factory ContentBlockGenerationResult.fromJson(Map<String, dynamic> json) {
    return ContentBlockGenerationResult(
      title:             json['title'] ?? '',
      hooks:             List<String>.from(json['hooks'] ?? []),
      scriptOutline:     json['scriptOutline'] ?? '',
      contentType:       ContentType.fromString(json['contentType'] ?? 'educational'),
      ctaType:           ContentCtaType.fromString(json['ctaType'] ?? 'soft'),
      platform:          ContentPlatform.fromString(json['platform'] ?? 'instagram'),
      format:            ContentFormat.fromString(json['format'] ?? 'reel'),
      description:       json['description'],
      productSuggestion: json['productSuggestion'],
      tags:              List<String>.from(json['tags'] ?? []),
    );
  }

  /// Convert to CreateContentBlockDto for saving
  CreateContentBlockDto toCreateDto({
    required String brandId,
    String? projectId,
    String? planId,
    String? planPhaseId,
    String? phaseLabel,
    DateTime? scheduledAt,
  }) {
    return CreateContentBlockDto(
      brandId:      brandId,
      projectId:    projectId,
      planId:       planId,
      planPhaseId:  planPhaseId,
      phaseLabel:   phaseLabel,
      title:        title,
      description:  description,
      contentType:  contentType,
      platform:     platform,
      format:       format,
      hooks:        hooks,
      scriptOutline: scriptOutline,
      ctaType:      ctaType,
      tags:         tags,
      scheduledAt:  scheduledAt,
    );
  }
}
