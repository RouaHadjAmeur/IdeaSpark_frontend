import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../view_models/brand_view_model.dart';
import '../../models/brand.dart';
import '../../models/plan.dart';
import '../../widgets/kpi_tile.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/auth_view_model.dart';

class MarketingStrategyScreen extends StatefulWidget {
  const MarketingStrategyScreen({super.key});

  @override
  State<MarketingStrategyScreen> createState() => _MarketingStrategyScreenState();
}

class _MarketingStrategyScreenState extends State<MarketingStrategyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBrandId;

  final List<String> _tabs = [
    'Dashboard',
    'Phases',
    'Contenu',
    'Budget',
    '✦ IA',
    'Communauté',
    'Automation',
    'Monétisation'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandViewModel>().loadBrands();
      context.read<PlanViewModel>().loadPlans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandVm = context.watch<BrandViewModel>();
    final planVm = context.watch<PlanViewModel>();
    
    // Auto-select first brand if none selected
    if (_selectedBrandId == null && brandVm.brands.isNotEmpty) {
      _selectedBrandId = brandVm.brands.first.id;
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
      body: Column(
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
      ),
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
          items: brandVm.brands.map((b) => DropdownMenuItem(
            value: b.id,
            child: Text(b.name),
          )).toList(),
          onChanged: (val) => setState(() => _selectedBrandId = val),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BrandViewModel brandVm) {
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
                const Text('Campagne en cours · Jour 22 / 91', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  children: [
                    _buildHeroBadge('● Live', isLive: true),
                    _buildHeroBadge('Meta Ads'),
                    _buildHeroBadge('Influenceur'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('68%', style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white)),
              const Text('complet', style: TextStyle(fontSize: 10, color: Colors.white60)),
              const SizedBox(height: 4),
              Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(width: 60 * 0.68, height: 4, decoration: BoxDecoration(color: const Color(0xFF7FFCE8), borderRadius: BorderRadius.circular(99))),
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
          _buildKpiObjectives(),
          const SizedBox(height: 14),
          _buildAiInsightAlert(),
        ],
      ),
    );
  }

  // Removed _buildKpiTile and replaced with KpiTile widget

  Widget _buildPerformanceChart(Plan? plan) {
    // If no plan, show placeholder bars
    final List<Map<String, dynamic>> barData = plan != null && plan.phases.isNotEmpty
        ? plan.phases.map((p) => {
            'label': 'P${plan.phases.indexOf(p) + 1}',
            'val': p.status == PhaseStatus.terminated ? 100.0 : (p.status == PhaseStatus.inProgress ? 65.0 : 15.0),
            'color': p.status == PhaseStatus.terminated ? const Color(0xFF0EBFA1) : (p.status == PhaseStatus.inProgress ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0))
          }).toList()
        : [
            {'label': 'P1', 'val': 28.0, 'color': const Color(0xFF6D4ED3)},
            {'label': 'P2', 'val': 42.0, 'color': const Color(0xFF6D4ED3)},
            {'label': 'P3', 'val': 70.0, 'color': const Color(0xFF0EBFA1)},
          ];

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

  Widget _buildKpiObjectives() {
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
          _buildProgressRow('Taux de conversion', 4.2, 5.0, '%', const Color(0xFF6D4ED3)),
          _buildProgressRow('ROAS', 3.1, 4.0, 'x', const Color(0xFFE8366B)),
          _buildProgressRow('Impressions', 184, 200, 'K', const Color(0xFF0EBFA1)),
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

  Widget _buildAiInsightAlert() {
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fatigue créative détectée on Facebook', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('⚡ IA · Priorité haute', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFE8366B))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Engagement FB en baisse de 12% sur 5 jours. Rotation de créatifs recommandée.', style: TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
          const SizedBox(height: 4),
          const Text('→ Appliquer la suggestion ↗', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFE8366B))),
        ],
      ),
    );
  }

  Widget _buildPhasesTab(Plan? plan) {
    if (plan == null || plan.phases.isEmpty) {
      return const Center(child: Text('Aucune phase définie pour cette campagne.'));
    }

    final allPlans = context.read<PlanViewModel>().plans;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: plan.phases.length,
      itemBuilder: (context, index) {
        final phase = plan.phases[index];
        final linkedPlans = allPlans.where((p) => p.linkedPhaseId == phase.id).toList();
        
        return Column(
          children: [
            if (index == 0) ...[
              _buildSectionHead('Phases de Campagne', '${plan.phases.length} phases · Planifié'),
              const SizedBox(height: 12),
            ],
            _buildPhaseItem(
              '${index + 1}',
              phase.name,
              phase.description ?? 'Pas de description',
              'Sem. ${phase.weekNumber}',
              phase.status.name,
              isActive: phase.status == PhaseStatus.inProgress,
              isDone: phase.status == PhaseStatus.terminated,
              isPending: phase.status == PhaseStatus.upcoming,
              contentBlocks: phase.contentBlocks,
              linkedPlans: linkedPlans,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHead(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
        const SizedBox(height: 8),
        Container(height: 3, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFFE8366B), Color(0xFF0EBFA1)]), borderRadius: BorderRadius.circular(99))),
      ],
    );
  }

  Widget _buildPhaseItem(String num, String name, String desc, String date, String status, {bool isDone = false, bool isActive = false, bool isPending = false, double? progress, List<ContentBlock> contentBlocks = const [], List<Plan> linkedPlans = const []}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEE9FD)))),
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
                  color: isDone ? const Color(0xFFE8FFF9) : (isActive ? const Color(0xFFF0EEFF) : const Color(0xFFEEE9FD)),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(num, style: TextStyle(fontWeight: FontWeight.w700, color: isDone ? const Color(0xFF0EBFA1) : (isActive ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0))))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
                    if (progress != null) ...[
                      const SizedBox(height: 8),
                      Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFEEE9FD), borderRadius: BorderRadius.circular(99)), child: FractionallySizedBox(widthFactor: progress, child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFF8B6FE8)]), borderRadius: BorderRadius.circular(99))))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(date, style: const TextStyle(fontSize: 10, color: Color(0xFFA89EC0))),
                  Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDone ? const Color(0xFF0EBFA1) : (isActive ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0)))),
                ],
              ),
            ],
          ),
          if (contentBlocks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 44, top: 12, bottom: 6),
              child: Text('Projets & Plans:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6D4ED3), letterSpacing: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                children: contentBlocks.map((block) => _buildProjectFeatureRow(block)).toList(),
              ),
            ),
          ],
          if (linkedPlans.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 44, top: 12, bottom: 6),
              child: Text('Projets d\'Exécution:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0EBFA1), letterSpacing: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Column(
                children: linkedPlans.map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8FFF9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0EBFA1).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Text(p.objective.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0D7A69)))),
                      InkWell(
                        onTap: () => context.push('/project-board', extra: p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EBFA1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Ouvrir le Board', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
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
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFF9F8FF), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(block.format == ContentFormat.reel ? Icons.movie_outlined : Icons.image_outlined, size: 14, color: const Color(0xFF6D4ED3)),
          const SizedBox(width: 8),
          Expanded(child: Text(block.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
          _buildFeatureBadge(block.pillar),
          const SizedBox(width: 4),
          _buildFeatureBadge(block.format.name),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0xFF6D4ED3).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF6D4ED3))),
    );
  }

  Widget _buildContenuTab(Plan? plan) {
    if (plan == null) return const Center(child: Text('Aucun contenu.'));

    final allBlocks = plan.phases.expand((p) => p.contentBlocks).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHead('Calendrier Editorial', '${allBlocks.length} posts prévus'),
        const SizedBox(height: 12),
        ...allBlocks.map((block) => _buildPostItem(
          block.format == ContentFormat.reel ? '🎬' : '📸',
          block.title,
          'Jour ${block.recommendedDayOffset}',
          block.pillar,
          block.status.name,
          const Color(0xFF6D4ED3),
        )),
      ],
    );
  }

  Widget _buildPostItem(String icon, String title, String time, String platform, String status, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEEE9FD))),
      child: Row(
        children: [
          Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Center(child: Text(icon))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text('$platform · $time', style: const TextStyle(fontSize: 11, color: Color(0xFFA89EC0))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFF0EEFF), borderRadius: BorderRadius.circular(99)),
            child: Text(status, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF6D4ED3))),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetTab(Plan? plan) {
    if (plan == null) return const Center(child: Text('Budget non défini.'));
    
    final budgetDna = plan.projectDNA.budget;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHead('Répartition Budget', 'Total: ${budgetDna.totalBudget}'),
        const SizedBox(height: 12),
        ...budgetDna.platformROAS.map((item) => _buildPlatformBudget(
          item['name'] ?? 'Inconnu',
          '${(budgetDna.totalBudget * (item['percent'] / 100)).toInt()} TND',
          '${item['percent']}%',
          'platform',
          item['color'] is int ? Color(item['color']) : const Color(0xFF6D4ED3),
        )),
      ],
    );
  }

  Widget _buildPlatformBudget(String name, String amount, String pct, String icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFEEE9FD)), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: Center(child: Text(name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                Text('$pct du budget total', style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B5F85))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF6D4ED3))),
              Text(pct, style: const TextStyle(fontSize: 10.5, color: Color(0xFFA89EC0))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiTab() {
     return ListView(
       padding: const EdgeInsets.all(16),
       children: [
         _buildSectionHead('Insights Stratégiques', 'Généré par IdeaSpark AI'),
         const SizedBox(height: 12),
         _buildAiInsightItem('Performance', 'Ton ROAS a augmenté de 15% grâce à l\'optimisation des horaires de publication.', 'good', 0.92),
         _buildAiInsightItem('Audience', 'Une nouvelle opportunité détectée chez les 18-24 ans sur TikTok.', 'info', 0.78),
       ],
     );
  }

  Widget _buildAiInsightItem(String cat, String desc, String type, double conf) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFEEE9FD)), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cat.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6D4ED3), letterSpacing: 0.3)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF6B5F85), height: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Confiance IA:', style: TextStyle(fontSize: 11, color: Color(0xFFA89EC0))),
              const SizedBox(width: 7),
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: const Color(0xFFEEE9FD), borderRadius: BorderRadius.circular(99)), child: FractionallySizedBox(widthFactor: conf, child: Container(decoration: BoxDecoration(color: const Color(0xFF6D4ED3), borderRadius: BorderRadius.circular(99)))))),
              const SizedBox(width: 7),
              Text('${(conf * 100).toInt()}%', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildChallengeCard(String name, String desc, String meta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFF8B6FE8)]), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 10),
          Text(meta, style: const TextStyle(fontSize: 11, color: Colors.white60)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6D4ED3), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))), child: const Text('Gérer le Challenge')),
        ],
      ),
    );
  }

  Widget _buildFeedItem(String name, String content, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEE9FD)))),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF6D4ED3), borderRadius: BorderRadius.circular(99)), child: Center(child: Text(name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(time, style: const TextStyle(fontSize: 10.5, color: Color(0xFFA89EC0))),
                  ],
                ),
                Text(content, style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B5F85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAutomationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHead('Automations IA', 'Règles actives'),
        const SizedBox(height: 12),
        _buildAutomationItem('Réponse Auto aux DMs', 'Répondre aux questions fréquentes via IA.', true),
        _buildAutomationItem('Optimisation Enchères', 'Ajuster le budget Ads en temps réel.', true),
        _buildAutomationItem('Repost Multi-plateforme', 'Adapter & poster automatiquement sur Reels/TikTok.', false),
      ],
    );
  }

  Widget _buildAutomationItem(String name, String desc, bool isOn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFEEE9FD)), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF0EEFF), borderRadius: BorderRadius.circular(11)), child: const Center(child: Icon(Icons.bolt, color: Color(0xFF6D4ED3)))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B5F85))),
              ],
            ),
          ),
          Switch(value: isOn, onChanged: (v) {}, activeColor: const Color(0xFF6D4ED3)),
        ],
      ),
    );
  }

  Widget _buildCreditsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Crédits restants', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
              Text('1,250', style: GoogleFonts.syne(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
              const Text('Valide jusqu\'au 30/06', style: TextStyle(fontSize: 11, color: Colors.white60)),
            ],
          ),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFF59E0B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Acheter')),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String price, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isActive ? const Color(0xFFF0EEFF) : Colors.white, border: Border.all(color: isActive ? const Color(0xFF6D4ED3) : const Color(0xFFEEE9FD), width: isActive ? 2 : 1), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(isActive ? 'Plan Actuel' : 'Mettre à niveau', style: const TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
            ],
          ),
          Text(price, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF6D4ED3))),
        ],
      ),
    );
  }

  Widget _buildCommunityTab(Plan? plan) {
    if (plan == null) return const Center(child: Text('Aucun plan.'));
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHead('Collaborateurs Réels', '${plan.collaboratorIds.length} membres'),
        const SizedBox(height: 12),
        if (plan.collaboratorIds.isEmpty)
           const Center(child: Padding(
             padding: EdgeInsets.all(20),
             child: Text('Tu travailles seul sur cette campagne.', style: TextStyle(fontSize: 12, color: Colors.grey)),
           ))
        else
          ...plan.collaboratorIds.map((id) => _buildInteractionItem('Collaborateur $id', 'Membre actif de l\'équipe', 'En ligne')),
        
        const SizedBox(height: 24),
        _buildSectionHead('Activités Récentes', 'Mises à jour du plan'),
        _buildInteractionItem('IA Strategist', 'Plan optimisé pour TikTok', 'Il y a 1h'),
        _buildInteractionItem('Owner', 'Budget Ads validé', 'Il y a 3h'),
      ],
    );
  }

  Widget _buildCommunityInsightCard(String label, String val, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildInteractionItem(String user, String text, String time) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: const Color(0xFF6D4ED3).withValues(alpha: 0.1), child: Text(user[0])),
      title: Text(user, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      subtitle: Text(text, style: const TextStyle(fontSize: 12)),
      trailing: Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }

  Widget _buildMonetizationTab(Plan? plan) {
    if (plan == null) return const Center(child: Text('Aucune donnée.'));
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHead('Revenus & ROI', 'Objectif: ${plan.objective.name}'),
        const SizedBox(height: 12),
        _buildRevenueCard('Ventes Directes', '0 TND', 'Objectif: 5k', Colors.blue),
        _buildRevenueCard('Valeur du Lead', '0 TND', 'Estimé', Colors.purple),
        const SizedBox(height: 16),
        _buildSectionHead('Produits Liés', '${plan.productIds.length} produits'),
        if (plan.productIds.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Aucun produit lié à cette campagne.', textAlign: TextAlign.center),
          ),
      ],
    );
  }

  Widget _buildRevenueCard(String label, String amount, String sub, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }
}
