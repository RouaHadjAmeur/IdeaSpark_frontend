enum BrandTone { professional, friendly, bold, educational, luxury, playful }

enum BrandPlatform { tiktok, instagram, youtube, facebook }

enum BrandGoal {
  growAudience,
  increaseSales,
  buildAuthority,
  promoteProducts,
  affiliateMarketing,
  personalBrand,
}

enum PostingFrequency { threePerWeek, fivePerWeek, daily, custom }

enum RevenueType {
  physicalProducts,
  digitalProducts,
  services,
  affiliate,
  sponsorships,
  mixed,
}

enum PromotionIntensity { low, balanced, aggressive }

enum BrandSeasonality { seasonal, alwaysActive, campaignBased }

// ─────────────── Nested models ───────────────

class BrandAudience {
  final String ageRange;
  final String gender;
  final List<String> interests;

  BrandAudience({
    required this.ageRange,
    required this.gender,
    required this.interests,
  });

  factory BrandAudience.fromJson(Map<String, dynamic> json) => BrandAudience(
        ageRange: json['ageRange'] ?? '',
        gender: json['gender'] ?? '',
        interests: List<String>.from(json['interests'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'ageRange': ageRange,
        'gender': gender,
        'interests': interests,
      };
}

class ContentMix {
  final int educational;
  final int promotional;
  final int storytelling;
  final int authority;

  const ContentMix({
    this.educational = 25,
    this.promotional = 25,
    this.storytelling = 25,
    this.authority = 25,
  });

  int get total => educational + promotional + storytelling + authority;

  factory ContentMix.fromJson(Map<String, dynamic> json) => ContentMix(
        educational: (json['educational'] as num?)?.toInt() ?? 25,
        promotional: (json['promotional'] as num?)?.toInt() ?? 25,
        storytelling: (json['storytelling'] as num?)?.toInt() ?? 25,
        authority: (json['authority'] as num?)?.toInt() ?? 25,
      );

  Map<String, dynamic> toJson() => {
        'educational': educational,
        'promotional': promotional,
        'storytelling': storytelling,
        'authority': authority,
      };
}

class BrandKPIs {
  final double? monthlyRevenueTarget;
  final int? monthlyFollowerGrowthTarget;
  final double? campaignConversionGoal;

  const BrandKPIs({
    this.monthlyRevenueTarget,
    this.monthlyFollowerGrowthTarget,
    this.campaignConversionGoal,
  });

  bool get isEmpty =>
      monthlyRevenueTarget == null &&
      monthlyFollowerGrowthTarget == null &&
      campaignConversionGoal == null;

  factory BrandKPIs.fromJson(Map<String, dynamic> json) => BrandKPIs(
        monthlyRevenueTarget: (json['monthlyRevenueTarget'] as num?)?.toDouble(),
        monthlyFollowerGrowthTarget: json['monthlyFollowerGrowthTarget'] as int?,
        campaignConversionGoal: (json['campaignConversionGoal'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (monthlyRevenueTarget != null) 'monthlyRevenueTarget': monthlyRevenueTarget,
        if (monthlyFollowerGrowthTarget != null) 'monthlyFollowerGrowthTarget': monthlyFollowerGrowthTarget,
        if (campaignConversionGoal != null) 'campaignConversionGoal': campaignConversionGoal,
      };
}

class SmartRotation {
  final int maxConsecutivePromoPosts;
  final int minGapBetweenPromotions;

  const SmartRotation({
    this.maxConsecutivePromoPosts = 2,
    this.minGapBetweenPromotions = 3,
  });

  factory SmartRotation.fromJson(Map<String, dynamic> json) => SmartRotation(
        maxConsecutivePromoPosts: (json['maxConsecutivePromoPosts'] as num?)?.toInt() ?? 2,
        minGapBetweenPromotions: (json['minGapBetweenPromotions'] as num?)?.toInt() ?? 3,
      );

  Map<String, dynamic> toJson() => {
        'maxConsecutivePromoPosts': maxConsecutivePromoPosts,
        'minGapBetweenPromotions': minGapBetweenPromotions,
      };
}

// ─────────────── Main Brand model ───────────────

class Brand {
  final String? id;

  // Identity
  final String name;
  final String? description;
  final BrandTone tone;
  final BrandAudience audience;
  final List<BrandPlatform> platforms;
  final List<String> contentPillars;

  // Strategic objective
  final BrandGoal? mainGoal;
  final BrandKPIs? kpis;

  // Content strategy
  final PostingFrequency? postingFrequency;
  final String? customPostingFrequency;
  final ContentMix? contentMix;

  // Monetization
  final List<RevenueType> revenueTypes;
  final PromotionIntensity? promotionIntensity;

  // Positioning
  final String? uniqueAngle;
  final String? mainPainPointSolved;

  // Competition & calendar
  final List<String> competitors;
  final BrandSeasonality? seasonality;

  // Smart rotation
  final SmartRotation? smartRotation;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Brand({
    this.id,
    required this.name,
    this.description,
    required this.tone,
    required this.audience,
    required this.platforms,
    required this.contentPillars,
    this.mainGoal,
    this.kpis,
    this.postingFrequency,
    this.customPostingFrequency,
    this.contentMix,
    this.revenueTypes = const [],
    this.promotionIntensity,
    this.uniqueAngle,
    this.mainPainPointSolved,
    this.competitors = const [],
    this.seasonality,
    this.smartRotation,
    this.createdAt,
    this.updatedAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    T? enumOrNull<T extends Enum>(List<T> values, dynamic raw) {
      if (raw == null) return null;
      return values.cast<T?>().firstWhere((e) => e?.name == raw, orElse: () => null);
    }

    return Brand(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      description: json['description'],
      tone: enumOrNull(BrandTone.values, json['tone']) ?? BrandTone.professional,
      audience: BrandAudience.fromJson(json['audience'] ?? {}),
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((e) => enumOrNull(BrandPlatform.values, e))
              .whereType<BrandPlatform>()
              .toList() ??
          [],
      contentPillars: List<String>.from(json['contentPillars'] ?? []),
      mainGoal: enumOrNull(BrandGoal.values, json['mainGoal']),
      kpis: json['kpis'] != null ? BrandKPIs.fromJson(json['kpis']) : null,
      postingFrequency: enumOrNull(PostingFrequency.values, json['postingFrequency']),
      customPostingFrequency: json['customPostingFrequency'],
      contentMix: json['contentMix'] != null ? ContentMix.fromJson(json['contentMix']) : null,
      revenueTypes: (json['revenueTypes'] as List<dynamic>?)
              ?.map((e) => enumOrNull(RevenueType.values, e))
              .whereType<RevenueType>()
              .toList() ??
          [],
      promotionIntensity: enumOrNull(PromotionIntensity.values, json['promotionIntensity']),
      uniqueAngle: json['uniqueAngle'],
      mainPainPointSolved: json['mainPainPointSolved'],
      competitors: List<String>.from(json['competitors'] ?? []),
      seasonality: enumOrNull(BrandSeasonality.values, json['seasonality']),
      smartRotation: json['smartRotation'] != null ? SmartRotation.fromJson(json['smartRotation']) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final hasKpis = kpis != null && !kpis!.isEmpty;
    return {
      'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
      'tone': tone.name,
      'audience': audience.toJson(),
      'platforms': platforms.map((e) => e.name).toList(),
      'contentPillars': contentPillars,
      if (mainGoal != null) 'mainGoal': mainGoal!.name,
      if (hasKpis) 'kpis': kpis!.toJson(),
      if (postingFrequency != null) 'postingFrequency': postingFrequency!.name,
      if (customPostingFrequency != null && customPostingFrequency!.isNotEmpty)
        'customPostingFrequency': customPostingFrequency,
      if (contentMix != null) 'contentMix': contentMix!.toJson(),
      if (revenueTypes.isNotEmpty) 'revenueTypes': revenueTypes.map((e) => e.name).toList(),
      if (promotionIntensity != null) 'promotionIntensity': promotionIntensity!.name,
      if (uniqueAngle != null && uniqueAngle!.isNotEmpty) 'uniqueAngle': uniqueAngle,
      if (mainPainPointSolved != null && mainPainPointSolved!.isNotEmpty)
        'mainPainPointSolved': mainPainPointSolved,
      if (competitors.isNotEmpty) 'competitors': competitors,
      if (seasonality != null) 'seasonality': seasonality!.name,
      if (smartRotation != null) 'smartRotation': smartRotation!.toJson(),
    };
  }
}
