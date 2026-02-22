import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/plan.dart';
import '../../models/brand.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/brand_view_model.dart';

class ExecutionHubScreen extends StatefulWidget {
  const ExecutionHubScreen({super.key});

  @override
  State<ExecutionHubScreen> createState() => _ExecutionHubScreenState();
}

class _ExecutionHubScreenState extends State<ExecutionHubScreen> {
  PlanStatus? _statusFilter;
  String? _brandFilter;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

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
    _searchCtrl.addListener(
        () => setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanViewModel>().loadPlans();
      context.read<BrandViewModel>().loadBrands();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Plan> _filtered(List<Plan> plans) => plans.where((p) {
        if (_brandFilter != null && p.brandId != _brandFilter) return false;
        if (_statusFilter != null && p.status != _statusFilter) return false;
        if (_searchQuery.isNotEmpty &&
            !p.name.toLowerCase().contains(_searchQuery)) {
          return false;
        }
        return true;
      }).toList();

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
                // ── Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Execution Hub',
                            style: GoogleFonts.syne(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface),
                          ),
                          if (vm.plans.isNotEmpty)
                            Text(
                              '${vm.plans.length} project${vm.plans.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    if (vm.isLoading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      ),
                  ]),
                ),

                // ── Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon:
                          const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              })
                          : null,
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      hintStyle: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                // ── Status tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(children: [
                    _HubChip(
                      label: 'All',
                      color: cs.primary,
                      isActive: _statusFilter == null,
                      showDot: false,
                      onTap: () => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _HubChip(
                      label: 'Active',
                      color: Colors.green,
                      isActive: _statusFilter == PlanStatus.active,
                      onTap: () =>
                          setState(() => _statusFilter = PlanStatus.active),
                    ),
                    const SizedBox(width: 8),
                    _HubChip(
                      label: 'Draft',
                      color: cs.onSurfaceVariant,
                      isActive: _statusFilter == PlanStatus.draft,
                      onTap: () =>
                          setState(() => _statusFilter = PlanStatus.draft),
                    ),
                    const SizedBox(width: 8),
                    _HubChip(
                      label: 'Completed',
                      color: cs.tertiary,
                      isActive: _statusFilter == PlanStatus.completed,
                      onTap: () =>
                          setState(() => _statusFilter = PlanStatus.completed),
                    ),
                  ]),
                ),

                // ── Brand filter
                if (brandVm.brands.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(children: [
                      _HubChip(
                        label: 'All brands',
                        color: cs.primary,
                        isActive: _brandFilter == null,
                        showDot: false,
                        onTap: () => setState(() => _brandFilter = null),
                      ),
                      ...brandVm.brands.map((b) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _HubChip(
                              label: b.name,
                              color: _brandColor(b.id ?? b.name),
                              isActive: _brandFilter == b.id,
                              onTap: () =>
                                  setState(() => _brandFilter = b.id),
                            ),
                          )),
                    ]),
                  ),

                const Divider(height: 1),

                // ── Content list
                if (vm.isLoading && vm.plans.isEmpty)
                  const Expanded(
                      child: Center(child: CircularProgressIndicator()))
                else if (vm.error != null && vm.plans.isEmpty)
                  _buildError(context, cs, vm)
                else if (filtered.isEmpty)
                  _buildEmpty(context, cs)
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => vm.loadPlans(),
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final plan = filtered[i];
                          final brand = brandVm.brands
                              .cast<Brand?>()
                              .firstWhere((b) => b?.id == plan.brandId,
                                  orElse: () => null);
                          return _ProjectCard(
                            plan: plan,
                            brand: brand,
                            brandColor: _brandColor(plan.brandId),
                            onOpenBoard: () =>
                                context.push('/project-board', extra: plan),
                            onViewDetail: () =>
                                context.push('/plan-detail', extra: plan),
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
            label: const Text('New Plan'),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme cs) => Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rocket_launch_outlined,
                    size: 56,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  'No projects found',
                  style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first content plan to get started.',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/projects-flow'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Plan'),
                  style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildError(
          BuildContext context, ColorScheme cs, PlanViewModel vm) =>
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 48, color: cs.error.withValues(alpha: 0.7)),
                const SizedBox(height: 12),
                Text(vm.error ?? 'Failed to load projects',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurface)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: vm.loadPlans,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _confirmDelete(PlanViewModel vm, Plan plan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text(
            'Delete "${plan.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await vm.deletePlan(plan.id!);
  }
}

