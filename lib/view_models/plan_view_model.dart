import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plan.dart';
import '../models/brand.dart';
import '../models/content_block.dart' as cb;
import '../services/plan_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../services/content_block_service.dart';
import '../services/dashboard_alert_service.dart';

class PlanViewModel extends ChangeNotifier {
  // ─── State ────────────────────────────────────────────────────────────────

  List<Plan> _plans = [];
  Plan? _currentPlan;
  List<CalendarEntry> _allCalendarEntries = [];

  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isSaving = false;
  String? _error;
  List<String> _hiddenPlanIds = [];

  // ─── AI Dashboard Alerts ──────────────────────────────────────────────────
  final _alertService = DashboardAlertService();
  List<DashboardAlert> _aiAlerts = [];
  bool _isLoadingAlerts = false;
  DateTime? _alertsLastRefreshed;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Plan> get plans => _plans.where((p) => !_hiddenPlanIds.contains(p.id)).toList();
  Plan? get currentPlan => _currentPlan;
  List<CalendarEntry> get allCalendarEntries => _allCalendarEntries;

  Plan? getDraftPlanForBrand(String brandId) {
    try {
      return _plans.firstWhere(
        (p) => p.brandId == brandId && p.status == PlanStatus.draft,
      );
    } catch (_) {
      return null;
    }
  }

  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSaving => _isSaving;
  String? get error => _error;

  List<DashboardAlert> get aiAlerts => _aiAlerts;
  bool get isLoadingAlerts => _isLoadingAlerts;
  DateTime? get alertsLastRefreshed => _alertsLastRefreshed;

  Map<String, dynamic> _aiInsights = {};
  Map<String, dynamic> get aiInsights => _aiInsights;

  // ─── Plans CRUD ───────────────────────────────────────────────────────────

