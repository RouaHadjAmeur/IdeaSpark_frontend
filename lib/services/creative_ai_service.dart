import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../models/post_analysis.dart';
import '../models/optimal_timing.dart';

class CreativeAIService {
  /// Analyser un post et obtenir un score de performance
  static Future<PostAnalysis> analyzePost({
    required String caption,
    required List<String> hashtags,
    String? imageUrl,
    DateTime? scheduledTime,
    required String platform,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/post-analyzer/score');

      print('📊 [PostAnalyzer] Analyzing post...');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'caption': caption,
          'hashtags': hashtags,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (scheduledTime != null)
            'scheduledTime': scheduledTime.toIso8601String(),
          'platform': platform,
        }),
      ).timeout(const Duration(seconds: 30));

      print('📊 [PostAnalyzer] Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final analysis = PostAnalysis.fromJson(data);
        print('✅ [PostAnalyzer] Score: ${analysis.overallScore}/100');
        return analysis;
      } else {
        throw Exception('Failed to analyze post: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [PostAnalyzer] Error: $e');
      rethrow;
    }
  }

  /// Générer des hooks viraux
  static Future<List<String>> generateViralHooks({
    required String topic,
    required String platform,
    required String tone,
    int count = 5,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/viral-hooks/generate');

      print('🎣 [ViralHooks] Generating hooks for: $topic');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'topic': topic,
          'platform': platform,
          'tone': tone,
          'count': count,
        }),
      ).timeout(const Duration(seconds: 30));

      print('🎣 [ViralHooks] Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hooks = List<String>.from(data['hooks'] ?? []);
        print('✅ [ViralHooks] Generated ${hooks.length} hooks');
        return hooks;
      } else {
        throw Exception('Failed to generate hooks: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [ViralHooks] Error: $e');
      rethrow;
    }
  }

  /// Obtenir les heures optimales pour poster
  static Future<OptimalTiming> getOptimalTiming({
    required String platform,
    required String contentType,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse('${ApiConfig.baseUrl}/optimal-timing/predict');

      print('⏰ [OptimalTiming] Predicting for: $platform - $contentType');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'platform': platform,
          'contentType': contentType,
        }),
      ).timeout(const Duration(seconds: 30));

      print('⏰ [OptimalTiming] Status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timing = OptimalTiming.fromJson(data);
        print('✅ [OptimalTiming] Best times: ${timing.bestTimes.length}');
        return timing;
      } else {
        throw Exception('Failed to get optimal timing: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [OptimalTiming] Error: $e');
      rethrow;
    }
  }
}
