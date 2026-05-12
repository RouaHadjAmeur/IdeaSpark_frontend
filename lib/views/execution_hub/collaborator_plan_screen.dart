import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/plan.dart';
import '../../services/brand_service.dart';
import '../../services/content_block_service.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/collaboration_view_model.dart';

// ── Dynamic colour tokens — reads from Theme.of(context) ─────────────────────
// Usage: final c = _C(context);  then use c.accent, c.ink, etc.
class _C {
  _C(BuildContext context)
      : _cs = Theme.of(context).colorScheme,
        _dark = Theme.of(context).brightness == Brightness.dark;

  final ColorScheme _cs;
  final bool _dark;

  // Primary action — cyan (dark) / teal (light)
  Color get accent     => _cs.primary;
  // Secondary action — electric blue
  Color get accent2    => _dark ? Color(0xFF38BDF8) : Color(0xFF0284C7);
  // Text
  Color get ink        => _cs.onSurface;
  Color get ink2       => _cs.onSurfaceVariant;
  Color get ink3       => _dark ? Color(0xFF64748B) : Color(0xFF94A3B8);
  // Backgrounds
  Color get bg         => _dark ? Color(0xFF0F172A) : Color(0xFFF8FAFC);
  Color get white      => _cs.surface;
  // Borders
  Color get border     => _cs.outlineVariant;
  Color get border2    => _dark ? Color(0xFF334155) : Color(0xFFCBD5E1);
  // Semantic — success
  Color get green      => _dark ? Color(0xFF34D399) : Color(0xFF059669);
  Color get greenPale  => _dark ? Color(0xFF064E3B) : Color(0xFFD1FAE5);
  Color get greenMid   => _dark ? Color(0xFF6EE7B7) : Color(0xFF6EE7B7);
  // Semantic — error / revision
  Color get rose       => _dark ? Color(0xFFFCA5A5) : Color(0xFF991B1B);
  Color get rosePale   => _dark ? Color(0xFF450A0A) : Color(0xFFFEE2E2);
  Color get roseMid    => _dark ? Color(0xFFF87171) : Color(0xFFFCA5A5);
  // Semantic — submitted / violet
  Color get violet     => _dark ? Color(0xFFA78BFA) : Color(0xFF5B21B6);
  Color get violetPale => _dark ? Color(0xFF2E1065) : Color(0xFFEDE9FE);
  Color get violetMid  => _dark ? Color(0xFFC4B5FD) : Color(0xFFC4B5FD);
  // Semantic — draft / amber
  Color get amber      => _dark ? Color(0xFFFBBF24) : Color(0xFF92400E);
  Color get amberPale  => _dark ? Color(0xFF451A03) : Color(0xFFFEF3C7);
  Color get amberMid   => _dark ? Color(0xFFFDE68A) : Color(0xFFFDE68A);
  // Semantic — published / slate
  Color get slateD     => _dark ? Color(0xFF94A3B8) : Color(0xFF0F172A);
  Color get slatePale  => _dark ? Color(0xFF1E293B) : Color(0xFFE2E8F0);
  // Scheduled / blue
  Color get bluePale   => _dark ? Color(0xFF0C2340) : Color(0xFFE0F2FE);
  Color get blueD      => _dark ? Color(0xFF38BDF8) : Color(0xFF0C4A6E);
}

/// Collaborator Execution Hub — new design matching HTML prototype.
/// Tabs: Mon Plan | Phases | Calendrier | Notes & DNA
class CollaboratorPlanScreen extends StatefulWidget {
  const CollaboratorPlanScreen({super.key});
  @override
  State<CollaboratorPlanScreen> createState() => _CollaboratorPlanScreenState();
}

