import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../models/video.dart';

<<<<<<< HEAD
class VideoGeneratorService {
  /// Générer une vidéo via Pexels Videos API
=======
import '../models/video_generator_models.dart';

class VideoGeneratorService {
  /// Génère une idée de vidéo (script) à partir d'un prompt (Agent Full Access)
  static Future<VideoIdea> generateVideoIdeaFromPrompt({
    required String prompt,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse(ApiConfig.generateVideoIdeasUrl);

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'platform': 'InstagramReels',
          'duration': '30s',
          'goal': 'ViralEngagement',
          'creatorType': 'Influencer',
          'tone': 'Trendy',
          'language': 'French',
          'productName': 'Agent AI',
          'productCategory': 'Marketing',
          'keyBenefits': ['Orchestration AI'],
          'targetAudience': 'Entrepreneurs',
          'productDescription': prompt, // Corrected field name to match backend DTO
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The backend returns an array of ideas, we take the first one
        final List<dynamic> ideasJson = data is List ? data : (data['ideas'] ?? [data]);
        if (ideasJson.isEmpty) throw Exception('No video ideas generated');
        return VideoIdea.fromJson(ideasJson.first);
      } else {
        throw Exception('Failed to generate video idea: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [VideoGenerator] Error in generateVideoIdeaFromPrompt: $e');
      rethrow;
    }
  }

  /// Rechercher une vidéo via Pexels Videos API (Backend search)
>>>>>>> wassim
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

<<<<<<< HEAD
      final url = Uri.parse('${ApiConfig.baseUrl}/video-generator/generate');
=======
      final url = Uri.parse(ApiConfig.searchVideoUrl);
>>>>>>> wassim

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

<<<<<<< HEAD
      print('🎬 [VideoGenerator] Generating video...');
      print('🎬 [VideoGenerator] Query: $query');
      print('🎬 [VideoGenerator] Duration: $duration');
=======
      print('🎬 [VideoGenerator] Searching stock video...');
      print('🎬 [VideoGenerator] Query: $query');
>>>>>>> wassim
      print('🎬 [VideoGenerator] Orientation: $orientation');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
<<<<<<< HEAD
          'description': query,
          'category': category,
          'duration': duration,
=======
          'query': query,
>>>>>>> wassim
          'orientation': orientation,
        }),
      ).timeout(const Duration(seconds: 30));

      print('🎬 [VideoGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
<<<<<<< HEAD
        final video = Video.fromJson(data);
        print('✅ [VideoGenerator] Video generated: ${video.id}');
        print('✅ [VideoGenerator] Duration: ${video.durationFormatted}');
        print('✅ [VideoGenerator] Resolution: ${video.resolution}');
=======
        if (data == null) throw Exception('No video found for this query');
        final video = Video.fromJson(data);
        print('✅ [VideoGenerator] Video found: ${video.id}');
>>>>>>> wassim
        return video;
      } else {
        print('❌ [VideoGenerator] Error: ${response.statusCode}');
        print('❌ [VideoGenerator] Body: ${response.body}');
        throw Exception('Failed to generate video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [VideoGenerator] Exception: $e');
      rethrow;
    }
  }

  /// Récupérer l'historique des vidéos générées
  static Future<List<Video>> getHistory() async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-generator/history');

      print('📚 [VideoGenerator] Fetching history...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📚 [VideoGenerator] Status: ${response.statusCode}');
      print('📚 [VideoGenerator] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('📊 [VideoGenerator] Parsed data type: ${data.runtimeType}');
        
        // Gérer différents formats de réponse
        List<dynamic> list;
        if (data is List) {
          // Si c'est directement un array
          print('✅ [VideoGenerator] Response is direct List');
          list = data;
        } else if (data is Map && data.containsKey('videos')) {
          // Si c'est un objet avec clé 'videos'
          print('✅ [VideoGenerator] Response has "videos" key');
          list = data['videos'] as List;
        } else if (data is Map && data.containsKey('data')) {
          // Si c'est un objet avec clé 'data'
          print('✅ [VideoGenerator] Response has "data" key');
          list = data['data'] as List;
        } else {
          throw Exception('Format de réponse non reconnu: $data');
        }
        
        final videos = list.map((json) => Video.fromJson(json as Map<String, dynamic>)).toList();
        print('✅ [VideoGenerator] Found ${videos.length} videos');
        return videos;
      } else {
        print('❌ [VideoGenerator] Error: ${response.statusCode}');
        print('❌ [VideoGenerator] Body: ${response.body}');
        throw Exception('Failed to fetch history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [VideoGenerator] History error: $e');
      rethrow;
    }
  }

  /// Sauvegarder la vidéo dans un post
  static Future<void> saveVideoToPost(String blockId, Video video) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/content-blocks/$blockId/video');

      print('💾 [VideoGenerator] Saving video to post $blockId...');

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

      print('💾 [VideoGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ [VideoGenerator] Video saved to post');
      } else {
        throw Exception('Failed to save video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [VideoGenerator] Save error: $e');
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
