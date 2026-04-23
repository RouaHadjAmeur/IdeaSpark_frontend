import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../models/video_generator_models.dart';
import 'package:flutter/foundation.dart';

class VideoIdeaGeneratorService {
  /// Générer des idées de vidéo
  Future<List<VideoIdea>> generateIdeas(VideoRequest request, {bool useRemote = false}) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/generate');

      debugPrint('💡 [VideoIdeaGenerator] Generating ideas...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productName': request.productName,
          'productCategory': request.productCategory,
          'platform': request.platform.name,
          'duration': request.duration.seconds,
          'goal': request.goal.name,
          'tone': request.tone.name,
          'language': request.language.code,
          'targetAudience': request.targetAudience,
          'keyBenefits': request.keyBenefits,
          'batchSize': request.batchSize,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('💡 [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final ideas = (data['ideas'] as List?)
            ?.map((json) => VideoIdea.fromJson(json))
            .toList() ?? [];
        debugPrint('✅ [VideoIdeaGenerator] Generated ${ideas.length} ideas');
        return ideas;
      } else {
        throw Exception('Failed to generate ideas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Error: $e');
      rethrow;
    }
  }

  /// Sauvegarder une idée
  Future<VideoIdea> saveIdea(VideoIdea idea) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/save');

      debugPrint('💾 [VideoIdeaGenerator] Saving idea...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(idea.toJson()),
      ).timeout(const Duration(seconds: 10));

      debugPrint('💾 [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final savedIdea = VideoIdea.fromJson(data);
        debugPrint('✅ [VideoIdeaGenerator] Idea saved with ID: ${savedIdea.id}');
        return savedIdea;
      } else {
        throw Exception('Failed to save idea: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Save error: $e');
      rethrow;
    }
  }

  /// Affiner une idée
  Future<VideoIdea> refineIdea(String ideaId, String instruction) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/$ideaId/refine');

      debugPrint('✨ [VideoIdeaGenerator] Refining idea...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'instruction': instruction,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('✨ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final refinedIdea = VideoIdea.fromJson(data);
        debugPrint('✅ [VideoIdeaGenerator] Idea refined');
        return refinedIdea;
      } else {
        throw Exception('Failed to refine idea: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Refine error: $e');
      rethrow;
    }
  }

  /// Approuver une version d'idée
  Future<VideoIdea> approveVersion(String ideaId, int versionIndex) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/$ideaId/approve');

      debugPrint('👍 [VideoIdeaGenerator] Approving version...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'versionIndex': versionIndex,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('👍 [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final approvedIdea = VideoIdea.fromJson(data);
        debugPrint('✅ [VideoIdeaGenerator] Version approved');
        return approvedIdea;
      } else {
        throw Exception('Failed to approve version: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Approve error: $e');
      rethrow;
    }
  }

  /// Récupérer l'historique des idées
  Future<List<VideoIdea>> getHistory() async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/history');

      debugPrint('📚 [VideoIdeaGenerator] Fetching history...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📚 [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ideas = (data['ideas'] as List?)
            ?.map((json) => VideoIdea.fromJson(json))
            .toList() ?? [];
        debugPrint('✅ [VideoIdeaGenerator] Found ${ideas.length} ideas');
        return ideas;
      } else {
        throw Exception('Failed to fetch history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] History error: $e');
      rethrow;
    }
  }

  /// Récupérer les idées favorites
  Future<List<VideoIdea>> getFavorites() async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/favorites');

      debugPrint('⭐ [VideoIdeaGenerator] Fetching favorites...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('⭐ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final favorites = (data['favorites'] as List?)
            ?.map((json) => VideoIdea.fromJson(json))
            .toList() ?? [];
        debugPrint('✅ [VideoIdeaGenerator] Found ${favorites.length} favorites');
        return favorites;
      } else {
        throw Exception('Failed to fetch favorites: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Favorites error: $e');
      rethrow;
    }
  }

  /// Basculer le statut favori d'une idée
  Future<VideoIdea> toggleFavorite(String ideaId) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/$ideaId/toggle-favorite');

      debugPrint('⭐ [VideoIdeaGenerator] Toggling favorite...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('⭐ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedIdea = VideoIdea.fromJson(data);
        debugPrint('✅ [VideoIdeaGenerator] Favorite toggled');
        return updatedIdea;
      } else {
        throw Exception('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Toggle error: $e');
      rethrow;
    }
  }

  /// Supprimer une idée
  Future<void> deleteIdea(String ideaId) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/$ideaId');

      debugPrint('🗑️ [VideoIdeaGenerator] Deleting idea...');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('🗑️ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ [VideoIdeaGenerator] Idea deleted');
      } else {
        throw Exception('Failed to delete idea: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Delete error: $e');
      rethrow;
    }
  }

  /// Analyser une image pour générer des idées
  Future<List<VideoIdea>> analyzeImage({
    required String imageUrl,
    required String brandName,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/video-ideas/analyze-image');

      debugPrint('🖼️ [VideoIdeaGenerator] Analyzing image...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'imageUrl': imageUrl,
          'brandName': brandName,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('🖼️ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final ideas = (data['ideas'] as List?)
            ?.map((json) => VideoIdea.fromJson(json))
            .toList() ?? [];
        debugPrint('✅ [VideoIdeaGenerator] Generated ${ideas.length} ideas from image');
        return ideas;
      } else {
        throw Exception('Failed to analyze image: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Analyze error: $e');
      rethrow;
    }
  }
}
