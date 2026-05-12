// assignment_service.dart
// Service for managing work assignments

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/assignment.dart';
import 'auth_service.dart';

class AssignmentService {
  static final AssignmentService _instance = AssignmentService._();
  factory AssignmentService() => _instance;
  AssignmentService._();

  Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Create Assignment ────────────────────────────────────────────────────

  Future<Assignment> createAssignment(Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/create';

    debugPrint('[AssignmentService] POST $url');
    debugPrint('[AssignmentService] Body: ${jsonEncode(data)}');

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    debugPrint('[AssignmentService] createAssignment status=${response.statusCode}');

    if (response.statusCode == 201) {
      return Assignment.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to create assignment: ${response.statusCode} - ${response.body}');
  }

  // ─── Get Assignments ──────────────────────────────────────────────────────

  Future<List<Assignment>> getAssignmentsByCampaign(String campaignId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/campaign/$campaignId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Assignment.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load assignments: ${response.statusCode}');
  }

  Future<List<Assignment>> getAssignmentsByCollaborator(String collaboratorId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/collaborator/tasks';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Assignment.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load collaborator tasks: ${response.statusCode}');
  }

  Future<Assignment> getAssignment(String assignmentId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/$assignmentId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Assignment.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load assignment: ${response.statusCode}');
  }

  // ─── Update Assignment Status ─────────────────────────────────────────────

  Future<Assignment> acceptAssignment(String assignmentId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/$assignmentId/accept';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Assignment.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to accept assignment: ${response.statusCode}');
  }

  Future<Assignment> declineAssignment(String assignmentId, String reason) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/$assignmentId/decline';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode({'reason': reason}),
    );

    if (response.statusCode == 200) {
      return Assignment.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to decline assignment: ${response.statusCode}');
  }

  Future<Assignment> startAssignment(String assignmentId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/$assignmentId/start';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Assignment.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to start assignment: ${response.statusCode}');
  }

  // ─── Update Assignment ────────────────────────────────────────────────────

  Future<Assignment> updateAssignment(String assignmentId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/$assignmentId';

    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Assignment.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to update assignment: ${response.statusCode}');
  }

  // ─── Delete Assignment ────────────────────────────────────────────────────

  Future<void> deleteAssignment(String assignmentId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/assignments/$assignmentId';

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete assignment: ${response.statusCode}');
    }
  }
}