class _CollaboratorPlanScreenState extends State<CollaboratorPlanScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  String? _openPostKey;
  final Map<String, bool> _expandedPhases = {};
  final Map<String, String> _scheduleMode = {};
  final Map<String, Set<String>> _platformToggles = {};
  Timer? _refreshTimer;

  // Dynamic colour tokens — refreshed on every build()
  late _C c;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    // Poll every 30s as reliable fallback for socket gaps
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _silentRefresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _silentRefresh();
    }
  }

  /// Refresh plan detail without showing loading spinner
  Future<void> _silentRefresh() async {
    if (!mounted) return;
    final pvm = context.read<PlanViewModel>();
    debugPrint('[CollaboratorPlanScreen] _silentRefresh — ${pvm.plans.length} plans');
    for (final plan in List.of(pvm.plans)) {
      if (plan.id != null) {
        try {
          await pvm.loadPlanById(plan.id!);       // 1. fresh plan (0 blocks from backend)
          await pvm.loadAndInjectBlocks(plan.id!); // 2. inject blocks from content-blocks API
          // Read AFTER injection
          final updated = pvm.plans.firstWhere((p) => p.id == plan.id, orElse: () => plan);
          debugPrint('[CollaboratorPlanScreen] refreshed ${plan.id} — blocks: ${updated.phases.expand((ph) => ph.contentBlocks).length}');
        } catch (e) {
          debugPrint('[CollaboratorPlanScreen] silentRefresh error: $e');
        }
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final pvm = context.read<PlanViewModel>();

    // 1. Load own plans first
    try { await pvm.loadPlans(); } catch (_) {}
    if (!mounted) return;

    // 2. Fetch brands the user collaborates on, then merge their plans
    try {
      final collabBrands = await BrandService.getMyCollaborationBrands();
      debugPrint('[CollaboratorPlanScreen] collabBrands: ${collabBrands.map((b) => '${b.name}(${b.id})').toList()}');
      for (final brand in collabBrands) {
        if (!mounted) return;
        final brandId = brand.id;
        if (brandId == null || brandId.isEmpty) continue;
        await pvm.mergeCollaboratorPlans(brandId);
      }
    } catch (e) {
      debugPrint('[CollaboratorPlanScreen] collab brands error: $e');
    }

    debugPrint('[CollaboratorPlanScreen] total plans: ${pvm.plans.length}');
    if (!mounted) return;

    // 3. Always load full phase+block detail for every plan
    for (final plan in List.of(pvm.plans)) {
      if (plan.id != null) {
        if (!mounted) return;
        try {
          await pvm.loadPlanById(plan.id!);
          await pvm.loadAndInjectBlocks(plan.id!);
          debugPrint('[CollaboratorPlanScreen] loaded plan ${plan.id} — blocks: ${pvm.plans.firstWhere((p) => p.id == plan.id, orElse: () => plan).phases.expand((ph) => ph.contentBlocks).length}');
        } catch (e) {
          debugPrint('[CollaboratorPlanScreen] loadPlanById(${plan.id}) error: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  List<Plan> _myPlans(PlanViewModel pvm, AuthViewModel authVm) =>
      pvm.plans.toList();

  String _findPlanId(PlanViewModel pvm, String blockId) {
    for (final plan in pvm.plans) {
      for (final phase in plan.phases) {
        for (final block in phase.contentBlocks) {
          if (block.id == blockId) return plan.id ?? '';
        }
      }
    }
    return '';
  }

  String _phaseEmoji(Phase phase) =>
      phase.status == PhaseStatus.terminated ? '✓' : '${phase.weekNumber}';

  String _formatEmoji(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:     return '🎬';
      case ContentFormat.story:    return '📸';
      case ContentFormat.carousel: return '🎠';
      default:                     return '🖼';
    }
  }

  Color _formatBg(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:     return Color(0xFFFCE7F3);
      case ContentFormat.story:    return Color(0xFFEFF6FF);
      case ContentFormat.carousel: return Color(0xFFFFFBEB);
      default:                     return Color(0xFFF0FDF4);
    }
  }

  Color _statusColor(ContentBlockStatus s) {
    switch (s) {
      case ContentBlockStatus.empty:             return c.ink3;
      case ContentBlockStatus.draft:             return c.amber;
      case ContentBlockStatus.submitted:         return c.violet;
      case ContentBlockStatus.revisionRequested: return c.rose;
      case ContentBlockStatus.approved:          return c.green;
      case ContentBlockStatus.scheduled:         return c.blueD;
      case ContentBlockStatus.published:         return c.slateD;
    }
  }

  Color _statusBg(ContentBlockStatus s) {
    switch (s) {
      case ContentBlockStatus.empty:             return c.border;
      case ContentBlockStatus.draft:             return c.amberPale;
      case ContentBlockStatus.submitted:         return c.violetPale;
      case ContentBlockStatus.revisionRequested: return c.rosePale;
      case ContentBlockStatus.approved:          return c.greenPale;
      case ContentBlockStatus.scheduled:         return c.bluePale;
      case ContentBlockStatus.published:         return c.slatePale;
    }
  }

  Set<String> _platformsFor(String key, Plan plan) {
    _platformToggles[key] ??= Set.from(plan.platforms);
    return _platformToggles[key]!;
  }

  String _schedFor(String key) => _scheduleMode[key] ?? 'auto';

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    c = _C(context);
    final authVm = context.watch<AuthViewModel>();
    final planVm = context.watch<PlanViewModel>();
    final collabVm = context.watch<CollaborationViewModel>();
    final plans  = _myPlans(planVm, authVm);

    // React to real-time plan_updated socket events
    final reloadId = collabVm.pendingPlanReloadId;
    if (reloadId != null) {
      collabVm.clearPendingPlanReload();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        debugPrint('[CollaboratorPlanScreen] socket triggered reload for plan $reloadId');
        try {
          await planVm.loadPlanById(reloadId);
          await planVm.loadAndInjectBlocks(reloadId);
        } catch (_) {}
      });
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: planVm.isLoading && plans.isEmpty
            ? Center(child: CircularProgressIndicator(color: c.accent))
            : plans.isEmpty
                ? _buildEmpty()
                : _buildHub(context, plans, planVm),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📋', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('Aucun projet assigné',
              style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: c.ink)),
            SizedBox(height: 8),
            Text('Le brand owner vous assignera bientôt à une campagne.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: c.ink3)),
          ],
        ),
      ),
    );
  }

  Widget _buildHub(BuildContext context, List<Plan> plans, PlanViewModel planVm) {
    final plan      = plans.first;
    final allBlocks = plan.phases.expand((p) => p.contentBlocks);
    final total     = allBlocks.length;
    final published = allBlocks.where((b) => b.status == ContentBlockStatus.published).length;
    final pct       = total == 0 ? 0 : (published / total * 100).toInt();

    // Revision notifications
    final revisions = plan.phases
        .expand((ph) => ph.contentBlocks)
        .where((b) => b.status == ContentBlockStatus.revisionRequested)
        .toList();

    return Column(
      children: [
        _buildTopBar(plan, pct),
        _buildNavTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMonPlanTab(plans, planVm, revisions),
              _buildPhasesTab(plan),
              _buildCalendarTab(plan, planVm),
              _buildNotesAndDNATab(plan, planVm),
            ],
          ),
        ),
      ],
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(Plan plan, int pct) {
    return Container(
      color: c.white,
      padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: c.bg, border: Border.all(color: c.border2),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(Icons.chevron_left_rounded, size: 20, color: c.ink),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Mon Espace',
                  style: GoogleFonts.syne(fontSize: 17, fontWeight: FontWeight.w700, color: c.ink)),
              ),
              Consumer<CollaborationViewModel>(
                builder: (_, cvm, __) {
                  final count = cvm.unreadNotificationsCount;
                  return Stack(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: c.bg, border: Border.all(color: c.border2),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(Icons.notifications_none_rounded, size: 18, color: c.ink),
                      ),
                      if (count > 0)
                        Positioned(
                          top: -2, right: -2,
                          child: Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: c.accent, shape: BoxShape.circle,
                              border: Border.all(color: c.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text('$count',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 10),
          // Campaign strip
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.ink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: c.accent, borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: Text(plan.objective.emoji,
                      style: TextStyle(fontSize: 18)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        plan.platforms.take(3).join(' · '),
                        style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$pct%',
                      style: TextStyle(
                        fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w700,
                        color: c.accent)),
                    Text('mes posts',
                      style: TextStyle(fontSize: 9, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav tabs ──────────────────────────────────────────────────────────────

  Widget _buildNavTabs() {
    return Container(
      color: c.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: c.border,
        indicatorColor: c.accent,
        indicatorWeight: 2.5,
        labelColor: c.accent,
        unselectedLabelColor: c.ink3,
        labelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Mon Plan'),
          Tab(text: 'Phases'),
          Tab(text: 'Calendrier'),
          Tab(text: 'Notes & DNA'),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — MON PLAN
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMonPlanTab(List<Plan> plans, PlanViewModel planVm,
      List<ContentBlock> revisions) {
    return RefreshIndicator(
      color: c.accent,
      onRefresh: _loadData,
      child: ListView(
        padding: EdgeInsets.only(bottom: 40),
        children: [
          _buildOverviewStrip(plans),
          // Revision notification banners
          for (final block in revisions)
            _buildRevisionBanner(block),
          // Phase accordions for each plan
          for (final plan in plans)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Column(
                children: plan.phases.asMap().entries.map((entry) {
                  final idx      = entry.key;
                  final phase    = entry.value;
                  final phaseKey = '${plan.id}_${phase.id ?? idx}';
                  final isOpen   = _expandedPhases[phaseKey] ??
                      (phase.status == PhaseStatus.inProgress);
                  return _buildPhaseCard(plan, phase, phaseKey, isOpen, planVm);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewStrip(List<Plan> plans) {
    final all       = plans.expand((p) => p.phases.expand((ph) => ph.contentBlocks));
    final total     = all.length;
    final published = all.where((b) => b.status == ContentBlockStatus.published).length;
    final submitted = all.where((b) => b.status == ContentBlockStatus.submitted).length;
    final revision  = all.where((b) => b.status == ContentBlockStatus.revisionRequested).length;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          _ovCell('$total',     'Total',    c.ink),
          SizedBox(width: 7),
          _ovCell('$published', 'Publiés',  c.green),
          SizedBox(width: 7),
          _ovCell('$submitted', 'Soumis',   c.violet),
          SizedBox(width: 7),
          _ovCell('$revision',  'Révision', c.rose),
        ],
      ),
    );
  }

  Widget _ovCell(String val, String lbl, Color color) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: c.white, border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(val, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
          SizedBox(height: 2),
          Text(lbl, style: TextStyle(fontSize: 10, color: c.ink3, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _buildRevisionBanner(ContentBlock block) {
    return GestureDetector(
      onTap: () {
        // Switch to Mon Plan tab and open the post
        _tabController.animateTo(0);
      },
      child: Container(
        margin: EdgeInsets.fromLTRB(12, 6, 12, 0),
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: c.rosePale,
          border: Border.all(color: c.roseMid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: c.rose, shape: BoxShape.circle),
            ),
            SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 12.5, color: c.rose, height: 1.4),
                  children: [
                    const TextSpan(text: 'Révision demandée', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: ' sur "${block.title}"'),
                    if (block.emotionalTrigger?.isNotEmpty == true)
                      TextSpan(text: ' · "${block.emotionalTrigger}"',
                        style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: c.rose),
          ],
        ),
      ),
    );
  }

  // ── Phase card ────────────────────────────────────────────────────────────

  Widget _buildPhaseCard(Plan plan, Phase phase, String phaseKey,
      bool isOpen, PlanViewModel planVm) {
    final total = phase.contentBlocks.length;
    final done  = phase.contentBlocks
        .where((b) => b.status == ContentBlockStatus.published).length;
    final pct   = total == 0 ? 0.0 : done / total;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.white,
        border: Border.all(color: isOpen ? c.accent : c.border, width: isOpen ? 1.5 : 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expandedPhases[phaseKey] = !isOpen),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: Row(
                children: [
                  // Phase ball
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: phase.status == PhaseStatus.terminated
                          ? c.greenPale
                          : phase.status == PhaseStatus.inProgress
                              ? c.ink : c.border,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(_phaseEmoji(phase),
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: phase.status == PhaseStatus.inProgress
                              ? Colors.white
                              : phase.status == PhaseStatus.terminated
                                  ? c.green : c.ink3)),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.name.isNotEmpty ? phase.name : 'Phase ${phase.weekNumber}',
                          style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
                        Text(
                          phase.description?.isNotEmpty == true
                              ? phase.description!
                              : 'Sem. ${phase.weekNumber}',
                          style: TextStyle(fontSize: 11, color: c.ink3),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  // Count badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOpen ? Color(0xFFFFF3ED) : c.bg,
                      border: Border.all(color: isOpen ? Color(0xFFFDBA74) : c.border2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('$total posts',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: isOpen ? c.accent : c.ink2)),
                  ),
                  SizedBox(width: 6),
                  Icon(isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16, color: c.ink3),
                ],
              ),
            ),
          ),
          // Progress bar
          Container(
            height: 2,
            color: c.border,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(color: c.accent),
            ),
          ),
          // Product + deadline chips
          if (phase.productIds.isNotEmpty)
            Container(
              padding: EdgeInsets.fromLTRB(12, 7, 12, 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border))),
              child: Wrap(
                spacing: 6,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.amberPale,
                      border: Border.all(color: c.amberMid),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('📦 ${phase.productIds.length} produit(s)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.amber)),
                  ),
                ],
              ),
            ),
          // Posts
          if (isOpen)
            phase.contentBlocks.isEmpty
                ? _emptyPhase()
                : Column(
                    children: phase.contentBlocks.asMap().entries.map((e) {
                      final postKey = '${phaseKey}_post_${e.key}';
                      return _buildPostCard(plan, phase, e.value, postKey, planVm);
                    }).toList(),
                  ),
        ],
      ),
    );
  }

  // ── Post card ─────────────────────────────────────────────────────────────

  Widget _buildPostCard(Plan plan, Phase phase, ContentBlock block,
      String postKey, PlanViewModel planVm) {
    final sc = _statusColor(block.status);
    final sb = _statusBg(block.status);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.border))),
      child: InkWell(
        onTap: () => _openPostBottomSheet(plan, phase, block, planVm),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _formatBg(block.format),
                  borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(_formatEmoji(block.format),
                    style: TextStyle(fontSize: 16))),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title.isNotEmpty ? block.title : 'Post sans titre',
                      style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      '${block.format.label} · ${plan.platforms.take(2).join(" + ")}',
                      style: TextStyle(fontSize: 11, color: c.ink3)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sb, borderRadius: BorderRadius.circular(7)),
                child: Text(block.status.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w700,
                    color: sc, letterSpacing: 0.3)),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: c.ink3),
            ],
          ),
        ),
      ),
    );
  }

  // ── Post bottom sheet ─────────────────────────────────────────────────────

  void _openPostBottomSheet(Plan plan, Phase phase, ContentBlock block, PlanViewModel planVm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostBottomSheet(
        plan: plan,
        phase: phase,
        block: block,
        planVm: planVm,
        c: c,
        onRefresh: _silentRefresh,
      ),
    );
  }


  // ── Status stepper ────────────────────────────────────────────────────────

  Widget _buildStatusStepper(ContentBlockStatus current) {
    final steps = [
      (ContentBlockStatus.empty,             '·',  'Vide'),
      (ContentBlockStatus.draft,             '✎',  'Brouillon'),
      (ContentBlockStatus.submitted,         '↑',  'Soumis'),
      (ContentBlockStatus.revisionRequested, '!',  'Révision'),
      (ContentBlockStatus.approved,          '✓',  'Approuvé'),
      (ContentBlockStatus.published,         '■',  'Publié'),
    ];

    final currentIdx = steps.indexWhere((s) => s.$1 == current);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.white, border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: steps.asMap().entries.map((entry) {
            final i     = entry.key;
            final step  = entry.value;
            final done  = i < currentIdx;
            final isCur = i == currentIdx;
            return Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: done ? c.accent : isCur ? c.white : c.bg,
                        border: Border.all(
                          color: (done || isCur) ? c.accent : c.border2, width: 1.5),
                        shape: BoxShape.circle,
                        boxShadow: isCur
                            ? [BoxShadow(color: c.accent.withValues(alpha: 0.2), blurRadius: 6, spreadRadius: 2)]
                            : null,
                      ),
                      child: Center(
                        child: Text(done ? '✓' : step.$2,
                          style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w800,
                            color: done ? Colors.white : isCur ? c.accent : c.ink3)),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(step.$3,
                      style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: isCur ? c.accent : c.ink3)),
                  ],
                ),
                if (entry.key < steps.length - 1)
                  Container(
                    width: 16, height: 1.5,
                    color: i < currentIdx ? c.accent : c.border2,
                    margin: EdgeInsets.only(bottom: 14)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── AI field ──────────────────────────────────────────────────────────────

  Widget _aiField(String label, String content, bool canEdit,
      bool isGenerating, VoidCallback onGenerate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
              style: TextStyle(
                fontSize: 10.5, fontWeight: FontWeight.w800,
                color: c.ink3, letterSpacing: 0.5)),
            if (canEdit)
              GestureDetector(
                onTap: isGenerating ? null : onGenerate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    border: Border.all(color: Color(0xFFBFDBFE)),
                    borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isGenerating)
                        SizedBox(width: 10, height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent2))
                      else
                        Text('✦', style: TextStyle(fontSize: 10, color: c.accent2)),
                      SizedBox(width: 3),
                      Text(isGenerating ? '...' : 'IA Générer',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800, color: c.accent2)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.white,
            border: Border.all(color: c.border2, width: 1.5),
            borderRadius: BorderRadius.circular(10)),
          child: Text(
            content.isEmpty ? '...' : content,
            style: TextStyle(
              fontSize: 13, height: 1.45,
              color: content.isEmpty ? c.ink3 : c.ink,
              fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  // ── AI toolbar ────────────────────────────────────────────────────────────

  Widget _buildAIToolbar() {
    final tools = [('🎬', 'Vidéo IA'), ('🖼', 'Image IA'), ('📤', 'Uploader'), ('✂️', 'Éditer'), ('🎤', 'Coach')];
    return Row(
      children: tools.map((t) => Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 3),
          padding: EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: c.white, border: Border.all(color: c.border, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Text(t.$1, style: TextStyle(fontSize: 18)),
              SizedBox(height: 3),
              Text(t.$2,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.ink2),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ── Upload zone ───────────────────────────────────────────────────────────

  Widget _buildUploadZone(ContentBlock block) {
    if (block.imageUrl != null && block.imageUrl!.isNotEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9)),
              child: Center(child: Text(_formatEmoji(block.format),
                  style: TextStyle(fontSize: 22))),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Média uploadé',
                    style: TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ),
            Text('✓', style: TextStyle(fontSize: 13, color: Color(0xFF4ADE80), fontWeight: FontWeight.w800)),
          ],
        ),
      );
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: c.border2, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: c.white),
      child: Column(
        children: [
          Text('📎', style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text('Déposer vidéo ou image',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.ink2)),
          SizedBox(height: 2),
          Text('MP4, MOV, JPG · max 500 MB',
            style: TextStyle(fontSize: 11, color: c.ink3)),
        ],
      ),
    );
  }

  // ── Platform toggles ──────────────────────────────────────────────────────

  Widget _buildPlatformToggles(String postKey, Plan plan, Set<String> active) {
    return Wrap(
      spacing: 7, runSpacing: 6,
      children: plan.platforms.map((p) {
        final isOn = active.contains(p);
        Color border, bg, fg;
        if (p.toLowerCase().contains('instagram')) {
          border = Color(0xFFBE185D); bg = Color(0xFFFDF2F8); fg = Color(0xFFBE185D);
        } else if (p.toLowerCase().contains('tiktok')) {
          border = Color(0xFF111111); bg = Color(0xFFF5F5F5); fg = Color(0xFF111111);
        } else {
          border = Color(0xFF1D4ED8); bg = Color(0xFFEFF3FF); fg = Color(0xFF1D4ED8);
        }
        return GestureDetector(
          onTap: () => setState(() {
            if (isOn) { active.remove(p); } else { active.add(p); }
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: isOn ? bg : c.white,
              border: Border.all(color: isOn ? border : c.border2, width: 1.5),
              borderRadius: BorderRadius.circular(99)),
            child: Text(p,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOn ? fg : c.ink2)),
          ),
        );
      }).toList(),
    );
  }

  // ── Schedule options ──────────────────────────────────────────────────────

  Widget _buildScheduleOptions(String postKey, String current) {
    final opts = [('🚀', 'Maintenant', 'Direct', 'now'), ('⚡', 'Auto', 'Dès upload', 'auto'), ('📅', 'Programmer', '+ Rappel', 'schedule')];
    return Row(
      children: opts.map((o) {
        final isOn = current == o.$4;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _scheduleMode[postKey] = o.$4),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 3),
              padding: EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: isOn ? c.ink : c.white,
                border: Border.all(color: isOn ? c.ink : c.border2, width: 1.5),
                borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Text(o.$1, style: TextStyle(fontSize: 18,
                    color: isOn ? Colors.white : null)),
                  SizedBox(height: 3),
                  Text(o.$2,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: isOn ? Colors.white70 : c.ink2)),
                  Text(o.$3,
                    style: TextStyle(fontSize: 9, color: isOn ? Colors.white38 : c.ink3)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bluePale, border: Border.all(color: Color(0xFFBAE6FD)),
        borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('DATE ET HEURE',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.ink3, letterSpacing: 0.5)),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.white, border: Border.all(color: Color(0xFFBAE6FD), width: 1.5),
              borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: c.blueD),
                SizedBox(width: 8),
                Text('Choisir une date…',
                  style: TextStyle(fontSize: 13, color: c.ink3, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Color(0xFFBAE6FD), borderRadius: BorderRadius.circular(7)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🔔', style: TextStyle(fontSize: 12)),
                SizedBox(width: 5),
                Text('Rappel 30 min avant',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.blueD)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
    padding: EdgeInsets.only(bottom: 2),
    child: Text(label,
      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.ink3, letterSpacing: 0.5)),
  );

  Widget _outlineBtn(String label, Color fg, Color bg, Color border, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bg, border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg))),
      ),
    );

  Widget _fullBtn(String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: Offset(0, 3))]),
        child: Center(child: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
      ),
    );

  Widget _emptyPhase() => Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Column(
      children: [
        Text('📭', style: TextStyle(fontSize: 32)),
        SizedBox(height: 8),
        Text('Aucun post assigné dans cette phase',
          style: TextStyle(fontSize: 13, color: c.ink3, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — PHASES (read-only overview)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPhasesTab(Plan plan) {
    return ListView(
      padding: EdgeInsets.fromLTRB(14, 12, 14, 40),
      children: [
        Text('Vue d\'ensemble · Lecture seule',
          style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink)),
        SizedBox(height: 12),
        ...plan.phases.asMap().entries.map((entry) {
          final idx   = entry.key;
          final phase = entry.value;
          final total = phase.contentBlocks.length;
          final done  = phase.contentBlocks
              .where((b) => b.status == ContentBlockStatus.published).length;
          final pct   = total == 0 ? 0.0 : done / total;

          String statusLabel; Color statusBg; Color statusFg;
          if (phase.status == PhaseStatus.terminated) {
            statusLabel = 'TERMINÉ'; statusBg = c.greenPale; statusFg = c.green;
          } else if (phase.status == PhaseStatus.inProgress) {
            statusLabel = 'EN COURS'; statusBg = Color(0xFFFFF3ED); statusFg = c.accent;
          } else {
            statusLabel = 'À VENIR'; statusBg = c.border; statusFg = c.ink3;
          }

          return Container(
            margin: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: c.white, border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: phase.status == PhaseStatus.terminated
                              ? c.greenPale
                              : phase.status == PhaseStatus.inProgress
                                  ? c.ink : c.border,
                          shape: BoxShape.circle),
                        child: Center(child: Text(_phaseEmoji(phase),
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800,
                            color: phase.status == PhaseStatus.inProgress
                                ? Colors.white
                                : phase.status == PhaseStatus.terminated
                                    ? c.green : c.ink3))),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(phase.name.isNotEmpty ? phase.name : 'Phase ${idx + 1}',
                              style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
                            Text('Sem. ${phase.weekNumber}',
                              style: TextStyle(fontSize: 11, color: c.ink3)),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg, borderRadius: BorderRadius.circular(99)),
                        child: Text(statusLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusFg)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mes posts',
                            style: TextStyle(fontSize: 12, color: c.ink3, fontWeight: FontWeight.w600)),
                          Text('$done / $total publiés',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.ink)),
                        ],
                      ),
                      SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: pct, minHeight: 5,
                          backgroundColor: c.border,
                          valueColor: AlwaysStoppedAnimation(
                            phase.status == PhaseStatus.terminated ? c.green : c.accent)),
                      ),
                      if (phase.productIds.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: c.amberPale, border: Border.all(color: c.amberMid),
                                borderRadius: BorderRadius.circular(99)),
                              child: Text('📦 ${phase.productIds.length} produit(s)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.amber)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3 — CALENDRIER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCalendarTab(Plan plan, PlanViewModel planVm) {
    final now   = DateTime.now();
    final year  = now.year;
    final month = now.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Mon

    // Collect all scheduled blocks
    final upcoming = plan.phases
        .expand((ph) => ph.contentBlocks)
        .where((b) =>
            b.status == ContentBlockStatus.approved ||
            b.status == ContentBlockStatus.scheduled ||
            b.status == ContentBlockStatus.published)
        .toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 40),
      children: [
        // Month header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_monthName(month)} $year',
              style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
            Row(
              children: [
                _calNavBtn('‹'),
                SizedBox(width: 5),
                _calNavBtn('›'),
              ],
            ),
          ],
        ),
        SizedBox(height: 12),
        // Day headers
        Row(
          children: ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'].map((d) =>
            Expanded(child: Center(
              child: Text(d, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.ink3, letterSpacing: 0.3))))).toList(),
        ),
        SizedBox(height: 4),
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, childAspectRatio: 1),
          itemCount: 42,
          itemBuilder: (_, i) {
            final dayNum = i - (startWeekday - 1) + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final isToday = dayNum == now.day;
            return Container(
              margin: EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isToday ? c.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(8)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$dayNum',
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday ? Colors.white : c.ink,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500)),
                  // Dot for posts on this day
                  if (!isToday)
                    Container(
                      width: 4, height: 4,
                      margin: EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: (dayNum % 5 == 0) ? c.accent : Colors.transparent,
                        shape: BoxShape.circle)),
                ],
              ),
            );
          },
        ),
        // Legend
        SizedBox(height: 10),
        Row(
          children: [
            _legendDot(Color(0xFFBE185D), 'Instagram'),
            SizedBox(width: 14),
            _legendDot(Color(0xFF1D4ED8), 'Facebook'),
            SizedBox(width: 14),
            _legendDot(c.accent, 'Programmé'),
          ],
        ),
        SizedBox(height: 20),
        // Upcoming posts
        Text('PROCHAINS POSTS',
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.ink3, letterSpacing: 0.5)),
        SizedBox(height: 10),
        if (upcoming.isEmpty)
          Text('Aucun post approuvé ou programmé.',
            style: TextStyle(fontSize: 13, color: c.ink3))
        else
          ...upcoming.take(5).map((block) => _buildUpcomingItem(block, plan)),
      ],
    );
  }

  Widget _calNavBtn(String label) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      color: c.white, border: Border.all(color: c.border2),
      borderRadius: BorderRadius.circular(8)),
    child: Center(child: Text(label,
      style: TextStyle(fontSize: 12, color: c.ink2))),
  );

  Widget _legendDot(Color color, String label) => Row(
    children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: c.ink3)),
    ],
  );

  String _monthName(int m) {
    const names = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return names[m];
  }

  Widget _buildUpcomingItem(ContentBlock block, Plan plan) {
    final sc = _statusColor(block.status);
    final sb = _statusBg(block.status);
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.white, border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _formatBg(block.format), borderRadius: BorderRadius.circular(9)),
            child: Center(child: Text(_formatEmoji(block.format),
                style: TextStyle(fontSize: 14))),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(block.title.isNotEmpty ? block.title : 'Post sans titre',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.ink),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(plan.platforms.take(2).join(' · '),
                  style: TextStyle(fontSize: 11, color: c.ink3)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: sb, borderRadius: BorderRadius.circular(7)),
            child: Text(block.status.label.toUpperCase(),
              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: sc, letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 4 — NOTES & DNA
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNotesAndDNATab(Plan plan, PlanViewModel planVm) {
    final noteCtrl = TextEditingController();

    return ListView(
      padding: EdgeInsets.fromLTRB(14, 14, 14, 40),
      children: [
        // ── Campaign notes ────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: c.white, border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notes de la campagne',
                      style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
                    if (plan.notes.isNotEmpty && !plan.notesSeen)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.rosePale, borderRadius: BorderRadius.circular(99)),
                        child: Text('Nouveau',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.rose)),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.border),
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.notes.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.bg, borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('👑', style: TextStyle(fontSize: 14)),
                                SizedBox(width: 6),
                                Text('Brand Owner',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.accent)),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(plan.notes,
                              style: TextStyle(fontSize: 12.5, color: c.ink, height: 1.45)),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                    // Reply compose
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.bg, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: noteCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Répondre ou ajouter une note…',
                              hintStyle: TextStyle(color: c.ink3, fontSize: 12.5),
                              filled: true,
                              fillColor: c.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(color: c.border2)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(9),
                                borderSide: BorderSide(color: c.border2)),
                              contentPadding: EdgeInsets.all(10)),
                            style: TextStyle(fontSize: 12.5),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              if (noteCtrl.text.trim().isEmpty) return;
                              await planVm.updatePlanNotes(plan.id!, noteCtrl.text.trim());
                              noteCtrl.clear();
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: c.accent, borderRadius: BorderRadius.circular(9)),
                              child: Text('Envoyer',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),

        // ── Plan overview ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: c.white, border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Text('Plan Overview',
                  style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
              ),
              Divider(height: 1, color: c.border),
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    _overviewRow('Objectif', plan.objective.label),
                    _overviewRow('Durée', '${plan.durationWeeks} semaines'),
                    _overviewRow('Fréquence', '${plan.postingFrequency}× / semaine'),
                    _overviewRow('Intensité', plan.promotionIntensity),
                    _overviewRow('Plateformes', plan.platforms.join(', ')),
                    SizedBox(height: 12),
                    Divider(height: 1, color: c.border),
                    SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('CONTENT MIX',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.ink3, letterSpacing: 0.5)),
                    ),
                    SizedBox(height: 10),
                    _mixBar('Éducatif',     plan.contentMixPreference['educational'] ?? 25, Color(0xFFE85D26)),
                    _mixBar('Promotionnel', plan.contentMixPreference['promotional'] ?? 25, Color(0xFF1D4ED8)),
                    _mixBar('Storytelling', plan.contentMixPreference['storytelling'] ?? 25, Color(0xFF059669)),
                    _mixBar('Autorité',     plan.contentMixPreference['authority'] ?? 25,    Color(0xFF7C3AED)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),

        // ── Brand DNA (read-only) ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: c.white, border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    Text('🧬 DNA IA de la marque',
                      style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: c.ink)),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.amberPale, border: Border.all(color: c.amberMid),
                        borderRadius: BorderRadius.circular(99)),
                      child: Text('Lecture seule',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.amber)),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.border),
              Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  children: [
                    _dnaField('Vision', plan.projectDNA.strategic.vision),
                    _dnaField('Angle de campagne', plan.projectDNA.strategic.campaignAngle),
                    _dnaField('Positionnement', plan.projectDNA.strategic.positioning),
                    _dnaField('Cible', plan.projectDNA.strategic.targetAudience.join(', ')),
                    _dnaField('Offre', plan.projectDNA.strategic.offer),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _overviewRow(String label, String value) => Padding(
    padding: EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: c.ink3, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.ink)),
      ],
    ),
  );

  Widget _mixBar(String label, dynamic rawVal, Color color) {
    final val = (rawVal as num?)?.toInt() ?? 25;
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90,
            child: Text(label, style: TextStyle(fontSize: 12.5, color: c.ink2))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: val / 100, minHeight: 4,
                backgroundColor: c.border,
                valueColor: AlwaysStoppedAnimation(color)),
            ),
          ),
          SizedBox(width: 8),
          SizedBox(width: 32,
            child: Text('$val%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _dnaField(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.ink3, letterSpacing: 0.4)),
          SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 12.5, color: c.ink, height: 1.45)),
        ],
      ),
    );
  }

}

