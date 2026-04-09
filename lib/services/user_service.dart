import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import 'auth_service.dart';

class SocialService {
  SocialService._();
  static final SocialService _instance = SocialService._();
  factory SocialService() => _instance;

  final _authService = AuthService();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authService.accessToken != null) 'Authorization': 'Bearer ${_authService.accessToken}',
  };

  // --- RECHERCHE ---
  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/users/search?query=$query'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AppUser.fromJson(json)).toList();
    } else {
      throw Exception('Échec de la recherche d\'utilisateurs');
    }
  }

  // --- INVITATIONS ---
  Future<void> sendInvitation(String receiverId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/invitations'),
      headers: _headers,
      body: jsonEncode({'receiver': receiverId}),
    );

    if (response.statusCode != 201) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Échec de l\'envoi de l\'invitation');
    }
  }

  Future<List<dynamic>> getPendingInvitations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/invitations/pending'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Échec de la récupération des invitations');
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/invitations/$invitationId/accept'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Échec de l\'acceptation');
    }
  }

  Future<void> rejectInvitation(String invitationId) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/invitations/$invitationId/reject'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Échec du refus');
    }
  }

  // --- AMITIÉS ---
  Future<List<AppUser>> getFriends() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/friendships'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final currentUserId = _authService.currentUser?.id;
      
      // Dans le backend, Friendship contient user1 et user2. 
      // On doit extraire l'ami (celui qui n'est pas moi).
      return data.map((f) {
        final u1 = AppUser.fromJson(f['user1']);
        final u2 = AppUser.fromJson(f['user2']);
        return u1.id == currentUserId ? u2 : u1;
      }).toList();
    } else {
      throw Exception('Échec de la récupération des amis');
    }
  }
}

