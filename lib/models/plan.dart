// ─── Enums ────────────────────────────────────────────────────────────────────

enum PlanObjective {
  brandAwareness,
  leadGeneration,
  salesConversion,
  audienceGrowth,
  productLaunch,
  seasonalCampaign,
}

enum PlanStatus { draft, active, completed }

enum ContentFormat { reel, carousel, story, post }

enum CtaType { soft, hard, educational }

enum ContentBlockStatus { draft, scheduled, edited }

enum CalendarEntryStatus { scheduled, published, cancelled }

// ─── Project DNA ─────────────────────────────────────────────────────────────

class StrategicDNA {
  final String vision;
  final List<String> targetAudience;
  final String offer;
  final String positioning;
  final String campaignAngle;
  final List<String> kpis;

  const StrategicDNA({
    this.vision = '',
    this.targetAudience = const [],
    this.offer = '',
    this.positioning = '',
    this.campaignAngle = '',
    this.kpis = const [],
  });

  factory StrategicDNA.fromJson(Map<String, dynamic> json) => StrategicDNA(
        vision: json['vision'] ?? '',
        targetAudience: List<String>.from(json['targetAudience'] ?? []),
        offer: json['offer'] ?? '',
        positioning: json['positioning'] ?? '',
        campaignAngle: json['campaignAngle'] ?? '',
        kpis: List<String>.from(json['kpis'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'vision': vision,
        'targetAudience': targetAudience,
        'offer': offer,
        'positioning': positioning,
        'campaignAngle': campaignAngle,
        'kpis': kpis,
      };
}

class ExecutionDNA {
  final int progressPercentage;
  final List<String> taskIds;
  final DateTime? overallDeadline;

  const ExecutionDNA({
    this.progressPercentage = 0,
    this.taskIds = const [],
    this.overallDeadline,
  });

  factory ExecutionDNA.fromJson(Map<String, dynamic> json) => ExecutionDNA(
        progressPercentage: (json['progressPercentage'] as num?)?.toInt() ?? 0,
        taskIds: List<String>.from(json['taskIds'] ?? []),
        overallDeadline: json['overallDeadline'] != null ? DateTime.tryParse(json['overallDeadline']) : null,
      );

  Map<String, dynamic> toJson() => {
        'progressPercentage': progressPercentage,
        'taskIds': taskIds,
        'overallDeadline': overallDeadline?.toIso8601String(),
      };
}

class ResourceAsset {
  final String type;
  final String url;
  final String label;

  const ResourceAsset({required this.type, required this.url, required this.label});

  factory ResourceAsset.fromJson(Map<String, dynamic> json) => ResourceAsset(
        type: json['type'] ?? '',
        url: json['url'] ?? '',
        label: json['label'] ?? '',
      );

  Map<String, dynamic> toJson() => {'type': type, 'url': url, 'label': label};
}

class ResourceDNA {
  final List<ResourceAsset> assets;
  final List<String> landingPages;
  final List<String> references;

  const ResourceDNA({
    this.assets = const [],
    this.landingPages = const [],
    this.references = const [],
  });

  factory ResourceDNA.fromJson(Map<String, dynamic> json) => ResourceDNA(
        assets: (json['assets'] as List<dynamic>?)?.map((a) => ResourceAsset.fromJson(a)).toList() ?? [],
        landingPages: List<String>.from(json['landingPages'] ?? []),
        references: List<String>.from(json['references'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'assets': assets.map((a) => a.toJson()).toList(),
        'landingPages': landingPages,
        'references': references,
      };
}

class SkillDNA {
  final List<String> requiredRoles;
  final List<String> missingRoles;

  const SkillDNA({
    this.requiredRoles = const [],
    this.missingRoles = const [],
  });

  factory SkillDNA.fromJson(Map<String, dynamic> json) => SkillDNA(
        requiredRoles: List<String>.from(json['requiredRoles'] ?? []),
        missingRoles: List<String>.from(json['missingRoles'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'requiredRoles': requiredRoles,
        'missingRoles': missingRoles,
      };
}

class PerformanceDNA {
  final int readinessScore;
  final List<String> weakPoints;
  final List<String> blockers;

  const PerformanceDNA({
    this.readinessScore = 0,
    this.weakPoints = const [],
    this.blockers = const [],
  });

  factory PerformanceDNA.fromJson(Map<String, dynamic> json) => PerformanceDNA(
        readinessScore: (json['readinessScore'] as num?)?.toInt() ?? 0,
        weakPoints: List<String>.from(json['weakPoints'] ?? []),
        blockers: List<String>.from(json['blockers'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'readinessScore': readinessScore,
        'weakPoints': weakPoints,
        'blockers': blockers,
      };
}

class ProjectDNA {
  final StrategicDNA strategic;
  final ExecutionDNA execution;
  final ResourceDNA resource;
  final SkillDNA skill;
  final PerformanceDNA performance;

  const ProjectDNA({
    this.strategic = const StrategicDNA(),
    this.execution = const ExecutionDNA(),
    this.resource = const ResourceDNA(),
    this.skill = const SkillDNA(),
    this.performance = const PerformanceDNA(),
  });

  factory ProjectDNA.fromJson(Map<String, dynamic> json) => ProjectDNA(
        strategic: StrategicDNA.fromJson(json['strategic'] ?? {}),
        execution: ExecutionDNA.fromJson(json['execution'] ?? {}),
        resource: ResourceDNA.fromJson(json['resource'] ?? {}),
        skill: SkillDNA.fromJson(json['skill'] ?? {}),
        performance: PerformanceDNA.fromJson(json['performance'] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        'strategic': strategic.toJson(),
        'execution': execution.toJson(),
        'resource': resource.toJson(),
        'skill': skill.toJson(),
        'performance': performance.toJson(),
      };
}

// ─── Nested models ────────────────────────────────────────────────────────────

class ContentBlock {
  final String? id;
  final String title;
  final String pillar;
  final String? productId;
  final ContentFormat format;
  final CtaType ctaType;
  final String? emotionalTrigger;
  final int recommendedDayOffset;
  final String? recommendedTime;
  final ContentBlockStatus status;
  final String? imageUrl;

  const ContentBlock({
    this.id,
    required this.title,
    required this.pillar,
    this.productId,
    required this.format,
    required this.ctaType,
    this.emotionalTrigger,
    this.recommendedDayOffset = 0,
    this.recommendedTime,
    this.status = ContentBlockStatus.draft,
    this.imageUrl,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    T? enumOrNull<T extends Enum>(List<T> values, dynamic raw) {
      if (raw == null) return null;
      return values.cast<T?>().firstWhere((e) => e?.name == raw, orElse: () => null);
    }

    return ContentBlock(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      pillar: json['pillar'] ?? '',
      productId: json['productId'],
      format: enumOrNull(ContentFormat.values, json['format']) ?? ContentFormat.post,
      ctaType: enumOrNull(CtaType.values, json['ctaType']) ?? CtaType.soft,
      emotionalTrigger: json['emotionalTrigger'],
      recommendedDayOffset: (json['recommendedDayOffset'] as num?)?.toInt() ?? 0,
      recommendedTime: json['recommendedTime'],
      status: enumOrNull(ContentBlockStatus.values, json['status']) ?? ContentBlockStatus.draft,
      imageUrl: json['imageUrl'],
    );
  }
}

class Phase {
  final String? id;
  final String name;
  final int weekNumber;
  final String? description;
  final List<ContentBlock> contentBlocks;

  const Phase({
    this.id,
    required this.name,
    required this.weekNumber,
    this.description,
    this.contentBlocks = const [],
  });

  factory Phase.fromJson(Map<String, dynamic> json) => Phase(
        id: json['_id'] ?? json['id'],
        name: json['name'] ?? '',
        weekNumber: (json['weekNumber'] as num?)?.toInt() ?? 1,
        description: json['description'],
        contentBlocks: (json['contentBlocks'] as List<dynamic>?)
                ?.map((b) => ContentBlock.fromJson(b as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

// ─── CalendarEntry ────────────────────────────────────────────────────────────

class CalendarEntry {
  final String? id;
  final String planId;
  final String contentBlockId;
  final String brandId;
  final DateTime scheduledDate;
  final String? scheduledTime;
  final String platform;
  final CalendarEntryStatus status;

  // Populated from plan phases (client-side join)
  final String? title;
  final String? pillar;
  final ContentFormat? format;
  final CtaType? ctaType;

  const CalendarEntry({
    this.id,
    required this.planId,
    required this.contentBlockId,
    required this.brandId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.platform,
    this.status = CalendarEntryStatus.scheduled,
    this.title,
    this.pillar,
    this.format,
    this.ctaType,
  });

  factory CalendarEntry.fromJson(Map<String, dynamic> json) {
    T? enumOrNull<T extends Enum>(List<T> values, dynamic raw) {
      if (raw == null) return null;
      return values.cast<T?>().firstWhere((e) => e?.name == raw, orElse: () => null);
    }

    return CalendarEntry(
      id: json['_id'] ?? json['id'],
      planId: json['planId'] ?? '',
      contentBlockId: json['contentBlockId'] ?? '',
      brandId: json['brandId'] ?? '',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.tryParse(json['scheduledDate']) ?? DateTime.now()
          : DateTime.now(),
      scheduledTime: json['scheduledTime'],
      platform: json['platform'] ?? '',
      status: enumOrNull(CalendarEntryStatus.values, json['status']) ?? CalendarEntryStatus.scheduled,
      title: json['title'],
      pillar: json['pillar'],
      format: enumOrNull(ContentFormat.values, json['format']),
      ctaType: enumOrNull(CtaType.values, json['ctaType']),
    );
  }

  /// Returns a copy with content block details filled in from a [ContentBlock].
  CalendarEntry withBlock(ContentBlock block) => CalendarEntry(
        id: id,
        planId: planId,
        contentBlockId: contentBlockId,
        brandId: brandId,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        platform: platform,
        status: status,
        title: block.title,
        pillar: block.pillar,
        format: block.format,
        ctaType: block.ctaType,
      );
}

// ─── Plan ─────────────────────────────────────────────────────────────────────

class Plan {
  final String? id;
  final String brandId;
  final String name;
  final PlanObjective objective;
  final DateTime startDate;
  final DateTime endDate;
  final int durationWeeks;
  final String promotionIntensity;
  final int postingFrequency;
  final List<String> platforms;
  final List<String> productIds;
  final Map<String, dynamic> contentMixPreference;
  final PlanStatus status;
  final String userId;
  final List<Phase> phases;
  final ProjectDNA projectDNA;
  final String notes;
  final bool notesSeen;
  final String? lastNoteAuthorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Plan({
    this.id,
    required this.brandId,
    required this.name,
    required this.objective,
    required this.startDate,
    required this.endDate,
    required this.durationWeeks,
    this.promotionIntensity = 'balanced',
    this.postingFrequency = 3,
    this.platforms = const [],
    this.productIds = const [],
    this.contentMixPreference = const {
      'educational': 25,
      'promotional': 25,
      'storytelling': 25,
      'authority': 25,
    },
    this.status = PlanStatus.draft,
    required this.userId,
    this.phases = const [],
    this.projectDNA = const ProjectDNA(),
    this.notes = '',
    this.notesSeen = true,
    this.lastNoteAuthorId,
    this.createdAt,
    this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    T? enumOrNull<T extends Enum>(List<T> values, dynamic raw) {
      if (raw == null) return null;
      return values.cast<T?>().firstWhere((e) => e?.name == raw, orElse: () => null);
    }

    return Plan(
      id: json['_id'] ?? json['id'],
      brandId: json['brandId'] ?? '',
      name: json['name'] ?? '',
      objective: enumOrNull(PlanObjective.values, json['objective']) ?? PlanObjective.brandAwareness,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate']) ?? DateTime.now()
          : DateTime.now(),
      durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 4,
      promotionIntensity: json['promotionIntensity'] ?? 'balanced',
      postingFrequency: (json['postingFrequency'] as num?)?.toInt() ?? 3,
      platforms: List<String>.from(json['platforms'] ?? []),
      productIds: List<String>.from(json['productIds'] ?? []),
      contentMixPreference: Map<String, dynamic>.from(json['contentMixPreference'] ?? {}),
      status: enumOrNull(PlanStatus.values, json['status']) ?? PlanStatus.draft,
      userId: json['userId'] as String? ?? '',
      phases: (json['phases'] as List<dynamic>?)
              ?.map((p) => Phase.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      projectDNA: ProjectDNA.fromJson(json['projectDNA'] ?? {}),
      notes: json['notes'] ?? '',
      notesSeen: json['notesSeen'] ?? true,
      lastNoteAuthorId: json['lastNoteAuthorId'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brandId': brandId,
    'name': name,
    'objective': objective.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'durationWeeks': durationWeeks,
    'promotionIntensity': promotionIntensity,
    'postingFrequency': postingFrequency,
    'platforms': platforms,
    'productIds': productIds,
    'contentMixPreference': contentMixPreference,
    'status': status.name,
    'userId': userId,
    'projectDNA': projectDNA.toJson(),
    'notes': notes,
    'notesSeen': notesSeen,
    'lastNoteAuthorId': lastNoteAuthorId,
  };

  /// Look up a [ContentBlock] by its id within this plan's embedded phases.
  ContentBlock? findBlock(String blockId) {
    for (final phase in phases) {
      for (final block in phase.contentBlocks) {
        if (block.id == blockId) return block;
      }
    }
    return null;
  }
}

// ─── Display helpers ─────────────────────────────────────────────────────────

extension PlanObjectiveDisplay on PlanObjective {
  String get emoji {
    const m = {
      PlanObjective.brandAwareness: '🌟',
      PlanObjective.leadGeneration: '🎯',
      PlanObjective.salesConversion: '💰',
      PlanObjective.audienceGrowth: '📈',
      PlanObjective.productLaunch: '🚀',
      PlanObjective.seasonalCampaign: '🌸',
    };
    return m[this] ?? '📋';
  }

  String get label {
    const m = {
      PlanObjective.brandAwareness: 'Brand Awareness',
      PlanObjective.leadGeneration: 'Lead Generation',
      PlanObjective.salesConversion: 'Sales Conversion',
      PlanObjective.audienceGrowth: 'Audience Growth',
      PlanObjective.productLaunch: 'Product Launch',
      PlanObjective.seasonalCampaign: 'Seasonal Campaign',
    };
    return m[this] ?? name;
  }

  String get description {
    const m = {
      PlanObjective.brandAwareness: 'Build visibility and recognition',
      PlanObjective.leadGeneration: 'Capture and convert prospects',
      PlanObjective.salesConversion: 'Drive direct purchases',
      PlanObjective.audienceGrowth: 'Maximize reach and followers',
      PlanObjective.productLaunch: 'Full launch buzz sequence',
      PlanObjective.seasonalCampaign: 'Seasonal promotion bursts',
    };
    return m[this] ?? '';
  }

  /// Server-side enum value (camelCase → snake_case)
  String get apiValue {
    const m = {
      PlanObjective.brandAwareness: 'brand_awareness',
      PlanObjective.leadGeneration: 'lead_generation',
      PlanObjective.salesConversion: 'sales_conversion',
      PlanObjective.audienceGrowth: 'audience_growth',
      PlanObjective.productLaunch: 'product_launch',
      PlanObjective.seasonalCampaign: 'seasonal_campaign',
    };
    return m[this] ?? name;
  }
}

extension ContentFormatDisplay on ContentFormat {
  String get label {
    const m = {
      ContentFormat.reel: 'Reel',
      ContentFormat.carousel: 'Carousel',
      ContentFormat.story: 'Story',
      ContentFormat.post: 'Post',
    };
    return m[this] ?? name;
  }
}

extension CalendarEntryStatusDisplay on CalendarEntryStatus {
  String get label {
    const m = {
      CalendarEntryStatus.scheduled: 'Scheduled',
      CalendarEntryStatus.published: 'Published',
      CalendarEntryStatus.cancelled: 'Cancelled',
    };
    return m[this] ?? name;
  }
}
