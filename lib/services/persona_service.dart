import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/persona_model.dart';
import '../core/api_config.dart';
import '../core/auth_service.dart';
import 'persona_completion_service.dart';

/// Service for managing user persona data
class PersonaService {
  final http.Client _client;
  final AuthService _authService;

  PersonaService({
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  /// Save user persona to backend
  Future<PersonaModel> savePersona(PersonaModel persona) async {
    try {
      final url = Uri.parse(ApiConfig.personaBase);
      final body = jsonEncode(persona.toJson());
      final token = _authService.accessToken;

      print('🚀 Saving persona to: $url');
      print('📦 Payload: $body');
      print('🔑 Auth token: ${token != null ? "Present" : "Missing"}');

      final headers = {
        'Content-Type': 'application/json',
      };

      // Add authorization header if token exists
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.post(
        url,
        headers: headers,
        body: body,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final savedPersona = PersonaModel.fromJson(data);

        // Mark persona as completed in local storage
        await PersonaCompletionService.markPersonaCompleted();

        print('✅ Persona saved successfully');
        return savedPersona;
      } else {
        print('❌ Failed to save persona: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        throw Exception('Failed to save persona: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving persona: $e');
      throw Exception('Error saving persona: $e');
    }
  }

  /// Get user persona from backend
  /// Backend returns { hasPersona: bool, persona?: {...} }
  Future<PersonaModel?> getPersona(String userId) async {
    try {
      final url = Uri.parse('${ApiConfig.personaBase}/me');
      final token = _authService.accessToken;

      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend wraps response: { hasPersona: true/false, persona: {...} }
        if (data is Map && data['hasPersona'] == true && data['persona'] != null) {
          return PersonaModel.fromJson(data['persona'] as Map<String, dynamic>);
        }
        return null; // hasPersona is false
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get persona: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting persona: $e');
    }
  }

  /// Update existing persona
  Future<PersonaModel> updatePersona(PersonaModel persona) async {
    try {
      final url = Uri.parse(ApiConfig.personaBase);
      final token = _authService.accessToken;

      final headers = {
        'Content-Type': 'application/json',
      };

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client.put(
        url,
        headers: headers,
        body: jsonEncode(persona.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PersonaModel.fromJson(data);
      } else {
        throw Exception('Failed to update persona: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating persona: $e');
    }
  }

  /// Check if user has completed persona onboarding
  Future<bool> hasPersona(String userId) async {
    try {
      final persona = await getPersona(userId);
      return persona != null;
    } catch (e) {
      return false;
    }
  }
}
