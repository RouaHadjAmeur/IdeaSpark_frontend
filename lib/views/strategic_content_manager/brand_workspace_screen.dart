import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_localizations.dart';
import '../../models/brand.dart';

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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Brand get brand => widget.brand;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _buildPillarsTab(context),
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
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: context.tr('brand_ws_overview')),
          Tab(text: context.tr('brand_ws_audience')),
          Tab(text: context.tr('brand_ws_pillars')),
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
