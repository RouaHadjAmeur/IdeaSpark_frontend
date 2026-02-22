import 'package:flutter/foundation.dart';
import '../models/content_block.dart';
import '../services/content_block_service.dart';

class ContentBlockViewModel extends ChangeNotifier {
  final ContentBlockService _service;

  ContentBlockViewModel({ContentBlockService? service})
      : _service = service ?? ContentBlockService();

  // ─── State ────────────────────────────────────────────────────────────────

  bool isLoading = false;
  String? errorMessage;

  /// The AI generation result (not yet saved)
  ContentBlockGenerationResult? generationResult;

  /// The saved block (after create/update)
  ContentBlock? currentBlock;

  /// User selection for context
  String? selectedBrandId;
  String? selectedBrandName;
  String? selectedProjectId;
  String? selectedPlanId;
  String? selectedPlanName;
  String? selectedPhaseId;
  String? selectedPhaseName;
  DateTime? selectedScheduledAt;

  /// List of blocks
  List<ContentBlock> blocks = [];

  // ─── Selection helpers ────────────────────────────────────────────────────

  void selectBrand(String id, String name) {
    selectedBrandId   = id;
    selectedBrandName = name;
    // Reset downstream
    selectedPlanId    = null;
    selectedPlanName  = null;
    selectedPhaseId   = null;
    selectedPhaseName = null;
    notifyListeners();
  }

  void selectPlan(String id, String name) {
    selectedPlanId   = id;
    selectedPlanName = name;
    selectedPhaseId  = null;
    selectedPhaseName = null;
    notifyListeners();
  }

  void selectPhase(String id, String label) {
    selectedPhaseId   = id;
    selectedPhaseName = label;
    notifyListeners();
  }

  void setScheduledAt(DateTime dt) {
    selectedScheduledAt = dt;
    notifyListeners();
  }

  void clearSelection() {
    selectedBrandId     = null;
    selectedBrandName   = null;
    selectedProjectId   = null;
    selectedPlanId      = null;
    selectedPlanName    = null;
    selectedPhaseId     = null;
    selectedPhaseName   = null;
    selectedScheduledAt = null;
    notifyListeners();
  }

  // ─── Generate AI ContentBlock ─────────────────────────────────────────────

  Future<void> generateVideoIdea({
    required String productName,
    String? brandTone,
    List<String>? contentPillars,
    String? activePlanPhase,
    ContentPlatform? platform,
    String language = 'English',
  }) async {
    _setLoading(true);
    try {
      generationResult = await _service.generateVideoIdea(
        productName:    productName,
        brandId:        selectedBrandId,
        brandTone:      brandTone,
        contentPillars: contentPillars,
        activePlanPhase: activePlanPhase,
        platform:       platform,
        language:       language,
        planId:         selectedPlanId,
        planPhaseId:    selectedPhaseId,
      );
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('ContentBlockViewModel.generateVideoIdea error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ─── Save as Idea ─────────────────────────────────────────────────────────

  Future<ContentBlock?> saveAsIdea() async {
    if (generationResult == null && currentBlock == null) return null;
    if (selectedBrandId == null) {
      errorMessage = 'Please select a brand before saving.';
      notifyListeners();
      return null;
    }

    _setLoading(true);
    try {
      final dto = (generationResult ?? _resultFromBlock(currentBlock!)).toCreateDto(
        brandId:    selectedBrandId!,
        projectId:  selectedProjectId,
        planId:     selectedPlanId,
        planPhaseId: selectedPhaseId,
        phaseLabel: selectedPhaseName,
      );
      currentBlock = await _service.create(dto);
      errorMessage = null;
      return currentBlock;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Approve ──────────────────────────────────────────────────────────────

  Future<ContentBlock?> approve() async {
    if (currentBlock == null) return null;
    _setLoading(true);
    try {
      currentBlock = await _service.updateStatus(
        currentBlock!.id,
        ContentBlockStatus.approved,
      );
      errorMessage = null;
      return currentBlock;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Add to Plan ──────────────────────────────────────────────────────────

  Future<ContentBlock?> addToPlan() async {
    if (currentBlock == null || selectedPlanId == null) {
      errorMessage = 'Select a plan first.';
      notifyListeners();
      return null;
    }
    _setLoading(true);
    try {
      currentBlock = await _service.attachToPlan(
        currentBlock!.id,
        planId:     selectedPlanId!,
        planPhaseId: selectedPhaseId,
        phaseLabel: selectedPhaseName,
      );
      errorMessage = null;
      return currentBlock;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Add to Calendar ──────────────────────────────────────────────────────

  Future<ContentBlock?> addToCalendar() async {
    if (currentBlock == null || selectedScheduledAt == null) {
      errorMessage = 'Select a date/time first.';
      notifyListeners();
      return null;
    }
    _setLoading(true);
    try {
      currentBlock = await _service.schedule(
        currentBlock!.id,
        selectedScheduledAt!,
      );
      errorMessage = null;
      return currentBlock;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Replace Post ─────────────────────────────────────────────────────────

  Future<ContentBlock?> replacePost(String targetId) async {
    if (currentBlock == null) return null;
    _setLoading(true);
    try {
      final updated = await _service.replace(currentBlock!.id, targetId);
      errorMessage = null;
      return updated;
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─── List ─────────────────────────────────────────────────────────────────

  Future<void> loadBlocks({String? brandId, String? planId, ContentBlockStatus? status}) async {
    _setLoading(true);
    try {
      blocks = await _service.list(brandId: brandId, planId: planId, status: status);
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _setLoading(bool val) {
    isLoading = val;
    notifyListeners();
  }

  ContentBlockGenerationResult _resultFromBlock(ContentBlock b) {
    return ContentBlockGenerationResult(
      title:        b.title,
      hooks:        b.hooks,
      scriptOutline: b.scriptOutline ?? '',
      contentType:  b.contentType,
      ctaType:      b.ctaType,
      platform:     b.platform,
      format:       b.format ?? ContentFormat.reel,
      description:  b.description,
      tags:         b.tags,
    );
  }
}
