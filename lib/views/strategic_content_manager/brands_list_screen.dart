import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/brand.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/challenge_view_model.dart';
import '../collaboration/challenges_screen.dart';
import '../collaboration/brand_team_sheet.dart';

class BrandsListScreen extends StatefulWidget {
  const BrandsListScreen({super.key});

  @override
  State<BrandsListScreen> createState() => _BrandsListScreenState();
}

class _BrandsListScreenState extends State<BrandsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form state
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  final _runnerUpCtrl = TextEditingController();
  final _maxSubCtrl = TextEditingController();
  final _minDurCtrl = TextEditingController();
  final _maxDurCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _criteriaCtrl = TextEditingController();

  String? _selectedBrandId;
  String _selectedVideoType = 'UGC';
  String? _selectedLanguage;
  DateTime? _selectedDeadline;
  final List<String> _selectedCriteria = [];

  static const _videoTypes = ['UGC', 'Testimonial', 'Product Demo', 'Unboxing', 'Other'];
  static const _languages = ['Tunisian Darija', 'French', 'Arabic', 'English'];
  static const Map<String, List<String>> _criteriaPresets = {
    'Video Quality': ['Good Lighting', 'Clean Background', 'Vertical Format', 'HD Resolution', 'Stable Footage'],
    'Content': ['Hook in 3s', 'Product Mentioned', 'Natural Tone', 'Authentic Reaction', 'Clear Storyline'],
    'Audio': ['Trending Audio', 'Clear Speech', 'No Background Noise', 'Original Voice'],
    'Engagement': ['Strong CTA', 'Emotional Appeal', 'Humor', 'Educational Value'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandViewModel>().loadBrands();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    _runnerUpCtrl.dispose();
    _maxSubCtrl.dispose();
    _minDurCtrl.dispose();
    _maxDurCtrl.dispose();
    _audienceCtrl.dispose();
    _criteriaCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleCtrl.clear();
    _descCtrl.clear();
    _rewardCtrl.clear();
    _runnerUpCtrl.clear();
    _maxSubCtrl.clear();
    _minDurCtrl.clear();
    _maxDurCtrl.clear();
    _audienceCtrl.clear();
    _criteriaCtrl.clear();
    setState(() {
      _selectedVideoType = 'UGC';
      _selectedLanguage = null;
      _selectedDeadline = null;
      _selectedCriteria.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    
    // If user is not premium, show collaborator challenges screen
    if (!authVm.isPremium) {
      return const ChallengesScreen();
    }
    
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: _buildHeader(context),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            labelStyle: GoogleFonts.syne(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            tabs: const [
              Tab(text: 'MY BRANDS'),
              Tab(text: 'LAUNCH CHALLENGE'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildBrandsTab(context),
              _buildLaunchChallengeTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'BRANDS & CHALLENGES',
          style: GoogleFonts.syne(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandsTab(BuildContext context) {
    return Consumer<BrandViewModel>(
      builder: (context, vm, _) {
        return RefreshIndicator(
          onRefresh: vm.loadBrands,
          child: CustomScrollView(
            slivers: [
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
                        if (context.read<AuthViewModel>().isPremiumBrandOwner) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: _buildAddBrandButton(context),
                          );
                        }
                        return const SizedBox(height: 100);
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
            Icon(
              Icons.label_important_outline_rounded,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No brands yet',
              style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first brand to start managing your content strategy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (context.read<AuthViewModel>().isPremiumBrandOwner)
              FilledButton.icon(
                onPressed: () => _openCreateBrand(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Brand'),
              )
            else if (context.read<AuthViewModel>().isBrandOwner)
              FilledButton.icon(
                onPressed: () => context.push('/premium-upsell'),
                icon: const Icon(Icons.star_rounded),
                label: const Text('Upgrade to Launch Brands'),
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

  Widget _buildLaunchChallengeTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<ChallengeViewModel, BrandViewModel>(
      builder: (context, challengeVm, brandVm, _) {
        // Auto-select brand if only one
        if (_selectedBrandId == null && brandVm.brands.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedBrandId = brandVm.brands.first.id);
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Launch New Challenge',
                style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface)),
              const SizedBox(height: 6),
              Text('Create a brief · set rewards · collect creator content',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 28),

              // ── Challenge Details ────────────────────────────────────────
              _buildFormSection(context, colorScheme, isDark,
                title: 'Challenge Details',
                children: [
                  _buildField(colorScheme, label: 'Challenge Title',
                    hint: 'e.g., Unboxing Challenge — Build Your Fort',
                    controller: _titleCtrl),
                  const SizedBox(height: 14),
                  _buildField(colorScheme, label: 'Description',
                    hint: 'Describe what you want creators to showcase...',
                    maxLines: 4, controller: _descCtrl),
                  const SizedBox(height: 14),
                  // Brand dropdown — real brands from API
                  _buildLabel(colorScheme, 'Brand'),
                  const SizedBox(height: 8),
                  brandVm.isLoading
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2)))
                    : brandVm.brands.isEmpty
                      ? Text('No brands found. Create a brand first.',
                          style: TextStyle(color: colorScheme.error, fontSize: 13))
                      : _buildDropdownField(
                          colorScheme,
                          value: _selectedBrandId,
                          items: brandVm.brands.map((b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name, overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedBrandId = v),
                          hint: 'Select your brand',
                        ),
                ]),
              const SizedBox(height: 20),

              // ── Content Requirements ─────────────────────────────────────
              _buildFormSection(context, colorScheme, isDark,
                title: 'Content Requirements',
                children: [
                  _buildLabel(colorScheme, 'Video Type'),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                    colorScheme,
                    value: _selectedVideoType,
                    items: _videoTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _selectedVideoType = v ?? 'UGC'),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _buildField(colorScheme, label: 'Min Duration (s)',
                      hint: '15', keyboardType: TextInputType.number, controller: _minDurCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(colorScheme, label: 'Max Duration (s)',
                      hint: '60', keyboardType: TextInputType.number, controller: _maxDurCtrl)),
                  ]),
                  const SizedBox(height: 14),
                  _buildLabel(colorScheme, 'Language'),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                    colorScheme,
                    value: _selectedLanguage,
                    items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() => _selectedLanguage = v),
                    hint: 'Select language',
                  ),
                  const SizedBox(height: 14),
                  _buildField(colorScheme, label: 'Target Audience',
                    hint: 'e.g., Parents 25-45', controller: _audienceCtrl),
                ]),
              const SizedBox(height: 20),

              // ── Evaluation Criteria ──────────────────────────────────────
              _buildFormSection(context, colorScheme, isDark,
                title: 'Evaluation Criteria',
                children: [
                  Text('Tap presets or type your own',
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 14),
                  ..._criteriaPresets.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w700, color: colorScheme.primary, letterSpacing: 0.8)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8,
                        children: entry.value.map((c) {
                          final sel = _selectedCriteria.contains(c);
                          return FilterChip(
                            label: Text(c, style: const TextStyle(fontSize: 11)),
                            selected: sel,
                            selectedColor: colorScheme.primaryContainer,
                            checkmarkColor: colorScheme.primary,
                            onSelected: (v) => setState(() {
                              v ? _selectedCriteria.add(c) : _selectedCriteria.remove(c);
                            }),
                          );
                        }).toList()),
                      const SizedBox(height: 14),
                    ],
                  )),
                  Row(children: [
                    Expanded(child: _buildField(colorScheme, label: 'Custom Criterion',
                      hint: 'e.g., "Mention discount code"', controller: _criteriaCtrl,
                      onSubmitted: _addCustomCriteria)),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: IconButton.filled(
                        onPressed: () => _addCustomCriteria(_criteriaCtrl.text),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                  if (_selectedCriteria.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Selected (${_selectedCriteria.length})',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: colorScheme.primary)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8,
                          children: _selectedCriteria.map((c) => Chip(
                            label: Text(c, style: const TextStyle(fontSize: 11)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            backgroundColor: colorScheme.primaryContainer,
                            onDeleted: () => setState(() => _selectedCriteria.remove(c)),
                          )).toList()),
                      ]),
                    ),
                  ],
                ]),
              const SizedBox(height: 20),

              // ── Campaign Settings ────────────────────────────────────────
              _buildFormSection(context, colorScheme, isDark,
                title: 'Campaign Settings',
                children: [
                  Row(children: [
                    Expanded(child: _buildField(colorScheme, label: 'Winner Reward (TND)',
                      hint: '500', keyboardType: TextInputType.number, controller: _rewardCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildField(colorScheme, label: 'Runner-up (TND)',
                      hint: '150', keyboardType: TextInputType.number, controller: _runnerUpCtrl)),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _buildField(colorScheme, label: 'Max Submissions',
                      hint: '30', keyboardType: TextInputType.number, controller: _maxSubCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDeadlinePicker(context, colorScheme)),
                  ]),
                ]),
              const SizedBox(height: 28),

              // ── Submit Row ───────────────────────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () { _resetForm(); _tabController.animateTo(0); },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 2,
                  child: FilledButton(
                    onPressed: challengeVm.isLoading ? null : () => _launchChallenge(context, challengeVm, brandVm),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: challengeVm.isLoading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Launch Challenge'),
                  ),
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  void _addCustomCriteria(String val) {
    val = val.trim();
    if (val.isNotEmpty && !_selectedCriteria.contains(val)) {
      setState(() { _selectedCriteria.add(val); _criteriaCtrl.clear(); });
    }
  }

  Future<void> _launchChallenge(BuildContext context, ChallengeViewModel vm, BrandViewModel brandVm) async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a challenge title')));
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')));
      return;
    }
    if (_rewardCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a winner reward')));
      return;
    }
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a deadline')));
      return;
    }

    final brandId = _selectedBrandId ?? (brandVm.brands.isNotEmpty ? brandVm.brands.first.id : null);
    if (brandId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a brand')));
      return;
    }

    try {
      final challenge = await vm.createChallenge({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'videoType': _selectedVideoType,
        'winnerReward': double.tryParse(_rewardCtrl.text.trim()) ?? 0,
        'runnerUpReward': double.tryParse(_runnerUpCtrl.text.trim()) ?? 0,
        'submissionCap': int.tryParse(_maxSubCtrl.text.trim()) ?? 30,
        'minDuration': int.tryParse(_minDurCtrl.text.trim()) ?? 15,
        'maxDuration': int.tryParse(_maxDurCtrl.text.trim()) ?? 60,
        'language': _selectedLanguage ?? '',
        'targetAudience': _audienceCtrl.text.trim(),
        'deadline': _selectedDeadline!.toIso8601String(),
        'criteria': _selectedCriteria,
      }, brandId);

      await vm.publishChallenge(challenge.id, brandId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge launched successfully! 🚀')));
        _resetForm();
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Launch failed: ${e.toString().replaceAll('Exception: ', '')}')));
      }
    }
  }

  Widget _buildDeadlinePicker(BuildContext context, ColorScheme colorScheme) {
    final hasDate = _selectedDeadline != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deadline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedDeadline = picked);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasDate ? colorScheme.primary : colorScheme.outlineVariant,
                  width: hasDate ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today, size: 17,
                  color: hasDate ? colorScheme.primary : colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  hasDate ? DateFormat('MMM d, yyyy').format(_selectedDeadline!) : 'Select date',
                  style: TextStyle(fontSize: 13,
                    color: hasDate ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                )),
                if (hasDate)
                  GestureDetector(
                    onTap: () => setState(() => _selectedDeadline = null),
                    child: Icon(Icons.close, size: 16, color: colorScheme.onSurfaceVariant),
                  ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(ColorScheme colorScheme, String label) => Text(label,
    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface));

  Widget _buildField(ColorScheme colorScheme, {
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextEditingController? controller,
    Function(String)? onSubmitted,
  }) {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildLabel(colorScheme, label),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          filled: true,
          fillColor: colorScheme.surfaceContainerHigh,
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _buildDropdownField<T>(ColorScheme colorScheme, {
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    String? hint,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        filled: true,
        fillColor: colorScheme.surfaceContainerHigh,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
    );
  }

  Widget _buildFormSection(BuildContext context, ColorScheme colorScheme, bool isDark, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700,
          color: colorScheme.onSurface)),
        const SizedBox(height: 16),
        ...children,
      ]),
    );
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
                        if (context.read<AuthViewModel>().isBrandOwner)
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant, size: 18),
                            onSelected: (v) {
                              if (v == 'edit') context.push('/brand-form', extra: brand);
                              if (v == 'delete') onDelete();
                              if (v == 'team') BrandTeamSheet.show(context, brand.id!, brand.name);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'team',
                                child: Row(
                                  children: [
                                    Icon(Icons.group_outlined, size: 16),
                                    SizedBox(width: 8),
                                    Text('Manage Team'),
                                  ],
                                ),
                              ),
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