// ── Project Card ──────────────────────────────────────────────────────────────

class _ProjectCard extends StatelessWidget {
  final Plan plan;
  final Brand? brand;
  final Color brandColor;
  final VoidCallback onOpenBoard;
  final VoidCallback onViewDetail;
  final VoidCallback onDelete;
  final bool isSaving;

  const _ProjectCard({
    required this.plan,
    required this.brand,
    required this.brandColor,
    required this.onOpenBoard,
    required this.onViewDetail,
    required this.onDelete,
    required this.isSaving,
  });

  static const _statusColors = {
    PlanStatus.draft: Color(0xFF9E9E9E),
    PlanStatus.active: Colors.green,
    PlanStatus.completed: Color(0xFF9C27B0),
  };

  static const _statusLabels = {
    PlanStatus.draft: 'Draft',
    PlanStatus.active: 'Active',
    PlanStatus.completed: 'Done',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColors[plan.status] ?? cs.onSurfaceVariant;
    final totalBlocks =
        plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
    final scheduledBlocks = plan.phases.fold<int>(
        0,
        (s, p) =>
            s +
            p.contentBlocks
                .where((b) => b.status == ContentBlockStatus.scheduled)
                .length);
    final doneBlocks = plan.phases.fold<int>(
        0,
        (s, p) =>
            s +
            p.contentBlocks
                .where((b) => b.status == ContentBlockStatus.edited)
                .length);

    return Container(
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
            // Brand color accent bar
            Container(width: 5, color: brandColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + status badge
                    Row(children: [
                      Text(plan.objective.emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          plan.name,
                          style: TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusLabels[plan.status] ?? plan.status.name,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // Brand badge + objective
                    if (brand != null)
                      Row(children: [
                        Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: brandColor,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                          brand!.name,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface),
                        ),
                        const SizedBox(width: 8),
                        Text('·',
                            style: TextStyle(
                                color: cs.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Text(
                          plan.objective.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant),
                        ),
                      ]),

                    const SizedBox(height: 4),

                    // Date range
                    Text(
                      _formatDateRange(plan.startDate, plan.endDate),
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant
                              .withValues(alpha: 0.8)),
                    ),

                    const SizedBox(height: 12),

                    // Progress stats + platform icons
                    Row(children: [
                      _StatPill('$totalBlocks', 'total',
                          cs.onSurface, cs),
                      const SizedBox(width: 12),
                      _StatPill('$scheduledBlocks', 'scheduled',
                          cs.primary, cs),
                      const SizedBox(width: 12),
                      _StatPill('$doneBlocks', 'done',
                          Colors.green, cs),
                      const Spacer(),
                      // Platform icons
                      ...plan.platforms.take(3).map((p) => Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _PlatformBadge(platform: p),
                          )),
                    ]),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onOpenBoard,
                          icon: const Icon(
                              Icons.dashboard_customize_rounded,
                              size: 15),
                          label: const Text('Open Board',
                              style: TextStyle(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onViewDetail,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.info_outline_rounded,
                              size: 17, color: cs.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: isSaving ? null : onDelete,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cs.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 17, color: cs.error),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[start.month - 1]} ${start.day} → ${m[end.month - 1]} ${end.day}, ${end.year}';
  }
}

class _StatPill extends StatelessWidget {
  final String value, label;
  final Color color;
  final ColorScheme cs;

  const _StatPill(this.value, this.label, this.color, this.cs);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style:
                  TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
        ],
      );
}

class _PlatformBadge extends StatelessWidget {
  final String platform;
  const _PlatformBadge({required this.platform});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final icons = <String, IconData>{
      'tiktok': Icons.music_note_rounded,
      'instagram': Icons.photo_camera_rounded,
      'youtube': Icons.play_circle_rounded,
      'facebook': Icons.facebook,
      'linkedin': Icons.work_rounded,
    };
    final icon =
        icons[platform.toLowerCase()] ?? Icons.device_hub_rounded;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 13, color: cs.primary),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _HubChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  const _HubChip({
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
          border:
              Border.all(color: isActive ? color : cs.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
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
        ]),
      ),
    );
  }
}
