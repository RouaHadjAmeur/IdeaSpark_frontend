import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../models/plan.dart';
import '../../models/brand.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/brand_view_model.dart';

class PlansListScreen extends StatefulWidget {
  const PlansListScreen({super.key});

  @override
  State<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends State<PlansListScreen> {
  PlanStatus? _statusFilter;
  String? _brandFilter;

  static const _palette = [
    Color(0xFFFF6B6B),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFFD93D),
    Color(0xFFC77DFF),
    Color(0xFFFF9F43),
    Color(0xFF00CFDD),
  ];

  Color _brandColor(String id) =>
      _palette[id.codeUnits.fold(0, (a, b) => a + b) % _palette.length];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanViewModel>().loadPlans();
      context.read<BrandViewModel>().loadBrands();
    });
  }

  List<Plan> _filtered(List<Plan> plans) => plans.where((p) {
        if (_brandFilter != null && p.brandId != _brandFilter) return false;
        if (_statusFilter != null && p.status != _statusFilter) return false;
        return true;
      }).toList();

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer2<PlanViewModel, BrandViewModel>(
      builder: (context, vm, brandVm, _) {
        final filtered = _filtered(vm.plans);
        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(cs, vm),
                _buildFilters(cs, brandVm),
                const Divider(height: 1),
                if (vm.isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator()))
                else if (vm.error != null && vm.plans.isEmpty)
                  _buildError(cs, vm)
                else if (filtered.isEmpty)
                  _buildEmpty(cs)
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => vm.loadPlans(),
                      child: Builder(builder: (context) {
                        // Grouping filtered plans by brand
                        final groups = <String, List<Plan>>{};
                        for (final p in filtered) {
                          groups.putIfAbsent(p.brandId, () => []).add(p);
                        }
                        final brandIds = groups.keys.toList();

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: brandIds.length,
                          itemBuilder: (context, bIdx) {
                            final bId = brandIds[bIdx];
                            final brandPlans = groups[bId]!;
                            final brand = brandVm.brands
                                .cast<Brand?>()
                                .firstWhere((b) => b?.id == bId,
                                    orElse: () => null);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Brand Header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12, height: 12,
                                        decoration: BoxDecoration(
                                          color: _brandColor(bId),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        brand?.name.toUpperCase() ?? context.tr('detail_unknown_brand'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
                                    ],
                                  ),
                                ),
                                // Projects in this brand
                                ...brandPlans.map((plan) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _PlanCard(
                                    plan: plan,
                                    brand: brand,
                                    brandColor: _brandColor(plan.brandId),
                                    onTap: () =>
                                        context.push('/plan-detail', extra: plan),
                                    onAddToCalendar: () => _addToCalendar(vm, plan),
                                    onDelete: () => _confirmDelete(vm, plan),
                                    isSaving: vm.isSaving,
                                  ),
                                )),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        );
                      }),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/projects/flow'),
            icon: const Icon(Icons.add_rounded),
            label: Text(context.tr('plans_new_btn')),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs, PlanViewModel vm) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('◎ Plans',
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            if (vm.plans.isNotEmpty)
              Text('${vm.plans.length} campagne${vm.plans.length == 1 ? '' : 's'} actives',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ─── Filters ──────────────────────────────────────────────────────────────

  Widget _buildFilters(ColorScheme cs, BrandViewModel brandVm) {
    final statuses = <(PlanStatus?, String, Color)>[
      (null, context.tr('plans_filter_all'), cs.primary),
      (PlanStatus.draft, context.tr('plans_filter_draft'), cs.onSurfaceVariant),
      (PlanStatus.active, context.tr('plans_filter_active'), Colors.green),
      (PlanStatus.completed, context.tr('plans_filter_completed'), cs.tertiary),
    ];

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: statuses
                .map((t) => Padding(
                      padding: EdgeInsets.only(
                          left: t == statuses.first ? 0 : 8),
                      child: _Chip(
                        label: t.$2,
                        color: t.$3,
                        isActive: _statusFilter == t.$1,
                        onTap: () => setState(() => _statusFilter = t.$1),
                      ),
                    ))
                .toList(),
          ),
        ),
        if (brandVm.brands.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _Chip(
                  label: context.tr('plans_all_brands'),
                  color: cs.primary,
                  isActive: _brandFilter == null,
                  onTap: () => setState(() => _brandFilter = null),
                  showDot: false,
                ),
                ...brandVm.brands.map((b) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _Chip(
                        label: b.name,
                        color: _brandColor(b.id ?? b.name),
                        isActive: _brandFilter == b.id,
                        onTap: () => setState(() => _brandFilter = b.id),
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Empty / Error ────────────────────────────────────────────────────────

  Widget _buildEmpty(ColorScheme cs) => Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_view_month_outlined,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(context.tr('plans_empty_title'),
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 8),
                Text(context.tr('plans_empty_desc'),
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/projects/flow'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(context.tr('plans_create_btn')),
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildError(ColorScheme cs, PlanViewModel vm) => Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 48, color: cs.error.withValues(alpha: 0.7)),
                const SizedBox(height: 12),
                Text(context.tr('plans_load_error'),
                    style: TextStyle(
                        color: cs.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(vm.error ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: vm.loadPlans,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
        ),
      );

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _addToCalendar(PlanViewModel vm, Plan plan) async {
    Plan target = plan;
    if (plan.status == PlanStatus.draft) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.tr('plans_activate_schedule_title')),
          content: Text(context.tr('plans_activate_schedule_msg')),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.tr('cancel'))),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.tr('plans_filter_active'))),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      final activated = await vm.activatePlan(plan.id!);
      if (activated == null) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Activation failed: ${vm.error ?? "Unknown error"}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
        return;
      }
      if (!mounted) return;
      target = activated;
    }
    if (target.id != null) {
      final entries = await vm.addToCalendar(target.id!);
      if (entries == null && vm.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed: ${vm.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ));
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.tr('plans_added_cal')),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _confirmDelete(PlanViewModel vm, Plan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('plans_delete_title')),
        content: Text('${ctx.tr('delete')} "${plan.name}"? ${ctx.tr('plans_cannot_undone')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(ctx.tr('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await vm.deletePlan(plan.id!);
      if (vm.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Delete failed: ${vm.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }
}

// ─── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final Brand? brand;
  final Color brandColor;
  final VoidCallback onTap;
  final VoidCallback onAddToCalendar;
  final VoidCallback onDelete;
  final bool isSaving;

  const _PlanCard({
    required this.plan,
    required this.brand,
    required this.brandColor,
    required this.onTap,
    required this.onAddToCalendar,
    required this.onDelete,
    required this.isSaving,
  });

  static const _statusColors = {
    PlanStatus.draft: Color(0xFF9E9E9E),
    PlanStatus.active: Colors.green,
    PlanStatus.completed: Color(0xFF9C27B0),
  };

  Map<PlanStatus, String> _statusLabels(BuildContext context) => {
        PlanStatus.draft: context.tr('plan_status_draft'),
        PlanStatus.active: context.tr('plan_status_active'),
        PlanStatus.completed: context.tr('plan_status_completed'),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColors[plan.status] ?? cs.onSurfaceVariant;
    final totalBlocks = plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
    final String title = plan.name.isNotEmpty ? plan.name : 'Sans titre';
    final String dateRange = _formatDateRange(plan.startDate, plan.endDate);

    // Mock progress calculation for UI consistency with prototype
    double progress = plan.status == PlanStatus.completed ? 1.0 : (plan.status == PlanStatus.active ? 0.4 : 0.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5), // var(--card) equivalent
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)), // var(--bdr) equivalent
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Meta
                Row(
                  children: [
                    Text('📅 $dateRange', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Text('📱 ${plan.objective.label}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats Boxes
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: cs.surface, // var(--surf)
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('${plan.phases.length}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Space Mono', color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text('Phases', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('$totalBlocks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Space Mono', color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text('Posts', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Progress Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED), // var(--p)
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avancement : ${(progress * 100).toInt()}%',
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Badge (Positioned top-right)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabels(context)[plan.status] ?? '',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[start.month - 1]} ${start.day} → ${months[end.month - 1]} ${end.day}, ${end.year}';
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final VoidCallback onTap;
  final bool showDot;

  const _Chip({
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest,
          border: Border.all(
              color: isActive ? color : cs.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.normal,
                color: isActive ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
