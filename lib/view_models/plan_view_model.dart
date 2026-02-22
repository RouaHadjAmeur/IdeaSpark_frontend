import 'package:flutter/foundation.dart';
import '../models/plan.dart';
import '../models/brand.dart';
import '../services/plan_service.dart';
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

  // ─── AI Dashboard Alerts ──────────────────────────────────────────────────
  final _alertService = DashboardAlertService();
  List<DashboardAlert> _aiAlerts = [];
  bool _isLoadingAlerts = false;
  DateTime? _alertsLastRefreshed;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Plan> get plans => _plans;
  Plan? get currentPlan => _currentPlan;
  List<CalendarEntry> get allCalendarEntries => _allCalendarEntries;

  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSaving => _isSaving;
  String? get error => _error;

  List<DashboardAlert> get aiAlerts => _aiAlerts;
  bool get isLoadingAlerts => _isLoadingAlerts;
  DateTime? get alertsLastRefreshed => _alertsLastRefreshed;

  // ─── Plans CRUD ───────────────────────────────────────────────────────────

  Future<void> loadPlans({String? brandId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _plans = await PlanService.getPlans(brandId: brandId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<Plan?> activatePlan(String planId) async {
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
    try {
      await PlanService.deletePlan(planId);
      _plans.removeWhere((p) => p.id == planId);
      _allCalendarEntries.removeWhere((e) => e.planId == planId);
      if (_currentPlan?.id == planId) _currentPlan = null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
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

  /// Loads calendar entries for ALL active plans and merges them.
  Future<void> loadAllCalendar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_plans.isEmpty) {
        _plans = await PlanService.getPlans();
      }
      final activePlans = _plans.where((p) => p.status == PlanStatus.active).toList();
      final List<CalendarEntry> combined = [];
      for (final plan in activePlans) {
        try {
          // Fetch plan detail (with phases) if not already loaded
          Plan detail = plan;
          if (plan.phases.isEmpty) {
            detail = await PlanService.getPlanById(plan.id!);
            _updatePlanInList(detail);
          }
          final entries = await PlanService.getCalendar(plan.id!);
          combined.addAll(_enrichEntries(entries, detail));
        } catch (_) {
          // Skip plans whose calendar can't be loaded
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
}
