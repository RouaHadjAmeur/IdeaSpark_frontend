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
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final plan = filtered[i];
                          final brand = brandVm.brands
                              .cast<Brand?>()
                              .firstWhere((b) => b?.id == plan.brandId,
                                  orElse: () => null);
                          return _PlanCard(
                            plan: plan,
                            brand: brand,
                            brandColor: _brandColor(plan.brandId),
                            onTap: () =>
                                context.push('/plan-detail', extra: plan),
                            onAddToCalendar: () => _addToCalendar(vm, plan),
                            onDelete: () => _confirmDelete(vm, plan),
                            isSaving: vm.isSaving,
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/projects-flow'),
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
            Text(context.tr('plans_title'),
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            if (vm.plans.isNotEmpty)
              Text('${vm.plans.length} plan${vm.plans.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
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
                  onPressed: () => context.push('/projects-flow'),
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
      if (activated == null || !mounted) return;
      target = activated;
    }
    if (target.id != null) {
      await vm.addToCalendar(target.id!);
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
    if (ok == true) await vm.deletePlan(plan.id!);
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
    final statusColor =
        _statusColors[plan.status] ?? cs.onSurfaceVariant;
    final totalBlocks =
        plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand color bar
              Container(width: 4, color: brandColor),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Text(
                          plan.objective.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            plan.name,
                            style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabels(context)[plan.status] ?? '',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Brand + objective
                    Text(
                      '${brand?.name ?? context.tr('detail_unknown_brand')} · ${plan.objective.label}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),

                    // Dates
                    Text(
                      _formatDateRange(plan.startDate, plan.endDate),
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                    ),

                    const SizedBox(height: 10),

                    // Stats row
                    Row(
                      children: [
                        _miniStat(
                            '${plan.phases.length}',
                            plan.phases.length == 1 ? 'phase' : 'phases',
                            cs),
                        const SizedBox(width: 12),
                        _miniStat(
                            '$totalBlocks',
                            totalBlocks == 1 ? 'post' : 'posts',
                            cs),
                        const SizedBox(width: 12),
                        _miniStat('${plan.durationWeeks}w', 'duration', cs),
                        const Spacer(),
                        // Action buttons
                        _actionIcon(
                          icon: Icons.calendar_month_outlined,
                          tooltip: context.tr('detail_add_cal_btn'),
                          color: cs.primary,
                          onTap: isSaving ? null : onAddToCalendar,
                        ),
                        const SizedBox(width: 4),
                        _actionIcon(
                          icon: Icons.delete_outline_rounded,
                          tooltip: context.tr('delete'),
                          color: cs.error,
                          onTap: isSaving ? null : onDelete,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ), // IntrinsicHeight
      ),
    );
  }

  Widget _miniStat(String value, String label, ColorScheme cs) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      );

  Widget _actionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: onTap == null
                  ? Colors.grey.withValues(alpha: 0.08)
                  : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? Colors.grey : color,
            ),
          ),
        ),
      );

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
