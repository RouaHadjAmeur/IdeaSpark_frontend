import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/voice_action.dart';
import 'auth_service.dart';

class LlmCommandService {
  final AuthService _authService = AuthService();

  Future<VoiceParseResponse> parseCommand(
      String text, Map<String, dynamic> context) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/voice/parse');
    final token = _authService.accessToken;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'text': text,
        'context': context,
      }),
    );

    debugPrint('[LLM] VOICE RESPONSE (${response.statusCode}): ${response.body}');

    if (response.statusCode == 200) {
      return VoiceParseResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to parse command: ${response.statusCode}');
    }
  }

  Future<VoiceConfirmResponse> confirmAction(
      String confirmationKey, String text) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/voice/confirm');
    final token = _authService.accessToken;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'confirmationKey': confirmationKey,
        'text': text,
      }),
    );

    if (response.statusCode == 200) {
      return VoiceConfirmResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to confirm action: ${response.statusCode}');
    }
  }
}
