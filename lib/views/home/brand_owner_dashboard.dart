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
import '../../services/content_block_service.dart';
import '../../view_models/collaboration_view_model.dart';
import '../strategic_content_manager/dashboard_v2_screen.dart'; // To reuse helper widgets if needed

class BrandOwnerDashboard extends StatefulWidget {
  const BrandOwnerDashboard({super.key});

  @override
  State<BrandOwnerDashboard> createState() => _BrandOwnerDashboardState();
}

class _BrandOwnerDashboardState extends State<BrandOwnerDashboard> with WidgetsBindingObserver {
  String? _selectedBrandId;
  final bool _profileChecked = false;
  double _activeProgression = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<CollaborationViewModel>().loadNotifications();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final brandVm = context.read<BrandViewModel>();
    final planVm  = context.read<PlanViewModel>();
    final collabVm = context.read<CollaborationViewModel>();
    await Future.wait([
      brandVm.loadBrands(),
      planVm.loadPlans(),
      collabVm.loadNotifications(),
    ]);
    if (!mounted) return;

    // Load active campaign progression
    final activePlans = planVm.plans.where((p) => p.status == PlanStatus.active).toList();
    if (activePlans.isNotEmpty) {
      final prog = await fetchProgression(activePlans.first.id!);
      if (mounted) setState(() => _activeProgression = prog);
    }

