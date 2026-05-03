enum PostStatus {
  scheduled,
  publishing,
  published,
  failed,
  cancelled,
}

enum SocialPlatform {
  instagram,
  tiktok,
  facebook,
  twitter,
  linkedin,
  youtube,
}

class SocialAccount {
  final String id;
  final String name;
  final SocialPlatform platform;
  final String username;
  final String? profileImageUrl;
  final bool isConnected;
  final String? accessToken;

  SocialAccount({
    required this.id,
    required this.name,
    required this.platform,
    required this.username,
    this.profileImageUrl,
    this.isConnected = false,
    this.accessToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform.name,
        'username': username,
        'profileImageUrl': profileImageUrl,
        'isConnected': isConnected,
        'accessToken': accessToken,
      };

  factory SocialAccount.fromJson(Map<String, dynamic> json) => SocialAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        platform: SocialPlatform.values.firstWhere(
          (e) => e.name == json['platform'],
          orElse: () => SocialPlatform.instagram,
        ),
        username: json['username'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        isConnected: json['isConnected'] as bool? ?? false,
        accessToken: json['accessToken'] as String?,
      );
}

class ShareStats {
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final double engagementRate;
  final DateTime lastUpdated;

  ShareStats({
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.shares = 0,
    this.saves = 0,
    this.engagementRate = 0.0,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
        'views': views,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'saves': saves,
        'engagementRate': engagementRate,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory ShareStats.fromJson(Map<String, dynamic> json) => ShareStats(
        views: json['views'] as int? ?? 0,
        likes: json['likes'] as int? ?? 0,
        comments: json['comments'] as int? ?? 0,
        shares: json['shares'] as int? ?? 0,
        saves: json['saves'] as int? ?? 0,
        engagementRate: (json['engagementRate'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );

  int get totalEngagement => likes + comments + shares + saves;
}

class ScheduledPost {
  final String id;
  final String contentId; // ID de l'image ou vidéo
  final String contentType; // 'image' ou 'video'
  final String contentUrl; // URL du contenu
  final String caption;
  final List<String> hashtags;
  final List<SocialPlatform> platforms;
  final List<String> accountIds;
  final DateTime scheduledTime;
  final PostStatus status;
  final Map<SocialPlatform, ShareStats>? platformStats; // Stats par plateforme
  final String? errorMessage; // Message d'erreur si échec
  final DateTime createdAt;
  final DateTime? publishedAt;

  ScheduledPost({
    required this.id,
    required this.contentId,
    required this.contentType,
    required this.contentUrl,
    required this.caption,
    this.hashtags = const [],
    required this.platforms,
    required this.accountIds,
    required this.scheduledTime,
    this.status = PostStatus.scheduled,
    this.platformStats,
    this.errorMessage,
    required this.createdAt,
    this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contentId': contentId,
        'contentType': contentType,
        'contentUrl': contentUrl,
        'caption': caption,
        'hashtags': hashtags,
        'platforms': platforms.map((e) => e.name).toList(),
        'accountIds': accountIds,
        'scheduledTime': scheduledTime.toIso8601String(),
        'status': status.name,
        'platformStats': platformStats?.map(
          (key, value) => MapEntry(key.name, value.toJson()),
        ),
        'errorMessage': errorMessage,
        'createdAt': createdAt.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
      };

  factory ScheduledPost.fromJson(Map<String, dynamic> json) => ScheduledPost(
        id: (json['id'] ?? json['_id']) as String,
        contentId: json['contentId'] as String,
        contentType: json['contentType'] as String,
        contentUrl: json['contentUrl'] as String,
        caption: json['caption'] as String,
        hashtags: (json['hashtags'] as List?)?.cast<String>() ?? [],
        platforms: (json['platforms'] as List?)
                ?.map((e) => SocialPlatform.values.firstWhere(
                      (platform) => platform.name == e,
                      orElse: () => SocialPlatform.instagram,
                    ))
                .toList() ??
            [],
        accountIds: (json['accountIds'] as List?)?.cast<String>() ?? [],
        scheduledTime: DateTime.parse(json['scheduledTime'] as String),
        status: PostStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PostStatus.scheduled,
        ),
        platformStats: (json['platformStats'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(
            SocialPlatform.values.firstWhere((e) => e.name == key),
            ShareStats.fromJson(value as Map<String, dynamic>),
          ),
        ),
        errorMessage: json['errorMessage'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String)
            : null,
      );

  ScheduledPost copyWith({
    String? id,
    String? contentId,
    String? contentType,
    String? contentUrl,
    String? caption,
    List<String>? hashtags,
    List<SocialPlatform>? platforms,
    List<String>? accountIds,
    DateTime? scheduledTime,
    PostStatus? status,
    Map<SocialPlatform, ShareStats>? platformStats,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? publishedAt,
  }) =>
      ScheduledPost(
        id: id ?? this.id,
        contentId: contentId ?? this.contentId,
        contentType: contentType ?? this.contentType,
        contentUrl: contentUrl ?? this.contentUrl,
        caption: caption ?? this.caption,
        hashtags: hashtags ?? this.hashtags,
        platforms: platforms ?? this.platforms,
        accountIds: accountIds ?? this.accountIds,
        scheduledTime: scheduledTime ?? this.scheduledTime,
        status: status ?? this.status,
        platformStats: platformStats ?? this.platformStats,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        publishedAt: publishedAt ?? this.publishedAt,
      );

  // Calculer les stats totales de toutes les plateformes
  ShareStats get totalStats {
    if (platformStats == null || platformStats!.isEmpty) {
      return ShareStats(lastUpdated: DateTime.now());
    }

    int totalViews = 0;
    int totalLikes = 0;
    int totalComments = 0;
    int totalShares = 0;
    int totalSaves = 0;
    DateTime latestUpdate = DateTime.fromMillisecondsSinceEpoch(0);

    for (final stats in platformStats!.values) {
      totalViews += stats.views;
      totalLikes += stats.likes;
      totalComments += stats.comments;
      totalShares += stats.shares;
      totalSaves += stats.saves;
      if (stats.lastUpdated.isAfter(latestUpdate)) {
        latestUpdate = stats.lastUpdated;
      }
    }

    final totalEngagement = totalLikes + totalComments + totalShares + totalSaves;
    final engagementRate = totalViews > 0 ? (totalEngagement / totalViews) * 100 : 0.0;

    return ShareStats(
      views: totalViews,
      likes: totalLikes,
      comments: totalComments,
      shares: totalShares,
      saves: totalSaves,
      engagementRate: engagementRate,
      lastUpdated: latestUpdate,
    );
  }

  // Vérifier si le post est en retard
  bool get isOverdue {
    return status == PostStatus.scheduled && DateTime.now().isAfter(scheduledTime);
  }

  // Temps restant avant publication
  Duration? get timeUntilPublication {
    if (status != PostStatus.scheduled) return null;
    final now = DateTime.now();
    if (now.isAfter(scheduledTime)) return null;
    return scheduledTime.difference(now);
  }
}

// Hashtags populaires par catégorie
class PopularHashtags {
  static const Map<String, List<String>> byCategory = {
    'cosmetics': [
      '#makeup',
      '#beauty',
      '#skincare',
      '#cosmetics',
      '#makeupartist',
      '#beautytips',
      '#glowup',
      '#selfcare',
      '#beautyproducts',
      '#makeuplover',
    ],
    'sports': [
      '#fitness',
      '#workout',
      '#sports',
      '#training',
      '#gym',
      '#fitnessmotivation',
      '#healthylifestyle',
      '#exercise',
      '#athlete',
      '#fitlife',
    ],
    'fashion': [
      '#fashion',
      '#style',
      '#outfit',
      '#ootd',
      '#fashionista',
      '#streetstyle',
      '#trend',
      '#fashionblogger',
      '#stylish',
      '#clothing',
    ],
    'food': [
      '#food',
      '#foodie',
      '#delicious',
      '#yummy',
      '#cooking',
      '#recipe',
      '#foodporn',
      '#instafood',
      '#chef',
      '#cuisine',
    ],
    'technology': [
      '#tech',
      '#technology',
      '#innovation',
      '#digital',
      '#gadgets',
      '#software',
      '#app',
      '#startup',
      '#ai',
      '#future',
    ],
    'travel': [
      '#travel',
      '#vacation',
      '#adventure',
      '#explore',
      '#wanderlust',
      '#trip',
      '#tourism',
      '#destination',
      '#journey',
      '#travelgram',
    ],
    'lifestyle': [
      '#lifestyle',
      '#life',
      '#inspiration',
      '#motivation',
      '#happiness',
      '#wellness',
      '#mindfulness',
      '#positivity',
      '#goals',
      '#success',
    ],
  };

  static List<String> getHashtagsForCategory(String category) {
    return byCategory[category.toLowerCase()] ?? byCategory['lifestyle']!;
  }
}