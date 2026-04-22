import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/collaboration_view_model.dart';
import '../../models/plan.dart';

import '../../services/content_block_service.dart';

class CollaboratorDashboard extends StatefulWidget {
  const CollaboratorDashboard({super.key});

  @override
  State<CollaboratorDashboard> createState() => _CollaboratorDashboardState();
}

class _CollaboratorDashboardState extends State<CollaboratorDashboard> with WidgetsBindingObserver {
  int _activeTasks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final collabVm = context.read<CollaborationViewModel>();
    final planVm = context.read<PlanViewModel>();
    
    await Future.wait([
      collabVm.loadNotifications(),
      planVm.loadPlans(), // To get shared plan details
    ]);

    if (!mounted) return;
    final planIds = planVm.plans.map((p) => p.id!).toList();
    if (planIds.isNotEmpty) {
      final count = await ContentBlockService().countActiveTasks(planIds);
      if (mounted) setState(() => _activeTasks = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final collabVm = context.watch<CollaborationViewModel>();
    final planVm = context.watch<PlanViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final fullName = authVm.displayName ?? 'Collaborator';
    final firstName = fullName.split(' ').first;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(context, firstName),
            const SizedBox(height: 24),
            _buildRoleBadge(context),
            const SizedBox(height: 24),
            _buildCollaborationStats(context, planVm),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Assigned Projects'),
            _buildProjectsList(context, planVm),
            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Recent Activity'),
            _buildActivityFeed(context, collabVm),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, String name) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COLLABORATOR HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: colorScheme.secondary, letterSpacing: 1.2)),
            Text('Hello, $name! 🚀', style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          ],
        ),
        _buildNotificationIcon(context),
      ],
    );
  }

  Widget _buildNotificationIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<CollaborationViewModel>(
      builder: (context, collabVm, _) {
        final count = collabVm.unreadNotificationsCount;
        return GestureDetector(
          onTap: () => context.push('/notifications'),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Badge(
                label: Text('$count'), isLabelVisible: count > 0,
                child: Icon(Icons.notifications_none_rounded, size: 22, color: colorScheme.onSurface),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.secondary.withOpacity(0.1), colorScheme.primary.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, color: colorScheme.secondary),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Professional Supporter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Help brands reach their creative potential.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborationStats(BuildContext context, PlanViewModel vm) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Projects', value: '${vm.plans.length}', icon: Icons.rocket_launch_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Tasks', value: '$_activeTasks', icon: Icons.task_alt_rounded)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildProjectsList(BuildContext context, PlanViewModel vm) {
    if (vm.isLoading && vm.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.plans.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
        child: const Column(
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text('No assigned projects yet.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Column(
      children: vm.plans.map((plan) => _ProjectCard(plan: plan)).toList(),
    );
  }

  Widget _buildActivityFeed(BuildContext context, CollaborationViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Colors.grey.withOpacity(0.1)), borderRadius: BorderRadius.circular(16)),
      child: const Column(
        children: [
          _ActivityItem(title: 'You joined "EcoLaunch Summer"', time: '2h ago'),
          _ActivityItem(title: 'Firas invited you to "TechSpark"', time: 'Yesterday'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outlineVariant)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.secondary),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Plan plan;
  const _ProjectCard({required this.plan});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        // Find plan in PlanViewModel if needed, or navigate by ID
        context.push('/projects');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outlineVariant)),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.rocket_launch_rounded, color: colorScheme.secondary, size: 20)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Objective: ${plan.objective.name}', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  const _ActivityItem({required this.title, required this.time});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13))),
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
