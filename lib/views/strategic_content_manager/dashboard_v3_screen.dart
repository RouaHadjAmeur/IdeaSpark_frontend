import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/call_service.dart';
import '../../modules/chat/call_screen.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/home_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/plan_view_model.dart';
import '../../models/plan.dart';
import '../../models/brand.dart';
import '../../core/app_localizations.dart';
import '../../services/dashboard_alert_service.dart';
import '../../view_models/collaboration_view_model.dart';

class DashboardV3Screen extends StatelessWidget {
  const DashboardV3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: DashboardContent());
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent>
    with WidgetsBindingObserver {
  String? _selectedBrandId;
  bool _profileChecked = false;

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
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _initCallService();
    });
  }

  void _initCallService() {
    final callService = CallService();
    callService.connect();
    callService.onIncomingCall.listen((data) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              remoteUserId: data['callerId']!,
              remoteUserName: data['callerName']!,
              isIncoming: true,
            ),
          ),
        );
      }
    });
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
    final planVm = context.read<PlanViewModel>();
    final collabVm = context.read<CollaborationViewModel>();
    await Future.wait([
      brandVm.loadBrands(),
      planVm.loadPlans(),
      collabVm.loadNotifications(),
    ]);
    if (!mounted) return;
    await planVm.loadAllCalendar();
    if (!mounted) return;
    await planVm.loadAiAlerts(brands: brandVm.brands);
    if (mounted) _checkProfileCompletion();
  }

  void _checkProfileCompletion() {
    if (_profileChecked) return;
    _profileChecked = true;

    final authVm = context.read<AuthViewModel>();
    final user = authVm.currentUser;
    if (user == null) return;

    final isIncomplete = (user.username?.isEmpty ?? true) ||
        (user.role == null) ||
        (user.skills?.isEmpty ?? true) ||
        (user.interests?.isEmpty ?? true);

    if (isIncomplete) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            ctx.tr('profile_incomplete_title'),
            style: const TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(ctx.tr('profile_incomplete_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('later')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/edit-profile');
              },
              child: Text(ctx.tr('complete_now')),
            ),
          ],
        ),
      );
    }
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
          final d = DateTime(
            e.scheduledDate.year,
            e.scheduledDate.month,
            e.scheduledDate.day,
          );
          return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
        }).length;

        int avgPromo = 0;
        if (filteredActive.isNotEmpty) {
          int total = 0;
          for (final p in filteredActive) {
            total += ((p.contentMixPreference['promotional'] ?? 0) as num)
                .toInt();
          }
          avgPromo = total ~/ filteredActive.length;
        }

        final isLoading =
            (brandVm.isLoading || planVm.isLoading) &&
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
                    const SizedBox(height: 16),
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
                  ],
                ),
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
            Text(
              'DASHBOARD',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
                letterSpacing: 1.2,
              ),
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
        Consumer<CollaborationViewModel>(
          builder: (context, collabVm, _) {
            final count = collabVm.unreadNotificationsCount;
            return GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Badge(
                    label: Text('$count'),
                    isLabelVisible: count > 0,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 22,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

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
                onTap: () => setState(
                  () => _selectedBrandId == brand.id
                      ? _selectedBrandId = null
                      : _selectedBrandId = brand.id,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required int thisWeekCount,
    required int activePlansCount,
    required int brandsCount,
    required int avgPromo,
  }) {
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
          sub: 'Total brands',
        ),
        _StatCard(
          label: 'Promo',
          value: '$avgPromo%',
          sub: 'Avg promotional',
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See all',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGeneratorsGrid(BuildContext context, HomeViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    final generators = vm.generatorList;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: generators.map((gen) {
        return GestureDetector(
          onTap: () {
            if (gen.typeId == 'camera-coach') {
              context.push('/camera-coach');
            } else if (gen.typeId == 'video') {
              context.push('/video-ideas-form');
            } else if (gen.typeId == 'product') {
              context.push('/product-ideas-form');
            } else if (gen.typeId == 'slogans') {
              context.push('/slogans-form');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  gen.icon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  gen.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendsSection(BuildContext context, HomeViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    final trends = vm.trendingList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Tendances'),
        const SizedBox(height: 12),
        ...trends.asMap().entries.map((entry) {
          final idx = entry.key;
          final trend = entry.value;
          final colors = [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
            colorScheme.tertiaryContainer,
            colorScheme.surfaceContainerHighest,
          ];
          final bgColor = colors[idx % colors.length];

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.push('/trends'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trend,
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool isHighlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlight
            ? colorScheme.primary.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 9,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;

  const _BrandPill({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
