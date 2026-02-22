import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../models/plan.dart';
import '../../models/brand.dart';
import '../../services/plan_service.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/brand_view_model.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late Plan _plan;
  bool _isLoadingDetail = false;
  final Set<int> _expandedPhases = {};

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
    _plan = widget.plan;
    // Fetch full plan with phases if not yet loaded
    if (_plan.phases.isEmpty && _plan.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
    } else {
      // Expand first phase by default
      if (_plan.phases.isNotEmpty) _expandedPhases.add(0);
    }
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoadingDetail = true);
    try {
      final detail = await PlanService.getPlanById(_plan.id!);
      if (mounted) {
        setState(() {
          _plan = detail;
          if (detail.phases.isNotEmpty) _expandedPhases.add(0);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDetail = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer2<PlanViewModel, BrandViewModel>(
      builder: (context, vm, brandVm, _) {
        final brand = brandVm.brands
            .cast<Brand?>()
            .firstWhere((b) => b?.id == _plan.brandId,
                orElse: () => null);
        final totalBlocks =
            _plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
        final brandColor = _brandColor(_plan.brandId);

        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(cs, vm),
                Expanded(
                  child: _isLoadingDetail
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          children: [
                            const SizedBox(height: 8),
                            _buildInfoBanner(cs, brand, brandColor),
                            const SizedBox(height: 16),
                            _buildStats(cs, totalBlocks),
                            const SizedBox(height: 20),
                            _buildActions(cs, vm),
                            if (_plan.phases.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _sectionLabel(context.tr('detail_phases_label'), cs),
                              const SizedBox(height: 10),
                              ..._plan.phases
                                  .asMap()
                                  .entries
                                  .map((e) => _buildPhaseCard(
                                      cs, e.key, e.value)),
                            ] else if (!_isLoadingDetail) ...[
                              const SizedBox(height: 24),
                              _buildNoPhasesHint(cs),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs, PlanViewModel vm) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_left_rounded,
                    size: 22, color: cs.onSurface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _plan.name,
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _statusBadge(_plan.status, cs),
            const SizedBox(width: 8),
            // Edit name button
            GestureDetector(
              onTap: () => _showEditNameDialog(vm),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_outlined,
                    size: 17, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );

  // ─── Info Banner ──────────────────────────────────────────────────────────

  Widget _buildInfoBanner(
      ColorScheme cs, Brand? brand, Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.06),
        border: Border.all(color: brandColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: brandColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                brand?.name ?? context.tr('detail_unknown_brand'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(width: 8),
              Text('·', style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              Text(
                '${_plan.objective.emoji} ${_plan.objective.label}',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _formatDate(_plan.startDate),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _formatDate(_plan.endDate),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Widget _buildStats(ColorScheme cs, int totalBlocks) {
    return Row(
      children: [
        _statItem('${_plan.phases.length}',
            context.tr('detail_phases_label'),
            Icons.layers_outlined, cs),
        const SizedBox(width: 8),
        _statItem('$totalBlocks', 'Posts',
            Icons.article_outlined, cs),
        const SizedBox(width: 8),
        _statItem('${_plan.durationWeeks}w', context.tr('detail_duration_stat'),
            Icons.hourglass_top_rounded, cs),
        const SizedBox(width: 8),
        _statItem('${_plan.postingFrequency}/wk', context.tr('detail_frequency_stat'),
            Icons.repeat_rounded, cs),
      ],
    );
  }

  Widget _statItem(
      String value, String label, IconData icon, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: cs.primary),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.primary)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Widget _buildActions(ColorScheme cs, PlanViewModel vm) {
    final isDraft = _plan.status == PlanStatus.draft;
    final isActive = _plan.status == PlanStatus.active;
    final hasPhases = _plan.phases.isNotEmpty;

    return Column(
      children: [
        // Activate (draft + has phases)
        if (isDraft && hasPhases)
          _actionButton(
            label: context.tr('detail_activate_btn'),
            color: Colors.green,
            onPressed: vm.isSaving ? null : () => _activatePlan(vm),
          ),

        // Add to Calendar (active)
        if (isActive)
          _actionButton(
            label: context.tr('detail_add_cal_btn'),
            color: cs.primary,
            onPressed: vm.isSaving ? null : () => _addToCalendar(vm),
          ),

        // Regenerate (has id + any status)
        if (_plan.id != null) ...[
          if (isDraft || isActive) const SizedBox(height: 8),
          _actionButton(
            label: context.tr('detail_regen_btn'),
            color: cs.secondary,
            outlined: true,
            onPressed: vm.isGenerating ? null : () => _regenerate(vm),
          ),
        ],

        const SizedBox(height: 8),
        // Delete
        _actionButton(
          label: context.tr('detail_delete_btn'),
          color: cs.error,
          outlined: true,
          onPressed: vm.isSaving ? null : () => _confirmDelete(vm),
        ),

        // Loading indicator
        if (vm.isSaving || vm.isGenerating) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cs.primary)),
              const SizedBox(width: 10),
              Text(
                vm.isGenerating
                    ? context.tr('detail_regen_gemini')
                    : context.tr('detail_processing'),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],

        // Error
        if (vm.error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onErrorContainer),
                  ),
                ),
                GestureDetector(
                  onTap: vm.clearError,
                  child: Icon(Icons.close_rounded,
                      size: 14,
                      color: cs.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool outlined = false,
  }) {
    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          )
        : FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            )
          : FilledButton(
              onPressed: onPressed,
              style: style,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
    );
  }

  // ─── Phases ───────────────────────────────────────────────────────────────

  Widget _buildPhaseCard(ColorScheme cs, int idx, Phase phase) {
    final isExpanded = _expandedPhases.contains(idx);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(
            color: isExpanded
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Phase header
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedPhases.remove(idx);
              } else {
                _expandedPhases.add(idx);
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? cs.primary
                          : cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'W${phase.weekNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isExpanded
                              ? cs.onPrimary
                              : cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                        ),
                        if (phase.description != null)
                          Text(
                            phase.description!,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant),
                            maxLines: isExpanded ? 3 : 1,
                            overflow: isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${phase.contentBlocks.length} posts',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Content blocks
          if (isExpanded && phase.contentBlocks.isNotEmpty) ...[
            Divider(height: 1, color: cs.outlineVariant),
            ...phase.contentBlocks.map((block) =>
                _buildContentBlock(cs, block)),
          ],
        ],
      ),
    );
  }

  Widget _buildContentBlock(ColorScheme cs, ContentBlock block) {
    final formatColor = _formatColor(block.format, cs);
    final ctaColor = _ctaColor(block.ctaType, cs);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: formatColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              block.format.label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: formatColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  children: [
                    // Pillar
                    Text(
                      block.pillar,
                      style: TextStyle(
                          fontSize: 10, color: cs.onSurfaceVariant),
                    ),
                    // CTA type
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: ctaColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${block.ctaType.name} CTA',
                        style: TextStyle(
                            fontSize: 9,
                            color: ctaColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    // Day + time
                    if (block.recommendedDayOffset < 7)
                      Text(
                        '${weekdays[block.recommendedDayOffset]} ${block.recommendedTime ?? ''}',
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPhasesHint(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: cs.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('detail_no_phases'),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  Text(
                      context.tr('detail_no_phases_desc'),
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );

  // ─── Action handlers ──────────────────────────────────────────────────────

  Future<void> _activatePlan(PlanViewModel vm) async {
    final activated = await vm.activatePlan(_plan.id!);
    if (activated != null && mounted) {
      setState(() => _plan = activated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.tr('detail_plan_activated')),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _addToCalendar(PlanViewModel vm) async {
    await vm.addToCalendar(_plan.id!);
    if (mounted && vm.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.tr('plans_added_cal')),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _regenerate(PlanViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('detail_regen_dialog_title')),
        content: Text(ctx.tr('detail_regen_dialog_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('detail_regen_confirm'))),
        ],
      ),
    );
    if (ok != true) return;
    final plan = await vm.regeneratePlan(_plan.id!);
    if (plan != null && mounted) {
      setState(() {
        _plan = plan;
        _expandedPhases.clear();
        if (plan.phases.isNotEmpty) _expandedPhases.add(0);
      });
    }
  }

  Future<void> _confirmDelete(PlanViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('plans_delete_title')),
        content: Text('${ctx.tr('delete')} "${_plan.name}"? ${ctx.tr('plans_cannot_undone')}'),
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
      await vm.deletePlan(_plan.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showEditNameDialog(PlanViewModel vm) async {
    final ctrl = TextEditingController(text: _plan.name);
    final cs = Theme.of(context).colorScheme;
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('detail_edit_name')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ctx.tr('detail_plan_name_label'),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(ctx.tr('save'))),
        ],
      ),
    );
    // Do NOT dispose ctrl here — the dialog's exit animation still references
    // it. The controller will be garbage-collected once it goes out of scope.
    if (newName != null && newName.isNotEmpty && newName != _plan.name) {
      try {
        final updated =
            await PlanService.updatePlan(_plan.id!, {'name': newName});
        if (mounted) setState(() => _plan = updated);
        // Also update in VM list
        if (mounted) vm.setCurrentPlan(updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update: $e'),
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, ColorScheme cs) => Text(
        text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: 1.2),
      );

  Widget _statusBadge(PlanStatus status, ColorScheme cs) {
    const colors = {
      PlanStatus.draft: Color(0xFF9E9E9E),
      PlanStatus.active: Colors.green,
      PlanStatus.completed: Color(0xFF9C27B0),
    };
    final labels = {
      PlanStatus.draft: context.tr('plan_status_draft'),
      PlanStatus.active: context.tr('plan_status_active'),
      PlanStatus.completed: context.tr('plan_status_completed'),
    };
    final color = colors[status] ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? '',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }

  Color _formatColor(ContentFormat f, ColorScheme cs) {
    switch (f) {
      case ContentFormat.reel:
        return const Color(0xFFE91E63);
      case ContentFormat.carousel:
        return const Color(0xFF2196F3);
      case ContentFormat.story:
        return const Color(0xFFFF9800);
      case ContentFormat.post:
        return cs.primary;
    }
  }

  Color _ctaColor(CtaType cta, ColorScheme cs) {
    switch (cta) {
      case CtaType.hard:
        return cs.error;
      case CtaType.soft:
        return cs.secondary;
      case CtaType.educational:
        return const Color(0xFF00BCD4);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
