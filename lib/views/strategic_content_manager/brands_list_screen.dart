import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/brand.dart';
import '../../view_models/brand_view_model.dart';

class BrandsListScreen extends StatefulWidget {
  const BrandsListScreen({super.key});

  @override
  State<BrandsListScreen> createState() => _BrandsListScreenState();
}

class _BrandsListScreenState extends State<BrandsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandViewModel>().loadBrands();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BrandViewModel>(
      builder: (context, vm, _) {
        return RefreshIndicator(
          onRefresh: vm.loadBrands,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: _buildHeader(context, vm),
                  ),
                ),
              ),
              if (vm.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.error != null)
                SliverFillRemaining(
                  child: _buildError(context, vm),
                )
              else if (vm.brands.isEmpty)
                SliverFillRemaining(
                  child: _buildEmpty(context, vm),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i < vm.brands.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _BrandCard(
                              brand: vm.brands[i],
                              onDelete: () => _confirmDelete(context, vm, vm.brands[i]),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _buildAddBrandButton(context),
                        );
                      },
                      childCount: vm.brands.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BrandViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'BRANDS',
          style: TextStyle(
            fontFamily: 'Syne',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        _buildNewPlanButton(context),
      ],
    );
  }

  Widget _buildNewPlanButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/projects-flow'),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'NEW PLAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, BrandViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              vm.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: vm.loadBrands, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, BrandViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.label_important_outline_rounded, size: 56, color: colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'No brands yet',
              style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first brand to start managing your content strategy.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openCreateBrand(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Brand'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBrandButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _openCreateBrand(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add New Brand',
              style: TextStyle(
                fontFamily: 'Space Mono',
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateBrand(BuildContext context) async {
    final router = GoRouter.of(context);
    await router.push('/brand-form');
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    context.read<BrandViewModel>().loadBrands();
  }

  Future<void> _confirmDelete(BuildContext context, BrandViewModel vm, Brand brand) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Brand'),
        content: Text('Delete "${brand.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await vm.deleteBrand(brand.id!);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'Failed to delete brand'), backgroundColor: errorColor),
      );
    }
  }
}

class _BrandCard extends StatelessWidget {
  final Brand brand;
  final VoidCallback onDelete;

  const _BrandCard({required this.brand, required this.onDelete});

  static const _accentColors = [
    Color(0xFFFF6B6B),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFFD93D),
    Color(0xFFC77DFF),
  ];

  Color get _accent {
    final idx = brand.name.codeUnits.fold(0, (a, b) => a + b) % _accentColors.length;
    return _accentColors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => context.push('/brand-workspace', extra: brand),
      child: Dismissible(
        key: Key(brand.id ?? brand.name),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          onDelete();
          return false; // The confirm dialog handles actual deletion
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned(left: 0, top: 0, bottom: 0, width: 4, child: Container(color: _accent)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                brand.name,
                                style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                              ),
                              if (brand.description != null && brand.description!.isNotEmpty)
                                Text(
                                  brand.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                        _ToneChip(tone: brand.tone),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant, size: 18),
                          onSelected: (v) {
                            if (v == 'edit') context.push('/brand-form', extra: brand);
                            if (v == 'delete') onDelete();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                    if (brand.platforms.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: brand.platforms.map((p) => _PlatformChip(platform: p, colorScheme: colorScheme)).toList(),
                        ),
                      ),
                    ],
                    if (brand.contentPillars.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Divider(color: colorScheme.outlineVariant, height: 1),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _BrandStat(label: 'Pillars', value: '${brand.contentPillars.length}', color: colorScheme.primary),
                            _BrandStat(label: 'Platforms', value: '${brand.platforms.length}', color: colorScheme.primary),
                            _BrandStat(label: 'Audience', value: brand.audience.ageRange.isNotEmpty ? brand.audience.ageRange : '—', color: colorScheme.primary),
                            _BrandStat(label: 'Tone', value: _capitalize(brand.tone.name), color: colorScheme.primary),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _ToneChip extends StatelessWidget {
  final BrandTone tone;
  const _ToneChip({required this.tone});

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

class _PlatformChip extends StatelessWidget {
  final BrandPlatform platform;
  final ColorScheme colorScheme;
  const _PlatformChip({required this.platform, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        platform.name[0].toUpperCase() + platform.name.substring(1),
        style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _BrandStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BrandStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 9, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8))),
      ],
    );
  }
}
