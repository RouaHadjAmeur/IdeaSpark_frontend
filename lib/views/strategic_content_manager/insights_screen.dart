import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_localizations.dart';
import '../../models/brand.dart';
import '../../models/plan.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/plan_view_model.dart';

// ─── Local data models ────────────────────────────────────────────────────────

class _ScoreFactor {
  final String label;
  final String detail;
  final String status; // good | neutral | bad
  const _ScoreFactor(
      {required this.label, required this.detail, required this.status});
}

class _RiskItem {
  final String label;
  final String severity; // info | warning | critical
  const _RiskItem({required this.label, required this.severity});
}

class _AlertItem {
  final String title;
  final String description;
  final String severity; // info | warning | critical
  final String actionLabel;
  const _AlertItem({
    required this.title,
    required this.description,
    required this.severity,
    required this.actionLabel,
  });
}

class _AIAction {
  final String emoji;
  final String title;
  final String description;
  final String actionLabel;
  const _AIAction({
    required this.emoji,
    required this.title,
    required this.description,
    required this.actionLabel,
  });
}

// ─── Score colour helpers ─────────────────────────────────────────────────────

Color _scoreColor(int score) {
  if (score >= 75) return const Color(0xFF6BCB77);
  if (score >= 50) return const Color(0xFFFFD93D);
  return const Color(0xFFFF6B6B);
}

String _scoreLabel(int score) {
  if (score >= 75) return 'Excellent';
  if (score >= 50) return 'Good';
  return 'Needs attention';
}

