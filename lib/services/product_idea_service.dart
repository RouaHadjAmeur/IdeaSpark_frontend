import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart';
import '../models/product_idea_model.dart';
import 'package:flutter/foundation.dart';

class ProductIdeaService {
  ProductIdeaService._();

  static Future<ProductIdeaResult> generateProductIdea({
    required String besoin,
    double? temperature,
    int? maxTokens,
  }) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final url = Uri.parse(ApiConfig.generateProductIdeaUrl);

    final Map<String, dynamic> body = {
      'besoin': besoin,
    };

    if (temperature != null) {
      body['temperature'] = temperature;
    }
    if (maxTokens != null) {
      body['max_tokens'] = maxTokens;
    }

    debugPrint('🚀 generateProductIdea URL: $url');
    debugPrint('🔑 Token: ${authToken != null ? "Présent" : "Absent"}');
    debugPrint('📝 Body: ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    debugPrint('📡 Réponse generateProductIdea: ${response.statusCode}');
    debugPrint('📄 Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final result = ProductIdeaResult.fromJson(data);
      
      // Save trace after successful generation
      _saveTrace(besoin, result);
      
      return result;
    } else {
      final bodyText = response.body;
      throw Exception(
        'Failed to generate product idea: ${response.statusCode} - $bodyText',
      );
    }
  }

  static Future<void> _saveTrace(String besoin, ProductIdeaResult result) async {
    try {
      final authService = AuthService();
      final authToken = authService.accessToken;
      if (authToken == null) return;

      final url = Uri.parse(ApiConfig.productIdeaTraceUrl);
      final body = {
        'besoin': besoin,
        'produit': result.produit.toJson(),
        'rawOutput': result.rawOutput,
        'durationSeconds': result.durationSeconds,
        'modelLoaded': result.modelLoaded,
        'status': 'success',
      };

      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(body),
      );
      debugPrint('✅ Trace saved for Product Idea');
    } catch (e) {
      debugPrint('❌ Error saving Product Idea trace: $e');
    }
  }

  // CRUD Methods for Saved Product Ideas
  static Future<SavedProductIdea> saveProductIdea({
    required String besoin,
    required ProductSection produit,
    required String rawOutput,
    required double durationSeconds,
    required bool modelLoaded,
  }) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final url = Uri.parse(ApiConfig.saveProductIdeaUrl);

    final Map<String, dynamic> body = {
      'besoin': besoin,
      'produit': {
        'nomDuProduit': produit.nomDuProduit,
        'probleme': produit.probleme,
        'solution': produit.solution,
        'cible': produit.cible,
        'modeleEconomique': produit.modeleEconomique,
        'mvp': produit.mvp,
      },
      'rawOutput': rawOutput,
      'durationSeconds': durationSeconds,
      'modelLoaded': modelLoaded,
    };

    debugPrint('Saving product idea to: $url');
    debugPrint('Request body: ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    debugPrint('Save product idea response: ${response.statusCode}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SavedProductIdea.fromJson(data);
    } else {
      final bodyText = response.body;
      throw Exception(
        'Failed to save product idea: ${response.statusCode} - $bodyText',
      );
    }
  }

  static Future<List<SavedProductIdea>> getProductIdeasHistory() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final url = Uri.parse(ApiConfig.getProductIdeasHistoryUrl);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    debugPrint('Get product ideas history response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data.map((item) => SavedProductIdea.fromJson(item)).toList();
    } else {
      final bodyText = response.body;
      throw Exception(
        'Failed to get product ideas history: ${response.statusCode} - $bodyText',
      );
    }
  }

  static Future<List<SavedProductIdea>> getProductIdeasFavorites() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final url = Uri.parse(ApiConfig.getProductIdeasFavoritesUrl);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    debugPrint('Get product ideas favorites response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List;
      return data.map((item) => SavedProductIdea.fromJson(item)).toList();
    } else {
      final bodyText = response.body;
      throw Exception(
        'Failed to get product ideas favorites: ${response.statusCode} - $bodyText',
      );
    }
  }

  static Future<SavedProductIdea> toggleProductIdeaFavorite(String id) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final url = Uri.parse(ApiConfig.toggleProductIdeaFavoriteUrl(id));

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    debugPrint('Toggle favorite response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return SavedProductIdea.fromJson(data);
    } else {
      final bodyText = response.body;
      throw Exception(
        'Failed to toggle product idea favorite: ${response.statusCode} - $bodyText',
      );
    }
  }

  static Future<void> deleteProductIdea(String id) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final url = Uri.parse(ApiConfig.deleteProductIdeaUrl(id));

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    debugPrint('Delete product idea response: ${response.statusCode}');

    if (response.statusCode != 200) {
      final bodyText = response.body;
      throw Exception(
        'Failed to delete product idea: ${response.statusCode} - $bodyText',
      );
    }
  }
}
