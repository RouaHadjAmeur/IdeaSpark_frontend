import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/api_config.dart';
import '../services/auth_service.dart';

class TrendingHashtag {
  final String name;
  final String? views;
  final String? trend;
  final String category;
  final String platform;

  TrendingHashtag({
    required this.name,
    this.views,
    this.trend,
    required this.category,
    required this.platform,
  });

  factory TrendingHashtag.fromJson(Map<String, dynamic> json) {
    return TrendingHashtag(
      name: json['name'] ?? '',
      views: json['views'],
      trend: json['trend'],
      category: json['category'] ?? '',
      platform: json['platform'] ?? '',
    );
  }
}

class TrendingHashtagsService {
  /// Récupérer les hashtags tendances pour une catégorie
  static Future<List<TrendingHashtag>> getTrendingHashtags({
    required String category,
    String platform = 'instagram',
    String country = 'FR',
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/trending-hashtags?category=$category&platform=$platform&country=$country',
      );

      print('📊 [TrendingHashtags] Fetching: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 [TrendingHashtags] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final hashtags = data.map((json) => TrendingHashtag.fromJson(json)).toList();
        print('✅ [TrendingHashtags] Received ${hashtags.length} hashtags');
        return hashtags;
      } else {
        throw Exception('Failed to fetch trending hashtags: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [TrendingHashtags] Error: $e');
      rethrow;
    }
  }

  /// Générer des hashtags pour un post spécifique
  static Future<List<String>> generateHashtags({
    required String brandName,
    required String postTitle,
    required String category,
    String platform = 'instagram',
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final encodedBrand = Uri.encodeComponent(brandName);
      final encodedTitle = Uri.encodeComponent(postTitle);
      
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/trending-hashtags/generate?brandName=$encodedBrand&postTitle=$encodedTitle&category=$category&platform=$platform',
      );

      print('📊 [TrendingHashtags] Generating hashtags: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 [TrendingHashtags] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<String> hashtags = List<String>.from(data['hashtags'] ?? []);
        print('✅ [TrendingHashtags] Generated ${hashtags.length} hashtags');
        return hashtags;
      } else {
        throw Exception('Failed to generate hashtags: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [TrendingHashtags] Error: $e');
      rethrow;
    }
  }

  /// Détecter la catégorie à partir de la description de la marque
  static String detectCategory(String? brandDescription) {
    if (brandDescription == null) return 'lifestyle';
    
    final desc = brandDescription.toLowerCase();
    
    if (desc.contains('cosmetic') || desc.contains('makeup') || 
        desc.contains('beauty') || desc.contains('skincare')) {
      return 'cosmetics';
    } else if (desc.contains('sport') || desc.contains('fitness') || 
               desc.contains('athletic')) {
      return 'sports';
    } else if (desc.contains('fashion') || desc.contains('clothing') || 
               desc.contains('apparel')) {
      return 'fashion';
    } else if (desc.contains('food') || desc.contains('restaurant') || 
               desc.contains('cuisine')) {
      return 'food';
    } else if (desc.contains('tech') || desc.contains('software') || 
               desc.contains('digital')) {
      return 'technology';
    }
    
    return 'lifestyle';
  }
}
