import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';
import '../models/plan.dart';
import '../models/brand.dart';
import 'auth_service.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class DashboardAlert {
  final String type;      // 'missed' | 'upcoming' | 'health' | 'info'
  final String severity;  // 'critical' | 'warning' | 'info'
  final String message;

  const DashboardAlert({
    required this.type,
    required this.severity,
    required this.message,
  });

  factory DashboardAlert.fromJson(Map<String, dynamic> j) => DashboardAlert(
        type:     j['type']     ?? 'info',
        severity: j['severity'] ?? 'info',
        message:  j['message']  ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'type': type, 'severity': severity, 'message': message};

  /// Map severity → indicator dot color.
  Color dotColor(ColorScheme cs) {
    switch (severity) {
      case 'critical': return const Color(0xFFFF6B6B);
      case 'warning':  return const Color(0xFFFFD93D);
      default:         return const Color(0xFF6BCB77);
    }
  }
}

// ─── Cache keys ───────────────────────────────────────────────────────────────

const _kAlertsKey     = 'dashboard_alerts_v1';
const _kTimestampKey  = 'dashboard_alerts_ts_v1';
// Refresh every 6 h max, AND always on a new calendar day
const _kCacheTtlHours = 6;

// ─── Service ──────────────────────────────────────────────────────────────────

class DashboardAlertService {
  Future<Map<String, String>> _authHeaders() async {
    final auth = AuthService();
    await auth.isLoggedIn();
    return {
      'Content-Type': 'application/json',
      if (auth.accessToken != null) 'Authorization': 'Bearer ${auth.accessToken}',
    };
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns alerts, using the 24h cache when valid.
  /// Pass [forceRefresh] to bypass the cache.
  Future<List<DashboardAlert>> getAlerts({
    required List<Plan> plans,
    required List<CalendarEntry> entries,
    required List<Brand> brands,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _readCache();
      if (cached != null) return cached;
    }

    try {
      final fresh = await _fetchFromBackend(
          plans: plans, entries: entries, brands: brands);
      await _writeCache(fresh);
      return fresh;
    } catch (_) {
      // If backend fails, return the stale cache or fallback
      final stale = await _readCache(ignoreExpiry: true);
      return stale ?? _localFallback(plans: plans, entries: entries, brands: brands);
    }
  }

  /// Clears the cached alerts so the next call forces a refresh.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAlertsKey);
    await prefs.remove(_kTimestampKey);
  }

  // ── Backend call ───────────────────────────────────────────────────────────

  Future<List<DashboardAlert>> _fetchFromBackend({
    required List<Plan> plans,
    required List<CalendarEntry> entries,
    required List<Brand> brands,
  }) async {
    final headers = await _authHeaders();
    final now = DateTime.now();

    // Build brand context — flag which brands have an active plan
    final activePlanBrandIds =
        plans.where((p) => p.status == PlanStatus.active).map((p) => p.brandId).toSet();

    final brandCtx = brands.map((b) => {
      'id': b.id ?? b.name,
      'name': b.name,
      'hasActivePlan': activePlanBrandIds.contains(b.id),
    }).toList();

    // Build plan context
    final planCtx = plans.map((p) {
      final brandName = brands
          .cast<Brand?>()
          .firstWhere((b) => b?.id == p.brandId, orElse: () => null)
          ?.name ?? '';
      final promo =
          ((p.contentMixPreference['promotional'] ?? 0) as num).toInt();
      return {
        'id': p.id ?? '',
        'name': p.name,
        'brandName': brandName,
        'status': p.status.name,
        'objective': p.objective.apiValue,
        'startDate': p.startDate.toIso8601String().slice(0, 10),
        'endDate': p.endDate.toIso8601String().slice(0, 10),
        'durationWeeks': p.durationWeeks,
        'promoRatio': promo,
      };
    }).toList();

    // Build entries context — include only next 72h + past 48h (for missed detection)
    final window48hAgo = now.subtract(const Duration(hours: 48));
    final window72h    = now.add(const Duration(hours: 72));
    final relevantEntries = entries.where((e) {
      final d = e.scheduledDate;
      return !d.isBefore(DateTime(window48hAgo.year, window48hAgo.month, window48hAgo.day)) &&
             !d.isAfter(DateTime(window72h.year, window72h.month, window72h.day));
    });

    final entryCtx = relevantEntries.map((e) {
      final planName = plans
          .cast<Plan?>()
          .firstWhere((p) => p?.id == e.planId, orElse: () => null)
          ?.name ?? '';
      final brandName = brands
          .cast<Brand?>()
          .firstWhere((b) => b?.id == e.brandId, orElse: () => null)
          ?.name ?? '';
      return {
        'planName': planName,
        'brandName': brandName,
        'title': e.title ?? 'Untitled',
        'platform': e.platform,
        if (e.format != null) 'format': e.format!.label,
        'status': e.status.name,
        'scheduledDate': '${e.scheduledDate.year.toString().padLeft(4,'0')}-'
            '${e.scheduledDate.month.toString().padLeft(2,'0')}-'
            '${e.scheduledDate.day.toString().padLeft(2,'0')}',
        if (e.scheduledTime != null) 'scheduledTime': e.scheduledTime!,
      };
    }).toList();

    final body = jsonEncode({
      'currentDateTime': now.toIso8601String(),
      'brands':  brandCtx,
      'plans':   planCtx,
      'entries': entryCtx,
    });

    final response = await http.post(
      Uri.parse(ApiConfig.dashboardAlertsUrl),
      headers: headers,
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['alerts'] as List<dynamic>?) ?? [];
      return list.map((j) => DashboardAlert.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Dashboard alerts backend returned ${response.statusCode}');
  }

  // ── Local fallback ─────────────────────────────────────────────────────────

  List<DashboardAlert> _localFallback({
    required List<Plan> plans,
    required List<CalendarEntry> entries,
    required List<Brand> brands,
  }) {
    final alerts = <DashboardAlert>[];
    final now = DateTime.now();
    // Cover all of today + all of tomorrow regardless of current hour
    final endOfTomorrow = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 2)); // midnight 2 days from now
    final activePlanBrandIds =
        plans.where((p) => p.status == PlanStatus.active).map((p) => p.brandId).toSet();