  Future<void> loadPlans({String? brandId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _plans = await PlanService.getPlans(brandId: brandId);
      await _loadHiddenPlans();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches plans for a brandId and MERGES them into the existing list (no replace).
  Future<void> mergeCollaboratorPlans(String brandId) async {
    try {
      final fetched = await PlanService.getPlans(brandId: brandId);
      debugPrint('[PlanViewModel] mergeCollaboratorPlans($brandId) → ${fetched.length} plans');
      for (final plan in fetched) {
        final idx = _plans.indexWhere((p) => p.id == plan.id);
        if (idx >= 0) {
          _plans[idx] = plan; // update existing
        } else {
          _plans.add(plan);   // add new
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[PlanViewModel] mergeCollaboratorPlans($brandId) error: $e');
    }
  }

  /// Fetches a single plan by ID (full detail including phases + content blocks)
  /// and updates it in the local list.
  Future<void> loadPlanById(String planId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final plan = await PlanService.getPlanById(planId);
      _currentPlan = plan;
      _updatePlanInList(plan);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cache of phase metadata (name, productIds, description) keyed by planId+phaseIdx
  // Used to restore data that the backend strips on PATCH responses
  final Map<String, List<Phase>> _phaseMetaCache = {};

  /// Call before updatePhases to cache phase metadata
  void _cachePhasesMeta(String planId, List<Phase> phases) {
    _phaseMetaCache[planId] = List.of(phases);
  }

  /// Fetches content blocks from the dedicated endpoint and injects them
  /// into the matching plan phases. Call this when the plan's phases show 0 blocks.
  Future<void> loadAndInjectBlocks(String planId) async {
    try {
      final blockService = ContentBlockService();
      final rawBlocks = await blockService.list(planId: planId);
      debugPrint('[PlanViewModel] loadAndInjectBlocks($planId) → ${rawBlocks.length} blocks');
      if (rawBlocks.isEmpty) return;

      final planIdx = _plans.indexWhere((p) => p.id == planId);
      if (planIdx < 0) return;
      final plan = _plans[planIdx];

      // Use cached phase metadata if available (backend strips names/products on PATCH)
      final cachedPhases = _phaseMetaCache[planId] ?? plan.phases;
      final originalPhases = cachedPhases;

      debugPrint('[PlanViewModel] phases: ${plan.phases.map((p) => 'id=${p.id} name=${p.name} products=${p.productIds.length}').toList()}');
      debugPrint('[PlanViewModel] block phaseIds: ${rawBlocks.map((b) => 'phaseId=${b.planPhaseId} label=${b.phaseLabel}').toSet().toList()}');

      // Group blocks by planPhaseId first, then by phaseLabel as fallback
      final byPhaseId    = <String, List<cb.ContentBlock>>{};
      final byPhaseLabel = <String, List<cb.ContentBlock>>{};
      for (final b in rawBlocks) {
        if (b.planPhaseId != null && b.planPhaseId!.isNotEmpty) {
          byPhaseId.putIfAbsent(b.planPhaseId!, () => []).add(b);
        } else if (b.phaseLabel != null && b.phaseLabel!.isNotEmpty) {
          byPhaseLabel.putIfAbsent(b.phaseLabel!, () => []).add(b);
        } else {
          // No phase info — put in unassigned bucket (will go to phase 0)
          byPhaseId.putIfAbsent('__unassigned__', () => []).add(b);
        }
      }

      // Rebuild phases with injected blocks
      final updatedPhases = plan.phases.asMap().entries.map((entry) {
        final idx   = entry.key;
        final phase = entry.value;

        // Match by phase ID first, then by phase name/label, then unassigned to first phase
        List<cb.ContentBlock> phaseBlocks = [];
        if (phase.id != null && phase.id!.isNotEmpty) {
          phaseBlocks = byPhaseId[phase.id] ?? [];
        }
        if (phaseBlocks.isEmpty && phase.name.isNotEmpty) {
          phaseBlocks = byPhaseLabel[phase.name] ?? [];
        }
        // Last resort: put all unmatched blocks in first phase
        if (phaseBlocks.isEmpty && idx == 0) {
          phaseBlocks = [
            ...byPhaseId['__unassigned__'] ?? [],
            // Also include blocks whose phaseId doesn't match any current phase
            ...byPhaseId.entries
                .where((e) => e.key != '__unassigned__' &&
                    !plan.phases.any((p) => p.id == e.key))
                .expand((e) => e.value),
          ];
        }
        debugPrint('[PlanViewModel] phase[$idx] "${phase.name}" id=${phase.id} → ${phaseBlocks.length} blocks matched');

        if (phaseBlocks.isEmpty) return phase;

        // Restore original phase metadata if backend stripped it
        final original = idx < originalPhases.length ? originalPhases[idx] : phase;
        // Also try to get name from the blocks' phaseLabel as last resort
        final labelFromBlocks = phaseBlocks.firstWhere(
          (b) => b.phaseLabel != null && b.phaseLabel!.isNotEmpty,
          orElse: () => phaseBlocks.first,
        ).phaseLabel ?? '';
        final restoredName = phase.name.isNotEmpty ? phase.name
            : original.name.isNotEmpty ? original.name
            : labelFromBlocks;
        final restoredProducts = phase.productIds.isNotEmpty ? phase.productIds : original.productIds;
        final restoredDesc = phase.description?.isNotEmpty == true ? phase.description : original.description;

        // Convert cb.ContentBlock → plan.ContentBlock
        final planBlocks = phaseBlocks.map((b) => ContentBlock(
          id: b.id,
          title: b.title,
          pillar: b.contentType.toJson(),
          format: _mapFormat(b.format),
          ctaType: CtaType.soft,
          status: _mapStatus(b.status),
          hook: b.hooks.isNotEmpty ? b.hooks.first : '',
          caption: b.scriptOutline ?? '',
        )).toList();

        // Merge: avoid duplicates by ID
        final existingIds = phase.contentBlocks.map((b) => b.id).toSet();
        final newBlocks = planBlocks.where((b) => !existingIds.contains(b.id)).toList();

        return Phase(
          id: phase.id,
          name: restoredName,
          weekNumber: phase.weekNumber,
          description: restoredDesc,
          contentBlocks: [...phase.contentBlocks, ...newBlocks],
          status: phase.status,
          productIds: restoredProducts,
        );
      }).toList();

      _plans[planIdx] = Plan(
        id: plan.id,
        brandId: plan.brandId,
        name: plan.name,
        objective: plan.objective,
        startDate: plan.startDate,
        endDate: plan.endDate,
        durationWeeks: plan.durationWeeks,
        promotionIntensity: plan.promotionIntensity,
        postingFrequency: plan.postingFrequency,
        platforms: plan.platforms,
        productIds: plan.productIds,
        contentMixPreference: plan.contentMixPreference,
        status: plan.status,
        userId: plan.userId,
        phases: updatedPhases,
        projectDNA: plan.projectDNA,
        notes: plan.notes,
        notesSeen: plan.notesSeen,
        lastNoteAuthorId: plan.lastNoteAuthorId,
        collaboratorIds: plan.collaboratorIds,
        linkedStrategyId: plan.linkedStrategyId,
        linkedPhaseId: plan.linkedPhaseId,
        createdAt: plan.createdAt,
        updatedAt: plan.updatedAt,
      );
      final totalInjected = updatedPhases.expand((p) => p.contentBlocks).length;
      debugPrint('[PlanViewModel] loadAndInjectBlocks injected — total blocks now: $totalInjected');
      notifyListeners();
    } catch (e) {
      debugPrint('[PlanViewModel] loadAndInjectBlocks error: $e');
    }
  }

  ContentFormat _mapFormat(cb.ContentFormat? f) {
    switch (f) {
      case cb.ContentFormat.reel:     return ContentFormat.reel;
      case cb.ContentFormat.story:    return ContentFormat.story;
      case cb.ContentFormat.carousel: return ContentFormat.carousel;
      default:                        return ContentFormat.post;
    }
  }

  ContentBlockStatus _mapStatus(cb.ContentBlockStatus? s) {
    switch (s) {
      case cb.ContentBlockStatus.approved:   return ContentBlockStatus.approved;
      case cb.ContentBlockStatus.scheduled:  return ContentBlockStatus.scheduled;
      case cb.ContentBlockStatus.terminated: return ContentBlockStatus.published;
      case cb.ContentBlockStatus.inProcess:  return ContentBlockStatus.draft;
      default:                               return ContentBlockStatus.empty;
    }
  }

  /// Creates a plan, then immediately calls the AI to generate its structure.
  /// Returns the generated plan on success, null on failure.
  Future<Plan?> createAndGenerate(Map<String, dynamic> data, String brandId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      // 1. Create draft
      final plan = await PlanService.createPlan(data, brandId);
      _currentPlan = plan;
      _plans = [plan, ..._plans];
      notifyListeners();

      // 2. Generate AI structure
      _isGenerating = true;
      notifyListeners();
      final generated = await PlanService.generatePlanStructure(plan.id!);
      _currentPlan = generated;
      _updatePlanInList(generated);
      return generated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSaving = false;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Plan?> generatePlanStructure(String planId) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      final generated = await PlanService.generatePlanStructure(planId);
      _currentPlan = generated;
      _updatePlanInList(generated);
      return generated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<Plan?> activatePlan(String planId, {String? currentUserId, bool isBrandOwner = false}) async {
    // RBAC: Simple users can only activate plans they generated
    if (!isBrandOwner && currentUserId != null) {
      final plan = _plans.firstWhere((p) => p.id == planId, orElse: () => _currentPlan!);
      if (plan.userId != currentUserId) {
        _error = "Unauthorized: You can only activate plans you generated.";
        notifyListeners();
        return null;
      }
    }

    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await PlanService.activatePlan(planId);
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) _currentPlan = updated;
      return updated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<List<CalendarEntry>?> addToCalendar(String planId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final entries = await PlanService.addToCalendar(planId);
      final plan = _currentPlan ?? _plans.firstWhere((p) => p.id == planId, orElse: () => entries.isEmpty ? throw '' : _currentPlan!);
      final enriched = _enrichEntries(entries, plan);
      // Merge into _allCalendarEntries
      _allCalendarEntries.removeWhere((e) => e.planId == planId);
      _allCalendarEntries.addAll(enriched);
      _allCalendarEntries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      return enriched;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan(String planId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await PlanService.deletePlan(planId);
      _plans.removeWhere((p) => p.id == planId);
      _allCalendarEntries.removeWhere((e) => e.planId == planId);
      if (_currentPlan?.id == planId) _currentPlan = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> hidePlan(String planId) async {
    if (!_hiddenPlanIds.contains(planId)) {
      _hiddenPlanIds.add(planId);
      await _saveHiddenPlans();
      notifyListeners();
    }
  }

  Future<void> _loadHiddenPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hiddenPlanIds = prefs.getStringList('hidden_plan_ids') ?? [];
    } catch (_) {}
  }

  Future<void> _saveHiddenPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('hidden_plan_ids', _hiddenPlanIds);
    } catch (_) {}
  }

  Future<Plan?> regeneratePlan(String planId) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();
    try {
      final plan = await PlanService.regeneratePlan(planId);
      _updatePlanInList(plan);
      if (_currentPlan?.id == planId) _currentPlan = plan;
      return plan;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ─── Calendar loading ─────────────────────────────────────────────────────

  /// Loads calendar entries for ALL plans and merges them.
  Future<void> loadAllCalendar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_plans.isEmpty) {
        _plans = await PlanService.getPlans();
      }
      
      final List<CalendarEntry> combined = [];
      for (final plan in _plans) {
        try {
          // Fetch plan detail (with phases) if not already fully loaded
          Plan detail = plan;
          if (plan.phases.isEmpty) {
            detail = await PlanService.getPlanById(plan.id!);
            _updatePlanInList(detail);
          }
          final entries = await PlanService.getCalendar(plan.id!);
          if (entries.isNotEmpty) {
            combined.addAll(_enrichEntries(entries, detail));
          }
        } catch (e) {
          debugPrint('Calendar load failed for plan ${plan.id}: $e');
        }
      }
      combined.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      _allCalendarEntries = combined;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads calendar entries for a single plan (used after add-to-calendar).
  Future<void> loadCalendarForPlan(String planId) async {
    try {
      Plan? plan = _plans.firstWhere((p) => p.id == planId, orElse: () => _currentPlan!);
      if (plan.phases.isEmpty) {
        plan = await PlanService.getPlanById(planId);
        _updatePlanInList(plan);
      }
      final entries = await PlanService.getCalendar(planId);
      final enriched = _enrichEntries(entries, plan);
      _allCalendarEntries.removeWhere((e) => e.planId == planId);
      _allCalendarEntries.addAll(enriched);
      _allCalendarEntries.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  // ─── Helper: enrich entries with content block details ───────────────────

  List<CalendarEntry> _enrichEntries(List<CalendarEntry> entries, Plan plan) {
    return entries.map((entry) {
      final block = plan.findBlock(entry.contentBlockId);
      return block != null ? entry.withBlock(block) : entry;
    }).toList();
  }

  // ─── AI Dashboard Alerts ──────────────────────────────────────────────────

  /// Fetches Gemini-powered alerts. Results are cached 24 h on-device.
  /// Pass [brands] from BrandViewModel, [forceRefresh] to bypass cache.
  Future<void> loadAiAlerts({
    required List<Brand> brands,
    bool forceRefresh = false,
  }) async {
    _isLoadingAlerts = true;
    notifyListeners();
    try {
      _aiAlerts = await _alertService.getAlerts(
        plans: _plans,
        entries: _allCalendarEntries,
        brands: brands,
        forceRefresh: forceRefresh,
      );
      _alertsLastRefreshed = DateTime.now();
    } catch (_) {
      // Keep whatever alerts we already have
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }

  /// Forces a fresh Gemini call and clears the 24 h cache.
  Future<void> refreshAiAlerts({required List<Brand> brands}) async {
    await _alertService.clearCache();
    await loadAiAlerts(brands: brands, forceRefresh: true);
  }

  // ─── Project DNA & AI Insights ──────────────────────────────────────────────

  Future<bool> updateProjectDNA(String planId, Map<String, dynamic> dna) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await PlanService.updateProjectDNA(planId, dna);
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) _currentPlan = updated;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updatePlanNotes(String planId, String notes, {String? authorId}) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await PlanService.updatePlan(planId, {
        'notes': notes,
        'notesSeen': false,
        'lastNoteAuthorId': authorId,
      });
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) _currentPlan = updated;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> markNoteAsSeen(String planId) async {
    try {
      final updated = await PlanService.updatePlan(planId, {'notesSeen': true});
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) _currentPlan = updated;
    } catch (e) {
      debugPrint('Error marking note as seen: $e');
    }
  }

  Future<void> loadAIInsights(String planId) async {
    _isLoading = true;
    _error = null;
    Future.microtask(() => notifyListeners());
    try {
      _aiInsights = await PlanService.getAIInsights(planId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateHook(String planId, String blockId) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final updated = await PlanService.generateHook(planId, blockId);
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) {
        _currentPlan = updated;
        final block = updated.findBlock(blockId);
        if (block != null && block.status == ContentBlockStatus.empty) {
          await updateBlockStatus(blockId, ContentBlockStatus.draft);
        }
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> generateCaption(String planId, String blockId) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final updated = await PlanService.generateCaption(planId, blockId);
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) {
        _currentPlan = updated;
        final block = updated.findBlock(blockId);
        if (block != null && block.status == ContentBlockStatus.empty) {
          await updateBlockStatus(blockId, ContentBlockStatus.draft);
        }
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> generateVideoIdea(String planId, String blockId) async {
    _isGenerating = true;
    notifyListeners();
    try {
      final updated = await PlanService.generateVideoIdea(planId, blockId);
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) {
        _currentPlan = updated;
        final block = updated.findBlock(blockId);
        if (block != null && block.status == ContentBlockStatus.empty) {
          await updateBlockStatus(blockId, ContentBlockStatus.draft);
        }
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  // ─── Misc ─────────────────────────────────────────────────────────────────

  void setCurrentPlan(Plan plan) {
    _currentPlan = plan;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _updatePlanInList(Plan updated) {
    final idx = _plans.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      _plans[idx] = updated;
    } else {
      _plans.insert(0, updated);
    }
  }

  Future<void> scheduleBlock(String blockId, DateTime scheduledAt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      debugPrint('Scheduling block $blockId for $scheduledAt');
      // In a real implementation, you'd call:
      // await ContentBlockService().schedule(blockId, scheduledAt);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBlockStatus(String blockId, ContentBlockStatus status) async {
    if (_currentPlan?.id == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      debugPrint('Updating block $blockId status to ${status.name}');
      final updated = await PlanService.updateBlockStatus(_currentPlan!.id!, blockId, status);
      _updatePlanInList(updated);
      _currentPlan = updated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePhases(String planId, List<Phase> phases) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      debugPrint('[PlanViewModel] updatePhases planId=$planId phases=${phases.length}');
      final phaseBlockCounts = phases.map((p) => '${p.name}:${p.contentBlocks.length}').join(', ');
      debugPrint('[PlanViewModel] updatePhases blocks per phase: $phaseBlockCounts');
      // Cache phase metadata before backend strips it
      _cachePhasesMeta(planId, phases);
      final payload = {'phases': phases.map((p) => p.toJson()).toList()};
      debugPrint('[PlanViewModel] first phase toJson: ${payload['phases']?.first}');
      final updated = await PlanService.updatePlan(planId, payload);
      final returnedBlockCounts = updated.phases.map((p) => '${p.name}:${p.contentBlocks.length}').join(', ');
      debugPrint('[PlanViewModel] updatePhases success — phases returned: ${updated.phases.length}, blocks: $returnedBlockCounts');
      debugPrint('[PlanViewModel] returned phase IDs: ${updated.phases.map((p) => p.id).toList()}');
      _updatePlanInList(updated);
      if (_currentPlan?.id == planId) _currentPlan = updated;
      // Fetch fresh plan then inject content blocks
      await loadPlanById(planId);
      await loadAndInjectBlocks(planId);
      await _notifyCollaboratorsPhaseUpdate(planId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[PlanViewModel] updatePhases error: $_error');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Sends a notification to all collaborators that the plan phases were updated.
  Future<void> _notifyCollaboratorsPhaseUpdate(String planId) async {
    try {
      final socket = SocketService();
      socket.emit('plan_updated', {'planId': planId, 'eventType': 'phases_updated'});
      socket.emit('notify_collaborators', {'planId': planId, 'eventType': 'post_assigned'});

      // Emit directly to each collaborator's user room
      try {
        final plan = _plans.firstWhere((p) => p.id == planId, orElse: () => _plans.first);
        for (final collaboratorId in plan.collaboratorIds) {
          socket.emitToRoom('user:$collaboratorId', 'notification', {
            'type': 'post_assigned',
            'planId': planId,
            'relatedPlanId': planId,
            'message': 'De nouveaux posts vous ont été assignés',
            'read': false,
          });
        }
      } catch (_) {}
      debugPrint('[PlanViewModel] emitted plan_updated socket event for $planId');
    } catch (e) {
      debugPrint('[PlanViewModel] socket emit error (non-fatal): $e');
    }
    try {
      await PlanService.notifyCollaborators(planId, 'phases_updated');
    } catch (e) {
      debugPrint('[PlanViewModel] notifyCollaborators REST error (non-fatal): $e');
    }
  }

}