    if (!mounted) return;
    await planVm.loadAllCalendar();
    if (!mounted) return;
    await planVm.loadAiAlerts(brands: brandVm.brands);
  }

  Future<double> fetchProgression(String planId) async {
      final svc = ContentBlockService();
      return svc.getPlanProgression(planId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BrandViewModel, PlanViewModel>(
      builder: (context, brandVm, planVm, _) {
        final brands = brandVm.brands;
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);

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

        final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        final thisWeekCount = entries.where((e) {
          final d = DateTime(e.scheduledDate.year, e.scheduledDate.month, e.scheduledDate.day);
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        }).length;

        int avgPromo = 0;
        if (filteredActive.isNotEmpty) {
          int total = 0;
          for (final p in filteredActive) {
            total += ((p.contentMixPreference['promotional'] ?? 0) as num).toInt();
          }
          avgPromo = total ~/ filteredActive.length;
        }

        final activeCampaign = filteredActive.isNotEmpty ? filteredActive.first : null;
        String campaignBrandName = '';
        if (activeCampaign != null) {
          campaignBrandName = brands
              .where((b) => b.id == activeCampaign.brandId)
              .map((b) => b.name)
              .firstOrNull ?? '—';
        }

        final next7End = todayStart.add(const Duration(days: 7));
        final next7Entries = entries.where((e) {
          final d = DateTime(e.scheduledDate.year, e.scheduledDate.month, e.scheduledDate.day);
          return !d.isBefore(todayStart) && d.isBefore(next7End);
        }).toList();

        final aiAlerts = planVm.aiAlerts;

        if ((brandVm.isLoading || planVm.isLoading) && brands.isEmpty && planVm.plans.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
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
                  _buildStatsGrid(context, thisWeekCount, filteredActive.length, brands.length, avgPromo),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Quick Actions'),
                  _buildGeneratorsGrid(context, vm),
                  const SizedBox(height: 24),
                  _buildTrendsSection(context, vm),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Active Campaigns', onSeeAll: () => context.push('/projects')),
                  _buildActiveCampaignStrip(context, activeCampaign, campaignBrandName, filteredActive.length),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Next 7 Days'),
                  _buildWeekPreview(context, todayStart, next7Entries, planVm.plans, brands),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Strategic AI Insights'),
                  _buildAIPanel(context, aiAlerts, isLoading: planVm.isLoadingAlerts, lastRefreshed: planVm.alertsLastRefreshed),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
            Text('BRAND OWNER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colorScheme.primary, letterSpacing: 1.2)),
            Text('$firstName 👋', style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          ],
        ),
        _buildNotificationIcon(context),
      ],
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<CollaborationViewModel>(
      builder: (context, collabVm, _) {
        final count = collabVm.unreadNotificationsCount;
        return GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Badge(
                label: Text('$count'), isLabelVisible: count > 0,
                child: Icon(Icons.notifications_none_rounded, size: 22, color: colorScheme.onSurface),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBrandsSwitcher(BuildContext context, List<Brand> brands) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _BrandPillLocal(label: 'All Brands', color: colorScheme.primary, isActive: _selectedBrandId == null, onTap: () => setState(() => _selectedBrandId = null)),
          ...brands.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: _BrandPillLocal(
                label: entry.value.name,
                color: Colors.blueAccent, // Simplified for now
                isActive: _selectedBrandId == entry.value.id,
                onTap: () => setState(() => _selectedBrandId = entry.value.id),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int thisWeek, int active, int totalBrands, int promo) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.4,
      children: [
        _StatCardLocal(label: 'This Week', value: '$thisWeek', sub: 'Posts planned', isHighlight: true),
        _StatCardLocal(label: 'Active', value: '$active', sub: 'Campaigns'),
        _StatCardLocal(label: 'Brands', value: '$totalBrands', sub: 'Total'),
        _StatCardLocal(label: 'Promo %', value: '$promo%', sub: 'Avg Intensity'),
      ],
    );
  }

  Widget _buildGeneratorsGrid(BuildContext context, HomeViewModel vm) {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6,
      children: vm.generatorList.map((e) => _QuickToolCardLocal(icon: e.icon, label: context.tr('gen_${e.typeId}'), onTap: () => context.push(_formRouteForType(e.typeId)))).toList(),
    );
  }

  String _formRouteForType(String typeId) {
    switch (typeId) {
      case 'camera-coach': return '/camera-coach';
      case 'video': return '/video-ideas-form';
      case 'product': return '/product-ideas-form';
      case 'slogans': return '/slogans-form';
      default: return '/criteria';
    }
  }

  Widget _buildTrendsSection(BuildContext context, HomeViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Market Trends', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton(onPressed: () => context.push('/trends'), child: const Text('Analyze')),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: vm.trendingList.map((t) => Padding(padding: const EdgeInsets.only(right: 8), child: Chip(label: Text(t, style: const TextStyle(fontSize: 12))))).toList()),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700)),
          if (onSeeAll != null) GestureDetector(onTap: onSeeAll, child: Text('See All →', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary))),
        ],
      ),
    );
  }

  Widget _buildActiveCampaignStrip(BuildContext context, Plan? campaign, String brandName, int total) {
    if (campaign == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1))),
      child: Column(
        children: [
          Row(
            children: [
              Text(campaign.objective.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(campaign.name, style: const TextStyle(fontWeight: FontWeight.bold)), Text('$brandName · ${campaign.durationWeeks} weeks')])),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${(_activeProgression * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: _activeProgression,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekPreview(BuildContext context, DateTime start, List<CalendarEntry> entries, List<Plan> plans, List<Brand> brands) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final d = start.add(Duration(days: i));
        final hasPosts = entries.any((e) => e.scheduledDate.day == d.day);
        return Column(
          children: [
            Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1], style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Container(width: 32, height: 32, decoration: BoxDecoration(color: hasPosts ? Theme.of(context).colorScheme.primary : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: Colors.grey.withValues(alpha: 0.2))), child: Center(child: Text('${d.day}', style: TextStyle(fontSize: 12, color: hasPosts ? Colors.white : null)))),
          ],
        );
      }),
    );
  }

  Widget _buildAIPanel(BuildContext context, List<DashboardAlert> alerts, {bool isLoading = false, DateTime? lastRefreshed}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.auto_awesome, size: 16, color: Colors.purple), const SizedBox(width: 8), const Text('STRATEGIC SUGGESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))]),
          const SizedBox(height: 12),
          if (isLoading) const LinearProgressIndicator(),
          ...alerts.take(3).map((a) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.circle, size: 6, color: Colors.purple), const SizedBox(width: 8), Expanded(child: Text(a.message, style: const TextStyle(fontSize: 12)))]))),
        ],
      ),
    );
  }
}

class _BrandPillLocal extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  const _BrandPillLocal({required this.label, required this.color, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: isActive ? color : cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: isActive ? color : cs.outlineVariant)),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class _StatCardLocal extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isHighlight;
  const _StatCardLocal({required this.label, required this.value, required this.sub, this.isHighlight = false});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isHighlight ? cs.primaryContainer : cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)), const Spacer(), Text(value, style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.bold, color: isHighlight ? cs.primary : cs.onSurface)), Text(sub, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant))]),
    );
  }
}

class _QuickToolCardLocal extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _QuickToolCardLocal({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon, style: const TextStyle(fontSize: 24)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}
