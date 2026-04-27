class VideoRequest {
  final Platform platform;
  final DurationOption duration;
  final VideoGoal goal;
  final CreatorType creatorType;
  final VideoTone tone;
  final VideoLanguage language;
  final String productName;
  final String productCategory;
  final List<String> keyBenefits;
  final String targetAudience;
  final String? price;
  final String? offer;
  final String? painPoint;
  final int batchSize;

  // Enhanced fields
  final String? productImagePath;
  final List<String>? ingredients;
  final List<String>? productFeatures;
  final String? useCases;
  final String? ageRange;
  final String? uniqueSellingPoint;
  final String? socialProof;

  VideoRequest({
    required this.platform,
    required this.duration,
    required this.goal,
    required this.creatorType,
    required this.tone,
    required this.language,
    required this.productName,
    required this.productCategory,
    required this.keyBenefits,
    required this.targetAudience,
    this.price,
    this.offer,
    this.painPoint,
    this.batchSize = 1,
    this.productImagePath,
    this.ingredients,
    this.productFeatures,
    this.useCases,
    this.ageRange,
    this.uniqueSellingPoint,
    this.socialProof,
  });
}

class VideoIdea {
  final String id;
  final List<VideoVersion> versions;
  final int currentVersionIndex;
  final String? productImageUrl;
  final String? userId;
  final bool isApproved;
  final bool isFavorite;
  final DateTime createdAt;

  VideoIdea({
    required this.id,
    required this.versions,
    this.currentVersionIndex = 0,
    this.productImageUrl,
    this.userId,
    this.isApproved = false,
    this.isFavorite = false,
    required this.createdAt,
  });

  VideoVersion get currentVersion => versions[currentVersionIndex];

