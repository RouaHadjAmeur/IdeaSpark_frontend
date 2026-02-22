import 'dart:convert';
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
      if (productCategory != null) 'productCategory': productCategory,
      if (keyBenefits     != null) 'keyBenefits':     keyBenefits,
      if (painPoint       != null) 'painPoint':        painPoint,
      if (brandId         != null) 'brandId':          brandId,
      if (brandTone       != null) 'brandTone':        brandTone,
      if (brandAudience   != null) 'brandAudience':    brandAudience,
      if (contentPillars  != null) 'contentPillars':   contentPillars,
      if (activePlanPhase != null) 'activePlanPhase':  activePlanPhase,
      if (currentWeek     != null) 'currentWeek':      currentWeek,
      if (promoRatio      != null) 'promoRatio':       promoRatio,
      if (calendarContext != null) 'calendarContext':  calendarContext,
      if (platform        != null) 'platform':         platform.toJson(),
      if (language        != null) 'language':         language,
      if (planId          != null) 'planId':            planId,
      if (planPhaseId     != null) 'planPhaseId':       planPhaseId,
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
        if (planPhaseId != null) 'planPhaseId': planPhaseId,
        if (phaseLabel  != null) 'phaseLabel':  phaseLabel,
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
