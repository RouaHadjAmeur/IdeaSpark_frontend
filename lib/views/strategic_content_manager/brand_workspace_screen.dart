import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../models/brand.dart';
import '../../models/plan.dart';
import '../../view_models/plan_view_model.dart';

class BrandWorkspaceScreen extends StatefulWidget {
  final Brand brand;
  const BrandWorkspaceScreen({super.key, required this.brand});

  @override
  State<BrandWorkspaceScreen> createState() => _BrandWorkspaceScreenState();
}

class _BrandWorkspaceScreenState extends State<BrandWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlanViewModel>().loadPlans();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Brand get brand => widget.brand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Debug: Check if brand is null
    if (brand.id == null || brand.name.isEmpty) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: Center(
          child: Text('Brand data is missing', style: TextStyle(color: cs.error)),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(context),
                  _buildAudienceTab(context),
                  _buildProductsTab(context),
                  _buildPillarsTab(context),
                  _buildPlansTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(color: colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chevron_left_rounded, size: 20, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              brand.name,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _ToneTag(tone: brand.tone),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: colorScheme.onSurfaceVariant),
            onPressed: () => context.push('/brand-form', extra: brand),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 2)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: colorScheme.primary,
        indicatorWeight: 2,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: 'Aperçu'),
          Tab(text: 'Audience'),
          Tab(text: 'Produits'),
          Tab(text: 'Piliers'),
          Tab(text: 'Plans'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (brand.description != null && brand.description!.isNotEmpty) ...[
            _InfoCard(
              title: context.tr('brand_ws_identity'),
              child: Text(
                brand.description!,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _InfoCard(
            title: context.tr('brand_ws_platforms'),
            child: brand.platforms.isEmpty
                ? Text(context.tr('brand_ws_no_platforms'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: brand.platforms.map((p) => _Chip(label: _capitalize(p.name), colorScheme: colorScheme)).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: context.tr('brand_ws_tone'),
            child: Row(
              children: [
                Icon(Icons.record_voice_over_rounded, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  _capitalize(brand.tone.name),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final audience = brand.audience;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            title: context.tr('brand_ws_age_range'),
            child: audience.ageRange.isEmpty
                ? Text(context.tr('brand_ws_not_specified'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))
                : Text(audience.ageRange, style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: context.tr('brand_ws_gender'),
            child: audience.gender.isEmpty
                ? Text(context.tr('brand_ws_not_specified'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))
                : Text(_capitalize(audience.gender), style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            title: context.tr('brand_ws_interests'),
            child: audience.interests.isEmpty
                ? Text(context.tr('brand_ws_no_interests'), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: audience.interests.map((i) => _Chip(label: i, colorScheme: colorScheme)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final products = brand.products;

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No products added yet.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.push('/brand-form', extra: brand),
              child: const Text('Add Products'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(child: Icon(Icons.broken_image_outlined, color: colorScheme.primary)),
                      )
                    : Container(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        child: Center(child: Icon(Icons.shopping_bag_outlined, color: colorScheme.primary)),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ready for campaigns',
                      style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPillarsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pillars = brand.contentPillars;

    if (pillars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.view_column_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(context.tr('brand_ws_no_pillars'), style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.push('/brand-form', extra: brand),
                child: Text(context.tr('brand_ws_edit_btn')),
              ),
            ],
          ),
        ),
      );
    }

    const pillarColors = [
      Color(0xFF00D9FF),
      Color(0xFFFF3D71),
      Color(0xFFFFD93D),
      Color(0xFF00FF88),
      Color(0xFFC77DFF),
    ];
    final pct = 1.0 / pillars.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(pillars.length, (i) {
          final color = pillarColors[i % pillarColors.length];
          return _buildPillarItem(pillars[i], pct, color);
        }),
      ),
    );
  }

  Widget _buildPillarItem(String label, double pct, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            flex: 5,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 32,
            child: Text(
              '${(pct * 100).toInt()}%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<PlanViewModel>(
      builder: (context, planVm, _) {
        // Filter plans for this brand
        final brandPlans = planVm.plans.where((p) => p.brandId == brand.id).toList();

        if (planVm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (brandPlans.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_view_month_outlined, size: 48, color: colorScheme.primary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('No plans yet', style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                  const SizedBox(height: 8),
                  Text('Create a campaign plan to get started', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push('/projects/flow'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create Plan'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: brandPlans.length,
          itemBuilder: (context, index) {
            final plan = brandPlans[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                onTap: () => context.push('/plan-detail', extra: plan),
              ),
            );
          },
        );
      },
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final ColorScheme colorScheme;
  const _Chip({required this.label, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
    );
  }
}

class _ToneTag extends StatelessWidget {
  final BrandTone tone;
  const _ToneTag({required this.tone});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tone.name[0].toUpperCase() + tone.name.substring(1),
        style: TextStyle(fontSize: 10, color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.onTap});

  static const _statusColors = {
    PlanStatus.draft: Color(0xFF9E9E9E),
    PlanStatus.active: Colors.green,
    PlanStatus.completed: Color(0xFF9C27B0),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = _statusColors[plan.status] ?? cs.onSurfaceVariant;
    final totalBlocks = plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
    final String title = plan.name.isNotEmpty ? plan.name : 'Sans titre';
    final String dateRange = _formatDateRange(plan.startDate, plan.endDate);
    double progress = plan.status == PlanStatus.completed ? 1.0 : (plan.status == PlanStatus.active ? 0.4 : 0.0);
    
    // Safety check for NaN/Infinity
    if (!progress.isFinite) progress = 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text('📅 $dateRange', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('📱 ${plan.objective.label}', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('${plan.phases.length}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Space Mono', color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text('Phases', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('$totalBlocks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Space Mono', color: cs.onSurface)),
                            const SizedBox(height: 2),
                            Text('Posts', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avancement : ${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(plan.status),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[start.month - 1]} ${start.day} → ${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  String _statusLabel(PlanStatus status) {
    switch (status) {
      case PlanStatus.draft:
        return 'Brouillon';
      case PlanStatus.active:
        return 'Actif';
      case PlanStatus.completed:
        return 'Complété';
    }
  }
}
