import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../services/auth_service.dart';
import '../models/scheduled_post.dart';

class AdvancedShareService {
  /// Programmer une publication
  static Future<ScheduledPost> schedulePost({
    required String contentId,
    required String contentType,
    required String contentUrl,
    required String caption,
    required List<String> hashtags,
    required List<SocialPlatform> platforms,
    required List<String> accountIds,
    required DateTime scheduledTime,
    String? audioUrl,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('📅 [AdvancedShare] Scheduling post...');
      print('📅 [AdvancedShare] Content: $contentId');
      print('📅 [AdvancedShare] Platforms: ${platforms.map((e) => e.name).join(', ')}');
      print('📅 [AdvancedShare] Scheduled for: $scheduledTime');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/schedule'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': contentId,
          'contentType': contentType,
          'contentUrl': contentUrl,
          'caption': caption,
          'hashtags': hashtags,
          'platforms': platforms.map((e) => e.name).toList(),
          'accountIds': accountIds,
          'scheduledTime': scheduledTime.toIso8601String(),
          if (audioUrl != null) 'audioUrl': audioUrl,
        }),
      ).timeout(const Duration(seconds: 180));

      print('📅 [AdvancedShare] Response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final scheduledPost = ScheduledPost.fromJson(data);
        print('✅ [AdvancedShare] Post scheduled successfully');
        return scheduledPost;
      } else {
        throw Exception('Failed to schedule post: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Schedule error: $e');
      rethrow;
    }
  }

  /// Obtenir les statistiques de partage d'un post
  static Future<ShareStats> getShareStats(String postId) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('📊 [AdvancedShare] Getting share stats for: $postId');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/statistics/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 [AdvancedShare] Stats response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = ShareStats.fromJson(data);
        print('✅ [AdvancedShare] Stats retrieved successfully');
        return stats;
      } else {
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Stats error: $e');
      rethrow;
    }
  }

  /// Partager avec une légende personnalisée
  static Future<void> shareWithCaption({
    required String contentUrl,
    required String caption,
    required List<SocialPlatform> platforms,
    required List<String> accountIds,
    String? audioUrl,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('💬 [AdvancedShare] Sharing with custom caption...');
      print('💬 [AdvancedShare] Platforms: ${platforms.map((e) => e.name).join(', ')}');

      final isVideo = contentUrl.toLowerCase().contains('.mp4') || contentUrl.toLowerCase().contains('.mov');
      final contentType = isVideo ? 'video' : 'image';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/share-now'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': 'temp_id',
          'contentType': contentType,
          'contentUrl': contentUrl,
          'caption': caption,
          'hashtags': [],
          'platforms': platforms.map((e) => e.name).toList(),
          'accountIds': accountIds,
          if (audioUrl != null) 'audioUrl': audioUrl,
        }),
      ).timeout(const Duration(seconds: 180));

      print('💬 [AdvancedShare] Share response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [AdvancedShare] Content shared successfully');
      } else {
        throw Exception('Failed to share: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Share error: $e');
      rethrow;
    }
  }

  /// Générer des hashtags automatiques
  static Future<List<String>> generateHashtags({
    required String content,
    required String category,
    int maxHashtags = 10,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('🏷️ [AdvancedShare] Generating hashtags...');
      print('🏷️ [AdvancedShare] Category: $category');
      print('🏷️ [AdvancedShare] Content length: ${content.length}');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/generate-hashtags'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': content,
          'category': category,
          'maxHashtags': maxHashtags,
        }),
      ).timeout(const Duration(seconds: 10));

      print('🏷️ [AdvancedShare] Hashtags response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hashtags = (data['hashtags'] as List).cast<String>();
        print('✅ [AdvancedShare] Generated ${hashtags.length} hashtags');
        return hashtags;
      } else {
        // Fallback: utiliser les hashtags locaux
        print('⚠️ [AdvancedShare] Using fallback hashtags');
        return PopularHashtags.getHashtagsForCategory(category).take(maxHashtags).toList();
      }
    } catch (e) {
      print('❌ [AdvancedShare] Hashtags error: $e');
      // Fallback: utiliser les hashtags locaux
      return PopularHashtags.getHashtagsForCategory(category).take(maxHashtags).toList();
    }
  }

  /// Partager sur plusieurs comptes simultanément
  static Future<Map<String, bool>> shareToMultipleAccounts({
    required String contentUrl,
    required String caption,
    required List<String> hashtags,
    required List<String> accountIds,
    String? audioUrl,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('👥 [AdvancedShare] Sharing to multiple accounts...');
      print('👥 [AdvancedShare] Accounts: ${accountIds.length}');

      final isVideo = contentUrl.toLowerCase().contains('.mp4') || contentUrl.toLowerCase().contains('.mov');
      final contentType = isVideo ? 'video' : 'image';

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/share-now'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contentId': 'temp_id',
          'contentType': contentType,
          'contentUrl': contentUrl,
          'caption': caption,
          'hashtags': hashtags,
          'platforms': ['instagram'],
          'accountIds': accountIds,
          if (audioUrl != null) 'audioUrl': audioUrl,
        }),
      ).timeout(const Duration(seconds: 180));

      print('👥 [AdvancedShare] Multiple share response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = Map<String, bool>.from(data['results']);
        print('✅ [AdvancedShare] Multi-share completed');
        return results;
      } else {
        throw Exception('Failed to share to multiple accounts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Multi-share error: $e');
      rethrow;
    }
  }

  /// Obtenir la liste des posts programmés
  static Future<List<ScheduledPost>> getScheduledPosts() async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('📋 [AdvancedShare] Getting scheduled posts...');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/scheduled-posts'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('📋 [AdvancedShare] Scheduled posts response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Gérer différents formats de réponse
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey('posts')) {
          list = data['posts'] as List;
        } else if (data is Map && data.containsKey('data')) {
          list = data['data'] as List;
        } else {
          throw Exception('Format de réponse non reconnu: $data');
        }
        
        final posts = list.map((e) => ScheduledPost.fromJson(e as Map<String, dynamic>)).toList();
        print('✅ [AdvancedShare] Found ${posts.length} scheduled posts');
        return posts;
      } else {
        throw Exception('Failed to get scheduled posts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Scheduled posts error: $e');
      rethrow;
    }
  }

  /// Annuler un post programmé
  static Future<void> cancelScheduledPost(String postId) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('❌ [AdvancedShare] Cancelling scheduled post: $postId');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/scheduled-posts/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('❌ [AdvancedShare] Cancel response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ [AdvancedShare] Post cancelled successfully');
      } else {
        throw Exception('Failed to cancel post: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Cancel error: $e');
      rethrow;
    }
  }

  /// Obtenir les comptes sociaux connectés
  static Future<List<SocialAccount>> getConnectedAccounts() async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('🔗 [AdvancedShare] Getting connected accounts...');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/connected-accounts'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('🔗 [AdvancedShare] Accounts response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Gérer différents formats de réponse
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey('accounts')) {
          list = data['accounts'] as List;
        } else if (data is Map && data.containsKey('data')) {
          list = data['data'] as List;
        } else {
          throw Exception('Format de réponse non reconnu: $data');
        }
        
        final accounts = list.map((e) => SocialAccount.fromJson(e as Map<String, dynamic>)).toList();
        print('✅ [AdvancedShare] Found ${accounts.length} connected accounts');
        return accounts;
      } else {
        throw Exception('Failed to get accounts: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Accounts error: $e');
      rethrow;
    }
  }

  /// Connecter un nouveau compte social
  static Future<SocialAccount> connectSocialAccount({
    required SocialPlatform platform,
    required String accessToken,
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('🔗 [AdvancedShare] Connecting ${platform.name} account...');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/connect-account'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'platform': platform.name,
          'accessToken': accessToken,
        }),
      ).timeout(const Duration(seconds: 15));

      print('🔗 [AdvancedShare] Connect response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final account = SocialAccount.fromJson(data);
        print('✅ [AdvancedShare] Account connected successfully');
        return account;
      } else {
        throw Exception('Failed to connect account: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Connect error: $e');
      rethrow;
    }
  }

  /// Déconnecter un compte social
  static Future<void> disconnectSocialAccount(String accountId) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      print('🔌 [AdvancedShare] Disconnecting account: $accountId');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/advanced-share/disconnect-account/$accountId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('🔌 [AdvancedShare] Disconnect response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ [AdvancedShare] Account disconnected successfully');
      } else {
        throw Exception('Failed to disconnect account: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [AdvancedShare] Disconnect error: $e');
      rethrow;
    }
  }
}