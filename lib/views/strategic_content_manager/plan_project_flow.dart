import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../models/brand.dart';
import '../../models/plan.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/plan_view_model.dart';
import '../loading/ai_plan_loading_screen.dart';
import '../../services/social_service.dart';
import '../../services/auth_service.dart';

class PlanProjectFlow extends StatefulWidget {
  const PlanProjectFlow({super.key});

  @override
  State<PlanProjectFlow> createState() => _PlanProjectFlowState();
}

class _PlanProjectFlowState extends State<PlanProjectFlow> {
  final _pageCtrl = PageController();
  int _step = 0;

  // Step 1
  Brand? _selectedBrand;

  // Step 2
  List<Product> _selectedProducts = [];

  // Step 3
  final _nameCtrl = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  int _durationWeeks = 4;
  int _postingFrequency = 3;
  final List<String> _collaboratorEmails = [];
  final _collabEmailCtrl = TextEditingController();

  // Step 3
  PlanObjective? _objective;

  // Step 4 (Linking)
  Plan? _linkedStrategy;
  Phase? _linkedPhase;

  // Step 5 (result)
  Plan? _generatedPlan;
  final Set<int> _expandedPhases = {};

  bool get _canContinue {
    switch (_step) {
      case 0: return _selectedBrand != null;
      case 1: return _selectedProducts.isNotEmpty;
      case 2: return _nameCtrl.text.trim().isNotEmpty;
      case 3: return _objective != null;
      default: return false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BrandViewModel>().loadBrands();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (!_canContinue) return;
    if (_step < 4) {
      setState(() => _step++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else {
      _createPlan();
    }
  }

  void _prevStep() {
    if (_step > 0 && _step < 5) {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else if (_step == 0) {
      context.pop();
    }
  }

  Future<void> _createPlan() async {
    final vm = context.read<PlanViewModel>();
    setState(() => _step = 4);
    _pageCtrl.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);

    final mix = _selectedBrand?.contentMix;
    final data = {
      'name': _nameCtrl.text.trim(),
      'brandId': _selectedBrand?.id,
      'productNames': _selectedProducts.map((p) => p.name).toList(),
      'productIds': _selectedProducts.map((p) => p.id).toList(),
      'objective': _objective!.apiValue,
      'startDate': _startDate.toIso8601String().split('T').first,
      'durationWeeks': _durationWeeks,
      'promotionIntensity': _selectedBrand?.promotionIntensity?.name ?? 'balanced',
      'postingFrequency': _postingFrequency,
      'platforms': _selectedBrand?.platforms.map((p) => p.name).toList() ?? [],
      'collaboratorEmails': _collaboratorEmails,
      'linkedStrategyId': _linkedStrategy?.id,
      'linkedPhaseId': _linkedPhase?.id,
      'contentMixPreference': mix != null
          ? {
              'educational': mix.educational,
              'promotional': mix.promotional,
              'storytelling': mix.storytelling,
              'authority': mix.authority,
            }
          : {'educational': 25, 'promotional': 25, 'storytelling': 25, 'authority': 25},
    };

    final plan = await vm.createAndGenerate(data, _selectedBrand!.id!);
    if (mounted) {
      setState(() => _generatedPlan = plan);
      // Navigate to plan detail immediately so the user can approve / edit
      if (plan != null) context.push('/plan-detail', extra: plan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final working = context.watch<PlanViewModel>().isGenerating || context.watch<PlanViewModel>().isSaving;
    
    // If working, show full immersive loading view
    if (working && _step == 4) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: AiPlanLoadingView(brandName: _selectedBrand?.name ?? 'Brand'),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            if (_step < 3) _buildStepIndicator(cs),
            const Divider(height: 1),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(cs),
                  _buildStep2(cs),
                  _buildStep3(cs),
                  _buildStep4(cs),
                  _buildStep5(cs),
                  _buildStepResult(cs),
                ],
              ),
            ),
            if (_step < 5) _buildNavBar(cs),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: _step < 3 ? _prevStep : null,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _step == 0 ? Icons.close_rounded : Icons.chevron_left_rounded,
                size: 20,
                color: _step == 3 ? cs.outlineVariant : cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            context.tr('plan_new_project'),
            style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const Spacer(),
          if (_step < 5)
            Text('${_step + 1} / 5',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ─── Step indicator ───────────────────────────────────────────────────────

  Widget _buildStepIndicator(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(9, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(height: 2, color: (i ~/ 2) < _step ? cs.primary : cs.outlineVariant),
            );
          }
          final idx = i ~/ 2;
          final done = idx < _step;
          final current = idx == _step;
          return Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? cs.primary : (current ? cs.primaryContainer : cs.surfaceContainerHighest),
              border: Border.all(
                color: (done || current) ? cs.primary : cs.outlineVariant,
                width: current ? 2 : 1,
              ),
            ),
            child: Center(
              child: done
                  ? Icon(Icons.check_rounded, size: 13, color: cs.onPrimary)
                  : Text('${idx + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: current ? cs.primary : cs.onSurfaceVariant,
                      )),
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Choose Brand ─────────────────────────────────────────────────

  Widget _buildStep1(ColorScheme cs) {
    return Consumer<BrandViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.brands.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_outlined, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(context.tr('plan_no_brands_title'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text(context.tr('plan_no_brands_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.push('/brand-form'),
                    child: Text(context.tr('plan_create_brand')),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text(context.tr('plan_choose_brand'),
                style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(context.tr('plan_choose_brand_desc'),
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            ...vm.brands.map((brand) => _OptionCard(
                  emoji: _brandEmoji(brand),
                  name: brand.name,
                  desc: brand.description?.isNotEmpty == true
                      ? brand.description!
                      : '${_cap(brand.tone.name)} · ${brand.platforms.map((p) => _cap(p.name)).join(", ")}',
                  isSelected: _selectedBrand?.id == brand.id,
                  cs: cs,
                  onTap: () => setState(() {
                    _selectedBrand = brand;
                    _selectedProducts = []; // Reset products when brand changes
                  }),
                )),
          ],
        );
      },
    );
  }

  // ─── Step 2: Choose Product ───────────────────────────────────────────────

  Widget _buildStep2(ColorScheme cs) {
    if (_selectedBrand == null) return const SizedBox.shrink();
    final products = _selectedBrand!.products;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text('Choose Product',
            style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text('Every campaign is linked to a specific product.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        if (products.isEmpty)
          Center(
            child: Column(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('No products found for this brand.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.push('/brand-form', extra: _selectedBrand),
                  child: const Text('Add Products to Brand'),
                ),
              ],
            ),
          )
        else
          ...products.map((p) {
            final isSelected = _selectedProducts.contains(p);
            return _OptionCard(
              imageUrl: p.imageUrl,
              emoji: '📦',
              name: p.name,
              desc: 'Product in ${_selectedBrand!.name}',
              isSelected: isSelected,
              cs: cs,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedProducts.remove(p);
                  } else {
                    _selectedProducts.add(p);
                  }
                });
              },
            );
          }),
      ],
    );
  }

