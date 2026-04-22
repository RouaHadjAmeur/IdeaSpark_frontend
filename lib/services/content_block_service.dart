import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/content_block.dart';
import '../core/api_config.dart';
import 'auth_service.dart';

class ContentBlockService {
  Future<Map<String, String>> _authHeaders() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final token = authService.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Generate (AI → ContentBlock JSON) ────────────────────────────────────

  Future<ContentBlockGenerationResult> generateVideoIdea({
    required String productName,
    String? productCategory,
    List<String>? keyBenefits,
    String? painPoint,
    String? brandId,
    String? brandTone,
    Map<String, dynamic>? brandAudience,
    List<String>? contentPillars,
    String? activePlanPhase,
    int? currentWeek,
    double? promoRatio,
    String? calendarContext,
    ContentPlatform? platform,
    String? language,
    String? planId,
    String? planPhaseId,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'productName': productName,
      'productCategory': ?productCategory,
      'keyBenefits':     ?keyBenefits,
      'painPoint':        ?painPoint,
      'brandId':          ?brandId,
      'brandTone':        ?brandTone,
      'brandAudience':    ?brandAudience,
      'contentPillars':   ?contentPillars,
      'activePlanPhase':  ?activePlanPhase,
      'currentWeek':      ?currentWeek,
      'promoRatio':       ?promoRatio,
      'calendarContext':  ?calendarContext,
      if (platform        != null) 'platform':         platform.toJson(),
      'language':         ?language,
      'planId':            ?planId,
      'planPhaseId':       ?planPhaseId,
    };

    final response = await http.post(
      Uri.parse(ApiConfig.generateAiVideoIdeaUrl),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ContentBlockGenerationResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Generate video idea failed: ${response.statusCode} ${response.body}');
  }

  // ─── Create (Save as Idea) ─────────────────────────────────────────────────

  Future<ContentBlock> create(CreateContentBlockDto dto) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.createContentBlockUrl),
      headers: headers,
      body: jsonEncode(dto.toJson()),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ContentBlock.fromJson(jsonDecode(response.body));
    }
    throw Exception('Save content block failed: ${response.statusCode} ${response.body}');
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Future<List<ContentBlock>> list({String? brandId, String? planId, ContentBlockStatus? status}) async {
    final headers = await _authHeaders();
    final url = ApiConfig.listContentBlocksUrl(
      brandId: brandId,
      planId:  planId,
      status:  status?.toJson(),
    );
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => ContentBlock.fromJson(j)).toList();
    }
    throw Exception('List content blocks failed: ${response.statusCode}');
  }

  // ─── Get One ──────────────────────────────────────────────────────────────

  Future<ContentBlock> getOne(String id) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse(ApiConfig.contentBlockByIdUrl(id)),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return ContentBlock.fromJson(jsonDecode(response.body));
    }
    throw Exception('Get content block failed: ${response.statusCode}');
  }

  // ─── Update Status ────────────────────────────────────────────────────────

  Future<ContentBlock> updateStatus(String id, ContentBlockStatus newStatus) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse(ApiConfig.updateBlockStatusUrl(id)),
      headers: headers,
      body: jsonEncode({'status': newStatus.toJson()}),
    );
    if (response.statusCode == 200) {
      return ContentBlock.fromJson(jsonDecode(response.body));
    }
    throw Exception('Update status failed: ${response.statusCode} ${response.body}');
  }

  // ─── Progression Calculation ──────────────────────────────────────────────

  Future<double> getPlanProgression(String planId) async {
    try {
      final blocks = await list(planId: planId);
      if (blocks.isEmpty) return 0.0;
      int totalItems = 0;
      int completedItems = 0;
      for (final b in blocks) {
        final checklist = b.productionChecklist.isEmpty ? {
          'Script': false,
          'Shoot / Record': false,
          'Edit': false,
          'Upload': false,
        } : b.productionChecklist;
        totalItems += checklist.length;
        completedItems += checklist.values.where((v) => v).length;
      }
      return totalItems == 0 ? 0.0 : completedItems / totalItems;
    } catch (_) {
      return 0.0;
    }
  }

  // ─── Task Count ───────────────────────────────────────────────────────────

  Future<int> countActiveTasks(List<String> planIds) async {
    try {
      int count = 0;
      for (final pid in planIds) {
        final blocks = await list(planId: pid);
        for (final b in blocks) {
           final checklist = b.productionChecklist.isEmpty ? {
             'Script': false,
             'Shoot / Record': false,
             'Edit': false,
             'Upload': false,
           } : b.productionChecklist;
           count += checklist.values.where((v) => !v).length;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // ─── Update Checklist ─────────────────────────────────────────────────────

  Future<void> updateChecklist(String id, Map<String, bool> checklist, {String? userId}) async {
    final headers = await _authHeaders();
    try {
      final response = await http.patch(
        Uri.parse(ApiConfig.updateChecklistUrl(id)),
        headers: headers,
        body: jsonEncode({
          'productionChecklist': checklist,
          'updatedBy': ?userId,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 204) return;
      // Fallback: try the generic update route
      final fallback = await http.patch(
        Uri.parse(ApiConfig.contentBlockByIdUrl(id)),
        headers: headers,
        body: jsonEncode({
          'productionChecklist': checklist,
          'updatedBy': ?userId,
        }),
      );
      if (fallback.statusCode != 200 && fallback.statusCode != 204) {
        // Backend doesn't support checklist sync yet — local update only.
        debugPrint('[ContentBlockService] Checklist sync unavailable '
            '(${fallback.statusCode}). Saved locally only.');
      }
    } catch (e) {
      debugPrint('[ContentBlockService] updateChecklist error: $e');
    }
  }

  // ─── Update Assignment ──────────────────────────────────────────────────

  Future<ContentBlock> updateAssignment(String id, {String? userId, String? userName}) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse(ApiConfig.contentBlockByIdUrl(id)),
      headers: headers,
      body: jsonEncode({
        'assignedTo': userId,
        'assignedToName': userName,
      }),
    );
    if (response.statusCode == 200) {
      return ContentBlock.fromJson(jsonDecode(response.body));
    }
    throw Exception('Update assignment failed: ${response.statusCode} ${response.body}');
  }

  // ─── Attach to Plan ───────────────────────────────────────────────────────

  Future<ContentBlock> attachToPlan(
    String id, {
    required String planId,
    String? planPhaseId,
    String? phaseLabel,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.attachBlockToPlanUrl(id)),
      headers: headers,
      body: jsonEncode({
        'planId': planId,
        'planPhaseId': ?planPhaseId,
        'phaseLabel':  ?phaseLabel,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ContentBlock.fromJson(jsonDecode(response.body));
    }
    throw Exception('Attach to plan failed: ${response.statusCode} ${response.body}');
  }

  // ─── Schedule ─────────────────────────────────────────────────────────────

  Future<ContentBlock> schedule(String id, DateTime scheduledAt) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.scheduleBlockUrl(id)),
      headers: headers,
      body: jsonEncode({'scheduledAt': scheduledAt.toIso8601String()}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ContentBlock.fromJson(jsonDecode(response.body));
    }
    throw Exception('Schedule failed: ${response.statusCode} ${response.body}');
  }

  // ─── Replace ──────────────────────────────────────────────────────────────

  Future<ContentBlock> replace(String sourceId, String targetId) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse(ApiConfig.replaceBlockUrl(sourceId)),
      headers: headers,
      body: jsonEncode({'targetId': targetId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ContentBlock.fromJson(jsonDecode(response.body));
    }
    throw Exception('Replace failed: ${response.statusCode} ${response.body}');
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> delete(String id) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse(ApiConfig.contentBlockByIdUrl(id)),
      headers: headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }
}