// ══════════════════════════════════════════════════════════════════════════════
// POST BOTTOM SHEET — opens when collaborator taps a post card
// ══════════════════════════════════════════════════════════════════════════════

class _PostBottomSheet extends StatefulWidget {
  final Plan plan;
  final Phase phase;
  final ContentBlock block;
  final PlanViewModel planVm;
  final _C c;
  final Future<void> Function() onRefresh;

  const _PostBottomSheet({
    required this.plan,
    required this.phase,
    required this.block,
    required this.planVm,
    required this.c,
    required this.onRefresh,
  });

  @override
  State<_PostBottomSheet> createState() => _PostBottomSheetState();
}

class _PostBottomSheetState extends State<_PostBottomSheet> {
  late ContentBlock _block;
  late _C c;

  @override
  void initState() {
    super.initState();
    _block = widget.block;
    _hook = widget.block.hook;
    _caption = widget.block.caption;
    _videoIdea = widget.block.emotionalTrigger ?? '';
  }

  // Local editable content state
  String _hook = '';
  String _caption = '';
  String _videoIdea = '';
  bool _isGenerating = false;

  // AI generation pools
  static const _hookPool = [
    'Ce que les dermatologues ne te disent jamais sur ta peau... 👀',
    'J\'ai testé ce produit pendant 7 jours — voici ce qui s\'est passé ✨',
    'Le secret que toutes les femmes à la peau parfaite ont en commun 🤍',
    'Pourquoi ta routine ne fonctionne pas (et comment la fixer) 💡',
    'POV : tu découvres enfin le produit qui change tout 🌟',
  ];
  static const _captionPool = [
    'Ma peau n\'a jamais été aussi lumineuse. Lien en bio 👆 #skincare',
    '7 jours, c\'est tout ce qu\'il a fallu. Résultats incroyables ✨ #beauté',
    'Depuis que j\'ai intégré ce produit, plus besoin de fond de teint 🌿',
    'La routine qui a tout changé pour moi. Découvrez-la en bio 💫',
    'Avant / Après — les résultats parlent d\'eux-mêmes 🔥 #transformation',
  ];
  static const _videoPool = [
    'Transition matin/soir · Gros plan texture · Voix off douce · Fond blanc',
    'POV : ta routine en 45s · Zoom application · Résultat final',
    'Before/after · Lumière naturelle · Musique apaisante · Sous-titres',
    'Unboxing + test live · Réaction authentique · Format vertical 9:16',
    'Tutoriel étape par étape · Texte animé · Musique tendance TikTok',
  ];

