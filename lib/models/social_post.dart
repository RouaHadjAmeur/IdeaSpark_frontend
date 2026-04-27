import '../services/auth_service.dart';

class SocialPost {
  final String id;
  final String content;
  final String source; // 'video' | 'slogan'
  final Map<String, dynamic>? sourceData;
  final List<String> hashtags;
  final String status; // 'draft' | 'published'
  final DateTime? publishedAt;
  final DateTime createdAt;
  final AppUser? user; // Populated from backend

  SocialPost({
    required this.id,
    required this.content,
    required this.source,
    this.sourceData,
    required this.hashtags,
    required this.status,
    this.publishedAt,
    required this.createdAt,
    this.user,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    return SocialPost(
      id: (json['id'] as String?) ?? (json['_id'] as String?) ?? '',
      content: json['content'] as String? ?? '',
      source: json['source'] as String? ?? 'video',
      sourceData: json['sourceData'] as Map<String, dynamic>?,
      hashtags: (json['hashtags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] as String? ?? 'draft',
      publishedAt: json['publishedAt'] != null ? DateTime.parse(json['publishedAt']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      user: json['userId'] != null && json['userId'] is Map<String, dynamic>
          ? AppUser.fromJson(json['userId'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'source': source,
      'sourceData': sourceData,
      'hashtags': hashtags,
      'status': status,
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}
