import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../services/auth_service.dart';

class InstagramInsights {
  final int? views;
  final int? interactions;
  final int? newFollowers;
  final int? contentShared;

  InstagramInsights({
    this.views,
    this.interactions,
    this.newFollowers,
    this.contentShared,
  });
}

class InstagramInsightsService {
  final AuthService _authService = AuthService();

  Future<InstagramInsights?> fetchInsights() async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/instagram-auth/insights'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) return null;
        return InstagramInsights(
          views: data['views'] as int?,
          interactions: data['interactions'] as int?,
          newFollowers: data['newFollowers'] as int?,
          contentShared: data['contentShared'] as int?,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<InstagramViewsDetails?> fetchViewsDetails() async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/instagram-auth/insights/views'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) return null;
        return InstagramViewsDetails.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<InstagramInteractionsDetails?> fetchInteractionsDetails() async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/instagram-auth/insights/interactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) return null;
        return InstagramInteractionsDetails.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<InstagramFollowersDetails?> fetchFollowersDetails() async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/instagram-auth/insights/followers'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) return null;
        return InstagramFollowersDetails.fromJson(data);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<TrendingAudioItem>> fetchTrendingAudio() async {
    try {
      final token = _authService.accessToken;
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/instagram-auth/insights/trending-audio'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((json) => TrendingAudioItem.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}

class TopContentItem {
  final String id;
  final String mediaType;
  final String thumbnailUrl;
  final String timestamp;
  final int views;

  TopContentItem({
    required this.id,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.timestamp,
    required this.views,
  });

  factory TopContentItem.fromJson(Map<String, dynamic> json) {
    return TopContentItem(
      id: json['id'] ?? '',
      mediaType: json['mediaType'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      timestamp: json['timestamp'] ?? '',
      views: json['views'] ?? 0,
    );
  }
}

class InstagramViewsDetails {
  final int totalViews;
  final int accountsReached;
  final double reelsPercentage;
  final double postsPercentage;
  final int profileVisits;
  final int externalLinkTaps;
  final List<TopContentItem> topContent;

  InstagramViewsDetails({
    required this.totalViews,
    required this.accountsReached,
    required this.reelsPercentage,
    required this.postsPercentage,
    required this.profileVisits,
    required this.externalLinkTaps,
    required this.topContent,
  });

  factory InstagramViewsDetails.fromJson(Map<String, dynamic> json) {
    var contentList = json['topContent'] as List? ?? [];
    List<TopContentItem> parsedContent = contentList.map((i) => TopContentItem.fromJson(i)).toList();

    return InstagramViewsDetails(
      totalViews: json['totalViews'] ?? 0,
      accountsReached: json['accountsReached'] ?? 0,
      reelsPercentage: (json['reelsPercentage'] ?? 0).toDouble(),
      postsPercentage: (json['postsPercentage'] ?? 0).toDouble(),
      profileVisits: json['profileVisits'] ?? 0,
      externalLinkTaps: json['externalLinkTaps'] ?? 0,
      topContent: parsedContent,
    );
  }
}

class InteractionContentItem {
  final String id;
  final String mediaType;
  final String thumbnailUrl;
  final String timestamp;
  final int interactions;
  final int likes;
  final int comments;

  InteractionContentItem({
    required this.id,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.timestamp,
    required this.interactions,
    required this.likes,
    required this.comments,
  });

  factory InteractionContentItem.fromJson(Map<String, dynamic> json) {
    return InteractionContentItem(
      id: json['id'] ?? '',
      mediaType: json['mediaType'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      timestamp: json['timestamp'] ?? '',
      interactions: json['interactions'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
    );
  }
}

class InstagramInteractionsDetails {
  final int totalInteractions;
  final int likes;
  final int comments;
  final int saves;
  final double reelsPercentage;
  final double postsPercentage;
  final int reelsLikes;
  final int reelsComments;
  final int reelsSaves;
  final int postsLikes;
  final int postsComments;
  final int postsSaves;
  final List<InteractionContentItem> topReels;
  final List<InteractionContentItem> topPosts;

  InstagramInteractionsDetails({
    required this.totalInteractions,
    required this.likes,
    required this.comments,
    required this.saves,
    required this.reelsPercentage,
    required this.postsPercentage,
    required this.reelsLikes,
    required this.reelsComments,
    required this.reelsSaves,
    required this.postsLikes,
    required this.postsComments,
    required this.postsSaves,
    required this.topReels,
    required this.topPosts,
  });

  factory InstagramInteractionsDetails.fromJson(Map<String, dynamic> json) {
    var reelsList = json['topReels'] as List? ?? [];
    List<InteractionContentItem> parsedReels = reelsList.map((i) => InteractionContentItem.fromJson(i)).toList();

    var postsList = json['topPosts'] as List? ?? [];
    List<InteractionContentItem> parsedPosts = postsList.map((i) => InteractionContentItem.fromJson(i)).toList();

    return InstagramInteractionsDetails(
      totalInteractions: json['totalInteractions'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      saves: json['saves'] ?? 0,
      reelsPercentage: (json['reelsPercentage'] ?? 0).toDouble(),
      postsPercentage: (json['postsPercentage'] ?? 0).toDouble(),
      reelsLikes: json['reelsLikes'] ?? 0,
      reelsComments: json['reelsComments'] ?? 0,
      reelsSaves: json['reelsSaves'] ?? 0,
      postsLikes: json['postsLikes'] ?? 0,
      postsComments: json['postsComments'] ?? 0,
      postsSaves: json['postsSaves'] ?? 0,
      topReels: parsedReels,
      topPosts: parsedPosts,
    );
  }
}

class DemographicItem {
  final String label;
  final double value;

  DemographicItem({required this.label, required this.value});

  factory DemographicItem.fromJson(Map<String, dynamic> json) {
    return DemographicItem(
      label: json['label'] ?? '',
      value: (json['percentage'] ?? json['value'] ?? 0).toDouble(),
    );
  }
}

class InstagramFollowersDetails {
  final int totalFollowers;
  final bool hasDemographics;
  final List<DemographicItem> genderSplit;
  final List<DemographicItem> ageRanges;
  final List<DemographicItem> activeTimes;

  InstagramFollowersDetails({
    required this.totalFollowers,
    required this.hasDemographics,
    required this.genderSplit,
    required this.ageRanges,
    required this.activeTimes,
  });

  factory InstagramFollowersDetails.fromJson(Map<String, dynamic> json) {
    var genderList = json['genderSplit'] as List? ?? [];
    List<DemographicItem> parsedGender = genderList.map((i) => DemographicItem.fromJson(i)).toList();

    var ageList = json['ageRanges'] as List? ?? [];
    List<DemographicItem> parsedAge = ageList.map((i) => DemographicItem.fromJson(i)).toList();

    var timeList = json['activeTimes'] as List? ?? [];
    List<DemographicItem> parsedTime = timeList.map((i) => DemographicItem.fromJson(i)).toList();

    return InstagramFollowersDetails(
      totalFollowers: json['totalFollowers'] ?? 0,
      hasDemographics: json['hasDemographics'] ?? false,
      genderSplit: parsedGender,
      ageRanges: parsedAge,
      activeTimes: parsedTime,
    );
  }
}

class TrendingAudioItem {
  final int rank;
  final String direction; // 'up', 'down', 'new'
  final String title;
  final String artist;
  final String reelsCount;
  final String imageUrl;
  final String? previewUrl;
  final String? isrc;

  TrendingAudioItem({
    required this.rank,
    required this.direction,
    required this.title,
    required this.artist,
    required this.reelsCount,
    required this.imageUrl,
    this.previewUrl,
    this.isrc,
  });

  factory TrendingAudioItem.fromJson(Map<String, dynamic> json) {
    return TrendingAudioItem(
      rank: json['rank'] ?? 0,
      direction: json['direction'] ?? 'new',
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      reelsCount: json['reelsCount'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      previewUrl: json['previewUrl'] ?? json['audioUrl'],
      isrc: json['isrc'],
    );
  }
}
