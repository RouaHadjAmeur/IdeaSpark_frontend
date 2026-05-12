import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../view_models/brand_view_model.dart';
import '../../models/brand.dart';
import '../../models/plan.dart';
import '../../models/content_block.dart' hide ContentBlock, ContentBlockStatus, ContentFormat;
import '../../services/content_block_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/kpi_tile.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/auth_view_model.dart';
import 'package:intl/intl.dart';
import '../../widgets/content_calendar_widget.dart';
import '../../view_models/collaboration_view_model.dart';
import '../../models/collaboration.dart';
import '../../widgets/status_workflow_node.dart';

class MarketingStrategyScreen extends StatefulWidget {
  const MarketingStrategyScreen({super.key});

  @override
  State<MarketingStrategyScreen> createState() => _MarketingStrategyScreenState();
}

class _MarketingStrategyScreenState extends State<MarketingStrategyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBrandId;
  final Map<String, bool> _expandedPhases = {};
  final TextEditingController _teamSearchCtrl = TextEditingController();

  static const _tabs = [
    'Dashboard',
    'Phases',
    'Contenu',
    'Budget',
    'DNA IA',
    'Communauté',
    'Automation',
    'Monétisation',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<BrandViewModel>().loadBrands();
      final pvm = context.read<PlanViewModel>();
      await pvm.loadPlans();
      // Inject content blocks for all loaded plans
      for (final plan in pvm.plans) {
        if (plan.id != null) await pvm.loadAndInjectBlocks(plan.id!);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teamSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandVm = context.watch<BrandViewModel>();
    final planVm = context.watch<PlanViewModel>();
    
    // Ensure _selectedBrandId is valid or reset it
    if (brandVm.brands.isNotEmpty) {
      if (_selectedBrandId == null || !brandVm.brands.any((b) => b.id == _selectedBrandId)) {
        _selectedBrandId = brandVm.brands.first.id;
      }
    } else {
      _selectedBrandId = null;
    }

    // Filter plans for selected brand
    final brandPlans = planVm.plans.where((p) => p.brandId == _selectedBrandId).toList();
    
    // Prioritize active plan, fallback to draft
    Plan? currentPlan;
    if (planVm.currentPlan?.brandId == _selectedBrandId) {
      currentPlan = planVm.currentPlan;
    } else if (brandPlans.isNotEmpty) {
      currentPlan = brandPlans.firstWhere(
        (p) => p.status == PlanStatus.active,
        orElse: () => brandPlans.firstWhere(
          (p) => p.status == PlanStatus.draft,
          orElse: () => brandPlans.first,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF), // --bg
      body: Builder(builder: (context) {
        // Marketing Strategy is brand-owner only — show nothing for collaborators
        final authVm = context.watch<AuthViewModel>();
        if (!authVm.isBrandOwner) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            _buildTopBar(brandVm),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDashboardTab(currentPlan),
                _buildPhasesTab(currentPlan),
                _buildContenuTab(currentPlan),
                _buildBudgetTab(currentPlan),
                _buildAiTab(),
                _buildCommunityTab(currentPlan),
                _buildAutomationTab(),
                _buildMonetizationTab(currentPlan),
              ],
            ),
          ),
        ],
        );
      }),
    );
  }

  Widget _buildTopBar(BrandViewModel brandVm) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      color: const Color(0xFF6D4ED3), // --primary
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
              ),
              Text(
                'Stratégie Marketing',
                style: GoogleFonts.syne(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              // Brand selector dropdown
              _buildBrandSelector(brandVm),
            ],
          ),
          const SizedBox(height: 14),
          // Hero Card
          _buildHeroCard(brandVm),
        ],
      ),
    );
  }

  Widget _buildBrandSelector(BrandViewModel brandVm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrandId,
          dropdownColor: const Color(0xFF6D4ED3),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          items: {for (var b in brandVm.brands) b.id: b}.values.map((b) => DropdownMenuItem(
            value: b.id,
            child: Text(b.name),
          )).toList(),
          onChanged: (val) => setState(() => _selectedBrandId = val),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BrandViewModel brandVm) {
    final planVm = context.read<PlanViewModel>();
    final brand = brandVm.brands.firstWhere(
      (b) => b.id == _selectedBrandId,
      orElse: () => Brand(
        name: 'Brand Strategy',
        tone: BrandTone.professional,
        audience: BrandAudience(ageRange: '', gender: '', interests: []),
        platforms: [],
        contentPillars: []
      )
    );

    // Get current plan for this brand
    final brandPlans = planVm.plans.where((p) => p.brandId == _selectedBrandId).toList();
    Plan? currentPlan;
    if (planVm.currentPlan?.brandId == _selectedBrandId) {
      currentPlan = planVm.currentPlan;
    } else if (brandPlans.isNotEmpty) {
      currentPlan = brandPlans.firstWhere(
        (p) => p.status == PlanStatus.active,
        orElse: () => brandPlans.firstWhere(
          (p) => p.status == PlanStatus.draft,
          orElse: () => brandPlans.first,
        ),
      );
    }

    // Calculate dynamic campaign progress
    int completedPhases = currentPlan?.phases.where((p) => p.status == PhaseStatus.terminated).length ?? 0;
    int totalPhases = currentPlan?.phases.length ?? 1;
    double progressPercentage = totalPhases > 0 ? (completedPhases / totalPhases * 100) : 0;

    // Calculate campaign days
    DateTime? startDate = currentPlan?.createdAt;
    DateTime? endDate = currentPlan?.endDate;
    int currentDay = 1;
    int totalDays = 91;
    if (startDate != null && endDate != null) {
      totalDays = endDate.difference(startDate).inDays;
      currentDay = DateTime.now().difference(startDate).inDays + 1;
      currentDay = currentDay.clamp(1, totalDays);
    }

    // Get active platforms from brand
    final activePlatforms = brand.platforms.take(3).map((p) => p.name).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(brand.name.isNotEmpty ? brand.name[0].toUpperCase() : 'B', style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${brand.name} Launch', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('Campagne en cours · Jour $currentDay / $totalDays', style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  children: [
                    if (currentPlan?.status == PlanStatus.active)
                      _buildHeroBadge('● Live', isLive: true),
                    ...activePlatforms.map((p) => _buildHeroBadge(p)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${progressPercentage.toInt()}%', style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
              const Text('complet', style: TextStyle(fontSize: 10, color: Colors.white60)),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 60 * (progressPercentage / 100), height: 4, decoration: BoxDecoration(color: const Color(0xFF7FFCE8), borderRadius: BorderRadius.circular(99))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBadge(String text, {bool isLive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFF0EBFA1).withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: isLive ? const Color(0xFF7FFCE8) : Colors.white70, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF6D4ED3),
        unselectedLabelColor: const Color(0xFFA89EC0),
        indicatorColor: const Color(0xFF6D4ED3),
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildDashboardTab(Plan? plan) {
    if (plan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insights_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Aucune campagne pour cette marque.'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final brandVm = context.read<BrandViewModel>();
                final brand = brandVm.brands.firstWhere((b) => b.id == _selectedBrandId);
                context.push('/campaign-planner', extra: brand);
              },
              child: const Text('Lancer une Stratégie'),
            ),
          ],
        ),
      );
    }

    if (plan.status == PlanStatus.draft) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6D4ED3).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note, size: 48, color: Color(0xFF6D4ED3)),
              ),
              const SizedBox(height: 24),
              Text(
                'Stratégie en attente',
                style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Votre stratégie de base a été créée. Complétez les détails pour générer votre plan d\'action complet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () {
                  final brandVm = context.read<BrandViewModel>();
                  final brand = brandVm.brands.firstWhere((b) => b.id == _selectedBrandId);
                  context.push('/campaign-planner', extra: {
                    'brand': brand,
                    'plan': plan,
                  });
                },
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Compléter la Stratégie'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6D4ED3),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final budgetDna = plan.projectDNA.budget;
    final totalBudget = budgetDna.totalBudget;
    final spentBudget = budgetDna.spentBudget;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              KpiTile(
                label: 'Portée totale',
                value: '0',
                delta: 'Nouveau',
                colors: const [Color(0xFF6D4ED3), Color(0xFF8B6FE8)],
              ),
              KpiTile(
                label: 'Engagement',
                value: '0%',
                delta: 'Nouveau',
                colors: const [Color(0xFFE8366B), Color(0xFFF06090)],
              ),
              KpiTile(
                label: 'Conversions',
                value: '0',
                delta: 'Nouveau',
                colors: const [Color(0xFF0EBFA1), Color(0xFF2DD4BF)],
              ),
              KpiTile(
                label: 'Budget utilisé',
                value: totalBudget > 0 ? '${((spentBudget / totalBudget) * 100).toInt()}%' : '0%',
                delta: '$spentBudget / $totalBudget',
                colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPerformanceChart(plan),
          const SizedBox(height: 14),
          _buildKpiObjectives(plan),
          const SizedBox(height: 14),
          _buildAiInsightAlert(plan),
        ],
      ),
    );
  }

  // Removed _buildKpiTile and replaced with KpiTile widget

  Widget _buildPerformanceChart(Plan? plan) {
    // Use actual phase data from plan
    final List<Map<String, dynamic>> barData = plan != null && plan.phases.isNotEmpty
        ? plan.phases.map((p) => {
            'label': 'P${plan.phases.indexOf(p) + 1}',
            'val': p.status == PhaseStatus.terminated ? 100.0 : (p.status == PhaseStatus.inProgress ? 65.0 : 15.0),
            'color': p.status == PhaseStatus.terminated ? const Color(0xFF0EBFA1) : (p.status == PhaseStatus.inProgress ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0))
          }).toList()
        : [];

    // If no phases, show empty state
    if (barData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12), blurRadius: 20)]),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Aucune phase définie pour cette campagne.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12), blurRadius: 20)]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Progression des Phases', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              _buildSmallChip('Phase Actuelle', true),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: barData.map((d) => _buildBar(d['label'], d['val'], d['color'])).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildMiniStat(plan?.projectDNA.performance.budgetScore.toString() ?? '0', 'Score Budget', const Color(0xFF6D4ED3)),
               _buildMiniStat(plan?.projectDNA.performance.timingScore.toString() ?? '0', 'Score Timing', const Color(0xFF0EBFA1)),
               _buildMiniStat('${plan?.projectDNA.performance.readinessScore}%', 'Readiness', const Color(0xFFE8366B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double height, Color color) {
    return Column(
      children: [
        Container(width: 15, height: height, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.vertical(top: Radius.circular(5)))),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFFA89EC0))),
      ],
    );
  }

  Widget _buildSmallChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: isSelected ? const Color(0xFF6D4ED3).withValues(alpha: 0.08) : Colors.transparent, border: Border.all(color: isSelected ? const Color(0xFF6D4ED3) : const Color(0xFF6D4ED3).withValues(alpha: 0.18)), borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(fontSize: 10.5, color: isSelected ? const Color(0xFF6D4ED3) : const Color(0xFF6B5F85))),
    );
  }

  Widget _buildMiniStat(String val, String label, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFDFCFF), border: Border.all(color: const Color(0xFF6D4ED3).withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(val, style: GoogleFonts.syne(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFFA89EC0))),
        ],
      ),
    );
  }

  Widget _buildKpiObjectives(Plan? plan) {
    if (plan == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12), blurRadius: 20)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Objectifs KPI', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600)),
                const Text('Voir tout', style: TextStyle(fontSize: 11.5, color: Color(0xFF6D4ED3), fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 14),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Aucun KPI défini pour cette campagne.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          ],
        ),
      );
    }

    // Build KPIs from performance scores
    final kpis = [
      {'name': 'Engagement Score', 'current': plan.projectDNA.performance.engagementScore, 'target': 100, 'unit': '%'},
      {'name': 'Consistency Score', 'current': plan.projectDNA.performance.consistencyScore, 'target': 100, 'unit': '%'},
      {'name': 'Budget Score', 'current': plan.projectDNA.performance.budgetScore, 'target': 100, 'unit': '%'},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12), blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Objectifs KPI', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600)),
              const Text('Voir tout', style: TextStyle(fontSize: 11.5, color: Color(0xFF6D4ED3), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 14),
          ...kpis.map((kpi) => _buildProgressRow(
            kpi['name'] as String,
            (kpi['current'] as num).toDouble(),
            (kpi['target'] as num).toDouble(),
            kpi['unit'] as String,
            const Color(0xFF6D4ED3),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String name, double current, double target, String unit, Color color) {
    final pct = current / target;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
              Text('$current / $target $unit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 3),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFF6D4ED3).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(99)),
            child: Align(alignment: Alignment.centerLeft, child: Container(width: 300 * pct, height: 6, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]), borderRadius: BorderRadius.circular(99)))),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightAlert(Plan? plan) {
    if (plan == null || plan.projectDNA.performance.weakPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstWeakPoint = plan.projectDNA.performance.weakPoints.first;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFE8366B).withValues(alpha: 0.04), border: Border.all(color: const Color(0xFFE8366B).withValues(alpha: 0.25)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFE8366B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Center(child: Text('📉'))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Point faible détecté: $firstWeakPoint', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const Text('⚡ IA · Priorité haute', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFE8366B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Optimisation recommandée pour améliorer les performances de cette campagne.', style: const TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
          const SizedBox(height: 4),
          const Text('→ Appliquer la suggestion ↗', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFE8366B))),
        ],
      ),
    );
  }

  // ── Adaptive phase color tokens — works in both dark and light mode ──────
  // Accent colours stay the same in both modes (they're vivid enough).
  static const _phViolet  = Color(0xFF7C5CBF);
  static const _phVioletB = Color(0xFF9B7FD4);
  static const _phCyan    = Color(0xFF00C4B4);
  static const _phRose    = Color(0xFFE11D48);
  static const _phAmber   = Color(0xFFF59E0B);
  static const _phGreen   = Color(0xFF16A34A);

  /// Returns a [_PC] (phase-colors) bundle adapted to the current brightness.
  _PC _pc(BuildContext ctx) {
    final cs     = Theme.of(ctx).colorScheme;
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    return _PC(
      bg:       cs.surface,
      surface:  isDark ? const Color(0xFF16132A) : cs.surfaceContainerLow,
      surface2: isDark ? const Color(0xFF1E1A36) : cs.surfaceContainerHighest,
      surface3: isDark ? const Color(0xFF252040) : cs.surfaceContainerHighest,
      border:   isDark ? const Color(0x12FFFFFF) : cs.outlineVariant.withValues(alpha: 0.5),
      border2:  isDark ? const Color(0x20FFFFFF) : cs.outlineVariant,
      text:     cs.onSurface,
      text2:    cs.onSurfaceVariant,
      text3:    cs.onSurfaceVariant.withValues(alpha: 0.6),
    );
  }

  Widget _buildPhasesTab(Plan? plan) {
    if (plan == null) {
      return _phasesEmptyState();
    }
    // Load full plan if phases are empty
    if (plan.phases.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || plan.id == null) return;
        final pvm = context.read<PlanViewModel>();
        await pvm.loadPlanById(plan.id!);
        await pvm.loadAndInjectBlocks(plan.id!);
      });
      return _phasesEmptyState();
    }

    final cvm = context.watch<CollaborationViewModel>();
    final c   = _pc(context);

    return Container(
      color: c.bg,
      child: ListView(
        padding: EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phases de Campagne',
                          style: GoogleFonts.syne(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
                      Text('${plan.phases.length} phases · Configurez les posts et collaborateurs',
                          style: TextStyle(fontSize: 12, color: c.text3)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditPhaseModal(plan,
                      Phase(name: '', weekNumber: plan.phases.length + 1),
                      plan.phases.length),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _phViolet,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: _phViolet.withValues(alpha: 0.35), blurRadius: 12, offset: Offset(0, 3))],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Phase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: plan.phases.isEmpty ? 0 :
                    plan.phases.where((p) => p.status == PhaseStatus.terminated).length / plan.phases.length,
                minHeight: 4,
                backgroundColor: c.surface2,
                valueColor: AlwaysStoppedAnimation(_phCyan),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: plan.phases.asMap().entries.map((entry) {
                final idx      = entry.key;
                final phase    = entry.value;
                final phaseKey = phase.id ?? 'phase_$idx';
                final isOpen   = _expandedPhases[phaseKey] ?? (phase.status == PhaseStatus.inProgress);
                return _buildDarkPhaseCard(plan, phase, phaseKey, idx, isOpen, cvm);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phasesEmptyState() {
    final c = _pc(context);
    return Container(
      color: c.bg,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('📋', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Aucune phase configurée',
              style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
          SizedBox(height: 8),
          Text('Appuyez sur + Phase pour commencer',
              style: TextStyle(fontSize: 13, color: c.text3)),
        ]),
      ),
    );
  }

  Widget _buildDarkPhaseCard(Plan plan, Phase phase, String phaseKey, int idx,
      bool isOpen, CollaborationViewModel cvm) {
    final c = _pc(context);
    final isDone   = phase.status == PhaseStatus.terminated;
    final isActive = phase.status == PhaseStatus.inProgress;
    final total    = phase.contentBlocks.length;
    final done     = phase.contentBlocks.where((b) => b.status == ContentBlockStatus.published).length;
    final pct      = total == 0 ? 0.0 : done / total;
    final hasProduct = phase.productIds.isNotEmpty;

    Color ballBg; Color ballFg;
    if (isDone)        { ballBg = Color(0x1A22C55E); ballFg = _phGreen; }
    else if (isActive) { ballBg = _phViolet;               ballFg = Colors.white; }
    else               { ballBg = c.surface2;             ballFg = c.text3; }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: isOpen ? _phViolet : c.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        // Header
        InkWell(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          onTap: () => setState(() => _expandedPhases[phaseKey] = !isOpen),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: ballBg, shape: BoxShape.circle,
                    boxShadow: isActive ? [BoxShadow(color: _phViolet.withValues(alpha: 0.4), blurRadius: 8, offset: Offset(0, 2))] : null),
                child: Center(child: Text(isDone ? '✓' : '${idx + 1}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ballFg))),
              ),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(phase.name.isNotEmpty ? phase.name : 'Phase ${idx + 1}',
                    style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                Text('Sem. ${phase.weekNumber}${phase.description != null && phase.description!.isNotEmpty ? " · ${phase.description}" : ""}',
                    style: TextStyle(fontSize: 11, color: c.text3), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen ? Color(0x1F7C5CBF) : c.surface2,
                  border: Border.all(color: isOpen ? Color(0x407C5CBF) : c.border2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('$total posts',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isOpen ? _phVioletB : c.text2)),
              ),
              SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showEditPhaseModal(plan, phase, idx),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(color: c.surface2, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('✎', style: TextStyle(fontSize: 13, color: c.text2))),
                ),
              ),
              SizedBox(width: 6),
              Icon(isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: c.text3),
            ]),
          ),
        ),
        // Progress bar
        Container(height: 2, color: c.surface2,
            child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: pct,
                child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [_phViolet, _phCyan]))))),
        // Product + deadline
        Container(
          padding: EdgeInsets.fromLTRB(12, 7, 12, 7),
          decoration: BoxDecoration(color: c.surface, border: Border(top: BorderSide(color: c.border))),
          child: Row(children: [
            if (hasProduct)
              GestureDetector(
                onTap: () => _showProductsSheet(context, plan, phase),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Color(0x1AF59E0B), border: Border.all(color: Color(0x33F59E0B)), borderRadius: BorderRadius.circular(99)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('📦 ${phase.productIds.length} produit(s)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _phAmber)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: _phAmber),
                  ]),
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Color(0x1A7C5CBF), border: Border.all(color: Color(0x407C5CBF)), borderRadius: BorderRadius.circular(99)),
                child: Text('⚠️ Aucun produit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _phVioletB)),
              ),
            SizedBox(width: 8),
            Text('⏱ Sem. ${phase.weekNumber}', style: TextStyle(fontSize: 11, color: c.text3, fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: c.surface2, border: Border.all(color: c.border2), borderRadius: BorderRadius.circular(99)),
              child: Text('$done/$total publiés', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.text3)),
            ),
          ]),
        ),
        // Post count stepper
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(color: c.surface2, border: Border(top: BorderSide(color: c.border))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Nombre de posts à produire', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text2)),
              Text('Répartis entre les collaborateurs', style: TextStyle(fontSize: 11, color: c.text3)),
            ])),
            _darkStepBtn('−', () {}),
            Container(constraints: const BoxConstraints(minWidth: 36), alignment: Alignment.center,
                child: Text('$total', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w800, color: c.text))),
            _darkStepBtn('+', () {}),
          ]),
        ),
        // Collaborators
        if (isOpen) _buildCollaboratorsSection(plan, phase, phaseKey, cvm),
      ]),
    );
  }

  Widget _darkStepBtn(String label, VoidCallback onTap) {
    final c = _pc(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: c.surface3, border: Border.all(color: c.border2), borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: c.text))),
      ),
    );
  }

  Widget _buildCollaboratorsSection(Plan plan, Phase phase, String phaseKey, CollaborationViewModel cvm) {
    final c = _pc(context);
    final members = cvm.members;
    if (members.isEmpty) {
      return Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        child: Text('Aucun collaborateur assigné. Invitez des membres via l\'onglet Team.',
            style: TextStyle(fontSize: 12, color: c.text3)),
      );
    }
    return Column(children: [
      Container(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
        child: Row(children: [
          Text('PLANS DES COLLABORATEURS',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.text3, letterSpacing: 0.6)),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: c.surface3, border: Border.all(color: c.border2), borderRadius: BorderRadius.circular(99)),
            child: Text('${members.length} assignés', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c.text3)),
          ),
        ]),
      ),
      ...members.map((member) {
        final memberKey = '${phaseKey}_${member.id}';
        final isExpanded = _expandedPhases[memberKey] ?? false;
        final memberPosts = phase.contentBlocks.toList();
        return _buildCollaboratorRow(plan, phase, member, memberKey, isExpanded, memberPosts);
      }),
    ]);
  }

  Widget _buildCollaboratorRow(Plan plan, Phase phase, CollabMember member,
      String memberKey, bool isExpanded, List<ContentBlock> posts) {
    final c = _pc(context);
    final submitted = posts.where((b) => b.status == ContentBlockStatus.submitted).length;
    final published = posts.where((b) => b.status == ContentBlockStatus.published).length;
    final approved  = posts.where((b) => b.status == ContentBlockStatus.approved).length;

    String badgeLabel; Color badgeBg; Color badgeFg;
    if (submitted > 0)      { badgeLabel = '$submitted soumis'; badgeBg = Color(0x1F7C5CBF); badgeFg = _phVioletB; }
    else if (published > 0) { badgeLabel = '$published publiés'; badgeBg = Color(0x1A22C55E); badgeFg = _phGreen; }
    else if (approved > 0)  { badgeLabel = '$approved approuvés'; badgeBg = Color(0x1A00D4C8); badgeFg = _phCyan; }
    else                    { badgeLabel = 'Vides'; badgeBg = c.surface3; badgeFg = c.text3; }

    final avatarColors = [
      [Color(0xFFBE185D), Color(0xFFF59E0B)],
      [Color(0xFF0D9488), Color(0xFF7C5CBF)],
      [Color(0xFFB45309), Color(0xFFBE123C)],
      [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
    ];
    final ci = member.name.codeUnits.fold(0, (a, b) => a + b) % avatarColors.length;
    final initials = member.name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Column(children: [
      InkWell(
        onTap: () => setState(() => _expandedPhases[memberKey] = !isExpanded),
        child: Container(
          padding: EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: LinearGradient(colors: avatarColors[ci]), shape: BoxShape.circle),
              child: Center(child: Text(initials.isNotEmpty ? initials : '?',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(member.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
              Text('${member.roleLabel} · ${posts.length} posts', style: TextStyle(fontSize: 11, color: c.text3)),
            ])),
            Row(children: posts.take(5).map((b) => Container(
              width: 8, height: 8, margin: EdgeInsets.only(left: 3),
              decoration: BoxDecoration(color: _dotColor(b.status), shape: BoxShape.circle),
            )).toList()),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: badgeBg, border: Border.all(color: badgeFg.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(99)),
              child: Text(badgeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: badgeFg)),
            ),
            SizedBox(width: 6),
            Icon(isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded, size: 14, color: c.text3),
          ]),
        ),
      ),
      if (isExpanded)
        Container(
          color: c.surface2,
          padding: EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: posts.isEmpty
              ? Padding(padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun post commencé.', style: TextStyle(fontSize: 12, color: c.text3)))
              : Column(children: posts.map((b) => _buildOwnerInlinePost(b, plan)).toList()),
        ),
    ]);
  }

  Color _dotColor(ContentBlockStatus s) {
    final c = _pc(context);
    switch (s) {
      case ContentBlockStatus.empty:             return c.surface3;
      case ContentBlockStatus.draft:             return _phAmber;
      case ContentBlockStatus.submitted:         return _phVioletB;
      case ContentBlockStatus.approved:          return _phCyan;
      case ContentBlockStatus.scheduled:         return _phCyan;
      case ContentBlockStatus.published:         return _phGreen;
      case ContentBlockStatus.revisionRequested: return _phRose;
    }
  }

  Widget _buildOwnerInlinePost(ContentBlock block, Plan plan) {
    final c = _pc(context);
    final postKey = 'inline_${block.id}';
    final isReviewing = _expandedPhases[postKey] ?? false;
    final statusColor = _dotColor(block.status);
    final isSubmitted = block.status == ContentBlockStatus.submitted;

    return Container(
      margin: EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: isSubmitted ? _phViolet.withValues(alpha: 0.5) : c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _expandedPhases[postKey] = !isReviewing),
          child: Padding(
            padding: EdgeInsets.fromLTRB(10, 9, 10, 9),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(color: _formatBgDark(block.format), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(_formatEmojiDark(block.format), style: TextStyle(fontSize: 14))),
              ),
              SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(block.title.isNotEmpty ? block.title : 'Post sans titre',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.text),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(block.format.label, style: TextStyle(fontSize: 11, color: c.text3)),
              ])),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
                child: Text(block.status.label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
              ),
              SizedBox(width: 6),
              // Delete button for admin
              GestureDetector(
                onTap: () => _confirmDeleteBlock(block, plan),
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: Color(0x1AF43F7A),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(child: Icon(Icons.delete_outline_rounded, size: 14, color: _phRose)),
                ),
              ),
            ]),
          ),
        ),
        if (isReviewing && isSubmitted) _buildReviewPanel(block, plan),
        if (isReviewing && !isSubmitted)
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Text(
              block.status == ContentBlockStatus.published ? '✓ Publié'
                  : block.status == ContentBlockStatus.approved ? '✓ Approuvé — en attente de publication'
                  : block.status == ContentBlockStatus.revisionRequested ? '✕ Révision demandée'
                  : 'En cours de rédaction…',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
            ),
          ),
      ]),
    );
  }

  Widget _buildReviewPanel(ContentBlock block, Plan plan) {
    final c = _pc(context);
    return Container(
      padding: EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Divider(color: c.border, height: 12),
        if (block.hook.isNotEmpty) ...[_reviewField('HOOK', block.hook), SizedBox(height: 6)],
        if (block.caption.isNotEmpty) ...[_reviewField('CAPTION', block.caption), SizedBox(height: 10)],
        Text('NOTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.text3, letterSpacing: 0.4)),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(color: c.surface2, border: Border.all(color: c.border2), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            maxLines: 2,
            style: TextStyle(fontSize: 12, color: c.text),
            decoration: InputDecoration(
              hintText: 'Laisser un commentaire…',
              hintStyle: TextStyle(color: c.text3, fontSize: 12),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(10),
            ),
          ),
        ),
        SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.revisionRequested),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(color: Color(0x1AF43F7A), border: Border.all(color: Color(0x33F43F7A)), borderRadius: BorderRadius.circular(9)),
                child: Center(child: Text('✕ Révision', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _phRose))),
              ),
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.approved),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(color: _phCyan, borderRadius: BorderRadius.circular(9)),
                child: Center(child: Text('✓ Approuver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black))),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  Future<void> _confirmDeleteBlock(ContentBlock block, Plan plan) async {
    final c = _pc(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ce post ?', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
        content: Text('Cette action est irréversible. Le collaborateur ne verra plus ce post.',
            style: TextStyle(fontSize: 13, color: c.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: TextStyle(color: c.text2))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _phRose),
            child: Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (block.id == null) return;
      await ContentBlockService().delete(block.id!);
      // Reload plan blocks
      final pvm = context.read<PlanViewModel>();
      await pvm.loadPlanById(plan.id!);
      await pvm.loadAndInjectBlocks(plan.id!);
      // Notify collaborator via socket
      SocketService().emit('plan_updated', {'planId': plan.id, 'eventType': 'block_deleted'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Post supprimé', style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: _phRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint('[MarketingStrategy] delete block error: $e');
    }
  }

  Widget _reviewField(String label, String value) {
    final c = _pc(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: c.text3, letterSpacing: 0.4)),
      SizedBox(height: 3),
      Container(
        width: double.infinity, padding: EdgeInsets.all(9),
        decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(8)),
        child: Text(value, style: TextStyle(fontSize: 12, color: c.text, height: 1.4)),
      ),
    ]);
  }

  Color _formatBgDark(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:     return Color(0x1FF43F7A);
      case ContentFormat.story:    return Color(0x1F3B82F6);
      case ContentFormat.carousel: return Color(0x1FF59E0B);
      default:                     return Color(0x1A22C55E);
    }
  }

  String _formatEmojiDark(ContentFormat f) {
    switch (f) {
      case ContentFormat.reel:     return '🎬';
      case ContentFormat.story:    return '📸';
      case ContentFormat.carousel: return '🎠';
      default:                     return '🖼';
    }
  }

  void _showProductsSheet(BuildContext context, Plan plan, Phase phase) {
    final brandVm = context.read<BrandViewModel>();
    final brand = brandVm.brands.cast<dynamic>().firstWhere(
      (b) => b.id == plan.brandId,
      orElse: () => null,
    );
    final c = _pc(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: c.border2, borderRadius: BorderRadius.circular(99)),
            ),
            Row(children: [
              Text('Produits en charge',
                style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: c.text)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(0x1AF59E0B),
                  border: Border.all(color: Color(0x33F59E0B)),
                  borderRadius: BorderRadius.circular(99)),
                child: Text('${phase.productIds.length} produit(s)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _phAmber)),
              ),
            ]),
            SizedBox(height: 16),
            ...phase.productIds.map((pid) {
              // Look up product from brand
              dynamic product;
              if (brand != null) {
                product = brand.products.cast<dynamic>().firstWhere(
                  (p) => p.id == pid || p.id?.toString() == pid,
                  orElse: () => null,
                );
              }
              final name = product?.name ?? pid;
              final imageUrl = product?.imageUrl;

              return Container(
                margin: EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surface2,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  // Product image or placeholder
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFFDE68A))),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text('📦', style: TextStyle(fontSize: 24))),
                            ),
                          )
                        : Center(child: Text('📦', style: TextStyle(fontSize: 24))),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                          style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: c.text),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0x1AF59E0B),
                            borderRadius: BorderRadius.circular(99)),
                          child: Text('Assigné à cette phase',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _phAmber)),
                        ),
                      ],
                    ),
                  ),
                ]),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showEditPhaseModal(Plan plan, Phase phase, int index) {
    final isNew = phase.name.isEmpty && index >= plan.phases.length;
    final nameCtrl = TextEditingController(text: phase.name);
    final descCtrl = TextEditingController(text: phase.description ?? '');

    // Start / end dates — derive from weekNumber if not stored
    DateTime startDate = DateTime.now().add(Duration(days: (phase.weekNumber - 1) * 7));
    DateTime endDate   = startDate.add(const Duration(days: 6));

    // Selected products (multi-selection)
    final selectedProductIds = Set<String>.from(phase.productIds);

    // Selected formats
    final selectedFormats = Set<ContentFormat>.from(
      phase.contentBlocks.map((b) => b.format).toSet(),
    );
    if (selectedFormats.isEmpty) {
      selectedFormats.addAll([ContentFormat.reel, ContentFormat.story]);
    }

    // Per-collaborator post counts: memberId → count
    final cvm     = context.read<CollaborationViewModel>();
    final members = cvm.members;
    final postCounts = <String, int>{
      for (final m in members) m.id: phase.contentBlocks.where((b) => b.pillar == m.id).length,
    };

    // Get brand products
    final brandVm = context.read<BrandViewModel>();
    final brand   = brandVm.brands.firstWhere(
      (b) => b.id == _selectedBrandId,
      orElse: () => brandVm.brands.isNotEmpty ? brandVm.brands.first : Brand(
        id: '', name: '', description: '', tone: BrandTone.professional,
        platforms: [], audience: BrandAudience(ageRange: '', gender: '', interests: []),
        contentPillars: [], mainGoal: BrandGoal.growAudience,
        postingFrequency: PostingFrequency.threePerWeek,
        contentMix: const ContentMix(), revenueTypes: [],
        promotionIntensity: PromotionIntensity.balanced,
        seasonality: BrandSeasonality.alwaysActive,
      ),
    );
    final products = brand.products;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final cs      = Theme.of(ctx).colorScheme;
          final isDark  = Theme.of(ctx).brightness == Brightness.dark;
          final bgColor = isDark ? const Color(0xFF16132A) : cs.surface;
          final fgColor = cs.onSurface;
          final subColor= cs.onSurfaceVariant;
          final fieldBg = isDark ? const Color(0xFF1E1A36) : cs.surfaceContainerHighest;
          final borderC = isDark ? const Color(0x20FFFFFF) : cs.outlineVariant;
          final violet  = const Color(0xFF7C5CBF);
          final amber   = const Color(0xFFF59E0B);

          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.97,
            builder: (_, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: borderC),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 4),
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: borderC,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isNew ? 'Nouvelle phase' : 'Modifier · ${phase.name}',
                                style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: fgColor),
                              ),
                              Text('Configurez les détails, posts et collaborateurs',
                                  style: TextStyle(fontSize: 12, color: subColor)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Divider(color: borderC, height: 1),
                  // Scrollable body
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [

                        // ── Phase name ──────────────────────────────────
                        _sheetLabel('NOM DE LA PHASE', subColor),
                        const SizedBox(height: 6),
                        _sheetField(nameCtrl, 'ex. Tease, Launch, Educate…', fieldBg, borderC, fgColor, subColor),
                        const SizedBox(height: 14),

                        // ── Description ─────────────────────────────────
                        _sheetLabel('DESCRIPTION / OBJECTIF', subColor),
                        const SizedBox(height: 6),
                        _sheetField(descCtrl, 'ex. Construire l\'anticipation sans révéler le produit',
                            fieldBg, borderC, fgColor, subColor, maxLines: 2),
                        const SizedBox(height: 14),

                        // ── Dates ────────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sheetLabel('DATE DÉBUT', subColor),
                                  const SizedBox(height: 6),
                                  _datePicker(ctx, startDate, fieldBg, borderC, fgColor, subColor, (d) => setS(() => startDate = d)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sheetLabel('DATE FIN', subColor),
                                  const SizedBox(height: 6),
                                  _datePicker(ctx, endDate, fieldBg, borderC, fgColor, subColor, (d) => setS(() => endDate = d)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Product selector ─────────────────────────────
                        _sheetLabel('PRODUIT ASSOCIÉ', subColor),
                        const SizedBox(height: 8),
                        if (products.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: amber.withValues(alpha: 0.08),
                              border: Border.all(color: amber.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Aucun produit dans ce brand. Ajoutez-en via la fiche brand.',
                                style: TextStyle(fontSize: 12, color: amber)),
                          )
                        else
                          ...products.map((prod) {
                            final prodKey = prod.id ?? prod.name;
                            final isOn = selectedProductIds.contains(prodKey);
                            return GestureDetector(
                              onTap: () => setS(() {
                                if (isOn) {
                                  selectedProductIds.remove(prodKey);
                                } else {
                                  selectedProductIds.add(prodKey);
                                }
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isOn ? amber.withValues(alpha: 0.08) : fieldBg,
                                  border: Border.all(
                                    color: isOn ? amber : borderC,
                                    width: isOn ? 1.5 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Product image or fallback emoji
                                    if (prod.imageUrl != null && prod.imageUrl!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          prod.imageUrl!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 44, height: 44,
                                            decoration: BoxDecoration(
                                              color: amber.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Center(child: Text('📦', style: TextStyle(fontSize: 22))),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(
                                          color: amber.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(child: Text('📦', style: TextStyle(fontSize: 22))),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(prod.name,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
                                    ),
                                    Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color: isOn ? amber : Colors.transparent,
                                        border: Border.all(color: isOn ? amber : borderC, width: 1.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: isOn
                                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 18),

                        // ── Content formats ──────────────────────────────
                        _sheetLabel('FORMATS DE CONTENU', subColor),
                        const SizedBox(height: 8),
                        Row(
                          children: ContentFormat.values.map((fmt) {
                            final isOn = selectedFormats.contains(fmt);
                            final emoji = fmt == ContentFormat.reel ? '🎬'
                                : fmt == ContentFormat.story ? '📸'
                                : fmt == ContentFormat.carousel ? '🎠' : '🖼';
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setS(() {
                                  if (isOn) selectedFormats.remove(fmt);
                                  else selectedFormats.add(fmt);
                                }),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isOn ? violet.withValues(alpha: 0.12) : fieldBg,
                                    border: Border.all(
                                      color: isOn ? violet : borderC,
                                      width: isOn ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(emoji, style: const TextStyle(fontSize: 20)),
                                      const SizedBox(height: 4),
                                      Text(fmt.label,
                                          style: TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.w700,
                                            color: isOn ? violet : subColor,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // ── Collaborators & post counts ──────────────────
                        _sheetLabel('COLLABORATEURS & POSTS ASSIGNÉS', subColor),
                        const SizedBox(height: 8),
                        if (members.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: fieldBg,
                              border: Border.all(color: borderC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Aucun collaborateur. Invitez-en via l\'onglet Team.',
                                style: TextStyle(fontSize: 12, color: subColor)),
                          )
                        else
                          ...members.map((member) {
                            final count = postCounts[member.id] ?? 0;
                            final isAssigned = count > 0;
                            final avatarColors = [
                              [const Color(0xFFBE185D), const Color(0xFFF59E0B)],
                              [const Color(0xFF0D9488), const Color(0xFF7C5CBF)],
                              [const Color(0xFFB45309), const Color(0xFFBE123C)],
                              [const Color(0xFF1D4ED8), const Color(0xFF7C3AED)],
                            ];
                            final ci = member.name.codeUnits.fold(0, (a, b) => a + b) % avatarColors.length;
                            final initials = member.name.trim().split(' ').take(2)
                                .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isAssigned ? violet.withValues(alpha: 0.08) : fieldBg,
                                border: Border.all(
                                  color: isAssigned ? violet : borderC,
                                  width: isAssigned ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: avatarColors[ci]),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(initials.isNotEmpty ? initials : '?',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(member.name,
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fgColor)),
                                        Text(member.roleLabel,
                                            style: TextStyle(fontSize: 11, color: subColor)),
                                      ],
                                    ),
                                  ),
                                  // Post count stepper
                                  Row(
                                    children: [
                                      _miniStepBtn('−', fieldBg, borderC, fgColor, () {
                                        setS(() => postCounts[member.id] = (count - 1).clamp(0, 99));
                                      }),
                                      Container(
                                        constraints: const BoxConstraints(minWidth: 32),
                                        alignment: Alignment.center,
                                        child: Text('$count',
                                            style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w800, color: fgColor)),
                                      ),
                                      _miniStepBtn('+', fieldBg, borderC, fgColor, () {
                                        setS(() => postCounts[member.id] = count + 1);
                                      }),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  // Assigned check
                                  Container(
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      color: isAssigned ? violet : Colors.transparent,
                                      border: Border.all(color: isAssigned ? violet : borderC, width: 1.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: isAssigned
                                        ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 28),

                        // ── Save button ──────────────────────────────────
                        StatefulBuilder(
                          builder: (ctx2, setSaving) {
                            bool isSaving = false;
                            return SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: isSaving ? null : () async {
                                  setSaving(() => isSaving = true);
                                  final planVm = context.read<PlanViewModel>();
                                  final blockService = ContentBlockService();
                                  debugPrint('[PhaseModal] saving — postCounts: $postCounts');

                                  final brandId   = plan.brandId;
                                  final phaseId   = phase.id;  // current ID before updatePhases regenerates it
                                  final phaseName = nameCtrl.text.trim().isNotEmpty
                                      ? nameCtrl.text.trim()
                                      : 'Phase ${index + 1}';

                                  // STEP 1: Create content blocks FIRST (before updatePhases changes phase IDs)
                                  int created = 0;
                                  for (final entry in postCounts.entries) {
                                    final memberId = entry.key;
                                    final count    = entry.value;
                                    if (count <= 0) continue;
                                    final existing = phase.contentBlocks
                                        .where((b) => b.emotionalTrigger == 'assigned:$memberId')
                                        .length;
                                    final toCreate = count - existing;
                                    for (int i = 0; i < toCreate; i++) {
                                      try {
                                        final block = await blockService.create(CreateContentBlockDto(
                                          brandId:     brandId,
                                          planId:      plan.id,
                                          planPhaseId: phaseId,
                                          phaseLabel:  phaseName,
                                          title:       'Post ${existing + i + 1} — $phaseName',
                                          contentType: ContentType.educational,
                                          platform:    ContentPlatform.instagram,
                                          hooks:       [],
                                          ctaType:     ContentCtaType.soft,
                                        ));
                                        created++;
                                        debugPrint('[PhaseModal] created block ${block.id} phaseId=$phaseId label=$phaseName');
                                      } catch (e) {
                                        debugPrint('[PhaseModal] create block error: $e');
                                      }
                                    }
                                  }
                                  debugPrint('[PhaseModal] created $created new blocks');

                                  // STEP 2: Save phase metadata
                                  final newProductIds = selectedProductIds.toList();
                                  final updatedPhases = List<Phase>.from(plan.phases);
                                  final updatedPhase = Phase(
                                    id: phase.id,
                                    name: phaseName,
                                    description: descCtrl.text.trim(),
                                    weekNumber: phase.weekNumber,
                                    contentBlocks: phase.contentBlocks,
                                    status: phase.status,
                                    productIds: newProductIds,
                                  );
                                  if (index < updatedPhases.length) {
                                    updatedPhases[index] = updatedPhase;
                                  } else {
                                    updatedPhases.add(updatedPhase);
                                  }
                                  await planVm.updatePhases(plan.id!, updatedPhases);

                                  // STEP 3: Close modal and show result
                                  if (mounted && Navigator.canPop(ctx)) {
                                    Navigator.pop(ctx);
                                  }
                                  final hasError = planVm.error != null;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            Icon(
                                              hasError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                hasError
                                                    ? 'Erreur: ${planVm.error}'
                                                    : 'Phase sauvegardée ✓',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                        backgroundColor: hasError ? Colors.red.shade700 : const Color(0xFF0EBFA1),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: violet,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        height: 18, width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text('Sauvegarder la phase',
                                        style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700)),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: subColor,
                              side: BorderSide(color: borderC),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Annuler'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Sheet helpers ──────────────────────────────────────────────────────────

  Widget _sheetLabel(String label, Color color) {
    return Text(label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5));
  }

  Widget _sheetField(TextEditingController ctrl, String hint,
      Color bg, Color border, Color fg, Color sub, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: sub, fontSize: 13),
        filled: true,
        fillColor: bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C5CBF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _datePicker(BuildContext ctx, DateTime date, Color bg, Color border,
      Color fg, Color sub, ValueChanged<DateTime> onPicked) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date,
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: sub),
            const SizedBox(width: 8),
            Text(
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStepBtn(String label, Color bg, Color border, Color fg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: fg)),
        ),
      ),
    );
  }





  void _confirmDeletePhase(Plan plan, String phaseId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer la phase ?'),
        content: Text('Cette action est irréversible et supprimera tous les blocs de contenu associés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          TextButton(
            onPressed: () async {
              final planVm = context.read<PlanViewModel>();
              final updatedPhases = List<Phase>.from(plan.phases);
              if (index < updatedPhases.length && (updatedPhases[index].id == phaseId || phaseId.startsWith('phase_'))) {
                 updatedPhases.removeAt(index);
              } else {
                 updatedPhases.removeWhere((p) => p.id == phaseId);
              }
              await planVm.updatePhases(plan.id!, updatedPhases);
              if (mounted) Navigator.pop(context);
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHead(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(sub, style: TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
        SizedBox(height: 8),
        Container(height: 3, decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFFE8366B), Color(0xFF0EBFA1)]), borderRadius: BorderRadius.circular(99))),
      ],
    );
  }

  Widget _buildPhaseItem(String num, String name, String desc, String date, String status, {bool isDone = false, bool isActive = false, bool isPending = false, double? progress, List<ContentBlock> contentBlocks = const [], List<Plan> linkedPlans = const []}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEE9FD)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone ? Color(0xFFE8FFF9) : (isActive ? Color(0xFFF0EEFF) : Color(0xFFEEE9FD)),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(num, style: TextStyle(fontWeight: FontWeight.w700, color: isDone ? Color(0xFF0EBFA1) : (isActive ? Color(0xFF6D4ED3) : Color(0xFFA89EC0))))),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    Text(desc, style: TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
                    if (progress != null) ...[
                      SizedBox(height: 8),
                      Container(height: 6, decoration: BoxDecoration(color: Color(0xFFEEE9FD), borderRadius: BorderRadius.circular(99)), child: FractionallySizedBox(widthFactor: progress, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFF8B6FE8)]), borderRadius: BorderRadius.circular(99))))),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(date, style: TextStyle(fontSize: 10, color: Color(0xFFA89EC0))),
                  Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDone ? Color(0xFF0EBFA1) : (isActive ? Color(0xFF6D4ED3) : Color(0xFFA89EC0)))),
                ],
              ),
            ],
          ),
          if (contentBlocks.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(left: 44, top: 12, bottom: 6),
              child: Text('Projets & Plans:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6D4ED3), letterSpacing: 0.5)),
            ),
            Padding(
              padding: EdgeInsets.only(left: 44),
              child: Column(
                children: contentBlocks.map((block) => _buildProjectFeatureRow(block)).toList(),
              ),
            ),
          ],
          if (linkedPlans.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(left: 44, top: 12, bottom: 6),
              child: Text('Projets d\'Exécution:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0EBFA1), letterSpacing: 0.5)),
            ),
            Padding(
              padding: EdgeInsets.only(left: 44),
              child: Column(
                children: linkedPlans.map((p) => Container(
                  margin: EdgeInsets.only(bottom: 6),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8FFF9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Color(0xFF0EBFA1).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(p.objective.emoji, style: TextStyle(fontSize: 14)),
                      SizedBox(width: 8),
                      Expanded(child: Text(p.name, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0D7A69)))),
                      InkWell(
                        onTap: () => context.push('/project-board', extra: p),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFF0EBFA1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Ouvrir le Board', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProjectFeatureRow(ContentBlock block) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(color: Color(0xFFF9F8FF), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(block.format == ContentFormat.reel ? Icons.movie_outlined : Icons.image_outlined, size: 14, color: Color(0xFF6D4ED3)),
          SizedBox(width: 8),
          Expanded(child: Text(block.title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          _buildFeatureBadge(block.pillar),
          SizedBox(width: 4),
          _buildFeatureBadge(block.format.name),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Color(0xFF6D4ED3).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF6D4ED3))),
    );
  }

  Widget _buildContenuTab(Plan? plan) {
    if (plan == null) return Center(child: Text('Aucun contenu.'));

    final cs = Theme.of(context).colorScheme;
    final planVm = context.watch<PlanViewModel>();

    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        _buildSectionHead('Calendrier Editorial', '${plan.phases.expand((p) => p.contentBlocks).length} posts prévus'),
        SizedBox(height: 12),
        ContentCalendarWidget(entries: planVm.allCalendarEntries),
        SizedBox(height: 32),
        Text('Prochaines Publications', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 16),
        ...planVm.allCalendarEntries.take(3).map((e) => _buildUpcomingPostCard(cs, e)),
      ],
    );
  }

  Widget _buildPostItem(String icon, String title, String time, String platform, String status, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFFEEE9FD))),
      child: Row(
        children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(icon))),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text('$platform · $time', style: TextStyle(fontSize: 11, color: Color(0xFFA89EC0))),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Color(0xFFF0EEFF), borderRadius: BorderRadius.circular(99)),
            child: Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6D4ED3))),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTab(Plan? plan) {
    if (plan == null) return Center(child: Text('Budget non défini.'));
    
    final budgetDna = plan.projectDNA.budget;

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHead('Répartition Budget', 'Total: ${budgetDna.totalBudget}'),
        SizedBox(height: 12),
        ...budgetDna.platformROAS.map((item) => _buildPlatformBudget(
          item['name'] ?? 'Inconnu',
          '${(budgetDna.totalBudget * (item['percent'] / 100)).toInt()} TND',
          '${item['percent']}%',
          'platform',
          item['color'] is int ? Color(item['color']) : Color(0xFF6D4ED3),
        )),
      ],
    );
  }

  Widget _buildPlatformBudget(String name, String amount, String pct, String icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color(0xFFEEE9FD)), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: Center(child: Text(name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)))),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text('$pct du budget total', style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5F85))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF6D4ED3))),
              Text(pct, style: TextStyle(fontSize: 10.5, color: Color(0xFFA89EC0))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiTab() {
     return ListView(
       padding: EdgeInsets.all(16),
       children: [
         _buildSectionHead('Insights Stratégiques', 'Généré par IdeaSpark AI'),
         SizedBox(height: 12),
         if (context.read<PlanViewModel>().currentPlan?.projectDNA.performance.weakPoints.isEmpty ?? true)
           Center(
             child: Padding(
               padding: EdgeInsets.symmetric(vertical: 20),
               child: Text('Aucun insight disponible pour le moment.', style: TextStyle(color: Colors.grey)),
             ),
           )
         else ...[
           ...context.read<PlanViewModel>().currentPlan!.projectDNA.performance.weakPoints.map((point) => 
             _buildAiInsightItem('Optimisation', 'Point faible détecté: $point', 'info', 0.75)
           ).toList(),
         ],
       ],
     );
  }

  Widget _buildAiInsightItem(String cat, String desc, String type, double conf) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color(0xFFEEE9FD)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cat.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6D4ED3), letterSpacing: 0.3)),
          SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 12, color: Color(0xFF6B5F85), height: 1.5)),
          SizedBox(height: 8),
          Row(
            children: [
              Text('Confiance IA:', style: TextStyle(fontSize: 11, color: Color(0xFFA89EC0))),
              SizedBox(width: 7),
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: Color(0xFFEEE9FD), borderRadius: BorderRadius.circular(99)), child: FractionallySizedBox(widthFactor: conf, child: Container(decoration: BoxDecoration(color: Color(0xFF6D4ED3), borderRadius: BorderRadius.circular(99)))))),
              SizedBox(width: 7),
              Text('${(conf * 100).toInt()}%', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildChallengeCard(String name, String desc, String meta) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFF8B6FE8)]), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          SizedBox(height: 4),
          Text(desc, style: TextStyle(fontSize: 12, color: Colors.white70)),
          SizedBox(height: 10),
          Text(meta, style: TextStyle(fontSize: 11, color: Colors.white60)),
          SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Color(0xFF6D4ED3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: Text('Gérer le Challenge')),
        ],
      ),
    );
  }

  Widget _buildFeedItem(String name, String content, String time) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEE9FD)))),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(0xFF6D4ED3), borderRadius: BorderRadius.circular(99)), child: Center(child: Text(name[0], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(time, style: TextStyle(fontSize: 10.5, color: Color(0xFFA89EC0))),
                  ],
                ),
                Text(content, style: TextStyle(fontSize: 12.5, color: Color(0xFF6B5F85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAutomationTab() {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHead('Automations IA', 'Règles actives'),
        SizedBox(height: 12),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Aucune automation configurée pour le moment.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _buildAutomationItem(String name, String desc, bool isOn) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color(0xFFEEE9FD)), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(0xFFF0EEFF), borderRadius: BorderRadius.circular(11)), child: Center(child: Icon(Icons.bolt, color: Color(0xFF6D4ED3)))),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(desc, style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5F85))),
              ],
            ),
          ),
          Switch(value: isOn, onChanged: (v) {}, activeColor: Color(0xFF6D4ED3)),
        ],
      ),
    );
  }

  Widget _buildCreditsBanner() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Crédits restants', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
              Text('1,250', style: GoogleFonts.syne(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('Valide jusqu\'au 30/06', style: TextStyle(fontSize: 11, color: Colors.white60)),
            ],
          ),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('Acheter')),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, bool isActive) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: isActive ? Color(0xFFF0EEFF) : Colors.white, border: Border.all(color: isActive ? Color(0xFF6D4ED3) : Color(0xFFEEE9FD), width: isActive ? 2 : 1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(isActive ? 'Plan Actuel' : 'Mettre à niveau', style: TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
            ],
          ),
          Text(price, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF6D4ED3))),
        ],
      ),
    );
  }

  Widget _buildCommunityTab(Plan? plan) {
    if (plan == null) {
      return const Center(child: Text('Aucun plan sélectionné.'));
    }

    final cs      = Theme.of(context).colorScheme;
    final cvm     = context.watch<CollaborationViewModel>();
    final violet  = const Color(0xFF7C5CBF);
    final members = cvm.members;

    // Load members when tab is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cvm.members.isEmpty && !cvm.isLoading && plan.id != null) {
        cvm.loadMembers(plan.id!);
      }
    });

    return RefreshIndicator(
      color: violet,
      onRefresh: () => cvm.loadMembers(plan.id!),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
        children: [

          // ── Header ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Équipe de Campagne',
                        style: GoogleFonts.syne(fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface)),
                    Text('${members.length + 1} membres · Gérez les collaborateurs',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Search & invite ──────────────────────────────────────────
          Text('INVITER UN COLLABORATEUR',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _teamSearchCtrl,
            onChanged: (val) {
              if (val.trim().length >= 2) {
                cvm.searchUsers(val.trim());
              } else {
                cvm.clearSearchResults();
              }
              setState(() {});
            },
            style: TextStyle(fontSize: 13, color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou email…',
              hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              prefixIcon: cvm.isSearching
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: violet),
                      ),
                    )
                  : Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
              suffixIcon: _teamSearchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18, color: cs.onSurfaceVariant),
                      onPressed: () {
                        _teamSearchCtrl.clear();
                        cvm.clearSearchResults();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: violet, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          // ── Search results ───────────────────────────────────────────
          if (cvm.searchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cvm.searchResults.length.clamp(0, 6),
                separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
                itemBuilder: (_, i) {
                  final user = cvm.searchResults[i];
                  final alreadyMember = members.any((m) => m.id == user.id);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: violet.withValues(alpha: 0.15),
                      child: Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 12, color: violet, fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(user.displayName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    subtitle: Text(user.email,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    trailing: alreadyMember
                        ? Text('Déjà membre',
                            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant))
                        : TextButton(
                            onPressed: cvm.isLoading
                                ? null
                                : () async {
                                    await cvm.inviteCollaborator(plan.id!, user.id);
                                    _teamSearchCtrl.clear();
                                    cvm.clearSearchResults();
                                    setState(() {});
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✅ Invitation envoyée à ${user.displayName}'),
                                          backgroundColor: const Color(0xFF16A34A),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            style: TextButton.styleFrom(
                              foregroundColor: violet,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            child: Text('INVITER',
                                style: GoogleFonts.syne(fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                  );
                },
              ),
            ),
          ] else if (_teamSearchCtrl.text.isNotEmpty && !cvm.isSearching) ...[
            const SizedBox(height: 8),
            Center(
              child: Text('Aucun utilisateur trouvé pour "${_teamSearchCtrl.text}"',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ),
          ],

          const SizedBox(height: 24),

          // ── Current team ─────────────────────────────────────────────
          Row(
            children: [
              Text('ÉQUIPE ACTUELLE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: cs.onSurfaceVariant, letterSpacing: 0.5)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: violet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('${members.length + 1}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: violet)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Owner row (always first)
          _teamMemberTile(
            cs: cs,
            name: context.read<AuthViewModel>().displayName ?? 'Vous',
            email: context.read<AuthViewModel>().email ?? '',
            role: 'Brand Owner',
            isOwner: true,
            onRemove: null,
          ),

          // Collaborator rows
          if (cvm.isLoading && members.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (members.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.group_add_rounded, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text('Aucun collaborateur pour le moment.',
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Recherchez un utilisateur ci-dessus pour l\'inviter.',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...members.map((member) => _teamMemberTile(
              cs: cs,
              name: member.name,
              email: member.email,
              role: member.roleLabel,
              isOwner: false,
              statusLabel: member.status == CollabStatus.pending ? 'En attente' : 'Actif',
              isPending: member.status == CollabStatus.pending,
              onRemove: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Retirer le collaborateur ?'),
                    content: Text('Retirer ${member.name} de cette campagne ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Retirer'),
                      ),
                    ],
                  ),
                );
                if (ok == true && plan.id != null) {
                  await cvm.removeCollaborator(plan.id!, member.id);
                }
              },
            )),
        ],
      ),
    );
  }

  Widget _teamMemberTile({
    required ColorScheme cs,
    required String name,
    required String email,
    required String role,
    required bool isOwner,
    String? statusLabel,
    bool isPending = false,
    VoidCallback? onRemove,
  }) {
    final violet = const Color(0xFF7C5CBF);
    final avatarColors = [
      [const Color(0xFFBE185D), const Color(0xFFF59E0B)],
      [const Color(0xFF0D9488), const Color(0xFF7C5CBF)],
      [const Color(0xFFB45309), const Color(0xFFBE123C)],
      [const Color(0xFF1D4ED8), const Color(0xFF7C3AED)],
    ];
    final ci = name.codeUnits.fold(0, (a, b) => a + b) % avatarColors.length;
    final initials = name.trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOwner
            ? violet.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest,
        border: Border.all(
          color: isOwner ? violet.withValues(alpha: 0.3) : cs.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: isOwner
                  ? const LinearGradient(colors: [Color(0xFF7C5CBF), Color(0xFF9B7FD4)])
                  : LinearGradient(colors: avatarColors[ci]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : '?',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    if (isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: violet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 10, color: violet),
                            const SizedBox(width: 3),
                            Text('OWNER',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: violet, letterSpacing: 0.4)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(email.isNotEmpty ? email : role,
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (!isOwner && statusLabel != null)
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF16A34A),
                    ),
                  ),
              ],
            ),
          ),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(role,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
          ),
          // Remove button
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.person_remove_rounded, size: 18, color: Colors.red),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.08),
                padding: const EdgeInsets.all(6),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildCommunityInsightCard(String label, String val, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildInteractionItem(String user, String text, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: Color(0xFF6D4ED3).withValues(alpha: 0.1), child: Text(user[0])),
      title: Text(user, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      subtitle: Text(text, style: TextStyle(fontSize: 12)),
      trailing: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }

  Widget _buildMonetizationTab(Plan? plan) {
    if (plan == null) return Center(child: Text('Aucune donnée.'));
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildSectionHead('Revenus & ROI', 'Objectif: ${plan.objective.name}'),
        SizedBox(height: 12),
        _buildRevenueCard('Ventes Directes', '${plan.projectDNA.budget.spentBudget} TND', 'Dépensé', Colors.blue),
        _buildRevenueCard('Valeur du Lead', '0 TND', 'Estimé', Colors.purple),
        SizedBox(height: 16),
        _buildSectionHead('Produits Liés', '${plan.productIds.length} produits'),
        if (plan.productIds.isEmpty)
          Padding(
            padding: EdgeInsets.all(20),
            child: Text('Aucun produit lié à cette campagne.', textAlign: TextAlign.center),
          )
        else
          ...plan.productIds.map((id) => Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color(0xFFEEE9FD)), borderRadius: BorderRadius.circular(12)),
            child: Text('Produit: $id', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          )).toList(),
      ],
    );
  }

  Widget _buildUpcomingPostCard(ColorScheme cs, CalendarEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFEEE9FD)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFF00D9FF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.movie_rounded, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title ?? 'Sans titre', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  '${DateFormat('EEEE d').format(entry.scheduledDate)} · ${entry.scheduledTime ?? '20:00'} · ${entry.platform}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Color(0xFFA89EC0)),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(entry.status.name.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6D4ED3))),
          ),
        ],
      ),
    );
  }

  Widget _buildPhasePostsContent(Plan plan, Phase phase, String phaseId, ColorScheme cs) {
    final contentBlocks = phase.contentBlocks ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posts de cette phase',
          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9090B0), letterSpacing: 0.8),
        ),
        SizedBox(height: 12),
        ...contentBlocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final postId = '${phaseId}_post_$index';
          final isExpanded = _expandedPhases[postId] ?? false;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Color(0xFFFDFCFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isExpanded ? Color(0xFF00D9FF).withValues(alpha: 0.3) : Color(0xFFEEE9FD), width: 1.5),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _expandedPhases[postId] = !isExpanded),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: _getFormatGradient(block.format),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(_getFormatEmoji(block.format), style: TextStyle(fontSize: 18))),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(block.title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${block.format.label} · ${plan.platforms.join(" + ")}', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(block.status.color))),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  Divider(height: 1, color: Color(0xFFEEE9FD)),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusWorkflowBar(currentStatus: block.status),
                        SizedBox(height: 16),
                        _buildWorkflowField('Hook', block.hook, () => context.read<PlanViewModel>().generateHook(plan.id!, block.id!)),
                        SizedBox(height: 12),
                        _buildWorkflowField('Caption', block.caption, () => context.read<PlanViewModel>().generateCaption(plan.id!, block.id!)),
                        SizedBox(height: 12),
                        _buildWorkflowField('Idée vidéo', block.emotionalTrigger ?? '', () {}),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            if (block.status == ContentBlockStatus.empty || block.status == ContentBlockStatus.draft)
                              Expanded(child: _actionBtn('Soumettre', Color(0xFF6D4ED3), () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.submitted))),
                            if (block.status == ContentBlockStatus.submitted) ...[
                              Expanded(child: _actionBtn('Revoir', Colors.orange, () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.revisionRequested))),
                              SizedBox(width: 8),
                              Expanded(child: _actionBtn('Approuver', Colors.green, () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.approved))),
                            ],
                            if (block.status == ContentBlockStatus.approved)
                              Expanded(child: _actionBtn('Programmer', Color(0xFF00D9FF), () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.scheduled))),
                            if (block.status == ContentBlockStatus.scheduled || block.status == ContentBlockStatus.approved) ...[
                              SizedBox(width: 8),
                              Expanded(child: _actionBtn('✓ Publier', Colors.green, () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.published))),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWorkflowField(String label, String content, VoidCallback onGen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF9090B0))),
            GestureDetector(onTap: onGen, child: Text('✦ Générer', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0ABFBC)))),
          ],
        ),
        SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: Color(0xFFFDFCFF), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFFEEE9FD))),
          child: Text(content.isEmpty ? '...' : content, style: GoogleFonts.spaceGrotesk(fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(label, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  LinearGradient _getFormatGradient(ContentFormat format) {
    switch (format) {
      case ContentFormat.reel: return LinearGradient(colors: [Color(0xFFFFD6E8), Color(0xFFFFE8D6)]);
      case ContentFormat.story: return LinearGradient(colors: [Color(0xFFD6E8FF), Color(0xFFE8D6FF)]);
      case ContentFormat.carousel: return LinearGradient(colors: [Color(0xFFFFF3D6), Color(0xFFD6F9FF)]);
      default: return LinearGradient(colors: [Color(0xFFD6FFD6), Color(0xFFD6F0FF)]);
    }
  }

  String _getFormatEmoji(ContentFormat format) {
    switch (format) {
      case ContentFormat.reel: return '🎬';
      case ContentFormat.story: return '📸';
      case ContentFormat.carousel: return '🎠';
      default: return '🖼';
    }
  }

  Widget _milestoneBanner(ColorScheme cs, PlanViewModel planVm, String? planId) {
    if (planId == null) return const SizedBox.shrink();
    final upcoming = planVm.allCalendarEntries.where((e) => e.planId == planId && e.scheduledDate.isAfter(DateTime.now())).toList();
    upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final next = upcoming.isNotEmpty ? upcoming.first : null;
    final diff = next != null ? next.scheduledDate.difference(DateTime.now()).inDays : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Color(0xFF6D4ED3), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PROCHAINE ÉTAPE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
                Text(next?.title ?? 'Prêt pour la suite', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(next != null ? 'DANS $diff JOURS' : 'PLANIFIÉ', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String label, String amount, String sub, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          SizedBox(height: 4),
          Text(amount, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text(sub, style: TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}

// ── Adaptive phase color bundle ───────────────────────────────────────────────
class _PC {
  final Color bg, surface, surface2, surface3, border, border2, text, text2, text3;
  const _PC({
    required this.bg, required this.surface, required this.surface2,
    required this.surface3, required this.border, required this.border2,
    required this.text, required this.text2, required this.text3,
  });
}
