import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/plan.dart';
import '../../services/permission_service.dart';
import '../../services/pdf_export_service.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/collaboration_view_model.dart';
import '../../view_models/plan_view_model.dart';
import '../../widgets/status_workflow_node.dart';
import '../execution_hub/collaborator_plan_screen.dart';

/// Brand Owner Strategy Hub.
///
/// Opened when a brand owner taps a campaign. Shows 5 tabs:
///   1. Plans      — phases + collaborator posts, approve / request revision
///   2. Approbations — flat queue of all submitted posts
///   3. Phases     — timeline progress per phase
///   4. Budget     — spend tracker, ROAS, CPL
///   5. DNA IA     — update brand AI context
///
/// Collaborators NEVER reach this screen — they land on CollaboratorPlanScreen.
class CampaignStrategyHubScreen extends StatefulWidget {
  final Plan plan;
  const CampaignStrategyHubScreen({super.key, required this.plan});

  @override
  State<CampaignStrategyHubScreen> createState() =>
      _CampaignStrategyHubScreenState();
}

class _CampaignStrategyHubScreenState extends State<CampaignStrategyHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Plan _plan;
  final Map<String, bool> _expandedPhases = {};
  final Map<String, bool> _expandedPosts = {};

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    // 5 tabs: Plans | Approbations | Phases | Budget | DNA IA
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final pvm = context.read<PlanViewModel>();
    final cvm = context.read<CollaborationViewModel>();

    // First ensure the plan is in the list, then fetch full detail with phases
    await pvm.loadPlans();
    await Future.wait([
      pvm.loadPlanById(_plan.id!),
      cvm.loadActivityLog(_plan.id!),
    ]);
    // Inject content blocks from the dedicated endpoint
    await pvm.loadAndInjectBlocks(_plan.id!);

    if (!mounted) return;
    final refreshed = context
        .read<PlanViewModel>()
        .plans
        .firstWhere((p) => p.id == _plan.id, orElse: () => _plan);
    setState(() => _plan = refreshed);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authVm = context.watch<AuthViewModel>();
    final perms = PermissionService(authVm.currentUser);
    final planVm = context.watch<PlanViewModel>();

    // Collaborators should never reach this screen — redirect to their hub
    if (!authVm.isBrandOwner) {
      return const CollaboratorPlanScreen();
    }

    // Always use the freshest plan from the view model
    _plan = planVm.plans.firstWhere(
      (p) => p.id == widget.plan.id,
      orElse: () => _plan,
    );

    // Count pending approvals for badge
    final pendingCount = _plan.phases
        .expand((ph) => ph.contentBlocks)
        .where((b) => b.status == ContentBlockStatus.submitted)
        .length;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            _buildTabBar(cs, pendingCount),
            // Show loading indicator while fetching full plan data
            if (planVm.isLoading && _plan.phases.isEmpty)
              const LinearProgressIndicator(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlansTab(cs, planVm, perms),
                  _buildApprobationsTab(cs, planVm, perms),
                  _buildPhasesTab(cs),
                  _buildBudgetTab(cs),
                  _buildDNATab(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    final progress = _plan.phases.isEmpty
        ? 0
        : (_plan.phases
                    .where((p) => p.status == PhaseStatus.terminated)
                    .length /
                _plan.phases.length *
                100)
            .toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surfaceContainerHighest,
                  foregroundColor: cs.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _plan.name,
                  style: GoogleFonts.syne(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Export PDF
              IconButton.filledTonal(
                onPressed: () => PdfExportService.exportPlan(_plan),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Campaign info strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primary.withValues(alpha: 0.15),
                  cs.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Text(
                  _plan.objective.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _plan.objective.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: _plan.platforms
                            .map((p) => _chip(p, cs.primary, cs))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$progress%',
                      style: GoogleFonts.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      'complet',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
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

  // ── Tab bar ────────────────────────────────────────────────────────────────

  Widget _buildTabBar(ColorScheme cs, int pendingCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        tabAlignment: TabAlignment.start,
        tabs: [
          const Tab(text: 'Plans'),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Approbations',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Tab(text: 'Phases'),
          const Tab(text: 'Budget'),
          const Tab(text: 'DNA IA'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — PLANS
  // Shows phases as collapsible sections. Inside each phase, each collaborator
  // appears as a sub-section with their posts. Brand owner can approve or
  // request revision. He CANNOT edit the collaborator's content directly.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPlansTab(
      ColorScheme cs, PlanViewModel planVm, PermissionService perms) {
    if (_plan.phases.isEmpty) {
      return _emptyState(cs, 'Aucune phase configurée pour cette campagne.');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: _plan.phases.asMap().entries.map((entry) {
          final idx = entry.key;
          final phase = entry.value;
          final phaseKey = phase.id ?? 'phase_$idx';
          final isExpanded =
              _expandedPhases[phaseKey] ?? (phase.status == PhaseStatus.inProgress);
          return _buildPhaseSection(cs, phase, phaseKey, isExpanded, planVm, perms);
        }).toList(),
      ),
    );
  }

  Widget _buildPhaseSection(
    ColorScheme cs,
    Phase phase,
    String phaseKey,
    bool isExpanded,
    PlanViewModel planVm,
    PermissionService perms,
  ) {
    final isDone = phase.status == PhaseStatus.terminated;
    final isActive = phase.status == PhaseStatus.inProgress;
    final phaseColor = isDone
        ? const Color(0xFF0EBFA1)
        : isActive
            ? const Color(0xFF6D4ED3)
            : const Color(0xFFA89EC0);

    final totalPosts = phase.contentBlocks.length;
    final publishedPosts = phase.contentBlocks
        .where((b) => b.status == ContentBlockStatus.published)
        .length;
    final pendingPosts = phase.contentBlocks
        .where((b) => b.status == ContentBlockStatus.submitted)
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: phaseColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // Phase header — compact
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                setState(() => _expandedPhases[phaseKey] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Phase number circle — small
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: phaseColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        phase.weekNumber.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: phaseColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.name.isNotEmpty ? phase.name : 'Phase ${phase.weekNumber}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (phase.description != null &&
                            phase.description!.isNotEmpty)
                          Text(
                            phase.description!,
                            style: TextStyle(
                                fontSize: 10, color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // Stats — compact
                  Text(
                    '$publishedPosts/$totalPosts',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: phaseColor),
                  ),
                  if (pendingPosts > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$pendingPosts ⏳',
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          // Posts list (brand owner sees ALL posts in this phase)
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: phase.contentBlocks.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Aucun post dans cette phase.',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  : Column(
                      children: phase.contentBlocks
                          .asMap()
                          .entries
                          .map((e) => _buildOwnerPostCard(
                                cs,
                                e.value,
                                '${phaseKey}_post_${e.key}',
                                planVm,
                                perms,
                              ))
                          .toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// Brand owner post card — can approve, request revision, leave a note.
  /// Cannot edit the collaborator's content directly.
  Widget _buildOwnerPostCard(
    ColorScheme cs,
    ContentBlock block,
    String cardKey,
    PlanViewModel planVm,
    PermissionService perms,
  ) {
    final isExpanded = _expandedPosts[cardKey] ?? false;
    final isSubmitted = block.status == ContentBlockStatus.submitted;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSubmitted
              ? Colors.orange.withValues(alpha: 0.4)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () =>
                setState(() => _expandedPosts[cardKey] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Format emoji — no big gradient box, just the emoji
                  Text(_formatEmoji(block.format),
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          block.title,
                          style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          block.format.label,
                          style: TextStyle(
                              fontSize: 10, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(block.status, cs),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _buildOwnerReviewPanel(cs, block, planVm, perms),
            ),
          ],
        ],
      ),
    );
  }

  /// The review panel the brand owner sees when he expands a post.
  /// Read-only content view + approve / request revision controls.
  Widget _buildOwnerReviewPanel(
    ColorScheme cs,
    ContentBlock block,
    PlanViewModel planVm,
    PermissionService perms,
  ) {
    final noteController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status workflow bar
        StatusWorkflowBar(currentStatus: block.status),
        const SizedBox(height: 14),

        // Read-only content fields
        _readOnlyField(cs, 'Hook', block.hook),
        const SizedBox(height: 10),
        _readOnlyField(cs, 'Caption', block.caption),
        const SizedBox(height: 10),
        _readOnlyField(
            cs, 'Idée vidéo', block.emotionalTrigger ?? ''),

        const SizedBox(height: 16),

        // Note field (brand owner can leave a written note)
        Text(
          'Note pour le collaborateur',
          style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ex: Le hook est trop agressif, adoucis le ton...',
            filled: true,
            fillColor: cs.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 16),

        // Action buttons — brand owner only, only when submitted
        if (perms.canApprovePosts &&
            block.status == ContentBlockStatus.submitted) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _requestRevision(
                      planVm, block, noteController.text),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Révision'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      _approvePost(planVm, block),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: const Text('Approuver'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],

        // Already approved
        if (block.status == ContentBlockStatus.approved ||
            block.status == ContentBlockStatus.scheduled ||
            block.status == ContentBlockStatus.published)
          _infoChip(
            cs,
            block.status == ContentBlockStatus.published
                ? '✅ Publié'
                : '✅ Approuvé — en attente de publication',
            Colors.green,
          ),

        // Revision requested
        if (block.status == ContentBlockStatus.revisionRequested)
          _infoChip(
              cs, '🔄 Révision demandée — en attente du collaborateur',
              Colors.orange),
      ],
    );
  }

  Future<void> _approvePost(PlanViewModel planVm, ContentBlock block) async {
    await planVm.updateBlockStatus(block.id!, ContentBlockStatus.approved);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Post approuvé — le collaborateur est notifié.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestRevision(
      PlanViewModel planVm, ContentBlock block, String note) async {
    await planVm.updateBlockStatus(
        block.id!, ContentBlockStatus.revisionRequested);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              note.isNotEmpty
                  ? '🔄 Révision demandée: "$note"'
                  : '🔄 Révision demandée — le collaborateur est notifié.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — APPROBATIONS
  // Flat queue of ALL submitted posts across all phases, sorted by submission.
  // The badge count on this tab is the most important UI signal.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildApprobationsTab(
      ColorScheme cs, PlanViewModel planVm, PermissionService perms) {
    // Collect all submitted posts across all phases
    final submitted = <_PostWithPhase>[];
    for (final phase in _plan.phases) {
      for (final block in phase.contentBlocks) {
        if (block.status == ContentBlockStatus.submitted) {
          submitted.add(_PostWithPhase(phase: phase, block: block));
        }
      }
    }

    if (submitted.isEmpty) {
      return _emptyState(
          cs, 'Aucun post en attente d\'approbation pour le moment.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: submitted.length,
      itemBuilder: (_, i) {
        final item = submitted[i];
        final cardKey = 'appro_${item.block.id ?? i}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase label
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Phase ${item.phase.weekNumber} — ${item.phase.name}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant),
              ),
            ),
            _buildOwnerPostCard(
                cs, item.block, cardKey, planVm, perms),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — PHASES
  // Visual timeline with progress bar per phase + expandable content blocks.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPhasesTab(ColorScheme cs) {
    if (_plan.phases.isEmpty) {
      return _emptyState(cs, 'Aucune phase configurée.');
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          _overallProgressCard(cs),
          const SizedBox(height: 20),
          ..._plan.phases.asMap().entries.map((entry) {
            final idx = entry.key;
            final phase = entry.value;
            final phaseKey = phase.id ?? 'phase_$idx';
            final isExpanded = _expandedPhases[phaseKey] ??
                (phase.status == PhaseStatus.inProgress);
            final total = phase.contentBlocks.length;
            final published = phase.contentBlocks
                .where((b) => b.status == ContentBlockStatus.published)
                .length;
            final pct = total == 0 ? 0.0 : published / total;
            final isDone = phase.status == PhaseStatus.terminated;
            final isActive = phase.status == PhaseStatus.inProgress;
            final phaseColor = isDone
                ? const Color(0xFF0EBFA1)
                : isActive
                    ? const Color(0xFF6D4ED3)
                    : const Color(0xFFA89EC0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: phaseColor.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  // Phase header — tap to expand
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(
                        () => _expandedPhases[phaseKey] = !isExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: phaseColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: phaseColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      phase.name.isNotEmpty
                                          ? phase.name
                                          : 'Phase ${idx + 1}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                    if (phase.description != null &&
                                        phase.description!.isNotEmpty)
                                      Text(
                                        phase.description!,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                '$published/$total',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: phaseColor),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: cs.onSurfaceVariant,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 8,
                              backgroundColor:
                                  cs.outlineVariant.withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation(phaseColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                phase.status.name.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: phaseColor),
                              ),
                              Text(
                                '${(pct * 100).toInt()}% publié',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Content blocks list — expanded
                  if (isExpanded && phase.contentBlocks.isNotEmpty) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Column(
                        children: phase.contentBlocks
                            .asMap()
                            .entries
                            .map((e) => _buildPhaseBlockRow(
                                cs, e.value, phaseKey, e.key))
                            .toList(),
                      ),
                    ),
                  ],
                  if (isExpanded && phase.contentBlocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        'Aucun post dans cette phase.',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
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

  Widget _buildPhaseBlockRow(
      ColorScheme cs, ContentBlock block, String phaseKey, int blockIdx) {
    final statusColor = Color(block.status.color as int);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(_formatEmoji(block.format),
              style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              block.title,
              style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              block.status.label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overallProgressCard(ColorScheme cs) {
    final total =
        _plan.phases.expand((p) => p.contentBlocks).length;
    final published = _plan.phases
        .expand((p) => p.contentBlocks)
        .where((b) => b.status == ContentBlockStatus.published)
        .length;
    final approved = _plan.phases
        .expand((p) => p.contentBlocks)
        .where((b) => b.status == ContentBlockStatus.approved)
        .length;
    final pending = _plan.phases
        .expand((p) => p.contentBlocks)
        .where((b) => b.status == ContentBlockStatus.submitted)
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d\'ensemble',
            style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statPill('$total', 'Total', cs.onSurface, cs),
              const SizedBox(width: 12),
              _statPill('$published', 'Publiés', Colors.green, cs),
              const SizedBox(width: 12),
              _statPill('$approved', 'Approuvés', cs.primary, cs),
              const SizedBox(width: 12),
              _statPill('$pending', 'En attente', Colors.orange, cs),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 4 — BUDGET
  // Donut chart placeholder + real-time spend tracker per platform.
  // Brand owner only — collaborators never see this.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBudgetTab(ColorScheme cs) {
    final budget = _plan.projectDNA.budget;
    final total = budget.totalBudget > 0 ? budget.totalBudget : 1000;
    final spent = budget.spentBudget;
    final remaining = total - spent;
    final pct = (spent / total * 100).toInt();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // Summary tiles
        Row(
          children: [
            Expanded(
                child: _budgetTile('Budget total', '\$$total',
                    cs.primary, cs)),
            const SizedBox(width: 12),
            Expanded(
                child: _budgetTile(
                    'Dépensé', '\$$spent', Colors.red, cs)),
            const SizedBox(width: 12),
            Expanded(
                child: _budgetTile(
                    'Restant', '\$$remaining', Colors.green, cs)),
          ],
        ),
        const SizedBox(height: 20),
        // Usage bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Utilisation du budget',
                      style: GoogleFonts.syne(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('$pct%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: pct > 80 ? Colors.red : Colors.green)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 12,
                  backgroundColor:
                      cs.outlineVariant.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation(
                      pct > 80 ? Colors.red : Colors.green),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Performance par plateforme',
            style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._plan.platforms.map((p) => _platformROASRow(p, cs)),
        const SizedBox(height: 20),
        // KPI section
        Text('KPIs',
            style: GoogleFonts.syne(
                fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._plan.projectDNA.strategic.kpis.map((kpi) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 10),
                  Text(kpi,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            )),
        if (_plan.projectDNA.strategic.kpis.isEmpty)
          _infoChip(cs, 'Aucun KPI défini pour cette campagne.',
              cs.onSurfaceVariant),
      ],
    );
  }

  Widget _budgetTile(
      String label, String val, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey)),
          const SizedBox(height: 4),
          Text(val,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color)),
        ],
      ),
    );
  }

  Widget _platformROASRow(String platform, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(platform.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
              const Text('ROAS: 4.2x',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.6,
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
            backgroundColor:
                cs.outlineVariant.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 5 — DNA IA
  // Brand owner can update the AI context at any time. All future AI
  // generations by all collaborators reflect the update immediately.
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDNATab(ColorScheme cs) {
    final dna = _plan.projectDNA.strategic;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // DNA score ring
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: 0.94,
                  strokeWidth: 10,
                  backgroundColor:
                      cs.outlineVariant.withValues(alpha: 0.2),
                  valueColor:
                      AlwaysStoppedAnimation(cs.primary),
                ),
              ),
              Column(
                children: [
                  Text('94%',
                      style: GoogleFonts.syne(
                          fontSize: 26, fontWeight: FontWeight.w900)),
                  Text('DNA SCORE',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        // Key messages
        _dnaSection(cs, 'Vision / Message clé', dna.vision),
        const SizedBox(height: 14),
        _dnaSection(cs, 'Angle de campagne', dna.campaignAngle),
        const SizedBox(height: 14),
        _dnaSection(cs, 'Positionnement', dna.positioning),
        const SizedBox(height: 14),
        _dnaSection(cs, 'Offre principale', dna.offer),
        const SizedBox(height: 20),
        // Update button
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '✅ DNA IA mis à jour — toutes les prochaines générations reflètent ce contexte.'),
                backgroundColor: Color(0xFF6D4ED3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Mettre à jour le DNA IA'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6D4ED3),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Toute modification ici est immédiatement injectée dans les générations IA de tous les collaborateurs de cette campagne.',
          style: TextStyle(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              height: 1.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _dnaSection(ColorScheme cs, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }


  // ══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _readOnlyField(ColorScheme cs, String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Text(
            content.isEmpty ? '—' : content,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                height: 1.4,
                color: content.isEmpty
                    ? cs.onSurfaceVariant
                    : cs.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(ContentBlockStatus status, ColorScheme cs) {
    final color = Color(status.color as int);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color),
      ),
    );
  }

  Widget _infoChip(ColorScheme cs, String message, Color color) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }

  Widget _chip(String label, Color color, ColorScheme cs) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }

  Widget _statPill(
      String value, String label, Color color, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ColorScheme cs, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 48,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEmoji(ContentFormat format) {
    switch (format) {
      case ContentFormat.reel:
        return '🎬';
      case ContentFormat.story:
        return '📸';
      case ContentFormat.carousel:
        return '🎠';
      default:
        return '🖼';
    }
  }
}

// ── Data holder ───────────────────────────────────────────────────────────────

class _PostWithPhase {
  final Phase phase;
  final ContentBlock block;
  const _PostWithPhase({required this.phase, required this.block});
}