  // Convenience getters for current version fields
  String get title => currentVersion.title;
  String get hook => currentVersion.hook;
  String get script => currentVersion.script;
  List<VideoScene> get scenes => currentVersion.scenes;
  String get cta => currentVersion.cta;
  String get caption => currentVersion.caption;
  List<String> get hashtags => currentVersion.hashtags;
  String get thumbnailText => currentVersion.thumbnailText;
  String get filmingNotes => currentVersion.filmingNotes;
  String get complianceNote => currentVersion.complianceNote;
  List<String> get suggestedLocations => currentVersion.suggestedLocations;
  List<LocationHook> get locationHooks => currentVersion.locationHooks;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'versions': versions.map((x) => x.toJson()).toList(),
      'currentVersionIndex': currentVersionIndex,
      'productImageUrl': productImageUrl,
      'userId': userId,
      'isApproved': isApproved,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VideoIdea.fromJson(Map<String, dynamic> map) {
    // Backend generate endpoint returns flat objects (title, hook, script, ...)
    // while saved/refined ideas have a nested versions array.
    List<VideoVersion> versions;
    if (map['versions'] != null && (map['versions'] as List).isNotEmpty) {
      versions = List<VideoVersion>.from(
          (map['versions'] as List).map((x) => VideoVersion.fromJson(x)));
    } else if (map['title'] != null || map['hook'] != null || map['script'] != null) {
      // Flat format from backend — wrap into a single version
      versions = [VideoVersion.fromJson(map)];
    } else {
      versions = [];
    }

    return VideoIdea(
      id: map['_id'] ?? (map['id'] ?? (map['id']?.toString() ?? '${DateTime.now().millisecondsSinceEpoch}')),
      versions: versions,
      currentVersionIndex: map['currentVersionIndex'] ?? 0,
      productImageUrl: map['productImageUrl'],
      userId: map['userId'],
      isApproved: map['isApproved'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class VideoVersion {
  final String title;
  final String hook;
  final String script;
  final List<VideoScene> scenes;
  final String cta;
  final String caption;
  final List<String> hashtags;
  final String thumbnailText;
  final String filmingNotes;
  final String complianceNote;
  final List<String> suggestedLocations;
  final List<LocationHook> locationHooks;
  final String? refinementInstruction;
  final DateTime createdAt;

  VideoVersion({
    required this.title,
    required this.hook,
    required this.script,
    required this.scenes,
    required this.cta,
    required this.caption,
    required this.hashtags,
    required this.thumbnailText,
    required this.filmingNotes,
    required this.complianceNote,
    required this.suggestedLocations,
    required this.locationHooks,
    this.refinementInstruction,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'hook': hook,
      'script': script,
      'scenes': scenes.map((x) => x.toJson()).toList(),
      'cta': cta,
      'caption': caption,
      'hashtags': hashtags,
      'thumbnailText': thumbnailText,
      'filmingNotes': filmingNotes,
      'complianceNote': complianceNote,
      'suggestedLocations': suggestedLocations,
      'locationHooks': locationHooks.map((x) => x.toJson()).toList(),
      'refinementInstruction': refinementInstruction,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VideoVersion.fromJson(Map<String, dynamic> map) {
    return VideoVersion(
      title: map['title'] ?? '',
      hook: map['hook'] ?? '',
      script: map['script'] ?? '',
      scenes: List<VideoScene>.from(
          map['scenes']?.map((x) => VideoScene.fromJson(x)) ?? []),
      cta: map['cta'] ?? '',
      caption: map['caption'] ?? '',
      hashtags: List<String>.from(map['hashtags'] ?? []),
      thumbnailText: map['thumbnailText'] ?? '',
      filmingNotes: map['filmingNotes'] ?? '',
      complianceNote: map['complianceNote'] ?? '',
      suggestedLocations: List<String>.from(map['suggestedLocations'] ?? []),
      locationHooks: List<LocationHook>.from(
          map['locationHooks']?.map((x) => LocationHook.fromJson(x)) ?? []),
      refinementInstruction: map['refinementInstruction'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class LocationHook {
  final String location;
  final String hook;

  LocationHook({required this.location, required this.hook});

  Map<String, dynamic> toJson() => {'location': location, 'hook': hook};

  factory LocationHook.fromJson(Map<String, dynamic> map) {
    return LocationHook(
      location: map['location'] ?? '',
      hook: map['hook'] ?? '',
    );
  }
}

class VideoScene {
  final int startSec;
  final int endSec;
  final SceneType shotType;
  final String description;
  final String onScreenText;
  final String voiceOver;

  VideoScene({
    required this.startSec,
    required this.endSec,
    required this.shotType,
    required this.description,
    required this.onScreenText,
    required this.voiceOver,
  });

  Map<String, dynamic> toJson() {
    return {
      'startSec': startSec,
      'endSec': endSec,
      'shotType': shotType.name,
      'description': description,
      'onScreenText': onScreenText,
      'voiceOver': voiceOver,
    };
  }

  factory VideoScene.fromJson(Map<String, dynamic> map) {
    return VideoScene(
      startSec: map['startSec'] ?? 0,
      endSec: map['endSec'] ?? 0,
      shotType: SceneType.values.firstWhere(
        (e) => e.name == map['shotType'],
        orElse: () => SceneType.aRoll,
      ),
      description: map['description'] ?? '',
      onScreenText: map['onScreenText'] ?? '',
      voiceOver: map['voiceOver'] ?? '',
    );
  }
}

enum Platform {
  tikTok,
  instagramReels,
  youTubeShorts,
  youTubeLong,
}

enum DurationOption {
  s15(15),
  s30(30),
  s60(60),
  s90(90);

  final int seconds;
  const DurationOption(this.seconds);
}

enum VideoGoal {
  sellProduct,
  brandAwareness,
  ugcReview,
  offerPromo,
  education,
  viralEngagement,
}

enum CreatorType {
  ecommerceBrand,
  influencer,
}

enum VideoTone {
  trendy,
  professional,
  emotional,
  funny,
  luxury,
  directResponse,
}

enum VideoLanguage {
  french('fr'),
  english('en'),
  arabic('ar'); // Tunisian-friendly

  final String code;
  const VideoLanguage(this.code);
}

enum SceneType {
  aRoll,
  bRoll,
  productCloseUp,
  testimonial,
  screenText,
}
enum ShotType {
  aRoll,
  bRoll,
  productCloseUp,
  testimonial,
  screenText,
}

