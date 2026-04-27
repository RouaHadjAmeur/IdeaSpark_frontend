import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/brand.dart';
import '../../models/task.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/collaboration_view_model.dart';
import '../plan-collaboration/collaboration_screen.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/google_calendar_storage_service.dart';
import '../../models/google_calendar_tokens.dart';
import '../../services/pdf_export_service.dart';
import '../../modules/camera_coach/camera_coach_screen.dart';
import '../generators/video_ideas_form_screen.dart';
import '../../services/deep_link_service.dart';
import '../../view_models/brand_view_model.dart';

class CampaignWorkspaceScreen extends StatefulWidget {
  final Plan plan;
  const CampaignWorkspaceScreen({super.key, required this.plan});

  @override
  State<CampaignWorkspaceScreen> createState() => _CampaignWorkspaceScreenState();
}

class _CampaignWorkspaceScreenState extends State<CampaignWorkspaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Plan _plan;
  
  // Feature states
  bool _isGoogleCalendarConnected = false;
  GoogleCalendarTokens? _googleTokens;


  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _tabController = TabController(length: 5, vsync: this);
    
    _checkGoogleCalendarConnection();
    
    // Listen for deep link OAuth callback
    DeepLinkService().onGoogleCalendarConnected = (tokens) {
      if (mounted) {
        setState(() {
          _googleTokens = tokens;
          _isGoogleCalendarConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Google Calendar connected!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  Future<void> _checkGoogleCalendarConnection() async {
    final tokens = await GoogleCalendarStorageService.getTokens();
    if (mounted) {
      setState(() {
        _googleTokens = tokens;
        _isGoogleCalendarConnected = tokens != null && !tokens.isExpired;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      final pvm = context.read<PlanViewModel>();
      final cvm = context.read<CollaborationViewModel>();
      
      await Future.wait([
        pvm.loadAIInsights(_plan.id!),
        cvm.loadTasks(_plan.id!),
        cvm.loadActivityLog(_plan.id!),
      ]);
      
      if (!mounted) return;
      final pvmReloaded = context.read<PlanViewModel>();
      await pvmReloaded.loadPlans();
      if (mounted) {
        final refreshedPlan = pvmReloaded.plans.firstWhere((p) => p.id == _plan.id);
        setState(() {
          _plan = refreshedPlan;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing workspace: $e');
    }
  }

  @override
  void dispose() {
    DeepLinkService().onGoogleCalendarConnected = null;
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            _buildTabBar(cs),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPhasesTab(cs),
                  _buildContentTab(cs),
                  _buildBudgetTab(cs),
                  _buildDNATab(cs),
                  _buildTeamTab(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    final progress = _plan.phases.isEmpty 
        ? 0 
        : (_plan.phases.where((p) => p.status == PhaseStatus.terminated).length / _plan.phases.length * 100).toInt();
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button and title
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
                  style: const TextStyle(fontFamily: 'Syne', fontSize: 24, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Campaign info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary.withValues(alpha: 0.2), cs.primary.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '⚡ ${_plan.objective.label}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _plan.name,
                            style: const TextStyle(
                              fontFamily: 'Syne',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Campagne active • Sem. ${_plan.durationWeeks}/8',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$progress%',
                          style: const TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        Text(
                          'complet',
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Platform badges
                Wrap(
                  spacing: 8,
                  children: [
                    _platformBadge('● Live', Colors.green, cs),
                    _platformBadge('TikTok', const Color(0xFF000000), cs),
                    _platformBadge('Instagram', const Color(0xFFE1306C), cs),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _platformBadge(String label, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    final activeColor = cs.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(10)),
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Phases'),
          Tab(text: 'Content'),
          Tab(text: 'Budget'),
          Tab(text: 'DNA IA'),
          Tab(text: 'Team'),
        ],
      ),
    );
  }

  Widget _buildPhasesTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ..._plan.phases.asMap().entries.map((entry) {
          final idx = entry.key;
          final phase = entry.value;
          
          Color statusColor;
          String statusText;
          switch (phase.status) {
            case PhaseStatus.terminated:
              statusColor = Colors.green;
              statusText = 'DONE';
              break;
            case PhaseStatus.inProgress:
              statusColor = const Color(0xFF6D4ED3);
              statusText = 'ACTIVE';
              break;
            case PhaseStatus.upcoming:
              statusColor = Colors.grey;
              statusText = 'UPCOMING';
              break;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      child: Center(child: Text('${idx + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    if (idx < _plan.phases.length - 1)
                      Container(width: 2, height: 100, color: statusColor.withValues(alpha: 0.3)),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(phase.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          _tag(statusText, statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _taskTag('✓ DONE', Colors.green),
                          _taskTag('⟳ IN PROGRESS', Colors.purple),
                          _taskTag('○ TODO', Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (phase.status != PhaseStatus.terminated)
                            _phaseActionButton('✦ Ideas', Colors.blue, () => _openIdeaGen(phase.contentBlocks.first)),
                          if (phase.name.toLowerCase().contains('conversion')) ...[
                            const SizedBox(width: 8),
                            _phaseActionButton('✦ Captions', Colors.purple, () {}),
                          ],
                        ],
                      ),
                      if (phase.productIds.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildPhaseProducts(phase, cs),
                      ],
                      if (phase.status != PhaseStatus.terminated) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showProductPicker(phase),
                          child: Text('+ Add product to phase', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        _milestoneBanner(cs),
      ],
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)),
    );
  }

  Widget _taskTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _phaseActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }

  Widget _milestoneBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NEXT MILESTONE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
                Text('Launch Product Sequence', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text('IN 3 DAYS', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildContentTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _injectBanner(cs),
        const SizedBox(height: 20),
        ..._plan.phases.expand((p) => p.contentBlocks).map((block) => _buildStrategyBlockCard(cs, block)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create New Block'),
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ],
    );
  }

  Widget _injectBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.secondaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.secondary.withValues(alpha: 0.2))),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: cs.secondary, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('Generate whole week strategy with AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right_rounded, color: cs.secondary),
        ],
      ),
    );
  }

  Widget _buildStrategyBlockCard(ColorScheme cs, ContentBlock block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _formatIcon(block.format, cs),
              const SizedBox(width: 12),
              Expanded(child: Text(block.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            ],
          ),
          const SizedBox(height: 16),
          _inputField('Hook', 'Enter viral hook...', block.hook, cs, () => context.read<PlanViewModel>().generateHook(_plan.id!, block.id!)),
          const SizedBox(height: 12),
          _inputField('Caption', 'Enter engaging caption...', block.caption, cs, () => context.read<PlanViewModel>().generateCaption(_plan.id!, block.id!)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _blockAction(Icons.videocam_rounded, '🎥 Coach', Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraCoachScreen()));
              }),
              _blockAction(Icons.auto_fix_high_rounded, '✦ Video IA', Colors.purple, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoIdeasFormScreen()));
              }),
              if (block.format == ContentFormat.carousel)
                _blockAction(Icons.collections_rounded, '🖼 Slides IA', Colors.amber, () {}),
              _blockAction(Icons.calendar_month_rounded, '📅 Schedule', Colors.green, () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formatIcon(ContentFormat f, ColorScheme cs) {
    IconData icon;
    switch (f) {
      case ContentFormat.reel: icon = Icons.movie_outlined; break;
      case ContentFormat.carousel: icon = Icons.view_carousel_outlined; break;
      case ContentFormat.story: icon = Icons.history_rounded; break;
      case ContentFormat.post: icon = Icons.image_outlined; break;
    }
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 20, color: cs.primary));
  }

  Widget _inputField(String label, String hint, String value, ColorScheme cs, VoidCallback onGen) {
    final pvm = context.watch<PlanViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
            if (pvm.isGenerating)
              const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2))
            else
              InkWell(onTap: onGen, child: Text('✦ Generate', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: cs.primary))),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: cs.outlineVariant)),
          child: Text(value.isEmpty ? hint : value, style: TextStyle(fontSize: 12, color: value.isEmpty ? cs.onSurfaceVariant.withValues(alpha: 0.5) : cs.onSurface)),
        ),
      ],
    );
  }

  Widget _blockAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _buildBudgetTab(ColorScheme cs) {
    final budget = _plan.projectDNA.budget;
    final total = budget.totalBudget > 0 ? budget.totalBudget : 1000;
    final spent = budget.spentBudget;
    final remaining = total - spent;
    final pct = (spent / total * 100).toInt();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _budgetTile('Spent', '\$$spent', Colors.red, cs)),
            const SizedBox(width: 12),
            Expanded(child: _budgetTile('Remaining', '\$$remaining', Colors.green, cs)),
            const SizedBox(width: 12),
            Expanded(child: _budgetTile('Usage', '$pct%', Colors.amber, cs)),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Platform Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ..._plan.platforms.map((p) => _platformROASRow(p, cs)),
      ],
    );
  }

  Widget _budgetTile(String label, String val, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _platformROASRow(String platform, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(platform.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const Text('ROAS: 4.2x', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: 0.6, borderRadius: BorderRadius.circular(4), minHeight: 6, backgroundColor: cs.outlineVariant.withValues(alpha: 0.2)),
        ],
      ),
    );
  }

  Widget _buildDNATab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(width: 120, height: 120, child: CircularProgressIndicator(value: 0.94, strokeWidth: 12, backgroundColor: cs.outlineVariant.withValues(alpha: 0.2))),
              const Column(
                children: [
                  Text('94%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Syne')),
                  Text('DNA SCORE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _dnaBar('Consistency', 0.85, cs),
        _dnaBar('Engagement', 0.92, cs),
        _dnaBar('Budget Efficiency', 0.78, cs),
        _dnaBar('Timing', 0.96, cs),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF6D4ED3), size: 18),
                  SizedBox(width: 8),
                  Text('STRATEGIC INSIGHT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF6D4ED3))),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Your engagement is peaking on Reels. Consider shifting 15% of your static post budget to high-impact video production for the launch phase.',
                style: TextStyle(fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => PdfExportService.exportPlan(_plan),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('Export Strategy PDF'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dnaBar(String label, double val, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              Text('${(val * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.primary)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: val, borderRadius: BorderRadius.circular(4), minHeight: 8, backgroundColor: cs.outlineVariant.withValues(alpha: 0.2)),
        ],
      ),
    );
  }
  Widget _buildTeamTab(ColorScheme cs) {
    final cvm = context.watch<CollaborationViewModel>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader(cs, 'Active Tasks', Icons.task_alt_rounded),
        const SizedBox(height: 12),
        if (cvm.tasks.isEmpty) _emptyState(cs, 'No tasks assigned yet.') else ...cvm.tasks.map((task) => _buildTaskItem(cs, task)),
        const SizedBox(height: 32),
        _sectionHeader(cs, 'Full Timeline', Icons.history_rounded),
        const SizedBox(height: 12),
        ...cvm.activityLog.map((log) => _buildActivityItem(cs, log)),
        const SizedBox(height: 32),
        if (context.watch<AuthViewModel>().isBrandOwner)
          SizedBox(
            width: double.infinity, height: 56,
            child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollaborationScreen(planId: _plan.id!, planName: _plan.name))), child: const Text('Manage Team & Invitations')),
          ),
      ],
    );
  }

  Widget _buildTaskItem(ColorScheme cs, Task task) {
    final statusColor = task.status == TaskStatus.done ? Colors.green : (task.status == TaskStatus.inProgress ? Colors.orange : cs.onSurfaceVariant);
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))),
      child: Row(children: [Checkbox(value: task.status == TaskStatus.done, onChanged: (val) { context.read<CollaborationViewModel>().updateTaskStatus(task.id, val! ? TaskStatus.done : TaskStatus.todo); }, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(task.title, style: TextStyle(fontWeight: FontWeight.w700, decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null)), Text(task.status.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor))])), if (task.assignedTo != null) CircleAvatar(radius: 12, backgroundColor: cs.primaryContainer, child: const Icon(Icons.person, size: 14))]),
    );
  }

  Widget _buildActivityItem(ColorScheme cs, dynamic log) {
    final actionType = log['actionType']?.toString() ?? '';
    final userName = log['userName']?.toString() ?? 'Utilisateur';
    
    String displayAction = actionType;
    if (actionType == 'owner') displayAction = 'Propriétaire';
    if (actionType == 'user') displayAction = 'Collaborateur';
    if (actionType == 'invited') displayAction = 'a été invité';
    if (actionType == 'task_update') displayAction = 'a mis à jour une tâche';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8, height: 8, 
            margin: const EdgeInsets.only(top: 6), 
            decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: cs.onSurface, fontSize: 13, height: 1.4),
                    children: [
                      TextSpan(text: userName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const TextSpan(text: ' • '),
                      TextSpan(text: displayAction, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600, fontSize: 11)),
                    ],
                  ),
                ),
                Text(
                  log['fieldChanged']?.toString() ?? '',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                if (log['createdAt'] != null)
                  Text(
                    DateFormat('MMM dd, HH:mm').format(DateTime.parse(log['createdAt'])),
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title, IconData icon) { return Row(children: [Icon(icon, size: 18, color: cs.primary), const SizedBox(width: 10), Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5))]); }
  Widget _emptyState(ColorScheme cs, String message) { return Container(padding: const EdgeInsets.symmetric(vertical: 32), width: double.infinity, decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))), child: Center(child: Text(message, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)))); }
  Widget _statusBadge(PlanStatus status, ColorScheme cs) { final color = status == PlanStatus.active ? Colors.green : (status == PlanStatus.draft ? Colors.orange : Colors.blue); return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(status.name.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900))); }

  void _openIdeaGen(ContentBlock block) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoIdeasFormScreen()));
  }

  Widget _collaboratorAvatars(List<String> ids, ColorScheme cs) {
    return Row(
      children: [
        const Text('Collaborators: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(width: 4),
        SizedBox(
          height: 24,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: ids.length.clamp(0, 5),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: cs.secondaryContainer, shape: BoxShape.circle, border: Border.all(color: cs.outline, width: 1)),
                child: Center(child: Text(ids[index].substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer))),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseProducts(Phase phase, ColorScheme cs) {
    final bvm = context.read<BrandViewModel>();
    final brand = bvm.brands.firstWhere((b) => b.id == _plan.brandId, orElse: () => bvm.brands.first);
    final phaseProducts = brand.products.where((p) => phase.productIds.contains(p.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PHASE PRODUCTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: phaseProducts.length,
            itemBuilder: (context, idx) {
              final prod = phaseProducts[idx];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(prod.imageUrl ?? '', width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: cs.surfaceContainerHighest, child: const Icon(Icons.inventory_2_rounded, size: 20))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(prod.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showProductPicker(Phase phase) {
    final bvm = context.read<BrandViewModel>();
    final brand = bvm.brands.firstWhere((b) => b.id == _plan.brandId, orElse: () => bvm.brands.first);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign Product to Phase', style: TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ...brand.products.map((prod) {
              final isSelected = phase.productIds.contains(prod.id);
              return ListTile(
                leading: CircleAvatar(backgroundImage: prod.imageUrl != null ? NetworkImage(prod.imageUrl!) : null, child: prod.imageUrl == null ? const Icon(Icons.inventory_2_rounded) : null),
                title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                trailing: Checkbox(
                  value: isSelected,
                  onChanged: (val) async {
                    final newIds = List<String>.from(phase.productIds);
                    if (val == true && prod.id != null) {
                      newIds.add(prod.id!);
                    } else if (prod.id != null) {
                      newIds.remove(prod.id!);
                    }
                    
                    // Update locally
                    final List<Phase> newPhases = _plan.phases.map<Phase>((p) {
                      if (p.id == phase.id) {
                        return Phase(
                          id: p.id,
                          name: p.name,
                          weekNumber: p.weekNumber,
                          description: p.description,
                          contentBlocks: p.contentBlocks,
                          status: p.status,
                          productIds: newIds,
                        );
                      }
                      return p;
                    }).toList();
                    
                    final updatedPlan = Plan(
                      id: _plan.id,
                      brandId: _plan.brandId,
                      name: _plan.name,
                      objective: _plan.objective,
                      startDate: _plan.startDate,
                      endDate: _plan.endDate,
                      durationWeeks: _plan.durationWeeks,
                      userId: _plan.userId,
                      phases: newPhases,
                      projectDNA: _plan.projectDNA,
                      collaboratorIds: _plan.collaboratorIds,
                    );
                    
                    setState(() => _plan = updatedPlan);
                    await context.read<PlanViewModel>().updateProjectDNA(_plan.id!, {'phases': newPhases.map((p) => p.toJson()).toList()});
                    if (mounted) Navigator.pop(context);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _activatePlan() {}
  void _sharePlan() {}
  void _regenerate() {}
  void _saveAsTemplate() {}
  void _confirmDelete() {}
}

