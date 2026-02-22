import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/home_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/plan_view_model.dart';
import '../../models/plan.dart';
import '../../models/brand.dart';
import '../../core/app_localizations.dart';
import '../../widgets/day_detail_sheet.dart';
import '../../services/dashboard_alert_service.dart';

class DashboardV2Screen extends StatelessWidget {
  const DashboardV2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DashboardContent(),
    );
  }
}

// ─── Dashboard Content ────────────────────────────────────────────────────────

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String? _selectedBrandId; // null = All Brands

  static const _brandColors = [
    Color(0xFFFF6B6B),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFFD93D),
    Color(0xFFC77DFF),
    Color(0xFFFF9F1C),
  ];

  Color _colorForIndex(int i) => _brandColors[i % _brandColors.length];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final brandVm = context.read<BrandViewModel>();
    final planVm  = context.read<PlanViewModel>();
    await Future.wait([brandVm.loadBrands(), planVm.loadPlans()]);
    if (!mounted) return;
    await planVm.loadAllCalendar();
    if (!mounted) return;
    // Load AI alerts after calendar is ready (uses cached result if < 24 h old)
    await planVm.loadAiAlerts(brands: brandVm.brands);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BrandViewModel, PlanViewModel>(
      builder: (context, brandVm, planVm, _) {
        final brands = brandVm.brands;
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

        // ─── Filtered entries & plans ─────────────────────────────────────
        final allEntries = planVm.allCalendarEntries;
        final entries = _selectedBrandId == null
            ? allEntries
            : allEntries.where((e) => e.brandId == _selectedBrandId).toList();

        final activePlans = planVm.plans
            .where((p) => p.status == PlanStatus.active)
            .toList();
        final filteredActive = _selectedBrandId == null
            ? activePlans
            : activePlans.where((p) => p.brandId == _selectedBrandId).toList();

        // ─── Stats ────────────────────────────────────────────────────────
        final weekStart =
            todayStart.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final thisWeekCount = entries.where((e) {
          final d = DateTime(
              e.scheduledDate.year, e.scheduledDate.month, e.scheduledDate.day);
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        }).length;

        int avgPromo = 0;
        if (filteredActive.isNotEmpty) {
          int total = 0;
          for (final p in filteredActive) {
            total +=
                ((p.contentMixPreference['promotional'] ?? 0) as num).toInt();
          }
          avgPromo = total ~/ filteredActive.length;
        }

        // ─── Active campaign ──────────────────────────────────────────────
        final activeCampaign =
            filteredActive.isNotEmpty ? filteredActive.first : null;
        String campaignBrandName = '';
        if (activeCampaign != null) {
          campaignBrandName = brands
              .where((b) => b.id == activeCampaign.brandId)
              .map((b) => b.name)
              .firstOrNull ?? '—';
        }

        // ─── Next 7 days entries ──────────────────────────────────────────
        final next7End = todayStart.add(const Duration(days: 7));
        final next7Entries = entries.where((e) {
          final d = DateTime(
              e.scheduledDate.year, e.scheduledDate.month, e.scheduledDate.day);
          return !d.isBefore(todayStart) && d.isBefore(next7End);
        }).toList();

        // ─── AI Alerts (Gemini-powered, 24 h cache) ───────────────────────
        final aiAlerts = planVm.aiAlerts;

        final isLoading = (brandVm.isLoading || planVm.isLoading) &&
            brands.isEmpty &&
            planVm.plans.isEmpty;

        if (isLoading) {
          return const SafeArea(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Consumer<HomeViewModel>(
                builder: (context, vm, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 24),
                    _buildBrandsSwitcher(context, brands),
                    const SizedBox(height: 24),
                    _buildStatsGrid(
                      context,
                      thisWeekCount: thisWeekCount,
                      activePlansCount: filteredActive.length,
                      brandsCount: brands.length,
                      avgPromo: avgPromo,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'Quick Actions'),
                    _buildGeneratorsGrid(context, vm),
                    const SizedBox(height: 24),
                    _buildTrendsSection(context, vm),
                    const SizedBox(height: 24),
                    _buildLibraryButton(context),
                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'Active Campaign',
                        onSeeAll: () => context.push('/projects')),
                    _buildActiveCampaignStrip(context, activeCampaign,
                        campaignBrandName, filteredActive.length),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'Next 7 Days'),
                    _buildWeekPreview(
                        context, todayStart, next7Entries,
                        planVm.plans, brands),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'AI Suggestions',
                        onSeeAll: planVm.isLoadingAlerts
                            ? null
                            : () => planVm.refreshAiAlerts(brands: brands)),
                    _buildAIPanel(
                      context, aiAlerts,
                      isLoading: planVm.isLoadingAlerts,
                      lastRefreshed: planVm.alertsLastRefreshed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Top bar ─────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();
    final fullName = authVm.displayName ?? authVm.email?.split('@').first ?? '—';
    final firstName = fullName.split(' ').first;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('hello'),
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            Text(
              '$firstName 👋',
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Scaffold.of(context).openDrawer(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Icon(Icons.menu_rounded,
                size: 20, color: colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  // ─── Brand switcher ──────────────────────────────────────────────────────────

  Widget _buildBrandsSwitcher(BuildContext context, List<Brand> brands) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BrandPill(
            label: 'All Brands',
            color: colorScheme.primary,
            isActive: _selectedBrandId == null,
            onTap: () => setState(() => _selectedBrandId = null),
          ),
          ...brands.asMap().entries.map((entry) {
            final idx = entry.key;
            final brand = entry.value;
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _BrandPill(
                label: brand.name,
                color: _colorForIndex(idx),
                isActive: _selectedBrandId == brand.id,
                onTap: () => setState(() => _selectedBrandId == brand.id
                    ? _selectedBrandId = null
                    : _selectedBrandId = brand.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Stats grid ──────────────────────────────────────────────────────────────

  Widget _buildStatsGrid(
    BuildContext context, {
    required int thisWeekCount,
    required int activePlansCount,
    required int brandsCount,
    required int avgPromo,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final promoOk = avgPromo <= 40;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          label: 'This Week',
          value: '$thisWeekCount',
          sub: 'Posts planned',
          isHighlight: thisWeekCount > 0,
        ),
        _StatCard(
          label: 'Active',
          value: '$activePlansCount',
          sub: 'Campaigns running',
        ),
        _StatCard(
          label: 'Brands',
          value: '$brandsCount',
          sub: 'In workspace',
        ),
        _StatCard(
          label: 'Promo %',
          value: activePlansCount > 0 ? '$avgPromo%' : '—',
          sub: activePlansCount > 0
              ? (promoOk ? 'OK · under 40%' : 'High · over 40%')
              : 'No active plans',
          valueColor: activePlansCount > 0
              ? (promoOk ? colorScheme.tertiary : const Color(0xFFFF6B6B))
              : colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  // ─── Generators grid ─────────────────────────────────────────────────────────

  Widget _buildGeneratorsGrid(BuildContext context, HomeViewModel vm) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: vm.generatorList.map((e) {
        return _QuickToolCard(
          icon: e.icon,
          label: context.tr('gen_${e.typeId}'),
          onTap: () => context.push(_formRouteForType(e.typeId)),
        );
      }).toList(),
    );
  }

  String _formRouteForType(String typeId) {
    switch (typeId) {
      case 'video':
        return '/video-ideas-form';
      case 'business':
        return '/business-ideas-form';
      case 'product':
        return '/product-ideas-form';
      case 'slogans':
        return '/slogans-form';
      default:
        return '/criteria';
    }
  }

  // ─── Trends section ───────────────────────────────────────────────────────────

  Widget _buildTrendsSection(BuildContext context, HomeViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('trends'),
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/trends'),
              child: Text(context.tr('see_all'),
                  style:
                      TextStyle(color: colorScheme.primary, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: vm.trendingList.map((t) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _TrendingChip(label: t),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Library button ──────────────────────────────────────────────────────────

  Widget _buildLibraryButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () => context.push('/saved-ideas'),
      icon: const Icon(Icons.folder_rounded, size: 20),
      label: Text(context.tr('library_saved')),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Section header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See all →',
                style: TextStyle(fontSize: 12, color: colorScheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Active campaign strip ───────────────────────────────────────────────────

  Widget _buildActiveCampaignStrip(
    BuildContext context,
    Plan? campaign,
    String brandName,
    int totalActive,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (campaign == null) {
      return GestureDetector(
        onTap: () => context.push('/projects-flow'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Start your first campaign',
                style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final now = DateTime.now();
    final elapsed = now.difference(campaign.startDate).inDays;
    final currentWeek =
        (elapsed ~/ 7).clamp(0, campaign.durationWeeks - 1) + 1;
    final totalWeeks = campaign.durationWeeks;
    final progressPercent =
        ((currentWeek / totalWeeks) * 100).round().clamp(0, 100);

    return GestureDetector(
      onTap: () => context.push('/projects'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border:
              Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(campaign.objective.emoji,
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.name,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$brandName · Week $currentWeek of $totalWeeks',
                    style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant),
                  ),
                  if (totalActive > 1)
                    Text(
                      '+${totalActive - 1} more active',
                      style: TextStyle(
                          fontSize: 10, color: colorScheme.primary),
                    ),
                ],
              ),
            ),
            Text(
              '$progressPercent%',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Next 7 days ─────────────────────────────────────────────────────────────

  Widget _buildWeekPreview(
    BuildContext context,
    DateTime todayStart,
    List<CalendarEntry> entries,
    List<Plan> plans,
    List<Brand> brands,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    const dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    final List<Widget> children = [];
    for (int i = 0; i < 7; i++) {
      if (i > 0) children.add(const SizedBox(width: 6));
      final day = todayStart.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      final dayEntries = entries.where((e) {
        final d = DateTime(e.scheduledDate.year, e.scheduledDate.month,
            e.scheduledDate.day);
        return d == dayKey;
      }).toList();
      final count = dayEntries.length;
      final label = dayLabels[day.weekday - 1];
      children.add(_DayPreview(
        label: label,
        count: count > 0 ? '$count' : '—',
        hasPost: count > 0,
        isToday: i == 0,
        dotColor: count > 0
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        onTap: () => showDayDetailSheet(
          context,
          date: day,
          entries: dayEntries,
          plans: plans,
          brands: brands,
        ),
      ));
    }

    return Row(children: children);
  }

  // ─── AI panel ────────────────────────────────────────────────────────────────

  Widget _buildAIPanel(
    BuildContext context,
    List<DashboardAlert> alerts, {
    bool isLoading = false,
    DateTime? lastRefreshed,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.06),
            cs.secondary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'STRATEGIC ALERTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                      strokeWidth: 1.5, color: cs.primary),
                )
              else if (lastRefreshed != null)
                Text(
                  'Updated ${_timeAgo(lastRefreshed)}',
                  style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Alert rows ──────────────────────────────────────────────────
          if (isLoading && alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Gemini is analyzing your schedule…',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            )
          else
            ...alerts.asMap().entries.map((entry) {
              final idx   = entry.key;
              final alert = entry.value;
              return Column(
                children: [
                  if (idx > 0)
                    Divider(color: cs.outlineVariant, height: 16),
                  _AISuggestion(
                    dotColor: alert.dotColor(cs),
                    text: alert.message,
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _TrendingChip extends StatelessWidget {
  final String label;

  const _TrendingChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _QuickToolCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickToolCard(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback? onTap;

  const _BrandPill({
    required this.label,
    required this.color,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.1)
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
              color: isActive ? color : colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isHighlight;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.isHighlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(
            color: isHighlight
                ? colorScheme.primary
                : colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 1)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
          Text(sub,
              style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8))),
        ],
      ),
    );
  }
}

class _DayPreview extends StatelessWidget {
  final String label;
  final Color dotColor;
  final String count;
  final bool hasPost;
  final bool isToday;
  final VoidCallback? onTap;

  const _DayPreview({
    required this.label,
    required this.dotColor,
    required this.count,
    this.hasPost = false,
    this.isToday = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isToday
              ? colorScheme.primary.withValues(alpha: 0.06)
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isToday
                ? colorScheme.primary.withValues(alpha: 0.5)
                : hasPost
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: isToday
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    fontWeight: isToday
                        ? FontWeight.w700
                        : FontWeight.normal)),
            const SizedBox(height: 6),
            Container(
              width: 20,
              height: 20,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(height: 4),
            Text(count,
                style: TextStyle(
                    fontSize: 10, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      ),
    );
  }
}

class _AISuggestion extends StatelessWidget {
  final Color dotColor;
  final String text;

  const _AISuggestion({required this.dotColor, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 6,
          height: 6,
          decoration:
              BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.4),
          ),
        ),
      ],
    );
  }
}