  Future<void> _generate(String type) async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    if (type == 'video') {
      // Navigate to video ideas generator with pre-filled context
      setState(() => _isGenerating = false);
      Navigator.pop(context);
      context.push('/video-ideas-form');
      return;
    }

    await Future.delayed(const Duration(milliseconds: 800));
    final rand = DateTime.now().millisecondsSinceEpoch;
    String generated;
    switch (type) {
      case 'hook':
        generated = _hookPool[rand % _hookPool.length];
        setState(() => _hook = generated);
        break;
      default:
        generated = _captionPool[rand % _captionPool.length];
        setState(() => _caption = generated);
    }
    // Save to backend
    if (_block.id != null) {
      try {
        await ContentBlockService().updateContent(
          _block.id!,
          hook: type == 'hook' ? generated : null,
          caption: type == 'caption' ? generated : null,
        );
      } catch (e) {
        debugPrint('[PostBottomSheet] save generated content error (non-fatal): $e');
      }
    }
    if (mounted) setState(() => _isGenerating = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    c = _C(context);
  }

  bool get _isRevision  => _block.status == ContentBlockStatus.revisionRequested;
  bool get _isApproved  => _block.status == ContentBlockStatus.approved || _block.status == ContentBlockStatus.scheduled;
  bool get _isPublished => _block.status == ContentBlockStatus.published;
  bool get _isSubmitted => _block.status == ContentBlockStatus.submitted;
  bool get _canEdit     => _block.status == ContentBlockStatus.empty || _block.status == ContentBlockStatus.draft || _isRevision;
  bool get _canSubmit   => _canEdit && (_hook.isNotEmpty || _caption.isNotEmpty);

