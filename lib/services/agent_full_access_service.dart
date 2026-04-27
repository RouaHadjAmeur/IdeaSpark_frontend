import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/agent_full_access_model.dart';
import 'auth_service.dart';

class AgentFullAccessService {
  AgentFullAccessService._();

  static Future<DecomposeResponse> decomposePrompt({
    required String idea,
    double? temperature,
    int? maxTokens,
  }) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final url = Uri.parse(ApiConfig.decomposePromptUrl);

    final Map<String, dynamic> body = {
      'idea': idea,
    };

    if (temperature != null) {
      body['temperature'] = temperature;
    }
    if (maxTokens != null) {
      body['max_tokens'] = maxTokens;
    }

    print('🚀 decomposePrompt URL: $url');
    print('📝 Body: ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(body),
    );

    print('📡 Réponse decomposePrompt: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return DecomposeResponse.fromJson(data);
    } else {
      throw Exception('Failed to decompose prompt: ${response.statusCode} - ${response.body}');
    }
  }
}
