import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/plan.dart';
import 'auth_service.dart';

class PlanService {
  PlanService._();

  static Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Create ──────────────────────────────────────────────────────────────

  static Future<Plan> createPlan(Map<String, dynamic> data, String brandId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('${ApiConfig.createPlanUrl}?brandId=$brandId'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Plan.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create plan: ${response.statusCode} - ${response.body}');
  }

  // ─── List ────────────────────────────────────────────────────────────────

  static Future<List<Plan>> getPlans({String? brandId}) async {
    final token = await _getToken();
    final url = ApiConfig.getPlansUrl(brandId: brandId);
    final response = await http.get(Uri.parse(url), headers: _headers(token));
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
    final response = await http.post(
      Uri.parse(ApiConfig.generatePlanUrl(id)),
      headers: _headers(token),
    );
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
}