    // Missed posts
    for (final e in entries) {
      if (e.status == CalendarEntryStatus.published ||
          e.status == CalendarEntryStatus.cancelled) { continue; }
      final time = e.scheduledTime?.split(':') ?? [];
      final scheduled = DateTime(
        e.scheduledDate.year,
        e.scheduledDate.month,
        e.scheduledDate.day,
        time.length >= 2 ? int.tryParse(time[0]) ?? 0 : 0,
        time.length >= 2 ? int.tryParse(time[1]) ?? 0 : 0,
      );
      if (scheduled.isBefore(now)) {
        final planName = plans
            .cast<Plan?>()
            .firstWhere((p) => p?.id == e.planId, orElse: () => null)
            ?.name ?? 'a plan';
        alerts.add(DashboardAlert(
          type: 'missed',
          severity: 'critical',
          message: '⚠️ Missed: "${e.title ?? 'Post'}" on ${e.platform} ($planName) — mark done or reschedule.',
        ));
        if (alerts.length >= 2) break;
      }
    }

    // Upcoming 24h
    for (final e in entries) {
      if (e.status != CalendarEntryStatus.scheduled) continue;
      final time = e.scheduledTime?.split(':') ?? [];
      final scheduled = DateTime(
        e.scheduledDate.year,
        e.scheduledDate.month,
        e.scheduledDate.day,
        time.length >= 2 ? int.tryParse(time[0]) ?? 23 : 23,
        time.length >= 2 ? int.tryParse(time[1]) ?? 59 : 59,
      );
      if (!scheduled.isBefore(now) && scheduled.isBefore(endOfTomorrow)) {
        final planName = plans
            .cast<Plan?>()
            .firstWhere((p) => p?.id == e.planId, orElse: () => null)
            ?.name ?? 'a plan';
        alerts.add(DashboardAlert(
          type: 'upcoming',
          severity: 'info',
          message: '📅 Due soon: "${e.title ?? 'Post'}" [${e.platform}] for "$planName" at ${e.scheduledTime ?? 'today'}.',
        ));
        if (alerts.where((a) => a.type == 'upcoming').length >= 2) break;
      }
    }

    // Brands without active plan
    for (final b in brands) {
      if (!activePlanBrandIds.contains(b.id)) {
        alerts.add(DashboardAlert(
          type: 'health',
          severity: 'warning',
          message: '🚨 "${b.name}" has no active campaign. Consider launching one.',
        ));
        break;
      }
    }

    // High promo ratio
    for (final p in plans.where((p) => p.status == PlanStatus.active)) {
      final promo = ((p.contentMixPreference['promotional'] ?? 0) as num).toInt();
      if (promo > 40) {
        alerts.add(DashboardAlert(
          type: 'health',
          severity: 'warning',
          message: '📊 "${p.name}" has $promo% promotional content — add educational posts to balance.',
        ));
        break;
      }
    }

    if (alerts.isEmpty) {
      alerts.add(const DashboardAlert(
        type: 'info',
        severity: 'info',
        message: '✅ All looks great! Your content strategy is on track.',
      ));
    }

    return alerts;
  }

  // ── SharedPreferences cache ────────────────────────────────────────────────

  Future<List<DashboardAlert>?> _readCache({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kAlertsKey);
      final ts  = prefs.getInt(_kTimestampKey);
      if (raw == null || ts == null) return null;

      if (!ignoreExpiry) {
        final saved = DateTime.fromMillisecondsSinceEpoch(ts);
        final now   = DateTime.now();
        // Invalidate if it's a new calendar day (midnight boundary)
        final differentDay = saved.year != now.year ||
            saved.month != now.month ||
            saved.day != now.day;
        if (differentDay) return null;
        // Also invalidate after 6 h within the same day
        if (now.difference(saved).inHours >= _kCacheTtlHours) return null;
      }

      final list = (jsonDecode(raw) as List<dynamic>);
      return list.map((j) => DashboardAlert.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(List<DashboardAlert> alerts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kAlertsKey, jsonEncode(alerts.map((a) => a.toJson()).toList()));
      await prefs.setInt(
          _kTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }
}

// ── Helper extension ──────────────────────────────────────────────────────────

extension _StringSlice on String {
  String slice(int start, int end) => substring(start, end > length ? length : end);
}
