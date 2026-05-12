// submission_service.dart
// Service for managing content submissions

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/submission.dart';
import 'auth_service.dart';

class SubmissionService {
  static final SubmissionService _instance = SubmissionService._();
  factory SubmissionService() => _instance;
  SubmissionService._();

  Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Create Submission ────────────────────────────────────────────────────

  Future<Submission> createSubmission(Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/create';

    debugPrint('[SubmissionService] POST $url');
    debugPrint('[SubmissionService] Body: ${jsonEncode(data)}');

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    debugPrint('[SubmissionService] createSubmission status=${response.statusCode}');

    if (response.statusCode == 201) {
      return Submission.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to create submission: ${response.statusCode} - ${response.body}');
  }

  // ─── Get Submissions ──────────────────────────────────────────────────────

  Future<List<Submission>> getSubmissionsByCampaign(String campaignId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/campaign/$campaignId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Submission.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load submissions: ${response.statusCode}');
  }

  Future<List<Submission>> getPendingSubmissions(String campaignId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/pending?campaignId=$campaignId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Submission.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load pending submissions: ${response.statusCode}');
  }

  Future<Submission> getSubmission(String submissionId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/$submissionId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Submission.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load submission: ${response.statusCode}');
  }

  // ─── Review Submission ────────────────────────────────────────────────────

  Future<Submission> approveSubmission(String submissionId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/$submissionId/approve';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Submission.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to approve submission: ${response.statusCode}');
  }

  Future<Submission> rejectSubmission(String submissionId, String feedback) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/$submissionId/reject';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode({'feedback': feedback}),
    );

    if (response.statusCode == 200) {
      return Submission.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to reject submission: ${response.statusCode}');
  }

  Future<Submission> requestChanges(String submissionId, String feedback) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/$submissionId/request-changes';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode({'feedback': feedback}),
    );

    if (response.statusCode == 200) {
      return Submission.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to request changes: ${response.statusCode}');
  }

  // ─── Update Submission ────────────────────────────────────────────────────

  Future<Submission> updateSubmission(String submissionId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/$submissionId';

    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Submission.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to update submission: ${response.statusCode}');
  }

  // ─── Delete Submission ────────────────────────────────────────────────────

  Future<void> deleteSubmission(String submissionId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/submissions/$submissionId';

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete submission: ${response.statusCode}');
    }
  }
}
