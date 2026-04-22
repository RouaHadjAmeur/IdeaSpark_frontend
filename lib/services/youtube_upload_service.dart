import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import 'auth_service.dart';

class YoutubeUploadService {
  YoutubeUploadService._();

  static final YoutubeUploadService _instance = YoutubeUploadService._();
  factory YoutubeUploadService() => _instance;

  Future<bool> isConnected() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse(ApiConfig.youtubeMeUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res));
    }
    final map = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    return map['connected'] == true;
  }

  Future<String> publishUpload({
    required String filePath,
    required String title,
    String? description,
    String? tagsCsv,
    String privacyStatus = 'private',
  }) async {
    final token = await _getToken();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.youtubePublishUploadUrl),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['title'] = title.trim();
    if (description != null && description.trim().isNotEmpty) {
      request.fields['description'] = description.trim();
    }
    if (tagsCsv != null && tagsCsv.trim().isNotEmpty) {
      request.fields['tagsCsv'] = tagsCsv.trim();
    }
    request.fields['privacyStatus'] = privacyStatus;
    request.files.add(await http.MultipartFile.fromPath('video', filePath));

    final streamedRes = await request.send();
    final body = await streamedRes.stream.bytesToString();

    if (streamedRes.statusCode != 200 && streamedRes.statusCode != 201) {
      throw Exception(_errorMessageFromRaw(body));
    }

    final map = _tryDecode(body) as Map<String, dynamic>? ?? {};
    final youtubeUrl = map['youtubeUrl']?.toString() ?? '';
    if (youtubeUrl.isEmpty) {
      throw Exception('Upload succeeded but no youtubeUrl was returned');
    }
    return youtubeUrl;
  }

  Future<String> createConnectUrl() async {
    final token = await _getToken();
    final res = await http.post(
      Uri.parse(ApiConfig.youtubeStartUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(_errorMessage(res));
    }

    final map = _tryDecode(res.body) as Map<String, dynamic>? ?? {};
    final authUrl = map['authUrl']?.toString() ?? '';
    if (authUrl.isEmpty) {
      throw Exception('No authUrl returned by backend');
    }
    return authUrl;
  }

  Future<void> disconnect() async {
    final token = await _getToken();
    final res = await http.delete(
      Uri.parse(ApiConfig.youtubeDisconnectUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(_errorMessage(res));
    }
  }

  Future<String> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('Not logged in');
    }
    return token;
  }

  String _errorMessage(http.Response res) {
    return _errorMessageFromRaw(res.body);
  }

  String _errorMessageFromRaw(String body) {
    final decoded = _tryDecode(body);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is List && message.isNotEmpty) return message.join(' ');
      if (message is String && message.isNotEmpty) return message;
      final error = decoded['error'];
      if (error is String && error.isNotEmpty) return error;
    }
    return body.isNotEmpty ? body : 'Request failed';
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return raw;
    }
  }
}