  // ─── Step 3: Plan Details ─────────────────────────────────────────────────

  Widget _buildStep3(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text(context.tr('plan_details_title'),
            style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text(context.tr('plan_details_desc'),
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        _label(context.tr('plan_name_label'), cs),
        TextField(
          controller: _nameCtrl,
          decoration: _deco(context.tr('plan_name_hint'), cs),
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        _label('Collaborators', cs),
        _buildCollaboratorsInput(cs),
        const SizedBox(height: 24),
        _label(context.tr('plan_start_date'), cs),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _startDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 12),
                Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                  style: TextStyle(fontSize: 14, color: cs.onSurface, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _label(context.tr('plan_duration_label'), cs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            border: Border.all(color: cs.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_durationWeeks ${context.tr('plan_weeks_suffix')}',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
              Row(
                children: [
                  IconButton(
                    onPressed: _durationWeeks > 1 ? () => setState(() => _durationWeeks--) : null,
                    icon: const Icon(Icons.remove_rounded),
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: _durationWeeks < 12 ? () => setState(() => _durationWeeks++) : null,
                    icon: const Icon(Icons.add_rounded),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _label(context.tr('plan_posts_week_label'), cs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [3, 5, 7].map((freq) {
            final sel = _postingFrequency == freq;
            return ChoiceChip(
              label: Text('$freq / week'),
              selected: sel,
              onSelected: (_) => setState(() => _postingFrequency = freq),
              selectedColor: cs.primary,
              labelStyle: TextStyle(
                color: sel ? cs.onPrimary : cs.onSurface,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCollaboratorsInput(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_collaboratorEmails.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _collaboratorEmails.map((email) {
              return Chip(
                label: Text(email, style: const TextStyle(fontSize: 11)),
                onDeleted: () => setState(() => _collaboratorEmails.remove(email)),
                deleteIconColor: cs.error,
                backgroundColor: cs.surfaceContainerHighest,
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 2) {
                    return const Iterable<String>.empty();
                  }
                  try {
                    final users = await SocialService().searchUsers(textEditingValue.text);
                    return users.map((u) => u.email).where((email) => !_collaboratorEmails.contains(email));
                  } catch (_) {
                    return const Iterable<String>.empty();
                  }
                },
                onSelected: (String selection) {
                  _collabEmailCtrl.text = selection;
                  _addCollab();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: _deco('Collaborator Email', cs),
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: (v) {
                      _collabEmailCtrl.text = v;
                      _addCollab();
                    },
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: cs.surface,
                      child: Container(
                        width: MediaQuery.of(context).size.width - 100,
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final email = options.elementAt(index);
                            return ListTile(
                              title: Text(email, style: const TextStyle(fontSize: 13)),
                              onTap: () => onSelected(email),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _addCollab,
              icon: const Icon(Icons.person_add_rounded),
            ),
          ],
        ),
      ],
    );
  }

  void _addCollab() {
    final email = _collabEmailCtrl.text.trim();
    if (email.isNotEmpty && email.contains('@') && !_collaboratorEmails.contains(email)) {
      setState(() {
        _collaboratorEmails.add(email);
        _collabEmailCtrl.clear();
      });
    }
  }

  // ─── Step 4: Objective ────────────────────────────────────────────────────

  Widget _buildStep4(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        Text(context.tr('plan_campaign_obj'),
            style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text(context.tr('plan_obj_desc'),
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: 24),
        ...PlanObjective.values.map((obj) => _OptionCard(
              emoji: obj.emoji,
              name: obj.label,
              desc: obj.description,
              isSelected: _objective == obj,
              cs: cs,
              onTap: () => setState(() => _objective = obj),
            )),
      ],
    );
  }

  // ─── Step 5: Link to Strategy ──────────────────────────────────────────────
  Widget _buildStep5(ColorScheme cs) {
    return Consumer<PlanViewModel>(
      builder: (context, vm, _) {
        final brandPlans = vm.plans.where((p) => p.brandId == _selectedBrand?.id).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text('Lien Stratégique',
                style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text('Assigner ce projet à une phase de ta stratégie marketing (Optionnel).',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 24),
            
            if (brandPlans.isEmpty)
              Center(
                child: Column(
                  children: [
                    _OptionCard(
                      emoji: '📢',
                      name: 'Aucune campagne active',
                      desc: 'Crée d\'abord une stratégie pour cette marque.',
                      isSelected: false,
                      cs: cs,
                      onTap: () {},
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => context.push('/campaign-planner', extra: _selectedBrand),
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                      label: const Text('Lancer une Stratégie'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              _label('Choisir la Campagne', cs),
              ...brandPlans.map((plan) => _OptionCard(
                emoji: plan.objective.emoji,
                name: plan.name,
                desc: '${plan.phases.length} phases · ${plan.platforms.join(", ")}',
                isSelected: _linkedStrategy?.id == plan.id,
                cs: cs,
                onTap: () => setState(() {
                  _linkedStrategy = plan;
                  _linkedPhase = null;
                }),
              )),
              
              if (_linkedStrategy != null) ...[
                const SizedBox(height: 24),
                _label('Assigner à une Phase', cs),
                ..._linkedStrategy!.phases.map((phase) => _OptionCard(
                  emoji: '📍',
                  name: phase.name,
                  desc: 'Semaine ${phase.weekNumber}',
                  isSelected: _linkedPhase?.id == phase.id,
                  cs: cs,
                  onTap: () => setState(() => _linkedPhase = phase),
                )),
              ],
            ],
          ],
        );
      }
    );
  }

  // ─── Step 6: Generating / Result ──────────────────────────────────────────
  Widget _buildStepResult(ColorScheme cs) {
    return Consumer<PlanViewModel>(
      builder: (context, vm, child) {
        final working = vm.isSaving || vm.isGenerating;

        // Error
        if (vm.error != null && !working) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
                  const SizedBox(height: 16),
                  Text(context.tr('plan_gen_failed'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text(vm.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: () {
                      vm.clearError();
                      setState(() {
                        _step = 2;
                        _pageCtrl.jumpToPage(2);
                        _generatedPlan = null;
                      });
                    },
                    child: Text(context.tr('plan_go_back')),
                  ),
                ],
              ),
            ),
          );
        }

        // Loading state is now handled at the build() level for full-screen immersion.
        // If we happen to be here without valid success state, show a small indicator or empty
        if (working || _generatedPlan == null) {
          return const SizedBox.shrink();
        }

        // Success – user was already pushed to PlanDetailScreen automatically.
        // This state is shown when they press back to return here.
        final plan = _generatedPlan!;
        final totalBlocks =
            plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: cs.primaryContainer, shape: BoxShape.circle),
                  child: Icon(Icons.check_rounded, size: 36, color: cs.primary),
                ),
                const SizedBox(height: 20),
                Text(context.tr('plan_created_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 6),
                Text(plan.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${plan.phases.length} phases · $totalBlocks posts',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.primary),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.push('/plan-detail', extra: plan),
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(context.tr('plan_view_approve')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: vm.isGenerating
                      ? null
                      : () async {
                          final regen =
                              await vm.regeneratePlan(plan.id!);
                          if (regen != null && mounted) {
                            setState(() {
                              _generatedPlan = regen;
                              _expandedPhases.clear();
                            });
                            context.push('/plan-detail', extra: regen);
                          }
                        },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.tr('plan_regenerate')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Nav bar ──────────────────────────────────────────────────────────────

  Widget _buildNavBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            OutlinedButton(
              onPressed: _prevStep,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: Text(context.tr('plan_back_btn')),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: _canContinue ? _nextStep : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                _step == 3 ? context.tr('plan_generate_btn') : context.tr('plan_continue'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared widgets ───────────────────────────────────────────────────────

  Widget _label(String text, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 1.2)),
      );

  InputDecoration _deco(String hint, ColorScheme cs) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: cs.onSurfaceVariant),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
      );

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _brandEmoji(Brand brand) {
    const m = {
      'professional': '💼', 'friendly': '😊', 'bold': '🔥',
      'educational': '📚', 'luxury': '💎', 'playful': '🎉',
    };
    return m[brand.tone.name] ?? '🏷️';
  }
}

// ─── Option card ──────────────────────────────────────────────────────────────

class _OptionCard extends StatelessWidget {
  final String? emoji;
  final String? imageUrl;
  final String name;
  final String desc;
  final bool isSelected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _OptionCard({
    this.emoji,
    this.imageUrl,
    required this.name,
    required this.desc,
    this.isSelected = false,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
          border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (emoji != null)
              Text(emoji!, style: const TextStyle(fontSize: 24))
            else
              const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                      )),
                  Text(desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                            : cs.onSurfaceVariant,
                      )),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : Colors.transparent,
                border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: isSelected ? Icon(Icons.check_rounded, size: 12, color: cs.onPrimary) : null,
            ),
          ],
        ),
      ),
    );
  }
}
