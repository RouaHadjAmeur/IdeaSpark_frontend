import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/plan.dart';
import '../view_models/plan_view_model.dart';

class SidebarNavigation extends StatefulWidget {
  const SidebarNavigation({super.key});

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  bool _plansExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanViewModel>().loadPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width * 0.8 : 280,
      color: colorScheme.surface,
      child: Column(
        children: [
          _buildProfileHeader(context, colorScheme),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader(context, context.tr('nav_main')),
                _SidebarItem(
                  icon: Icons.home_rounded,
                  label: context.tr('nav_dashboard'),
                  isActive: location == '/home',
                  onTap: () => context.go('/home'),
                ),
                _SidebarItem(
                  icon: Icons.label_important_outline_rounded,
                  label: context.tr('nav_brands'),
                  isActive: location.startsWith('/brands-list') ||
                      location.startsWith('/brand-workspace'),
                  onTap: () => context.push('/brands-list'),
                ),
                _SidebarItem(
                  icon: Icons.calendar_month_rounded,
                  label: context.tr('nav_calendar'),
                  badge: '3',
                  isActive: location.startsWith('/calendar'),
                  onTap: () => context.push('/calendar'),
                ),
                _SidebarItem(
                  icon: Icons.dashboard_customize_rounded,
                  label: 'Execution Hub',
                  isActive: location.startsWith('/projects') ||
                      location.startsWith('/project-board') ||
                      location.startsWith('/plan-project'),
                  onTap: () => context.go('/projects'),
                ),
                // ─── Plans expandable section ──────────────────────────
                _buildPlansSection(context, colorScheme, location),
                // ──────────────────────────────────────────────────────
                _SidebarItem(
                  icon: Icons.insights_rounded,
                  label: context.tr('nav_insights'),
                  isActive: location.startsWith('/insights'),
                  onTap: () => context.push('/insights'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, context.tr('nav_tools')),
                _SidebarItem(
                  icon: Icons.lightbulb_outline_rounded,
                  label: context.tr('nav_idea_gen'),
                  isActive: GoRouterState.of(context).matchedLocation == '/home',
                  onTap: () => context.push('/home'),
                ),
                _SidebarItem(
                  icon: Icons.favorite_border_rounded,
                  label: context.tr('nav_favorites'),
                  isActive: GoRouterState.of(context).matchedLocation == '/favorites',
                  onTap: () => context.go('/favorites'),
                ),
                _SidebarItem(
                  icon: Icons.history_rounded,
                  label: context.tr('nav_history'),
                  isActive: GoRouterState.of(context).matchedLocation == '/history',
                  onTap: () => context.go('/history'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, context.tr('nav_account')),
                _SidebarItem(
                  icon: Icons.person_outline_rounded,
                  label: context.tr('nav_profile'),
                  isActive: GoRouterState.of(context).matchedLocation == '/profile',
                  onTap: () => context.go('/profile'),
                ),
                _SidebarItem(
                  icon: Icons.star_border_rounded,
                  label: 'Credits · 1,349',
                  isActive: GoRouterState.of(context).matchedLocation.startsWith('/credits-shop'),
                  onTap: () => context.push('/credits-shop'),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: context.tr('settings'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ColorScheme colorScheme) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Container(
      padding: EdgeInsets.fromLTRB(20, isMobile ? 60 : 30, 20, 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                '🦊',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firas Kh.',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ─── Plans expandable section ─────────────────────────────────────────────

  static const _statusColors = {
    PlanStatus.draft: Color(0xFF9E9E9E),
    PlanStatus.active: Colors.green,
    PlanStatus.completed: Color(0xFF9C27B0),
  };

  Widget _buildPlansSection(
      BuildContext context, ColorScheme cs, String location) {
    return Consumer<PlanViewModel>(
      builder: (context, vm, _) {
        final plans = vm.plans;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            InkWell(
              onTap: () =>
                  setState(() => _plansExpanded = !_plansExpanded),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.layers_rounded,
                        size: 20, color: cs.onSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(context.tr('nav_plans'),
                          style: TextStyle(
                              fontSize: 14, color: cs.onSurface)),
                    ),
                    if (vm.isLoading)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      )
                    else if (plans.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${plans.length}',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.primary),
                        ),
                      ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _plansExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            // Expanded content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _plansExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (plans.isEmpty && !vm.isLoading)
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(52, 6, 20, 6),
                      child: Text(
                        context.tr('nav_no_plans'),
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant
                                .withValues(alpha: 0.7)),
                      ),
                    ),
                  ...plans.map((plan) => _PlanSubItem(
                        plan: plan,
                        statusColor:
                            _statusColors[plan.status] ??
                                cs.onSurfaceVariant,
                        onTap: () {
                          if (MediaQuery.of(context).size.width <
                              900) {
                            Scaffold.of(context).closeDrawer();
                          }
                          context.push('/plan-detail', extra: plan);
                        },
                      )),
                  // New Plan
                  InkWell(
                    onTap: () {
                      if (MediaQuery.of(context).size.width < 900) {
                        Scaffold.of(context).closeDrawer();
                      }
                      context.push('/projects-flow');
                    },
                    child: Container(
                      height: 40,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const SizedBox(width: 32),
                          Icon(Icons.add_rounded,
                              size: 14, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(context.tr('nav_new_plan'),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.badge,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isActive ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          color: isActive ? colorScheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17), // 20 - 3 for border
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: colorScheme.onSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Plan sub-item ────────────────────────────────────────────────────────────

class _PlanSubItem extends StatelessWidget {
  final Plan plan;
  final Color statusColor;
  final VoidCallback onTap;

  const _PlanSubItem({
    required this.plan,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // indent spacer
            const SizedBox(width: 32),
            // Status dot
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            // Objective emoji
            Text(
              plan.objective.emoji,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 6),
            // Plan name
            Expanded(
              child: Text(
                plan.name,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
