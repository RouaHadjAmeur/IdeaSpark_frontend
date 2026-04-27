import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/plan.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class PlanService {
  PlanService._();

  static Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  static Map<String, String> _headers(String? token, {String? brandId}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        if (brandId != null) 'x-brand-id': brandId,
      };

  // ─── Create ──────────────────────────────────────────────────────────────

  static Future<Plan> createPlan(Map<String, dynamic> data, String brandId) async {
    final token = await _getToken();
    final url = '${ApiConfig.createPlanUrl}?brandId=$brandId';
    
    final headers = _headers(token, brandId: brandId);
    debugPrint('[PlanService] POST $url | Headers: ${headers.keys} | Token Present: ${token != null}');
    debugPrint('[PlanService] Body: ${jsonEncode(data)}');
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );
    
    debugPrint('[PlanService] createPlan status=${response.statusCode} body=${response.body.substring(0, response.body.length.clamp(0, 400))}');
    if (response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    
    if (response.statusCode == 403) {
      throw Exception('Accès refusé : Votre abonnement ou vos crédits sont peut-être insuffisants pour cette action.');
    }
    
    throw Exception('Failed to create plan: ${response.statusCode} - ${response.body}');
  }

  // ─── List ────────────────────────────────────────────────────────────────

  static Future<List<Plan>> getPlans({String? brandId}) async {
    final token = await _getToken();
    final url = ApiConfig.getPlansUrl(brandId: brandId);
    final response = await http.get(Uri.parse(url), headers: _headers(token, brandId: brandId));
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Plan.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load plans: ${response.statusCode} - ${response.body}');
  }

  // ─── Get by ID ───────────────────────────────────────────────────────────

  static Future<Plan> getPlanById(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.planByIdUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load plan: ${response.statusCode} - ${response.body}');
  }

  // ─── Update ──────────────────────────────────────────────────────────────

  static Future<Plan> updatePlan(String id, Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.planByIdUrl(id)),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update plan: ${response.statusCode} - ${response.body}');
  }

  static Future<Plan> updateCampaignCopy(String id, String copy) async {
    final token = await _getToken();
    final headers = _headers(token);
    final body = jsonEncode({'notes': copy});

    // 1. Try specialized endpoint
    final response = await http.patch(
      Uri.parse(ApiConfig.updateCampaignCopyUrl(id)),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      return Plan.fromJson(jsonDecode(response.body));
    }

    // 2. Fallback to generic update if 400 or other failure
    if (response.statusCode == 400 || response.statusCode == 404) {
      final fallback = await http.patch(
        Uri.parse(ApiConfig.planByIdUrl(id)),
        headers: headers,
        body: body,
      );
      if (fallback.statusCode == 200) {
        return Plan.fromJson(jsonDecode(fallback.body));
      }
    }
    
    throw Exception('Failed to update campaign copy: ${response.statusCode} - ${response.body}');
  }

  // ─── Delete ──────────────────────────────────────────────────────────────

  static Future<void> deletePlan(String id) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse(ApiConfig.planByIdUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete plan: ${response.statusCode} - ${response.body}');
    }
  }

  // ─── Generate structure (Gemini AI) ──────────────────────────────────────

  static Future<Plan> generatePlanStructure(String id) async {
    final token = await _getToken();
    final url = ApiConfig.generatePlanUrl(id);
    
    debugPrint('[PlanService] POST $url (Gemini generation)');
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
    ).timeout(
      const Duration(seconds: 180),
      onTimeout: () => throw Exception('Plan generation timed out (>180s). Please try again.'),
    );
    
    debugPrint('[PlanService] generatePlanStructure status=${response.statusCode} body=${response.body.substring(0, response.body.length.clamp(0, 400))}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to generate plan structure: ${response.statusCode} - ${response.body}');
  }

  // ─── Activate ────────────────────────────────────────────────────────────

  static Future<Plan> activatePlan(String id) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.activatePlanUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to activate plan: ${response.statusCode} - ${response.body}');
  }

  // ─── Add to calendar ─────────────────────────────────────────────────────

  static Future<List<CalendarEntry>> addToCalendar(String id) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.addPlanToCalendarUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to add plan to calendar: ${response.statusCode} - ${response.body}');
  }

  // ─── Get calendar entries ────────────────────────────────────────────────

  static Future<List<CalendarEntry>> getCalendar(String planId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.getPlanCalendarUrl(planId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load calendar: ${response.statusCode} - ${response.body}');
  }

  // ─── Regenerate ──────────────────────────────────────────────────────────

  static Future<Plan> regeneratePlan(String id) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.regeneratePlanUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to regenerate plan: ${response.statusCode} - ${response.body}');
  }

  // ─── Project DNA ───────────────────────────────────────────────────────────

  static Future<Plan> updateProjectDNA(String id, Map<String, dynamic> dna) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.planDNAUrl(id)),
      headers: _headers(token),
      body: jsonEncode(dna),
    );
    if (response.statusCode == 200) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update project DNA: ${response.statusCode} - ${response.body}');
  }

  static Future<Map<String, dynamic>> getAIInsights(String id) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.aiProjectInsightsUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to get AI insights: ${response.statusCode} - ${response.body}');
  }

  static Future<Plan> generateHook(String planId, String blockId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.generateHookUrl(planId, blockId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to generate hook: ${response.statusCode} - ${response.body}');
  }

  static Future<Plan> generateCaption(String planId, String blockId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.generateCaptionUrl(planId, blockId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to generate caption: ${response.statusCode} - ${response.body}');
  }
}