// ─── Insights Screen ──────────────────────────────────────────────────────────

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _timeWindow = '30d'; // 7d | 30d | 90d
  String? _selectedBrandId; // null = all brands

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final brandVm = context.read<BrandViewModel>();
    final planVm = context.read<PlanViewModel>();
    await Future.wait([brandVm.loadBrands(), planVm.loadPlans()]);
    if (!mounted) return;
    await planVm.loadAllCalendar();
  }

  int get _windowDays =>
      _timeWindow == '7d' ? 7 : _timeWindow == '30d' ? 30 : 90;

  // ─── Score computations ──────────────────────────────────────────────────

  int _computeContentHealth(
    List<Plan> active,
    List<CalendarEntry> entries,
    int windowDays,
    int brandsCount,
  ) {
    int score = 40;
    if (active.isNotEmpty) score += 15;
    if (brandsCount > 0) score += 5;
    final expected = (windowDays / 7 * 2 * math.max(1, active.length));
    if (expected > 0) {
      score += ((entries.length / expected).clamp(0.0, 1.0) * 20).round();
    }
    if (active.isNotEmpty) {
      final mix = _computeAvgMix(active);
      final promo = mix['promotional'] ?? 0;
      if (promo <= 40) score += 15;
      if (promo <= 30) score += 5;
    }
    return score.clamp(0, 100);
  }

  int _computeAudienceMatch(
    List<Brand> brands,
    String? brandId,
  ) {
    final targets = brandId == null
        ? brands
        : brands.where((b) => b.id == brandId).toList();
    if (targets.isEmpty) return 35;
    int total = 0;
    for (final b in targets) {
      int s = 15;
      if (b.audience.ageRange.isNotEmpty) s += 15;
      if (b.audience.gender.isNotEmpty) s += 10;
      if (b.audience.interests.isNotEmpty) s += 10;
      if (b.mainGoal != null) s += 15;
      if (b.uniqueAngle != null && b.uniqueAngle!.isNotEmpty) s += 15;
      if (b.contentPillars.isNotEmpty) s += 10;
      if (b.kpis != null && !b.kpis!.isEmpty) s += 10;
      total += s.clamp(0, 100);
    }
    return (total / targets.length).round().clamp(0, 100);
  }

  int _computeConversionPotential(List<Plan> active) {
    if (active.isEmpty) return 20;
    int score = 25;
    final mix = _computeAvgMix(active);
    final promo = mix['promotional'] ?? 0;
    if (promo >= 20 && promo <= 40) {
      score += 25;
    } else if (promo > 0) {
      score += 10;
    }
    int hard = 0, total = 0;
    for (final plan in active) {
      for (final phase in plan.phases) {
        for (final block in phase.contentBlocks) {
          total++;
          if (block.ctaType == CtaType.hard) hard++;
        }
      }
    }
    if (total > 0) {
      final ratio = hard / total;
      if (ratio >= 0.2 && ratio <= 0.4) {
        score += 25;
      } else if (ratio > 0) {
        score += 10;
      }
    }
    final hasConversion = active.any((p) =>
        p.objective == PlanObjective.salesConversion ||
        p.objective == PlanObjective.leadGeneration);
    score += hasConversion ? 20 : 5;
    return score.clamp(0, 100);
  }

  Map<String, double> _computeAvgMix(List<Plan> plans) {
    if (plans.isEmpty) {
      return {
        'educational': 25,
        'promotional': 25,
        'storytelling': 25,
        'authority': 25
      };
    }
    final keys = ['educational', 'promotional', 'storytelling', 'authority'];
    final result = <String, double>{};
    for (final k in keys) {
      double sum = 0;
      for (final p in plans) {
        sum += ((p.contentMixPreference[k] ?? 0) as num).toDouble();
      }
      result[k] = sum / plans.length;
    }
    return result;
  }

  List<double> _generateSparkline(List<CalendarEntry> entries, int days) {
    const buckets = 7;
    final values = List<double>.filled(buckets, 0);
    final now = DateTime.now();
    for (final e in entries) {
      final daysAgo = now.difference(e.scheduledDate).inDays;
      if (daysAgo >= 0 && daysAgo < days) {
        final bucket =
            ((daysAgo / days) * buckets).floor().clamp(0, buckets - 1);
        values[buckets - 1 - bucket]++;
      }
    }
    return values;
  }

  // ─── Risk / Alert / AI computations ─────────────────────────────────────

  List<_RiskItem> _computeRisks(
    List<Brand> brands,
    List<Plan> all,
    List<Plan> active,
    List<CalendarEntry> entries,
    DateTime now,
  ) {
    final risks = <_RiskItem>[];
    if (active.isEmpty && brands.isNotEmpty) {
      risks.add(const _RiskItem(
          label: 'No active campaigns running', severity: 'critical'));
    }
    if (active.isNotEmpty) {
      final mix = _computeAvgMix(active);
      if ((mix['promotional'] ?? 0) > 40) {
        risks.add(const _RiskItem(
            label: 'Promotional ratio above 40%', severity: 'warning'));
      }
      if ((mix['educational'] ?? 0) < 20) {
        risks.add(const _RiskItem(
            label: 'Educational content below 20%', severity: 'warning'));
      }
    }
    final brandsNoActive = brands.where((b) =>
        !all.any((p) => p.brandId == b.id && p.status == PlanStatus.active));
    if (brandsNoActive.isNotEmpty) {
      risks.add(_RiskItem(
        label: '${brandsNoActive.length} brand(s) without active plan',
        severity: brandsNoActive.length > 1 ? 'warning' : 'info',
      ));
    }
    final noUpcoming = active.where((p) =>
        !entries.any((e) => e.planId == p.id && e.scheduledDate.isAfter(now)));
    if (noUpcoming.isNotEmpty) {
      risks.add(const _RiskItem(
          label: 'Active plan(s) with no upcoming posts', severity: 'warning'));
    }
    if (risks.isEmpty) {
      risks.add(const _RiskItem(
          label: 'No risks detected — strategy on track', severity: 'info'));
    }
    return risks;
  }

  List<_AlertItem> _computeAlerts(
    List<Brand> brands,
    List<Plan> all,
    List<Plan> active,
    List<CalendarEntry> entries,
    DateTime now,
  ) {
    final alerts = <_AlertItem>[];
    for (final brand in brands) {
      if (!all.any(
          (p) => p.brandId == brand.id && p.status == PlanStatus.active)) {
        alerts.add(_AlertItem(
          title: '"${brand.name}" has no active campaign',
          description:
              'This brand has been inactive. Launch a plan to stay consistent.',
          severity: 'critical',
          actionLabel: 'Create Plan →',
        ));
      }
    }
    for (final plan in active) {
      final promo =
          ((plan.contentMixPreference['promotional'] ?? 0) as num).toInt();
      if (promo > 40) {
        alerts.add(_AlertItem(
          title: '"${plan.name}" — High promo ratio ($promo%)',
          description:
              'Excessive promotion can reduce audience trust over time.',
          severity: 'warning',
          actionLabel: 'Optimize Mix →',
        ));
      }
    }
    for (final plan in active) {
      if (!entries
          .any((e) => e.planId == plan.id && e.scheduledDate.isAfter(now))) {
        alerts.add(_AlertItem(
          title: '"${plan.name}" — No upcoming posts',
          description:
              'Add this plan to the calendar to maintain posting schedule.',
          severity: 'warning',
          actionLabel: 'Add to Calendar →',
        ));
      }
    }
    return alerts;
  }

  List<_AIAction> _computeAIActions(
    List<Brand> brands,
    List<Plan> active,
    Map<String, double> mix,
  ) {
    final actions = <_AIAction>[];
    if ((mix['promotional'] ?? 0) > 35) {
      actions.add(const _AIAction(
        emoji: '📚',
        title: 'Balance with educational content',
        description:
            'Generate 2–3 educational posts to lower your promotional ratio below 40%.',
        actionLabel: 'Generate Ideas',
      ));
    }
    if (active.any((p) => p.objective == PlanObjective.productLaunch)) {
      actions.add(const _AIAction(
        emoji: '🎬',
        title: 'Create a teaser video for your launch',
        description:
            'Product launch phase detected. A teaser reel boosts pre-launch awareness.',
        actionLabel: 'Generate Video Idea',
      ));
    }
    if (brands.isNotEmpty && active.isEmpty) {
      actions.add(const _AIAction(
        emoji: '🚀',
        title: 'Launch your first strategic plan',
        description:
            'Your brands are ready. AI will structure your next 4 weeks of content.',
        actionLabel: 'Plan New Project',
      ));
    }
    if (actions.isEmpty) {
      actions.add(const _AIAction(
        emoji: '✨',
        title: 'Generate fresh content ideas',
        description:
            'Your strategy looks solid. Keep momentum with a new batch of ideas.',
        actionLabel: 'Quick Generate',
      ));
    }
    return actions;
  }

  // ─── Score factor breakdowns ─────────────────────────────────────────────

  List<_ScoreFactor> _healthFactors(
      List<Plan> active, List<CalendarEntry> entries, int days) {
    final mix = _computeAvgMix(active);
    final promo = mix['promotional'] ?? 0;
    final expected = (days / 7 * 2 * math.max(1, active.length));
    final freqOk = expected > 0 && entries.length >= expected * 0.7;
    return [
      _ScoreFactor(
        label: 'Active campaigns',
        detail: active.isEmpty
            ? 'No active plans found'
            : '${active.length} plan(s) running',
        status: active.isEmpty ? 'bad' : 'good',
      ),
      _ScoreFactor(
        label: 'Posting frequency',
        detail:
            freqOk ? 'On track with target frequency' : 'Below expected rate',
        status: freqOk ? 'good' : 'neutral',
      ),
      _ScoreFactor(
        label: 'Promo ratio',
        detail: promo <= 40
            ? '${promo.round()}% — within safe zone'
            : '${promo.round()}% — exceeds 40% limit',
        status: promo <= 40 ? 'good' : 'bad',
      ),
      _ScoreFactor(
        label: 'Content variety',
        detail: active.isEmpty
            ? 'Define a content mix in your plans'
            : '4 content types in rotation',
        status: active.isEmpty ? 'neutral' : 'good',
      ),
    ];
  }

  List<_ScoreFactor> _audienceFactors(List<Brand> brands, String? brandId) {
    final targets = brandId == null
        ? brands
        : brands.where((b) => b.id == brandId).toList();
    if (targets.isEmpty) {
      return [
        const _ScoreFactor(
            label: 'No brands defined',
            detail: 'Create a brand to enable audience analysis',
            status: 'bad')
      ];
    }
    final b = targets.first;
    return [
      _ScoreFactor(
          label: 'Audience age range',
          detail: b.audience.ageRange.isEmpty ? 'Not defined' : b.audience.ageRange,
          status: b.audience.ageRange.isEmpty ? 'bad' : 'good'),
      _ScoreFactor(
          label: 'Target gender',
          detail: b.audience.gender.isEmpty ? 'Not defined' : b.audience.gender,
          status: b.audience.gender.isEmpty ? 'neutral' : 'good'),
      _ScoreFactor(
          label: 'Interests',
          detail: b.audience.interests.isEmpty
              ? 'Not specified'
              : '${b.audience.interests.length} interests listed',
          status: b.audience.interests.isEmpty ? 'neutral' : 'good'),
      _ScoreFactor(
          label: 'KPI targets',
          detail: (b.kpis == null || b.kpis!.isEmpty)
              ? 'No KPIs configured'
              : 'KPIs configured',
          status: (b.kpis == null || b.kpis!.isEmpty) ? 'neutral' : 'good'),
    ];
  }

  List<_ScoreFactor> _conversionFactors(List<Plan> active) {
    if (active.isEmpty) {
      return [
        const _ScoreFactor(
            label: 'No active plans',
            detail: 'Launch a campaign to measure conversion potential',
            status: 'bad')
      ];
    }
    int hard = 0, total = 0;
    for (final p in active) {
      for (final ph in p.phases) {
        for (final b in ph.contentBlocks) {
          total++;
          if (b.ctaType == CtaType.hard) hard++;
        }
      }
    }
    final ctaRatio = total > 0 ? (hard / total * 100).round() : 0;
    final hasConversion = active.any((p) =>
        p.objective == PlanObjective.salesConversion ||
        p.objective == PlanObjective.leadGeneration);
    final mix = _computeAvgMix(active);
    final promo = (mix['promotional'] ?? 0).round();
    return [
      _ScoreFactor(
          label: 'Conversion objectives',
          detail: hasConversion
              ? 'Conversion-focused plan active'
              : 'No conversion-goal plan found',
          status: hasConversion ? 'good' : 'neutral'),
      _ScoreFactor(
          label: 'Hard CTA usage',
          detail: total == 0
              ? 'No content blocks defined yet'
              : '$ctaRatio% of posts have clear CTA',
          status: ctaRatio >= 20 ? 'good' : 'neutral'),
      _ScoreFactor(
          label: 'Promotional volume',
          detail: '$promo% avg promo content',
          status: promo >= 20 && promo <= 40
              ? 'good'
              : promo > 40
                  ? 'bad'
                  : 'neutral'),
    ];
  }

  // ─── Score detail modal ──────────────────────────────────────────────────

  void _showScoreDetail(
    BuildContext context,
    String title,
    int score,
    List<_ScoreFactor> factors,
    List<double> sparkline,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => _ScoreDetailSheet(
          title: title,
          score: score,
          factors: factors,
          sparkline: sparkline,
          scrollController: controller,
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<BrandViewModel, PlanViewModel>(
      builder: (context, brandVm, planVm, _) {
        final cs = Theme.of(context).colorScheme;
        final brands = brandVm.brands;
        final now = DateTime.now();
        final cutoff = now.subtract(Duration(days: _windowDays));

        final allEntries = planVm.allCalendarEntries;
        final entries = _selectedBrandId == null
            ? allEntries
            : allEntries.where((e) => e.brandId == _selectedBrandId).toList();
        final windowEntries =
            entries.where((e) => e.scheduledDate.isAfter(cutoff)).toList();

        final activePlans =
            planVm.plans.where((p) => p.status == PlanStatus.active).toList();
        final filteredActive = _selectedBrandId == null
            ? activePlans
            : activePlans
                .where((p) => p.brandId == _selectedBrandId)
                .toList();

        final contentHealth = _computeContentHealth(
            filteredActive, windowEntries, _windowDays, brands.length);
        final audienceMatch =
            _computeAudienceMatch(brands, _selectedBrandId);
        final conversionPot = _computeConversionPotential(filteredActive);
        final avgMix = _computeAvgMix(filteredActive);
        final risks = _computeRisks(
            brands, planVm.plans, filteredActive, entries, now);
        final alerts = _computeAlerts(
            brands, planVm.plans, filteredActive, entries, now);
        final aiActions =
            _computeAIActions(brands, filteredActive, avgMix);

        final sparkHealth = _generateSparkline(windowEntries, _windowDays);
        final sparkAudience =
            List<double>.generate(7, (i) => 50 + i * 3.0);
        final sparkConversion =
            List<double>.generate(7, (i) => 25 + (i % 3) * 7.0);

        final isLoading = (brandVm.isLoading || planVm.isLoading) &&
            brands.isEmpty &&
            planVm.plans.isEmpty;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: isLoading
                    ? const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey('$_timeWindow|$_selectedBrandId'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, cs),
                            const SizedBox(height: 16),
                            _buildFilters(context, cs, brands),
                            const SizedBox(height: 28),

                            // A – Strategic Snapshot
                            _SectionLabel(
                                letter: 'A',
                                title: context.tr('insights_snapshot')),
                            const SizedBox(height: 12),
                            _buildSnapshot(context, cs,
                                posts: windowEntries.length,
                                active: filteredActive.length,
                                health: contentHealth,
                                risks: risks
                                    .where((r) => r.severity != 'info')
                                    .length),
                            const SizedBox(height: 28),

                            // B – Health Scores
                            _SectionLabel(
                                letter: 'B',
                                title:
                                    context.tr('insights_health_scores')),
                            const SizedBox(height: 12),
                            _HealthScoreCard(
                              title:
                                  context.tr('insights_content_health'),
                              score: contentHealth,
                              sparkline: sparkHealth,
                              onTap: () => _showScoreDetail(
                                  context,
                                  context.tr('insights_content_health'),
                                  contentHealth,
                                  _healthFactors(filteredActive,
                                      windowEntries, _windowDays),
                                  sparkHealth),
                            ),
                            const SizedBox(height: 10),
                            _HealthScoreCard(
                              title:
                                  context.tr('insights_audience_match'),
                              score: audienceMatch,
                              sparkline: sparkAudience,
                              onTap: () => _showScoreDetail(
                                  context,
                                  context.tr('insights_audience_match'),
                                  audienceMatch,
                                  _audienceFactors(
                                      brands, _selectedBrandId),
                                  sparkAudience),
                            ),
                            const SizedBox(height: 10),
                            _HealthScoreCard(
                              title:
                                  context.tr('insights_conversion_pot'),
                              score: conversionPot,
                              sparkline: sparkConversion,
                              onTap: () => _showScoreDetail(
                                  context,
                                  context.tr('insights_conversion_pot'),
                                  conversionPot,
                                  _conversionFactors(filteredActive),
                                  sparkConversion),
                            ),
                            const SizedBox(height: 28),

                            // C – Content Distribution
                            _SectionLabel(
                                letter: 'C',
                                title:
                                    context.tr('insights_content_dist')),
                            const SizedBox(height: 12),
                            _buildContentDistribution(
                                context, cs, avgMix),
                            const SizedBox(height: 28),

                            // D – Risk Indicators
                            _SectionLabel(
                                letter: 'D',
                                title: context.tr('insights_risks')),
                            const SizedBox(height: 12),
                            _buildRisks(context, cs, risks),
                            const SizedBox(height: 28),

                            // E – Strategic Alerts
                            if (alerts.isNotEmpty) ...[
                              _SectionLabel(
                                  letter: 'E',
                                  title: context.tr('insights_alerts')),
                              const SizedBox(height: 12),
                              ...alerts.map((a) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: _AlertCard(alert: a),
                                  )),
                              const SizedBox(height: 18),
                            ],

                            // F – AI Recommended Actions
                            _SectionLabel(
                                letter: 'F',
                                title: context.tr('insights_ai_actions')),
                            const SizedBox(height: 12),
                            ...aiActions.map((a) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: _AIActionCard(action: a),
                                )),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('insights_title'),
              style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface),
            ),
            Text(
              context.tr('insights_subtitle'),
              style:
                  TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(Icons.menu_rounded, size: 20, color: cs.onSurface),
          ),
        ),
      ],
    );
  }

  // ─── Filters ─────────────────────────────────────────────────────────────

  Widget _buildFilters(
      BuildContext context, ColorScheme cs, List<Brand> brands) {
    return Row(
      children: [
        ...['7d', '30d', '90d'].map((w) {
          final active = _timeWindow == w;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _timeWindow = w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? cs.primary : cs.outlineVariant),
                ),
                child: Text(
                  w.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        GestureDetector(
          onTap: () => _showBrandPicker(context, cs, brands),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _selectedBrandId != null
                  ? cs.primary.withValues(alpha: 0.1)
                  : cs.surfaceContainerHighest,
              border: Border.all(
                  color: _selectedBrandId != null
                      ? cs.primary.withValues(alpha: 0.5)
                      : cs.outlineVariant),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.label_outline_rounded,
                    size: 13,
                    color: _selectedBrandId != null
                        ? cs.primary
                        : cs.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  _selectedBrandId == null
                      ? 'All Brands'
                      : (brands
                              .where((b) => b.id == _selectedBrandId)
                              .map((b) => b.name)
                              .firstOrNull ??
                          '—'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _selectedBrandId != null
                        ? cs.primary
                        : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 13,
                    color: _selectedBrandId != null
                        ? cs.primary
                        : cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showBrandPicker(
      BuildContext context, ColorScheme cs, List<Brand> brands) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('Filter by Brand',
                style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            const SizedBox(height: 12),
            _BrandPickerTile(
              label: 'All Brands',
              isSelected: _selectedBrandId == null,
              cs: cs,
              onTap: () {
                setState(() => _selectedBrandId = null);
                Navigator.pop(ctx);
              },
            ),
            ...brands.map((b) => _BrandPickerTile(
                  label: b.name,
                  isSelected: _selectedBrandId == b.id,
                  cs: cs,
                  onTap: () {
                    setState(() => _selectedBrandId = b.id);
                    Navigator.pop(ctx);
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ─── A – Snapshot ────────────────────────────────────────────────────────

  Widget _buildSnapshot(
    BuildContext context,
    ColorScheme cs, {
    required int posts,
    required int active,
    required int health,
    required int risks,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _SnapshotCard(
          label: 'Posts ($_timeWindow)',
          value: '$posts',
          icon: Icons.calendar_today_rounded,
          color: cs.primary,
          cs: cs,
        ),
        _SnapshotCard(
          label: 'Active Plans',
          value: '$active',
          icon: Icons.rocket_launch_rounded,
          color: const Color(0xFF6BCB77),
          cs: cs,
        ),
        _SnapshotCard(
          label: 'Content Health',
          value: '$health',
          icon: Icons.favorite_rounded,
          color: _scoreColor(health),
          cs: cs,
        ),
        _SnapshotCard(
          label: 'Risk Signals',
          value: '$risks',
          icon: Icons.warning_amber_rounded,
          color: risks > 0
              ? const Color(0xFFFF6B6B)
              : const Color(0xFF6BCB77),
          cs: cs,
        ),
      ],
    );
  }

  // ─── C – Content Distribution ────────────────────────────────────────────

  Widget _buildContentDistribution(
      BuildContext context, ColorScheme cs, Map<String, double> mix) {
    final items = [
      (
        label: 'Educational',
        key: 'educational',
        color: cs.primary,
        target: '30–40%'
      ),
      (
        label: 'Promotional',
        key: 'promotional',
        color: const Color(0xFFFF6B6B),
        target: '20–35%'
      ),
      (
        label: 'Storytelling',
        key: 'storytelling',
        color: cs.tertiary,
        target: '15–25%'
      ),
      (
        label: 'Authority',
        key: 'authority',
        color: const Color(0xFF6BCB77),
        target: '10–20%'
      ),
    ];
    final total =
        items.fold<double>(0, (s, e) => s + (mix[e.key] ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final pct =
                      total > 0 ? (mix[item.key] ?? 0) / total : 0.25;
                  return Expanded(
                    flex: (pct * 100).round().clamp(1, 100),
                    child: Container(
                      color: item.color,
                      margin: EdgeInsets.only(
                          right: entry.key < items.length - 1 ? 2 : 0),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) {
            final pct = total > 0
                ? ((mix[item.key] ?? 0) / total * 100).round()
                : 25;
            final isHigh = item.key == 'promotional' && pct > 40;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(item.label,
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurface))),
                      Text(
                        'Target: ${item.target}',
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: 10),
                      if (isHigh)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('HIGH',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF6B6B))),
                        ),
                      Text('$pct%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isHigh
                                  ? const Color(0xFFFF6B6B)
                                  : cs.onSurface)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 5,
                      backgroundColor:
                          cs.outlineVariant.withValues(alpha: 0.35),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          isHigh
                              ? const Color(0xFFFF6B6B)
                              : item.color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── D – Risk Indicators ─────────────────────────────────────────────────

  Widget _buildRisks(
      BuildContext context, ColorScheme cs, List<_RiskItem> risks) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: risks.asMap().entries.map((entry) {
          final idx = entry.key;
          final risk = entry.value;
          final (icon, color) = switch (risk.severity) {
            'critical' => (
                Icons.error_rounded,
                const Color(0xFFFF6B6B)
              ),
            'warning' => (
                Icons.warning_amber_rounded,
                const Color(0xFFFFD93D)
              ),
            _ => (
                Icons.check_circle_rounded,
                const Color(0xFF6BCB77)
              ),
          };
          return Column(
            children: [
              if (idx > 0)
                Divider(color: cs.outlineVariant, height: 16),
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(risk.label,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurface))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      risk.severity.toUpperCase(),
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: color),
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String letter;
  final String title;

  const _SectionLabel({required this.letter, required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(letter,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─── Health Score Card ────────────────────────────────────────────────────────

class _HealthScoreCard extends StatelessWidget {
  final String title;
  final int score;
  final List<double> sparkline;
  final VoidCallback onTap;

  const _HealthScoreCard({
    required this.title,
    required this.score,
    required this.sparkline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _scoreColor(score);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // Animated ring gauge
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: score / 100),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, value, _) => SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(56, 56),
                      painter: _RingPainter(
                        progress: value,
                        color: color,
                        bgColor: cs.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '$score',
                      style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text(_scoreLabel(score),
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            // Mini sparkline + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 60,
                  height: 28,
                  child: CustomPaint(
                    painter: _SparklinePainter(
                        values: sparkline, color: color),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 16, color: cs.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Alert Card ───────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final _AlertItem alert;

  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (borderColor, icon, label) = switch (alert.severity) {
      'critical' => (
          const Color(0xFFFF6B6B),
          Icons.error_rounded,
          'CRITICAL'
        ),
      'warning' => (
          const Color(0xFFFFD93D),
          Icons.warning_amber_rounded,
          'WARNING'
        ),
      _ => (cs.primary, Icons.info_outline_rounded, 'INFO'),
    };

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: borderColor),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: borderColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(alert.title,
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 4),
          Text(alert.description,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.4)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: borderColor.withValues(alpha: 0.12),
                foregroundColor: borderColor,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(alert.actionLabel,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Action Card ───────────────────────────────────────────────────────────

class _AIActionCard extends StatelessWidget {
  final _AIAction action;

  const _AIActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.06),
            cs.secondary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(action.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title,
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(action.description,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: cs.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action.actionLabel,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Snapshot Card ────────────────────────────────────────────────────────────

class _SnapshotCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  const _SnapshotCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const Spacer(),
          Text(value,
              style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ─── Brand Picker Tile ────────────────────────────────────────────────────────

class _BrandPickerTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _BrandPickerTile({
    required this.label,
    required this.isSelected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Icon(
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
        size: 20,
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.normal,
              color: isSelected ? cs.primary : cs.onSurface)),
    );
  }
}

// ─── Score Detail Bottom Sheet ────────────────────────────────────────────────

class _ScoreDetailSheet extends StatelessWidget {
  final String title;
  final int score;
  final List<_ScoreFactor> factors;
  final List<double> sparkline;
  final ScrollController scrollController;

  const _ScoreDetailSheet({
    required this.title,
    required this.score,
    required this.factors,
    required this.sparkline,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _scoreColor(score);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Ring + Title
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: score / 100),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (_, value, _) => SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(76, 76),
                        painter: _RingPainter(
                          progress: value,
                          color: color,
                          bgColor:
                              cs.outlineVariant.withValues(alpha: 0.25),
                          strokeWidth: 6,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$score',
                              style: GoogleFonts.syne(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: color)),
                          Text('/100',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.syne(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_scoreLabel(score),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Trend sparkline
          Text('Trend (${7} periods)',
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Container(
            height: 56,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: CustomPaint(
              painter:
                  _SparklinePainter(values: sparkline, color: color),
            ),
          ),
          const SizedBox(height: 24),
          // Score breakdown
          Text('Score breakdown',
              style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 14),
          ...factors.map((f) {
            final (icon, fColor) = switch (f.status) {
              'good' => (
                  Icons.check_circle_rounded,
                  const Color(0xFF6BCB77)
                ),
              'bad' => (
                  Icons.cancel_rounded,
                  const Color(0xFFFF6B6B)
                ),
              _ => (
                  Icons.radio_button_unchecked_rounded,
                  const Color(0xFFFFD93D)
                ),
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: fColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface)),
                        Text(f.detail,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Sparkline Painter ────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _SparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height -
          ((values[i] - minVal) / range) * (size.height * 0.75) -
          size.height * 0.1;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath
          ..moveTo(x, size.height)
          ..lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}
