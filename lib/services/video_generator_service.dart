import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../models/video.dart';
import 'package:flutter/foundation.dart';

class VideoGeneratorService {
  /// Générer une vidéo via Pexels Videos API
  static Future<Video> generateVideo({
    required String description,
    String? category,
    String? specificObject,
    String? duration, // 'short', 'medium', 'long'
    String? orientation, // 'portrait', 'landscape', 'square'
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-generator/generate');

      // Construire la query optimale - priorité: objet spécifique > description
      String query = '';
      
      // Priorité 1: Objet spécifique (le plus important)
      if (specificObject != null && specificObject.isNotEmpty) {
        query = specificObject;
      }
      
      // Priorité 2: Description
      if (description.isNotEmpty) {
        if (query.isEmpty) {
          query = description;
        } else {
          query = '$query $description';
        }
      }
      
      // Priorité 3: Catégorie
      if (category != null && category.isNotEmpty) {
        if (query.isEmpty) {
          query = category;
        } else {
          query = '$query $category';
        }
      }

      debugPrint('🎬 [VideoGenerator] Generating video...');
      debugPrint('🎬 [VideoGenerator] Query: $query');
      debugPrint('🎬 [VideoGenerator] Duration: $duration');
      debugPrint('🎬 [VideoGenerator] Orientation: $orientation');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'description': query,
          'category': category,
          'duration': duration,
          'orientation': orientation,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('🎬 [VideoGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final video = Video.fromJson(data);
        debugPrint('✅ [VideoGenerator] Video generated: ${video.id}');
        debugPrint('✅ [VideoGenerator] Duration: ${video.durationFormatted}');
        debugPrint('✅ [VideoGenerator] Resolution: ${video.resolution}');
        return video;
      } else {
        debugPrint('❌ [VideoGenerator] Error: ${response.statusCode}');
        debugPrint('❌ [VideoGenerator] Body: ${response.body}');
        throw Exception('Failed to generate video: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoGenerator] Exception: $e');
      rethrow;
    }
  }

  /// Récupérer l'historique des vidéos générées
  static Future<List<Video>> getHistory() async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-generator/history');

      debugPrint('📚 [VideoGenerator] Fetching history...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📚 [VideoGenerator] Status: ${response.statusCode}');
      debugPrint('📚 [VideoGenerator] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        debugPrint('📊 [VideoGenerator] Parsed data type: ${data.runtimeType}');
        
        // Gérer différents formats de réponse
        List<dynamic> list;
        if (data is List) {
          // Si c'est directement un array
          debugPrint('✅ [VideoGenerator] Response is direct List');
          list = data;
        } else if (data is Map && data.containsKey('videos')) {
          // Si c'est un objet avec clé 'videos'
          debugPrint('✅ [VideoGenerator] Response has "videos" key');
          list = data['videos'] as List;
        } else if (data is Map && data.containsKey('data')) {
          // Si c'est un objet avec clé 'data'
          debugPrint('✅ [VideoGenerator] Response has "data" key');
          list = data['data'] as List;
        } else {
          throw Exception('Format de réponse non reconnu: $data');
        }
        
        final videos = list.map((json) => Video.fromJson(json as Map<String, dynamic>)).toList();
        debugPrint('✅ [VideoGenerator] Found ${videos.length} videos');
        return videos;
      } else {
        debugPrint('❌ [VideoGenerator] Error: ${response.statusCode}');
        debugPrint('❌ [VideoGenerator] Body: ${response.body}');
        throw Exception('Failed to fetch history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [VideoGenerator] History error: $e');
      rethrow;
    }
  }

  /// Sauvegarder la vidéo dans un post
  static Future<void> saveVideoToPost(String blockId, Video video) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/content-blocks/$blockId/video');

      debugPrint('💾 [VideoGenerator] Saving video to post $blockId...');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'videoUrl': video.videoUrl,
          'videoThumbnail': video.thumbnailUrl,
          'videoDuration': video.duration,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('💾 [VideoGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [VideoGenerator] Video saved to post');
      } else {
        throw Exception('Failed to save video: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoGenerator] Save error: $e');
      rethrow;
    }
  }

  /// Détecter la catégorie depuis la description de la marque
  static String detectCategory(String brandDescription) {
    final desc = brandDescription.toLowerCase();

    if (desc.contains('cosmetic') ||
        desc.contains('makeup') ||
        desc.contains('beauty') ||
        desc.contains('skincare') ||
        desc.contains('parfum')) {
      return 'cosmetics';
    } else if (desc.contains('sport') ||
        desc.contains('fitness') ||
        desc.contains('gym') ||
        desc.contains('training')) {
      return 'sports';
    } else if (desc.contains('fashion') ||
        desc.contains('vêtement') ||
        desc.contains('mode') ||
        desc.contains('clothing')) {
      return 'fashion';
    } else if (desc.contains('food') ||
        desc.contains('cuisine') ||
        desc.contains('restaurant') ||
        desc.contains('nourriture')) {
      return 'food';
    } else if (desc.contains('tech') ||
        desc.contains('digital') ||
        desc.contains('software') ||
        desc.contains('app')) {
      return 'technology';
    } else if (desc.contains('travel') ||
        desc.contains('voyage') ||
        desc.contains('tourism')) {
      return 'travel';
    }

    return 'lifestyle';
  }
}
