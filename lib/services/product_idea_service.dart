import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart';
import '../models/product_idea_model.dart';

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

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      return ProductIdeaResult.fromJson(data);
    } else {
      final bodyText = response.body;
      throw Exception(
        'Failed to generate product idea: ${response.statusCode} - $bodyText',
      );
    }
  }
}
