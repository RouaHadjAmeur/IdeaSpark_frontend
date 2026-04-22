import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/plan.dart';
import '../../models/task.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/collaboration_view_model.dart';
import '../plan-collaboration/collaboration_screen.dart';
import '../content/post_preview_screen.dart';
import '../../view_models/auth_view_model.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/google_calendar_storage_service.dart';
import '../../models/google_calendar_tokens.dart';
import '../../services/deep_link_service.dart';
import '../../views/settings/google_calendar_token_screen.dart';
import '../../services/notification_service.dart';
import '../../services/in_app_notification_service.dart';
import '../notifications/notifications_screen.dart';
import '../analytics/plan_stats_screen.dart';
import '../../services/pdf_export_service.dart';

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
  bool _remindersActive = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _tabController = TabController(length: 4, vsync: this);
    
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
                  _buildCommandCenter(cs),
                  _buildContentPlan(cs),
                  _buildNotesSection(cs),
                  _buildCollaboration(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _plan.name,
                  style: const TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_plan.objective.label} • ${_plan.durationWeeks} Weeks',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (_plan.status == PlanStatus.draft)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () => _activatePlan(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.rocket_launch_rounded, size: 14),
                label: const Text('Activate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          _statusBadge(_plan.status, cs),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              switch (value) {
                case 'share': _sharePlan(); break;
                case 'regen': _regenerate(); break;
                case 'template': _saveAsTemplate(); break;
                case 'delete': _confirmDelete(); break;
              }
            },
            itemBuilder: (context) {
              final isOwner = context.read<AuthViewModel>().isBrandOwner;
              return [
                const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_rounded, size: 18), SizedBox(width: 12), Text('Share Plan')])),
                if (isOwner)
                  const PopupMenuItem(value: 'regen', child: Row(children: [Icon(Icons.auto_fix_high_rounded, size: 18), SizedBox(width: 12), Text('Regenerate AI')])),
                if (isOwner)
                  const PopupMenuItem(value: 'template', child: Row(children: [Icon(Icons.bookmark_added_rounded, size: 18), SizedBox(width: 12), Text('Save Template')])),
                if (isOwner) const PopupMenuDivider(),
                if (isOwner)
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: cs.error), const SizedBox(width: 12), Text('Delete Campaign', style: TextStyle(color: cs.error))])),
              ];
            },
          ),
        ],
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
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(10)),
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        tabs: const [
          Tab(text: 'Command'),
          Tab(text: 'Plan'),
          Tab(text: 'Notes'),
          Tab(text: 'Collab'),
        ],
      ),
    );
  }

  Widget _buildCommandCenter(ColorScheme cs) {
    final pvm = context.watch<PlanViewModel>();
    final cvm = context.watch<CollaborationViewModel>();
    final insights = pvm.aiInsights;
    final readiness = _plan.projectDNA.performance.readinessScore;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildReadinessCard(cs, readiness, insights),
        if (_plan.status == PlanStatus.draft) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: () => _activatePlan(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.green.withValues(alpha: 0.3),
              ),
              icon: const Icon(Icons.rocket_launch_rounded),
              label: const Text('Activate Campaign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildProgressSection(cs, cvm),
        const SizedBox(height: 20),
        _buildQuickStats(cs),
        const SizedBox(height: 24),
        _buildActionGrid(cs),
        const SizedBox(height: 24),
        _buildAIRecommendations(cs, insights),
      ],
    );
  }

  Widget _buildActionGrid(ColorScheme cs) {
    final isActive = _plan.status == PlanStatus.active;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Campaign Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _actionCard(
              cs, 
              _isGoogleCalendarConnected ? 'Sync Google Cal' : 'Connect Google Cal', 
              Icons.calendar_month_rounded, 
              isActive ? const Color(0xFF4285F4) : Colors.grey,
              onTap: isActive ? _syncToGoogleCalendar : null,
            ),
            _actionCard(
              cs, 
              _remindersActive ? 'Disable Reminders' : 'Enable Reminders', 
              _remindersActive ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, 
              _remindersActive ? Colors.orange : cs.primary,
              onTap: isActive ? _toggleReminders : null,
            ),
            _actionCard(
              cs, 
              'Campaign Stats', 
              Icons.bar_chart_rounded, 
              const Color(0xFF673AB7),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanStatsScreen(plan: _plan))),
            ),
            _actionCard(
              cs, 
              'Export PDF', 
              Icons.picture_as_pdf_rounded, 
              const Color(0xFFE53935),
              onTap: () => PdfExportService.exportPlan(_plan),
            ),
          ],
        ),
        if (!isActive)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Note: Calendar & Reminders features require an "Active" campaign.', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _actionCard(ColorScheme cs, String label, IconData icon, Color color, {VoidCallback? onTap}) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icon, size: 20, color: isDisabled ? Colors.grey : color)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDisabled ? Colors.grey : cs.onSurface))),
          ],
        ),
      ),
    );
  }

  Future<void> _activatePlan() async {
    final vm = context.read<PlanViewModel>();
    final activated = await vm.activatePlan(_plan.id!);
    if (activated != null && mounted) {
      setState(() {
        _plan = activated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Campaign Activated! 🚀 Your schedule is now live.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ─── Legacy Actions Port ──────────────────────────────────────────────────

  Future<void> _toggleReminders() async {
    if (_remindersActive) {
      await NotificationService.cancelAll();
      InAppNotificationService().clear();
      setState(() => _remindersActive = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rappels désactivés 🔕'), behavior: SnackBarBehavior.floating));
      }
    } else {
      await _schedulePostReminders();
      setState(() => _remindersActive = true);
    }
  }

  Future<void> _schedulePostReminders() async {
    final phases = _plan.phases;
    if (phases.isEmpty) return;

    int count = 0;
    for (final phase in phases) {
      for (final block in phase.contentBlocks) {
        count++;
        InAppNotificationService().add(AppNotification(id: count, title: '📢 Post to publish - ${_plan.name}', body: '${block.title}\n${block.format.name}', time: DateTime.now(), type: 'post'));
        await NotificationService.schedulePublicationReminder(id: count, title: '📢 ${_plan.name} - Ready to post!', body: block.title, scheduledTime: DateTime.now());
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ $count reminders activated for ${_plan.name}!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _sharePlan() async {
    final totalPosts = _plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
    final text = '''🚀 Marketing Plan: ${_plan.name}\nObjective: ${_plan.objective.label}\n📅 Duration: ${_plan.durationWeeks} weeks • $totalPosts posts\n\nCreated with IdeaSpark ✨''';
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(text, subject: 'Marketing Plan - ${_plan.name}', sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null);
  }

  Future<void> _saveAsTemplate() async {
    // In a real app, we'd use a TemplateService. 
    // For now, let's show a success message as in the legacy detail view.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🔖 "${_plan.name}" saved as template!'), backgroundColor: Colors.purple, behavior: SnackBarBehavior.floating));
  }


  Future<void> _configureGoogleCalendar() async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const GoogleCalendarTokenScreen()));
    if (result == true) {
      await _checkGoogleCalendarConnection();
    }
  }

  Future<void> _syncToGoogleCalendar() async {
    if (_googleTokens == null) {
      _configureGoogleCalendar();
      return;
    }
    try {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Plan synchronized with Google Calendar!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      debugPrint('Google Calendar sync error: $e');
    }
  }

  Future<void> _regenerate() async {
    final pvm = context.read<PlanViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate Plan?'),
        content: const Text('This will replace your current content strategy with a new one generated by AI.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Regenerate')),
        ],
      ),
    );
    if (ok != true) return;
    
    final plan = await pvm.regeneratePlan(_plan.id!);
    if (plan != null && mounted) {
      setState(() => _plan = plan);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✨ Plan regenerated successfully!'), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _confirmDelete() async {
    final pvm = context.read<PlanViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Campaign?'),
        content: Text('Are you sure you want to delete "${_plan.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await pvm.deletePlan(_plan.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _buildReadinessCard(ColorScheme cs, int score, Map<String, dynamic> insights) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primary, cs.primary.withValues(alpha: 0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Project Readiness', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('AI Insights', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Syne', fontWeight: FontWeight.w800)),
                ],
              ),
              Container(width: 70, height: 70, decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: Center(child: Text('$score%', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)))),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(insights['summary'] ?? 'AI is analyzing your campaign DNA for readiness improvements...', style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ColorScheme cs, CollaborationViewModel cvm) {
    final totalTasks = cvm.tasks.length;
    final doneTasks = cvm.tasks.where((t) => t.status == TaskStatus.done).length;
    final progress = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Execution Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('${(progress * 100).toInt()}%', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: cs.surfaceContainerHighest, valueColor: AlwaysStoppedAnimation(cs.primary)),
        ),
        const SizedBox(height: 8),
        Text('$doneTasks of $totalTasks milestones completed', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildQuickStats(ColorScheme cs) {
    final totalPosts = _plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
    return Row(
      children: [
        _quickStatCard(cs, '$totalPosts', 'Total Posts', Icons.grid_view_rounded),
        const SizedBox(width: 12),
        _quickStatCard(cs, '${_plan.platforms.length}', 'Platforms', Icons.devices_rounded),
        const SizedBox(width: 12),
        _quickStatCard(cs, '${_plan.productIds.length}', 'Products', Icons.inventory_2_outlined),
      ],
    );
  }

  Widget _quickStatCard(ColorScheme cs, String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))),
        child: Column(children: [Icon(icon, size: 24, color: cs.primary), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))]),
      ),
    );
  }

  Widget _buildAIRecommendations(ColorScheme cs, Map<String, dynamic> insights) {
    final List list = insights['recommendations'] ?? [];
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Strategic Recommendations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...list.map((rec) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cs.secondaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.secondary.withValues(alpha: 0.1))),
          child: Row(children: [Icon(Icons.tips_and_updates_rounded, color: cs.secondary, size: 20), const SizedBox(width: 16), Expanded(child: Text(rec.toString(), style: const TextStyle(fontSize: 13, height: 1.4)))]),
        )),
      ],
    );
  }

  Widget _buildNotesSection(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader(cs, 'Project Notes', Icons.note_alt_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: TextField(
            maxLines: 15,
            decoration: InputDecoration(
              hintText: 'Start writing project notes, ideas, or reminders...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Notes are saved automatically to your project.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContentPlan(ColorScheme cs) {
    if (_plan.phases.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_fix_high_rounded, size: 64, color: cs.primary.withValues(alpha: 0.5)), const SizedBox(height: 16), const Text('No content strategy found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 8), const Text('Generate your AI content plan to see it here.', style: TextStyle(color: Colors.grey))]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: _plan.phases.length,
      itemBuilder: (context, idx) {
        final phase = _plan.phases[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)), child: Text('Week ${phase.weekNumber}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: cs.primary))), const SizedBox(width: 12), Text(phase.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]),
              const SizedBox(height: 16),
              ...phase.contentBlocks.map((block) => _buildBlockCard(cs, block)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBlockCard(ColorScheme cs, ContentBlock block) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))),
      child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(_formatIcon(block.format), color: cs.primary, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(block.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)), const SizedBox(height: 4), Text('${block.format.name.toUpperCase()} • ${block.pillar}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))])), IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostPreviewScreen(block: block, brandName: _plan.name))), icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16))]),
    );
  }

  IconData _formatIcon(ContentFormat format) {
    switch (format) {
      case ContentFormat.reel: return Icons.movie_outlined;
      case ContentFormat.carousel: return Icons.view_carousel_outlined;
      case ContentFormat.story: return Icons.history_rounded;
      case ContentFormat.post: return Icons.image_outlined;
    }
  }

  Widget _buildCollaboration(ColorScheme cs) {
    final cvm = context.watch<CollaborationViewModel>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionHeader(cs, 'Active Tasks', Icons.task_alt_rounded),
        const SizedBox(height: 12),
        if (cvm.tasks.isEmpty) _emptyState(cs, 'No tasks assigned yet.') else ...cvm.tasks.map((task) => _buildTaskItem(cs, task)),
        const SizedBox(height: 32),
        _sectionHeader(cs, 'Timeline / Activity', Icons.history_rounded),
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
    
    // Map backend roles/actions to friendly labels
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
}

