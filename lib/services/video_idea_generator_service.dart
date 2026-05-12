import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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

      final url = Uri.parse(ApiConfig.generateVideoIdeasUrl);

      debugPrint('💡 [VideoIdeaGenerator] Generating ideas...');

      // If we have an image, use multipart/form-data
      if (request.productImagePath != null) {
        final multipartRequest = http.MultipartRequest('POST', url);
        
        // Add auth header
        multipartRequest.headers['Authorization'] = 'Bearer $token';
        
        // Add text fields
        multipartRequest.fields['platform'] = _mapPlatform(request.platform);
        multipartRequest.fields['duration'] = request.duration.seconds.toString();
        multipartRequest.fields['goal'] = _mapGoal(request.goal);
        multipartRequest.fields['creatorType'] = _mapCreatorType(request.creatorType);
        multipartRequest.fields['tone'] = _mapTone(request.tone);
        multipartRequest.fields['language'] = _mapLanguage(request.language);
        multipartRequest.fields['productName'] = request.productName;
        multipartRequest.fields['productCategory'] = request.productCategory;
        multipartRequest.fields['targetAudience'] = request.targetAudience;
        multipartRequest.fields['batchSize'] = request.batchSize.toString();
        
        if (request.price != null) multipartRequest.fields['price'] = request.price!;
        if (request.offer != null) multipartRequest.fields['offer'] = request.offer!;
        if (request.painPoint != null) multipartRequest.fields['painPoint'] = request.painPoint!;
        
        // Add keyBenefits
        for (var benefit in request.keyBenefits) {
          multipartRequest.fields['keyBenefits[]'] = benefit;
        }

        // Add image
        final file = File(request.productImagePath!);
        if (await file.exists()) {
          multipartRequest.files.add(
            await http.MultipartFile.fromPath(
              'productImage',
              file.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }

        final streamedResponse = await multipartRequest.send().timeout(const Duration(seconds: 60));
        final response = await http.Response.fromStream(streamedResponse);

        debugPrint('💡 [VideoIdeaGenerator] Status: ${response.statusCode}');

        if (response.statusCode == 201 || response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final ideas = data.map((json) => VideoIdea.fromJson(json)).toList();
          debugPrint('✅ [VideoIdeaGenerator] Generated ${ideas.length} ideas');
          return ideas;
        } else {
          throw Exception('Failed to generate ideas: ${response.statusCode} ${response.body}');
        }
      }

      // Standard JSON request if no image
      final body = {
        'platform': _mapPlatform(request.platform),
        'duration': request.duration.seconds,
        'goal': _mapGoal(request.goal),
        'creatorType': _mapCreatorType(request.creatorType),
        'tone': _mapTone(request.tone),
        'language': _mapLanguage(request.language),
        'productName': request.productName,
        'productCategory': request.productCategory,
        'keyBenefits': request.keyBenefits,
        'targetAudience': request.targetAudience,
        'price': request.price,
        'offer': request.offer,
        'painPoint': request.painPoint,
        'batchSize': request.batchSize,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      debugPrint('💡 [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        final ideas = data.map((json) => VideoIdea.fromJson(json)).toList();
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

      final url = Uri.parse(ApiConfig.saveVideoIdeaUrl);

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

      final url = Uri.parse(ApiConfig.refineVideoIdeaUrl);

      debugPrint('✨ [VideoIdeaGenerator] Refining idea...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ideaId': ideaId,
          'customInstruction': instruction,
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

      final url = Uri.parse(ApiConfig.approveVersionUrl);

      debugPrint('👍 [VideoIdeaGenerator] Approving version...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ideaId': ideaId,
          'versionIndex': versionIndex,
        }),
      ).timeout(const Duration(seconds: 10));

      debugPrint('👍 [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
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

      final url = Uri.parse(ApiConfig.getHistoryUrl);

      debugPrint('📚 [VideoIdeaGenerator] Fetching history...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('📚 [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final ideas = data.map((json) => VideoIdea.fromJson(json)).toList();
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

      final url = Uri.parse(ApiConfig.getFavoritesUrl);

      debugPrint('⭐ [VideoIdeaGenerator] Fetching favorites...');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('⭐ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final favorites = data.map((json) => VideoIdea.fromJson(json)).toList();
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

      final url = Uri.parse(ApiConfig.toggleFavoriteUrl(ideaId));

      debugPrint('⭐ [VideoIdeaGenerator] Toggling favorite...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('⭐ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
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

      final url = Uri.parse(ApiConfig.deleteVideoIdeaUrl(ideaId));

      debugPrint('🗑️ [VideoIdeaGenerator] Deleting idea...');

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('🗑️ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
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
  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse(ApiConfig.analyzeVideoImageUrl);
      final multipartRequest = http.MultipartRequest('POST', url);
      
      multipartRequest.headers['Authorization'] = 'Bearer $token';

      final file = File(imagePath);
      if (!await file.exists()) throw Exception('Image file not found');

      multipartRequest.files.add(
        await http.MultipartFile.fromPath(
          'productImage',
          file.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      debugPrint('🖼️ [VideoIdeaGenerator] Analyzing image...');

      final streamedResponse = await multipartRequest.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('🖼️ [VideoIdeaGenerator] Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ [VideoIdeaGenerator] Image analyzed successfully');
        return data;
      } else {
        throw Exception('Image analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [VideoIdeaGenerator] Analyze error: $e');
      rethrow;
    }
  }

  // Helper methods for enum mapping
  String _mapPlatform(Platform platform) {
    switch (platform) {
      case Platform.tikTok:
        return 'tiktok';
      case Platform.instagramReels:
        return 'instagram_reels';
      case Platform.youTubeShorts:
        return 'youtube_shorts';
      case Platform.youTubeLong:
        return 'youtube_long';
    }
  }

  String _mapGoal(VideoGoal goal) {
    switch (goal) {
      case VideoGoal.sellProduct:
        return 'sell_product';
      case VideoGoal.brandAwareness:
        return 'brand_awareness';
      case VideoGoal.ugcReview:
        return 'ugc_review';
      case VideoGoal.education:
        return 'education';
      case VideoGoal.viralEngagement:
        return 'viral_engagement';
      case VideoGoal.offerPromo:
        return 'offer_promo';
    }
  }

  String _mapTone(VideoTone tone) {
    switch (tone) {
      case VideoTone.trendy:
        return 'trendy';
      case VideoTone.professional:
        return 'professional';
      case VideoTone.emotional:
        return 'emotional';
      case VideoTone.funny:
        return 'funny';
      case VideoTone.luxury:
        return 'luxury';
      case VideoTone.directResponse:
        return 'direct_response';
    }
  }

  String _mapCreatorType(CreatorType type) {
    switch (type) {
      case CreatorType.ecommerceBrand:
        return 'ecommerce_brand';
      case CreatorType.influencer:
        return 'influencer';
    }
  }

  String _mapLanguage(VideoLanguage language) {
    return language.code;
  }
}
