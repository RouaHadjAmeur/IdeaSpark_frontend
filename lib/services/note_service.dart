// note_service.dart
// Service for managing notes and feedback

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/note.dart';
import 'auth_service.dart';

class NoteService {
  static final NoteService _instance = NoteService._();
  factory NoteService() => _instance;
  NoteService._();

  Future<String?> _getToken() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    return authService.accessToken;
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // ─── Create Note ──────────────────────────────────────────────────────────

  Future<Note> createNote(Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notes/create';

    debugPrint('[NoteService] POST $url');
    debugPrint('[NoteService] Body: ${jsonEncode(data)}');

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    debugPrint('[NoteService] createNote status=${response.statusCode}');

    if (response.statusCode == 201) {
      return Note.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to create note: ${response.statusCode} - ${response.body}');
  }

  // ─── Get Notes ────────────────────────────────────────────────────────────

  Future<List<Note>> getNotesByCampaign(String campaignId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notes/campaign/$campaignId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load notes: ${response.statusCode}');
  }

  Future<List<Note>> getNotesByCollaborator(String collaboratorId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/collaborator/notes?collaboratorId=$collaboratorId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load collaborator notes: ${response.statusCode}');
  }

  Future<List<Note>> getUnreadNotes(String collaboratorId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/collaborator/notes/unread?collaboratorId=$collaboratorId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    }

    throw Exception('Failed to load unread notes: ${response.statusCode}');
  }

  Future<Note> getNote(String noteId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notes/$noteId';

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load note: ${response.statusCode}');
  }

  // ─── Mark Note as Seen ────────────────────────────────────────────────────

  Future<Note> markNoteSeen(String noteId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notes/$noteId/mark-seen';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to mark note as seen: ${response.statusCode}');
  }

  // ─── Update Note ──────────────────────────────────────────────────────────

  Future<Note> updateNote(String noteId, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notes/$noteId';

    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return Note.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to update note: ${response.statusCode}');
  }

  // ─── Delete Note ──────────────────────────────────────────────────────────

  Future<void> deleteNote(String noteId) async {
    final token = await _getToken();
    final url = '${ApiConfig.baseUrl}/notes/$noteId';

    final response = await http.delete(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete note: ${response.statusCode}');
    }
  }
}
