import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/task.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/collaboration_view_model.dart';
import '../plan-collaboration/collaboration_screen.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/permission_service.dart';
import '../../services/google_calendar_storage_service.dart';
import '../../models/google_calendar_tokens.dart';
import '../../services/pdf_export_service.dart';
import '../../services/deep_link_service.dart';
import '../../widgets/status_workflow_node.dart';
import '../../widgets/content_calendar_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/google_calendar_service.dart';
import '../templates/plan_templates_screen.dart';

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
  bool _isSyncing = false;
  
  // Phase expansion state
  final Map<String, bool> _expandedPhases = {};


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
    final planVm = context.watch<PlanViewModel>();
    
    // Get the latest version of the plan from the view model
    final activePlan = planVm.plans.firstWhere(
      (p) => p.id == widget.plan.id, 
      orElse: () => planVm.currentPlan?.id == widget.plan.id ? planVm.currentPlan! : widget.plan
    );
    
    // Update local _plan for helper methods that use it
    _plan = activePlan;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            _buildTabBar(cs),
            _buildStrategicToolsBar(cs),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPhasesTab(activePlan, cs),
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

  Widget _buildStrategicToolsBar(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _ToolButton(
            label: 'Exporter PDF',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.redAccent,
            onTap: () => PdfExportService.exportPlan(_plan),
          ),
          const SizedBox(width: 12),
          _ToolButton(
            label: _isSyncing ? 'Synchronisation...' : (_isGoogleCalendarConnected ? 'Sync Calendar' : 'Connecter Google'),
            icon: _isSyncing ? Icons.sync_rounded : Icons.calendar_today_rounded,
            color: _isGoogleCalendarConnected ? const Color(0xFF00D9FF) : Colors.blue,
            onTap: _isSyncing ? null : (_isGoogleCalendarConnected ? _syncToGoogleCalendar : _connectGoogleCalendar),
          ),
          const SizedBox(width: 12),
          _ToolButton(
            label: 'Templates',
            icon: Icons.style_rounded,
            color: const Color(0xFF6D4ED3),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanTemplatesScreen())),
          ),
          const SizedBox(width: 12),
          _ToolButton(
            label: 'Collaboration',
            icon: Icons.group_rounded,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollaborationScreen(planId: _plan.id!, planName: _plan.name, planOwnerId: _plan.userId))),
          ),
        ],
      ),
    );
  }

  Future<void> _connectGoogleCalendar() async {
    final authVm = context.read<AuthViewModel>();
    final token = authVm.accessToken;
    if (token == null) return;
    
    final service = GoogleCalendarService();
    final result = await service.getAuthUrl(token);
    if (result.isSuccess && result.data != null) {
      await launchUrl(Uri.parse(result.data!));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: ${result.error}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _syncToGoogleCalendar() async {
    if (_googleTokens == null) return;
    
    setState(() => _isSyncing = true);
    
    final authVm = context.read<AuthViewModel>();
    final token = authVm.accessToken;
    if (token == null) return;

    final service = GoogleCalendarService();
    final result = await service.syncPlan(
      planId: _plan.id!,
      tokens: _googleTokens!,
      authToken: token,
    );

    if (mounted) {
      setState(() => _isSyncing = false);
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Synchronisation réussie !'), backgroundColor: Color(0xFF0EBFA1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Échec sync: ${result.error}'), backgroundColor: Colors.red),
        );
      }
    }
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
          Tab(text: 'Contenu'),
          Tab(text: 'Budget'),
          Tab(text: 'IA'),
          Tab(text: 'Team'),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ColorScheme cs) {
    final plan = widget.plan;
    final planVm = context.watch<PlanViewModel>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHead('Vues d\'ensemble', 'Performance de la semaine'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard('Readiness', '${plan.projectDNA.performance.readinessScore}%', Icons.analytics_rounded, const Color(0xFF6D4ED3), cs)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Budget', '${plan.projectDNA.budget.spentBudget} TND', Icons.account_balance_wallet_rounded, const Color(0xFF00D9FF), cs)),
          ],
        ),
        const SizedBox(height: 24),
        _buildAIInsightsSection(cs, planVm),
        const SizedBox(height: 24),
        _buildUpcomingTasksSection(cs, planVm),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection(ColorScheme cs, PlanViewModel planVm) {
    final insights = planVm.aiInsights;
    final alert = planVm.aiAlerts.isNotEmpty ? planVm.aiAlerts.first : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF6D4ED3).withValues(alpha: 0.05), const Color(0xFF00D9FF).withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6D4ED3).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF6D4ED3), size: 20),
              const SizedBox(width: 8),
              Text('CONSEIL DE L\'IA', style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 13, color: const Color(0xFF6D4ED3))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert?.message ?? insights['recommendation'] ?? 'Votre plan est en cours d\'optimisation. Continuez à publier pour affiner les prédictions.',
            style: GoogleFonts.spaceGrotesk(fontSize: 14, height: 1.5, color: const Color(0xFF4A4063)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTasksSection(ColorScheme cs, PlanViewModel planVm) {
    final upcoming = planVm.allCalendarEntries.where((e) => e.planId == widget.plan.id && e.scheduledDate.isAfter(DateTime.now())).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHead('Tâches Prioritaires', 'À venir cette semaine'),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('Aucune publication programmée pour le moment.'),
          ))
        else
          ...upcoming.map((e) => _taskMini(e.title ?? 'Post', DateFormat('EEEE d').format(e.scheduledDate), e.status == CalendarEntryStatus.published, cs)),
      ],
    );
  }

  Widget _taskMini(String title, String time, bool isDone, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: isDone ? Colors.green : Colors.orange, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13))),
          Text(time, style: GoogleFonts.spaceGrotesk(fontSize: 11, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildPhasesTab(Plan plan, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...plan.phases.asMap().entries.map((entry) {
          final idx = entry.key;
          final phase = entry.value;
          final phaseId = phase.id ?? 'phase_$idx';
          final isExpanded = _expandedPhases[phaseId] ?? (phase.status == PhaseStatus.inProgress);
          
          final isDone = phase.status == PhaseStatus.terminated;
          final isActive = phase.status == PhaseStatus.inProgress;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDone ? const Color(0xFFE8FFF9) : (isActive ? const Color(0xFFF0EEFF) : const Color(0xFFEEE9FD)),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    context.push('/phase-detail', extra: {
                      'plan': plan,
                      'phase': phase,
                      'phaseIndex': idx,
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDone ? const Color(0xFFE8FFF9) : (isActive ? const Color(0xFFF0EEFF) : const Color(0xFFEEE9FD)),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              phase.weekNumber.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isDone ? const Color(0xFF0EBFA1) : (isActive ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0)),
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
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              Text(
                                phase.description ?? 'Pas de description',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B5F85)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Sem. ${phase.weekNumber}',
                              style: const TextStyle(fontSize: 10, color: Color(0xFFA89EC0)),
                            ),
                            Text(
                              phase.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDone ? const Color(0xFF0EBFA1) : (isActive ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: const Color(0xFF6D4ED3),
                        ),
                      ],
                    ),
                  ),
                ),
                if (context.read<AuthViewModel>().isBrandOwner)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showEditPhaseModal(plan, phase, idx),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF6D4ED3)),
                        ),
                        TextButton.icon(
                          onPressed: () => _confirmDeletePhase(plan, phaseId, idx),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Supprimer', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),

                if (isExpanded) ...[
                  Divider(height: 1, color: const Color(0xFFEEE9FD)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildPhasePostsContent(phase, phaseId, cs),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 20),
        _milestoneBanner(cs, context.watch<PlanViewModel>()),
      ],
    );
  }


  Widget _milestoneBanner(ColorScheme cs, PlanViewModel planVm) {
    final upcoming = planVm.allCalendarEntries.where((e) => e.planId == widget.plan.id && e.scheduledDate.isAfter(DateTime.now())).toList();
    upcoming.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final next = upcoming.isNotEmpty ? upcoming.first : null;
    final diff = next != null ? next.scheduledDate.difference(DateTime.now()).inDays : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF6D4ED3), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.flag_rounded, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PROCHAINE ÉTAPE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
                Text(next?.title ?? 'Prêt pour la suite', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Text(next != null ? 'DANS $diff JOURS' : 'PLANIFIÉ', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildContentTab(ColorScheme cs) {
    final plan = widget.plan;
    final planVm = context.watch<PlanViewModel>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHead('Calendrier Editorial', '${plan.phases.expand((p) => p.contentBlocks).length} posts prévus'),
        const SizedBox(height: 12),
        ContentCalendarWidget(entries: planVm.allCalendarEntries.where((e) => e.planId == plan.id).toList()),
        const SizedBox(height: 32),
        Text('Prochaines Publications', style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...planVm.allCalendarEntries.where((e) => e.planId == plan.id && e.scheduledDate.isAfter(DateTime.now())).take(3).map((e) => _buildUpcomingPostCard(cs, e)),
      ],
    );
  }

  Widget _buildUpcomingPostCard(ColorScheme cs, CalendarEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFF00D9FF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.movie_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title ?? 'Sans titre', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  '${DateFormat('EEEE d').format(entry.scheduledDate)} · ${entry.scheduledTime ?? '20:00'} · ${entry.platform}',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(entry.status.name.toUpperCase(), style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF6D4ED3))),
          ),
        ],
      ),
    );
  }





  Widget _editableInputField(String label, String hint, TextEditingController controller, ColorScheme cs, VoidCallback onGen) {
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
        TextField(
          controller: controller,
          maxLines: null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: cs.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: TextStyle(fontSize: 12, color: cs.onSurface),
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
            child: FilledButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollaborationScreen(planId: _plan.id!, planName: _plan.name, planOwnerId: _plan.userId))), child: const Text('Manage Team & Invitations')),
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




  Widget _buildPhasePostsContent(Phase phase, String phaseId, ColorScheme cs) {
    final contentBlocks = phase.contentBlocks ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Posts de cette phase',
          style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF9090B0), letterSpacing: 0.8),
        ),
        const SizedBox(height: 12),
        ...contentBlocks.asMap().entries.map((entry) {
          final index = entry.key;
          final block = entry.value;
          final postId = '${phaseId}_post_$index';
          final isExpanded = _expandedPhases[postId] ?? false;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isExpanded ? const Color(0xFF00D9FF).withValues(alpha: 0.3) : const Color(0xFFEBEBF5), width: 1.5),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _expandedPhases[postId] = !isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: _getFormatGradient(block.format),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(_getFormatEmoji(block.format), style: const TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(block.title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${block.format.label} · ${_plan.platforms.join(" + ")}', style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Color(block.status.color))),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, color: Color(0xFFEBEBF5)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusWorkflowBar(currentStatus: block.status),
                        const SizedBox(height: 16),
                        _buildWorkflowField('Hook', block.hook, () => context.read<PlanViewModel>().generateHook(_plan.id!, block.id!)),
                        const SizedBox(height: 12),
                        _buildWorkflowField('Caption', block.caption, () => context.read<PlanViewModel>().generateCaption(_plan.id!, block.id!)),
                        const SizedBox(height: 12),
                        _buildWorkflowField('Idée vidéo', block.emotionalTrigger ?? '', () {}),
                        const SizedBox(height: 20),
                        Builder(builder: (context) {
                          final isBrandOwner = context.read<AuthViewModel>().isBrandOwner;
                          return Row(
                            children: [
                              // Collaborator actions
                              if (!isBrandOwner) ...[
                                if (block.status == ContentBlockStatus.empty || block.status == ContentBlockStatus.draft)
                                  Expanded(child: _actionBtn('Soumettre', const Color(0xFF6D4ED3), () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.submitted))),
                                if (block.status == ContentBlockStatus.approved || block.status == ContentBlockStatus.scheduled)
                                  Expanded(child: _actionBtn('✓ Publier', Colors.green, () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.published))),
                              ],
                              // Brand owner actions
                              if (isBrandOwner) ...[
                                if (block.status == ContentBlockStatus.submitted) ...[
                                  Expanded(child: _actionBtn('Revoir', Colors.orange, () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.revisionRequested))),
                                  const SizedBox(width: 8),
                                  Expanded(child: _actionBtn('Approuver', Colors.green, () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.approved))),
                                ],
                                if (block.status == ContentBlockStatus.approved)
                                  Expanded(child: _actionBtn('Programmer', const Color(0xFF00D9FF), () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.scheduled))),
                                if (block.status == ContentBlockStatus.scheduled || block.status == ContentBlockStatus.approved) ...[
                                  const SizedBox(width: 8),
                                  Expanded(child: _actionBtn('✓ Publier', Colors.green, () => context.read<PlanViewModel>().updateBlockStatus(block.id!, ContentBlockStatus.published))),
                                ],
                              ],
                            ],
                          );
                        }),
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
            Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF9090B0))),
            GestureDetector(onTap: onGen, child: Text('✦ Générer', style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0ABFBC)))),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFAFAFE), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8E8F0))),
          child: Text(content.isEmpty ? '...' : content, style: GoogleFonts.spaceGrotesk(fontSize: 13, height: 1.4)),
        ),
      ],
    );
  }

  
  



  Future<void> _saveContentBlock(BuildContext context, ContentBlock block, String hook, String caption) async {
    try {
      // For now, just show a success message since we're updating local state
      // In a real app, you'd call a service to update the backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Content saved successfully!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
      Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error saving content: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _markAsDone(BuildContext context, ContentBlock block) async {
    try {
      final pvm = context.read<PlanViewModel>();
      
      // Update the block status to published
      await pvm.updateBlockStatus(block.id ?? '', ContentBlockStatus.published);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Marked as done!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDateAndSchedule(BuildContext context, ContentBlock block, ColorScheme cs) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date == null) return;

    if (!context.mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    
    if (time == null) return;

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    
    try {
      final pvm = context.read<PlanViewModel>();
      await pvm.scheduleBlock(block.id ?? '', scheduled);
      
      if (context.mounted) {
        final fmt = DateFormat('MMM d, yyyy • h:mm a');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📅 Scheduled for ${fmt.format(scheduled)} ✓'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error scheduling: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
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
      case ContentFormat.reel: return const LinearGradient(colors: [Color(0xFFFFD6E8), Color(0xFFFFE8D6)]);
      case ContentFormat.story: return const LinearGradient(colors: [Color(0xFFD6E8FF), Color(0xFFE8D6FF)]);
      case ContentFormat.carousel: return const LinearGradient(colors: [Color(0xFFFFF3D6), Color(0xFFD6F9FF)]);
      default: return const LinearGradient(colors: [Color(0xFFD6FFD6), Color(0xFFD6F0FF)]);
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

  void _showEditPhaseModal(Plan plan, Phase phase, int index) {
    final nameController = TextEditingController(text: phase.name);
    final descController = TextEditingController(text: phase.description);
    final weekController = TextEditingController(text: phase.weekNumber.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier la Phase', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            _buildField('Nom de la phase', nameController),
            const SizedBox(height: 16),
            _buildField('Description', descController, maxLines: 3),
            const SizedBox(height: 16),
            _buildField('Numéro de semaine', weekController, isNumber: true),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () async {
                  final planVm = context.read<PlanViewModel>();
                  final updatedPhases = List<Phase>.from(_plan.phases);
                  updatedPhases[index] = Phase(
                    id: phase.id,
                    name: nameController.text,
                    description: descController.text,
                    weekNumber: int.tryParse(weekController.text) ?? phase.weekNumber,
                    contentBlocks: phase.contentBlocks,
                    status: phase.status,
                    productIds: phase.productIds,
                  );
                  await planVm.updatePhases(_plan.id!, updatedPhases);
                  if (mounted) Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6D4ED3)),
                child: const Text('Enregistrer les modifications'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F7FF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _confirmDeletePhase(Plan plan, String phaseId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la phase ?'),
        content: const Text('Cette action est irréversible et supprimera tous les blocs de contenu associés.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
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
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
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
        Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF6B5F85))),
        const SizedBox(height: 8),
        Container(height: 3, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6D4ED3), Color(0xFFE8366B), Color(0xFF0EBFA1)]), borderRadius: BorderRadius.circular(99))),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ToolButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
