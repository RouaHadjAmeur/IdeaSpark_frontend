import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../models/social_post.dart';

class SocialService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = _authService.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<SocialPost>> getFeed() async {
    final response = await http.get(
      Uri.parse(ApiConfig.socialFeed),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SocialPost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load feed: ${response.body}');
    }
  }

  Future<List<AppUser>> getSuggestions() async {
    final response = await http.get(
      Uri.parse(ApiConfig.socialSuggestions),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load suggestions: ${response.body}');
    }
  }

  Future<AppUser?> getUserProfile(String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.publicProfile}/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<bool> acceptFollowRequest(String followerId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.socialAccept}/$followerId'),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<AppUser>> getPendingRequests() async {
    final response = await http.get(
      Uri.parse(ApiConfig.socialPendingRequests),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json['followerId'])).toList();
    }
    return [];
  }

  Future<void> followUser(String userId) async {
    final response = await http.post(
      Uri.parse(ApiConfig.followUrl(userId)),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to follow user: ${response.body}');
    }
  }

  Future<void> unfollowUser(String userId) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.unfollowUrl(userId)),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unfollow user: ${response.body}');
    }
  }

  Future<List<AppUser>> getFollowing() async {
    final response = await http.get(
      Uri.parse(ApiConfig.socialFollowingUrl),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load following list: ${response.body}');
    }
  }

  Future<List<AppUser>> getFollowers() async {
    final response = await http.get(
      Uri.parse(ApiConfig.socialFollowersUrl),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load followers list: ${response.body}');
    }
  }

  Future<List<AppUser>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse(ApiConfig.searchUsersUrl(query)),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users: ${response.body}');
    }
  }

  Future<List<AppUser>> getFollowersById(String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.socialBase}/followers/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<AppUser>> getFollowingById(String userId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.socialBase}/following/$userId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    }
    return [];
  }

  /// Returns mutual follows (friends) of the current user with their shared collaboration plans.
  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await http.get(
      Uri.parse(ApiConfig.socialFriendsUrl),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Returns mutual follows of any user (without shared plans).
  Future<List<AppUser>> getFriendsById(String userId) async {
    final response = await http.get(
      Uri.parse(ApiConfig.socialFriendsByIdUrl(userId)),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    }
    return [];
  }
}
