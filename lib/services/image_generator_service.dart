import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

enum ImageStyle {
  minimalist,
  colorful,
  professional,
  fun,
}

class GeneratedImage {
  final String id;
  final String url;
  final String prompt;
  final ImageStyle style;
  final DateTime createdAt;

  GeneratedImage({
    required this.id,
    required this.url,
    required this.prompt,
    required this.style,
    required this.createdAt,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['_id'] ?? json['id'] ?? '',
      url: json['url'] as String,
      prompt: json['prompt'] as String,
      style: ImageStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => ImageStyle.professional,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'prompt': prompt,
        'style': style.name,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ImageGeneratorService {
  static Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  /// Generate an image using Unsplash (FREE) based on user description and style
  static Future<GeneratedImage> generateImage({
    required String description,
    required ImageStyle style,
    String? brandName,
    String? category,
  }) async {
    final token = await _getToken();
    
    // 🔍 DEBUG LOGS
    final endpoint = '${ApiConfig.baseUrl}/ai-images/generate';
    final requestBody = {
      'description': description,
      'style': style.name,
      'brandName': brandName,
      'category': category,
    };
    
    debugPrint('🔍 [Flutter] Calling backend...');
    debugPrint('📍 [Flutter] URL: $endpoint');
    debugPrint('📦 [Flutter] Body: ${jsonEncode(requestBody)}');
    debugPrint('🔑 [Flutter] Token: ${token != null ? "Present (${token.substring(0, 20)}...)" : "Missing"}');
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: _headers(token),
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30), // Timeout augmenté pour Unsplash API
        onTimeout: () {
          throw Exception('Timeout: La génération d\'image prend trop de temps (>30s)');
        },
      );

      debugPrint('✅ [Flutter] Response status: ${response.statusCode}');
      debugPrint('📄 [Flutter] Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return GeneratedImage(
          id: data['_id'] ?? data['id'] ?? '',
          url: data['url'] as String,
          prompt: data['prompt'] as String? ?? description,
          style: style,
          createdAt: DateTime.now(),
        );
      }

      throw Exception('Backend error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      debugPrint('❌ [Flutter] ERROR: $e');
      
      // Ne PAS utiliser de fallback - on veut voir l'erreur!
      rethrow;
    }
  }

  /// Get user's generated images history
  static Future<List<GeneratedImage>> getHistory() async {
    final token = await _getToken();
    
    final endpoint = '${ApiConfig.baseUrl}/ai-images/history';
    debugPrint('🔍 [Flutter] Getting image history from: $endpoint');
    
    final response = await http.get(
      Uri.parse(endpoint),
      headers: _headers(token),
    );

    debugPrint('✅ [Flutter] History response status: ${response.statusCode}');
    debugPrint('📄 [Flutter] History response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      debugPrint('📊 [Flutter] Parsed data type: ${data.runtimeType}');
      debugPrint('📊 [Flutter] Parsed data: $data');
      
      // Gérer différents formats de réponse
      List<dynamic> list;
      if (data is List) {
        // Si c'est directement un array
        debugPrint('✅ [Flutter] Response is direct List');
        list = data;
      } else if (data is Map && data.containsKey('images')) {
        // Si c'est un objet avec clé 'images'
        debugPrint('✅ [Flutter] Response has "images" key');
        list = data['images'] as List;
      } else if (data is Map && data.containsKey('data')) {
        // Si c'est un objet avec clé 'data'
        debugPrint('✅ [Flutter] Response has "data" key');
        list = data['data'] as List;
      } else {
        throw Exception('Format de réponse non reconnu: $data');
      }
      
      debugPrint('📊 [Flutter] Found ${list.length} images');
      return list.map((e) => GeneratedImage.fromJson(e as Map<String, dynamic>)).toList();
    }

    debugPrint('❌ [Flutter] History error: ${response.statusCode}');
    debugPrint('❌ [Flutter] Response body: ${response.body}');
    throw Exception('Failed to load history: ${response.statusCode} - ${response.body}');
  }

  /// Delete a generated image
  static Future<void> deleteImage(String imageId) async {
    final token = await _getToken();
    
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/ai-images/$imageId'),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete image: ${response.statusCode}');
    }
  }

  /// Save image URL to a content block
  static Future<void> saveImageToPost({
    required String contentBlockId,
    required String imageUrl,
  }) async {
    final token = await _getToken();
    
    debugPrint('💾 [Flutter] Saving image to post...');
    debugPrint('📍 [Flutter] ContentBlock ID: $contentBlockId');
    debugPrint('🖼️ [Flutter] Image URL: $imageUrl');
    
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/content-blocks/$contentBlockId/image'),
        headers: _headers(token),
        body: jsonEncode({'imageUrl': imageUrl}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('✅ [Flutter] Save response: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to save image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [Flutter] Save error: $e');
      rethrow;
    }
  }

  /// Get style-specific prompt enhancement
  static String getStylePrompt(ImageStyle style) {
    switch (style) {
      case ImageStyle.minimalist:
        return 'minimalist design, clean lines, simple composition, white background, modern aesthetic';
      case ImageStyle.colorful:
        return 'vibrant colors, bold and bright, eye-catching, energetic, playful color palette';
      case ImageStyle.professional:
        return 'professional photography, high quality, corporate style, clean and polished, business aesthetic';
      case ImageStyle.fun:
        return 'fun and playful, whimsical, creative, entertaining, lighthearted style';
    }
  }

  /// Get style icon
  static String getStyleIcon(ImageStyle style) {
    switch (style) {
      case ImageStyle.minimalist:
        return '⚪';
      case ImageStyle.colorful:
        return '🌈';
      case ImageStyle.professional:
        return '💼';
      case ImageStyle.fun:
        return '🎉';
    }
  }

  /// Get style label
  static String getStyleLabel(ImageStyle style) {
    switch (style) {
      case ImageStyle.minimalist:
        return 'Minimaliste';
      case ImageStyle.colorful:
        return 'Coloré';
      case ImageStyle.professional:
        return 'Professionnel';
      case ImageStyle.fun:
        return 'Fun';
    }
  }
}
