import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:http_parser/http_parser.dart';
import '../core/api_config.dart';
import '../models/challenge.dart';
import '../models/submission.dart';
import 'auth_service.dart';

class ChallengeService {
  static final ChallengeService _instance = ChallengeService._();
  factory ChallengeService() => _instance;
  ChallengeService._();

  Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ── Challenges ───────────────────────────────────────────────────────────

  Future<List<Challenge>> discoverChallenges() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.discoverChallengesUrl),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Challenge.fromJson(e)).toList();
    }
    throw Exception('Failed to discover challenges');
  }

  Future<List<Challenge>> getBrandChallenges(String brandId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.brandChallengesUrl(brandId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Challenge.fromJson(e)).toList();
    }
    throw Exception('Failed to load brand challenges');
  }

  Future<Challenge> createChallenge(Map<String, dynamic> data) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(ApiConfig.challengesBase),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode == 201) {
      return Challenge.fromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Failed to create challenge');
  }

  Future<void> publishChallenge(String id) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.publishChallengeUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to publish challenge');
    }
  }

  // ── Submissions ──────────────────────────────────────────────────────────

  Future<List<Submission>> getChallengeSubmissions(String challengeId) async {
    final token = await _getToken();
    final url = ApiConfig.getChallengeSubmissionsUrl(challengeId);
    // ignore: avoid_print
    print('[ChallengeService] GET $url');
    final response = await http.get(Uri.parse(url), headers: _headers(token));
    // ignore: avoid_print
    print('[ChallengeService] status=${response.statusCode} body=${response.body.substring(0, response.body.length.clamp(0, 300))}');
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Submission.fromJson(e)).toList();
    }
    throw Exception('Failed to load submissions (${response.statusCode})');
  }

  Future<Submission> submitVideo(String challengeId, String videoPath) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.submitVideoUrl(challengeId)),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'video',
        videoPath,
        contentType: MediaType('video', 'mp4'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return Submission.fromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Failed to submit video');
  }

  Future<void> shortlistSubmission(String id, bool shortlisted) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.shortlistSubmissionUrl(id)),
      headers: _headers(token),
      body: jsonEncode({'shortlisted': shortlisted}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update shortlist status');
    }
  }

  Future<void> declareWinner(String id) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.declareWinnerUrl(id)),
      headers: _headers(token),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to declare winner');
    }
  }

  Future<void> requestRevision(String id, String feedback) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.submissionRevisionUrl(id)),
      headers: _headers(token),
      body: jsonEncode({'feedback': feedback}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Failed to request revision');
    }
  }

  Future<void> rateSubmission(String id, int rating) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(ApiConfig.rateSubmissionUrl(id)),
      headers: _headers(token),
      body: jsonEncode({'rating': rating}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to rate submission');
    }
  }

  Future<Map<String, dynamic>> getBrandStats(String brandId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.getBrandChallengeStatsUrl(brandId)),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load brand stats');
  }

  Future<List<Submission>> getMySubmissions() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse(ApiConfig.getMySubmissionsUrl),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Submission.fromJson(e)).toList();
    }
    throw Exception('Failed to load my submissions');
  }

  Future<Submission> updateSubmission(String submissionId, File file) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse('${ApiConfig.baseUrl}/submissions/$submissionId/revise'),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    request.files.add(await http.MultipartFile.fromPath('video', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Submission.fromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Failed to update submission');
  }
}