  String _findPlanId(String blockId) {
    for (final plan in widget.planVm.plans) {
      for (final phase in plan.phases) {
        for (final b in phase.contentBlocks) {
          if (b.id == blockId) return plan.id ?? '';
        }
      }
    }
    return widget.plan.id ?? '';
  }

  void _refreshBlock() {
    // Find updated block from ViewModel
    for (final plan in widget.planVm.plans) {
      for (final phase in plan.phases) {
        for (final b in phase.contentBlocks) {
          if (b.id == _block.id) {
            if (mounted) setState(() => _block = b);
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    c = _C(context);
    final planVm = widget.planVm;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: c.border2, borderRadius: BorderRadius.circular(99)),
            ),
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _formatBgFor(_block.format),
                      borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(_formatEmojiFor(_block.format), style: TextStyle(fontSize: 18))),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _block.title.isNotEmpty ? _block.title : 'Post sans titre',
                          style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(widget.phase.name.isNotEmpty ? widget.phase.name : 'Phase',
                          style: TextStyle(fontSize: 11, color: c.ink3)),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusBgFor(_block.status),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(_block.status.label.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                        color: _statusColorFor(_block.status), letterSpacing: 0.3)),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: c.ink3, size: 20),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Status stepper
                  _buildStepper(),
                  SizedBox(height: 14),

                  // Banners
                  if (_isRevision) _revisionBanner(),
                  if (_isApproved) _approvedBanner(),
                  if (_isPublished) _publishedBanner(),
                  if (_isSubmitted) _submittedBanner(),

                  // AI Fields
                  if (!_isPublished) ...[
                    _aiField('HOOK', _hook, _isGenerating, () => _generate('hook')),
                    SizedBox(height: 10),
                    _aiField('CAPTION', _caption, _isGenerating, () => _generate('caption')),
                    SizedBox(height: 10),
                    _aiField('IDÉE VIDÉO', _videoIdea, _isGenerating, () => _generate('video')),
                    SizedBox(height: 16),

                    // Products in charge
                    if (widget.phase.productIds.isNotEmpty) ...[
                      _sectionLabel('PRODUITS EN CHARGE'),
                      SizedBox(height: 8),
                      _buildProductsSection(),
                      SizedBox(height: 16),
                    ],

                    // AI Content Tools
                    _sectionLabel('CRÉER LE CONTENU'),
                    SizedBox(height: 8),
                    _buildAIToolbar(),
                    SizedBox(height: 12),

                    // Upload zone
                    _buildUploadZone(),
                    SizedBox(height: 16),

                    // Platform toggles
                    _sectionLabel('PUBLIER SUR'),
                    SizedBox(height: 8),
                    _buildPlatformToggles(),
                    SizedBox(height: 16),

                    // Schedule
                    _sectionLabel('QUAND PUBLIER ?'),
                    SizedBox(height: 8),
                    _buildScheduleOptions(),
                    SizedBox(height: 20),

                    // Action buttons
                    if (_canEdit) ...[
                      if (_canSubmit)
                        _actionBtn(
                          _isRevision ? '↑ Resoumettre pour approbation' : '↑ Soumettre pour approbation',
                          c.accent,
                          () async {
                            widget.planVm.setCurrentPlan(widget.plan);
                            await widget.planVm.updateBlockStatus(_block.id!, ContentBlockStatus.submitted);
                            _refreshBlock();
                            await widget.onRefresh();
                          },
                        ),
                    ],
                    if (_isApproved)
                      _actionBtn('✓ Marquer comme publié', c.green, () async {
                        widget.planVm.setCurrentPlan(widget.plan);
                        await widget.planVm.updateBlockStatus(_block.id!, ContentBlockStatus.published);
                        _refreshBlock();
                        await widget.onRefresh();
                        if (mounted) Navigator.pop(context);
                      }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final steps = [
      (ContentBlockStatus.empty,             '·',  'Vide'),
      (ContentBlockStatus.draft,             '✎',  'Brouillon'),
      (ContentBlockStatus.submitted,         '↑',  'Soumis'),
      (ContentBlockStatus.revisionRequested, '!',  'Révision'),
      (ContentBlockStatus.approved,          '✓',  'Approuvé'),
      (ContentBlockStatus.published,         '■',  'Publié'),
    ];
    final currentIdx = steps.indexWhere((s) => s.$1 == _block.status);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.white, border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: steps.asMap().entries.map((entry) {
            final i = entry.key; final step = entry.value;
            final done = i < currentIdx; final isCur = i == currentIdx;
            return Row(children: [
              Column(children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: done ? c.accent : isCur ? c.white : c.bg,
                    border: Border.all(color: (done || isCur) ? c.accent : c.border2, width: 1.5),
                    shape: BoxShape.circle,
                    boxShadow: isCur ? [BoxShadow(color: c.accent.withValues(alpha: 0.2), blurRadius: 6, spreadRadius: 2)] : null,
                  ),
                  child: Center(child: Text(done ? '✓' : step.$2,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                      color: done ? Colors.white : isCur ? c.accent : c.ink3))),
                ),
                SizedBox(height: 3),
                Text(step.$3, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                  color: isCur ? c.accent : c.ink3)),
              ]),
              if (i < steps.length - 1)
                Container(width: 16, height: 1.5, color: i < currentIdx ? c.accent : c.border2,
                  margin: EdgeInsets.only(bottom: 14)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _aiField(String label, String content, bool isGenerating, VoidCallback onGenerate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.ink3, letterSpacing: 0.5)),
            GestureDetector(
              onTap: isGenerating ? null : onGenerate,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  border: Border.all(color: Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(99)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (isGenerating)
                    SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: c.accent2))
                  else
                    Text('✦', style: TextStyle(fontSize: 10, color: c.accent2)),
                  SizedBox(width: 3),
                  Text(isGenerating ? '...' : 'IA Générer',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: c.accent2)),
                ]),
              ),
            ),
          ],
        ),
        SizedBox(height: 5),
        Container(
          width: double.infinity, padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.white, border: Border.all(color: c.border2, width: 1.5),
            borderRadius: BorderRadius.circular(10)),
          child: Text(
            content.isEmpty ? '...' : content,
            style: TextStyle(fontSize: 13, height: 1.45,
              color: content.isEmpty ? c.ink3 : c.ink, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: Offset(0, 3))]),
        child: Center(child: Text(label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
      ),
    );

  Widget _revisionBanner() => Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(color: c.rosePale, border: Border.all(color: c.roseMid), borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('✏️', style: TextStyle(fontSize: 16)),
      SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Note du Brand Owner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.rose)),
        SizedBox(height: 3),
        Text(_block.emotionalTrigger?.isNotEmpty == true ? _block.emotionalTrigger! : 'Des modifications ont été demandées.',
          style: TextStyle(fontSize: 12, color: c.rose, height: 1.4)),
      ])),
    ]),
  );

  Widget _approvedBanner() => Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: c.greenPale, border: Border.all(color: c.greenMid), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(Icons.check_circle_rounded, color: c.green, size: 16),
      SizedBox(width: 7),
      Text('Approuvé — tu peux maintenant publier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.green)),
    ]),
  );

  Widget _publishedBanner() => Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: c.slatePale, border: Border.all(color: Color(0xFF1E293B)), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(Icons.check_circle_rounded, color: c.slateD, size: 16),
      SizedBox(width: 7),
      Text('Publié ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.slateD)),
    ]),
  );

  Widget _submittedBanner() => Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: c.violetPale, border: Border.all(color: c.violetMid), borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(Icons.hourglass_top_rounded, color: c.violet, size: 16),
      SizedBox(width: 7),
      Text("En attente d'approbation…", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.violet)),
    ]),
  );

  Color _formatBgFor(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:     return Color(0xFFFCE7F3);
      case ContentFormat.story:    return Color(0xFFEFF6FF);
      case ContentFormat.carousel: return Color(0xFFFFFBEB);
      default:                     return Color(0xFFF0FDF4);
    }
  }

  String _formatEmojiFor(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:     return '🎬';
      case ContentFormat.story:    return '📸';
      case ContentFormat.carousel: return '🎠';
      default:                     return '🖼';
    }
  }

  Color _statusColorFor(ContentBlockStatus s) {
    switch (s) {
      case ContentBlockStatus.empty:             return Color(0xFFA8A29E);
      case ContentBlockStatus.draft:             return Color(0xFF92400E);
      case ContentBlockStatus.submitted:         return Color(0xFF5B21B6);
      case ContentBlockStatus.revisionRequested: return Color(0xFF991B1B);
      case ContentBlockStatus.approved:          return Color(0xFF059669);
      case ContentBlockStatus.scheduled:         return Color(0xFF0C4A6E);
      case ContentBlockStatus.published:         return Color(0xFF0F172A);
    }
  }

  Color _statusBgFor(ContentBlockStatus s) {
    switch (s) {
      case ContentBlockStatus.empty:             return Color(0xFFE7E5E4);
      case ContentBlockStatus.draft:             return Color(0xFFFEF3C7);
      case ContentBlockStatus.submitted:         return Color(0xFFEDE9FE);
      case ContentBlockStatus.revisionRequested: return Color(0xFFFEE2E2);
      case ContentBlockStatus.approved:          return Color(0xFFD1FAE5);
      case ContentBlockStatus.scheduled:         return Color(0xFFE0F2FE);
      case ContentBlockStatus.published:         return Color(0xFFE2E8F0);
    }
  }

  Widget _sectionLabel(String label) => Text(label,
    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: c.ink3, letterSpacing: 0.5));

  Widget _buildAIToolbar() {
    return Row(
      children: [
        _toolBtn('🎬', 'Vidéo IA', () {
          Navigator.pop(context);
          context.push('/video-ideas-form');
        }),
        _toolBtn('🖼', 'Image IA', () {
          Navigator.pop(context);
          context.push('/generators');
        }),
        _toolBtn('📤', 'Uploader', () => _pickFile()),
        _toolBtn('✂️', 'Éditer', () {
          Navigator.pop(context);
          context.push('/image-editor');
        }),
        _toolBtn('🎤', 'Coach', () {
          Navigator.pop(context);
          context.push('/camera-coach');
        }),
      ],
    );
  }

  Widget _toolBtn(String emoji, String label, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: c.white, border: Border.all(color: c.border, width: 1.5),
          borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(emoji, style: TextStyle(fontSize: 17)),
          SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.ink2), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );

  Future<void> _pickFile() async {
    // Use file_picker if available, otherwise show snackbar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Fonctionnalité upload disponible bientôt'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: c.border2, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: c.white),
        child: Column(children: [
          Text('📎', style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Text('Déposer vidéo ou image',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.ink2)),
          SizedBox(height: 2),
          Text('MP4, MOV, JPG · max 500 MB',
            style: TextStyle(fontSize: 11, color: c.ink3)),
        ]),
      ),
    );
  }

  String _selectedSched = 'auto';
  DateTime? _scheduledAt;
  final List<String> _selectedPlatforms = [];

  Widget _buildPlatformToggles() {
    final platforms = widget.plan.platforms.isNotEmpty
        ? widget.plan.platforms
        : ['Instagram', 'TikTok', 'Facebook'];
    return Wrap(
      spacing: 7, runSpacing: 6,
      children: platforms.map((p) {
        final isOn = _selectedPlatforms.contains(p);
        Color border, bg, fg;
        if (p.toLowerCase().contains('instagram')) {
          border = Color(0xFFBE185D); bg = Color(0xFFFDF2F8); fg = Color(0xFFBE185D);
        } else if (p.toLowerCase().contains('tiktok')) {
          border = Color(0xFF111111); bg = Color(0xFFF5F5F5); fg = Color(0xFF111111);
        } else {
          border = Color(0xFF1D4ED8); bg = Color(0xFFEFF3FF); fg = Color(0xFF1D4ED8);
        }
        return GestureDetector(
          onTap: () => setState(() {
            if (isOn) { _selectedPlatforms.remove(p); } else { _selectedPlatforms.add(p); }
          }),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: isOn ? bg : c.white,
              border: Border.all(color: isOn ? border : c.border2, width: 1.5),
              borderRadius: BorderRadius.circular(99)),
            child: Text(p, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isOn ? fg : c.ink2)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProductsSection() {
    // Try to get product names from BrandViewModel
    final brandVm = context.read<BrandViewModel>();
    final brand = brandVm.brands.cast<dynamic>().firstWhere(
      (b) => b.id == widget.plan.brandId,
      orElse: () => null,
    );
    return Wrap(
      spacing: 6, runSpacing: 6,
      children: widget.phase.productIds.map((pid) {
        // Look up product name from brand
        String name = pid;
        if (brand != null) {
          final product = brand.products.cast<dynamic>().firstWhere(
            (p) => p.id == pid || p.id?.toString() == pid,
            orElse: () => null,
          );
          if (product != null) name = product.name ?? pid;
        }
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Color(0xFFFEF3C7),
            border: Border.all(color: Color(0xFFFDE68A)),
            borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('📦', style: TextStyle(fontSize: 12)),
            SizedBox(width: 5),
            Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildScheduleOptions() {
    final opts = [
      ('🚀', 'Maintenant', 'Direct', 'now'),
      ('⚡', 'Auto', 'Dès upload', 'auto'),
      ('📅', 'Programmer', '+ Rappel', 'schedule'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: opts.map((o) {
            final isOn = _selectedSched == o.$4;
            return Expanded(
              child: GestureDetector(
                onTap: () async {
                  setState(() => _selectedSched = o.$4);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: c.accent),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null && mounted) {
                      setState(() {
                        _scheduledAt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                      });
                    }
                  }
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 3),
                  padding: EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: isOn ? c.ink : c.white,
                    border: Border.all(color: isOn ? c.ink : c.border2, width: 1.5),
                    borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text(o.$1, style: TextStyle(fontSize: 17, color: isOn ? Colors.white : null)),
                    SizedBox(height: 3),
                    Text(o.$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: isOn ? Colors.white70 : c.ink2)),
                    Text(o.$3, style: TextStyle(fontSize: 9, color: isOn ? Colors.white38 : c.ink3)),
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
        if (_scheduledAt != null) ...[
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.bluePale,
              border: Border.all(color: c.blueD.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: c.blueD),
              SizedBox(width: 8),
              Text(
                '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} à ${_scheduledAt!.hour.toString().padLeft(2,'0')}:${_scheduledAt!.minute.toString().padLeft(2,'0')}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.blueD)),
              Spacer(),
              GestureDetector(
                onTap: () => setState(() => _scheduledAt = null),
                child: Icon(Icons.close_rounded, size: 16, color: c.blueD)),
            ]),
          ),
          SizedBox(height: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: c.bluePale, borderRadius: BorderRadius.circular(7)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🔔', style: TextStyle(fontSize: 12)),
              SizedBox(width: 5),
              Text('Rappel 30 min avant',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c.blueD)),
            ]),
          ),
        ],
      ],
    );
  }
}
