import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../models/brand.dart';
import '../../view_models/brand_view_model.dart';

// ─── Suggestion data ───

const _kCategories = [
  'E-commerce', 'Beauty / Skincare', 'Fitness', 'Personal Brand', 'Content Creator',
];

const _kCategoryEmojis = <String, String>{
  'E-commerce': '🛍',
  'Beauty / Skincare': '💄',
  'Fitness': '🏋️',
  'Personal Brand': '💼',
  'Content Creator': '🎬',
};

const _kInterestSuggestions = <String, List<String>>{
  'E-commerce': ['Online shopping', 'Discounts & deals', 'Reviews', 'Trendy products', 'Lifestyle', 'Quality products', 'Convenience', 'Brand trust'],
  'Beauty / Skincare': ['Self-care', 'Glow up', 'Anti-aging', 'Skincare routine', 'Natural products', 'Luxury beauty', 'Confidence', 'Wellness'],
  'Fitness': ['Weight loss', 'Muscle building', 'Healthy eating', 'Discipline', 'Home workouts', 'Gym lifestyle', 'Transformation', 'Motivation'],
  'Personal Brand': ['Entrepreneurship', 'Productivity', 'Marketing', 'Side hustles', 'Leadership', 'Self-development', 'Online income', 'Growth mindset'],
  'Content Creator': ['Viral trends', 'Social media growth', 'Monetization', 'Storytelling', 'Audience growth', 'Content strategy', 'Creative tools', 'Reels & TikTok'],
};

const _kPillarTemplates = <String, List<String>>{
  'Universal': ['Educational', 'Promotional', 'Storytelling', 'Authority', 'Community'],
  'E-commerce': ['Product spotlight', 'Problem-solution', 'Testimonials', 'Educational usage', 'Lifestyle integration'],
  'Beauty / Skincare': ['Skincare education', 'Product benefits', 'Before & After', 'Self-care mindset', 'Luxury identity'],
  'Fitness': ['Workout tips', 'Transformation stories', 'Nutrition advice', 'Motivation', 'Product showcase'],
  'Personal Brand': ['Educational insights', 'Case studies', 'Personal story', 'Authority building', 'Offers & services'],
  'Content Creator': ['Behind the scenes', 'Tips & tricks', 'Trending topics', 'Collaboration', 'Monetization strategies'],
};

class CreateEditBrandScreen extends StatefulWidget {
  final Brand? brand;
  const CreateEditBrandScreen({super.key, this.brand});

  @override
  State<CreateEditBrandScreen> createState() => _CreateEditBrandScreenState();
}

class _CreateEditBrandScreenState extends State<CreateEditBrandScreen> {
  final _pageCtrl = PageController();
  int _step = 0;
  static const _totalSteps = 5;
  static const _stepNames = ['Identity', 'Audience', 'Content', 'Revenue', 'Advanced'];

  // Step 1: Identity
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late BrandTone _tone;

  // Step 2: Audience & Platforms
  late final Set<BrandPlatform> _platforms;
  late final TextEditingController _ageRangeCtrl;
  late final TextEditingController _genderCtrl;
  late final List<String> _interests;
  final _interestInputCtrl = TextEditingController();

  // Step 3: Content Strategy
  late final List<String> _pillars;
  final _pillarInputCtrl = TextEditingController();
  late PostingFrequency? _postingFrequency;
  late final TextEditingController _customFreqCtrl;
  late int _educationalPct;
  late int _promotionalPct;
  late int _storytellingPct;
  late int _authorityPct;

  // Step 4: Goals & Revenue
  late BrandGoal? _mainGoal;
  late final Set<RevenueType> _revenueTypes;
  late PromotionIntensity _promotionIntensity;
  late final TextEditingController _revenueTargetCtrl;
  late final TextEditingController _followerTargetCtrl;
  late final TextEditingController _conversionGoalCtrl;

  // Step 5: Advanced
  late final TextEditingController _uniqueAngleCtrl;
  late final TextEditingController _painPointCtrl;
  late final List<String> _competitors;
  final _competitorInputCtrl = TextEditingController();
  late BrandSeasonality _seasonality;
  late int _maxConsecutivePromo;
  late int _minGapDays;

  // UI helper (not persisted)
  String? _brandCategory;

  bool get _isEdit => widget.brand != null;

  @override
  void initState() {
    super.initState();
    final b = widget.brand;
    final mix = b?.contentMix;
    final rotation = b?.smartRotation;

    _nameCtrl = TextEditingController(text: b?.name ?? '');
    _descCtrl = TextEditingController(text: b?.description ?? '');
    _tone = b?.tone ?? BrandTone.professional;

    _platforms = Set.from(b?.platforms ?? []);
    _ageRangeCtrl = TextEditingController(text: b?.audience.ageRange ?? '');
    _genderCtrl = TextEditingController(text: b?.audience.gender ?? '');
    _interests = List.from(b?.audience.interests ?? []);

    // Auto-detect category from existing interests so suggestions appear on edit
    if (_interests.isNotEmpty) {
      String? bestCat;
      int bestScore = 0;
      for (final cat in _kCategories) {
        final suggestions = _kInterestSuggestions[cat] ?? <String>[];
        final score = _interests.where(suggestions.contains).length;
        if (score > bestScore) {
          bestScore = score;
          bestCat = cat;
        }
      }
      _brandCategory = bestCat;
    }

    _pillars = List.from(b?.contentPillars ?? []);
    _postingFrequency = b?.postingFrequency;
    _customFreqCtrl = TextEditingController(text: b?.customPostingFrequency ?? '');
    _educationalPct = mix?.educational ?? 25;
    _promotionalPct = mix?.promotional ?? 25;
    _storytellingPct = mix?.storytelling ?? 25;
    _authorityPct = mix?.authority ?? 25;

    _mainGoal = b?.mainGoal;
    _revenueTypes = Set.from(b?.revenueTypes ?? []);
    _promotionIntensity = b?.promotionIntensity ?? PromotionIntensity.balanced;
    _revenueTargetCtrl = TextEditingController(text: b?.kpis?.monthlyRevenueTarget?.toString() ?? '');
    _followerTargetCtrl = TextEditingController(text: b?.kpis?.monthlyFollowerGrowthTarget?.toString() ?? '');
    _conversionGoalCtrl = TextEditingController(text: b?.kpis?.campaignConversionGoal?.toString() ?? '');

    _uniqueAngleCtrl = TextEditingController(text: b?.uniqueAngle ?? '');
    _painPointCtrl = TextEditingController(text: b?.mainPainPointSolved ?? '');
    _competitors = List.from(b?.competitors ?? []);
    _seasonality = b?.seasonality ?? BrandSeasonality.alwaysActive;
    _maxConsecutivePromo = rotation?.maxConsecutivePromoPosts ?? 2;
    _minGapDays = rotation?.minGapBetweenPromotions ?? 3;
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in [
      _nameCtrl, _descCtrl, _ageRangeCtrl, _genderCtrl, _interestInputCtrl,
      _pillarInputCtrl, _customFreqCtrl, _revenueTargetCtrl, _followerTargetCtrl,
      _conversionGoalCtrl, _uniqueAngleCtrl, _painPointCtrl, _competitorInputCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Navigation ───

  void _nextStep() {
    if (_step == 0 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand name is required')),
      );
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _submit() async {
    final totalMix = _educationalPct + _promotionalPct + _storytellingPct + _authorityPct;
    int norm(int v) => totalMix > 0 ? ((v / totalMix) * 100).round() : 25;

    final hasKpis = _revenueTargetCtrl.text.isNotEmpty ||
        _followerTargetCtrl.text.isNotEmpty ||
        _conversionGoalCtrl.text.isNotEmpty;

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      if (_descCtrl.text.isNotEmpty) 'description': _descCtrl.text.trim(),
      'tone': _tone.name,
      'audience': {
        'ageRange': _ageRangeCtrl.text.trim(),
        'gender': _genderCtrl.text.trim(),
        'interests': List.from(_interests),
      },
      'platforms': _platforms.map((p) => p.name).toList(),
      'contentPillars': List.from(_pillars),
      if (_mainGoal != null) 'mainGoal': _mainGoal!.name,
      if (hasKpis) 'kpis': {
        if (_revenueTargetCtrl.text.isNotEmpty)
          'monthlyRevenueTarget': double.tryParse(_revenueTargetCtrl.text),
        if (_followerTargetCtrl.text.isNotEmpty)
          'monthlyFollowerGrowthTarget': int.tryParse(_followerTargetCtrl.text),
        if (_conversionGoalCtrl.text.isNotEmpty)
          'campaignConversionGoal': double.tryParse(_conversionGoalCtrl.text),
      },
      if (_postingFrequency != null) 'postingFrequency': _postingFrequency!.name,
      if (_postingFrequency == PostingFrequency.custom && _customFreqCtrl.text.isNotEmpty)
        'customPostingFrequency': _customFreqCtrl.text.trim(),
      'contentMix': {
        'educational': norm(_educationalPct),
        'promotional': norm(_promotionalPct),
        'storytelling': norm(_storytellingPct),
        'authority': norm(_authorityPct),
      },
      if (_revenueTypes.isNotEmpty) 'revenueTypes': _revenueTypes.map((r) => r.name).toList(),
      'promotionIntensity': _promotionIntensity.name,
      if (_uniqueAngleCtrl.text.isNotEmpty) 'uniqueAngle': _uniqueAngleCtrl.text.trim(),
      if (_painPointCtrl.text.isNotEmpty) 'mainPainPointSolved': _painPointCtrl.text.trim(),
      if (_competitors.isNotEmpty) 'competitors': List.from(_competitors),
      'seasonality': _seasonality.name,
      'smartRotation': {
        'maxConsecutivePromoPosts': _maxConsecutivePromo,
        'minGapBetweenPromotions': _minGapDays,
      },
    };

    final vm = context.read<BrandViewModel>();
    final result = _isEdit
        ? await vm.updateBrand(widget.brand!.id!, data)
        : await vm.createBrand(data);

    if (!mounted) return;
    if (result != null) {
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error ?? 'An error occurred'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            _buildStepIndicator(cs),
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
                ],
              ),
            ),
            _buildNavBar(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: _prevStep,
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
                color: cs.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit Brand' : 'New Brand',
                  style: TextStyle(fontFamily: 'Syne', fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface),
                ),
                Text(_stepNames[_step], style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            '${_step + 1} / $_totalSteps',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(height: 2, color: (i ~/ 2) < _step ? cs.primary : cs.outlineVariant),
            );
          }
          final idx = i ~/ 2;
          final done = idx < _step;
          final current = idx == _step;
          return Container(
            width: 28,
            height: 28,
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
                  ? Icon(Icons.check_rounded, size: 14, color: cs.onPrimary)
                  : Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: current ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Identity ───

  Widget _buildStep1(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _label('Brand Info', cs),
        TextField(
          controller: _nameCtrl,
          decoration: _deco('Brand Name *', cs),
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descCtrl,
          decoration: _deco('Description (optional)', cs),
          maxLines: 3,
          textInputAction: TextInputAction.newline,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 24),
        _label('Brand Tone', cs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BrandTone.values.map((t) {
            final sel = _tone == t;
            return ChoiceChip(
              label: Text(_cap(t.name)),
              selected: sel,
              onSelected: (_) => setState(() => _tone = t),
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

  // ─── Step 2: Audience & Platforms ───

  Widget _buildStep2(ColorScheme cs) {
    final suggestions = _brandCategory != null
        ? (_kInterestSuggestions[_brandCategory!] ?? <String>[])
            .where((s) => !_interests.contains(s))
            .toList()
        : <String>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _label('Platforms', cs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BrandPlatform.values.map((p) {
            final sel = _platforms.contains(p);
            return FilterChip(
              label: Text(_cap(p.name)),
              selected: sel,
              onSelected: (v) => setState(() => v ? _platforms.add(p) : _platforms.remove(p)),
              selectedColor: cs.primaryContainer,
              checkmarkColor: cs.onPrimaryContainer,
              labelStyle: TextStyle(
                color: sel ? cs.onPrimaryContainer : cs.onSurface,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _label('Audience', cs),
        TextField(
          controller: _ageRangeCtrl,
          decoration: _deco('Age Range (e.g. 18–35)', cs),
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _genderCtrl,
          decoration: _deco('Gender (All / Male / Female)', cs),
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 24),

        // ── Brand Category (interest suggestion helper) ──
        _label('Brand Category', cs),
        Text(
          'Pick a category to get tailored interest suggestions.',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kCategories.map((cat) {
            final sel = _brandCategory == cat;
            return ChoiceChip(
              label: Text('${_kCategoryEmojis[cat]} $cat', style: const TextStyle(fontSize: 12)),
              selected: sel,
              onSelected: (_) => setState(() => _brandCategory = sel ? null : cat),
              selectedColor: cs.secondaryContainer,
              labelStyle: TextStyle(
                color: sel ? cs.onSecondaryContainer : cs.onSurface,
                fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        // ── Suggested interests ──
        if (_brandCategory != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 13, color: cs.primary),
              const SizedBox(width: 5),
              Text(
                'Suggested for ${_kCategoryEmojis[_brandCategory!]} $_brandCategory',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (suggestions.isEmpty)
            Text(context.tr('brand_suggestions_all_added'),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions
                  .map((s) => ActionChip(
                        label: Text(s, style: TextStyle(fontSize: 11, color: cs.onSurface)),
                        avatar: Icon(Icons.add_rounded, size: 14, color: cs.primary),
                        onPressed: () => setState(() => _interests.add(s)),
                        backgroundColor: cs.surfaceContainerHighest,
                        side: BorderSide(color: cs.outlineVariant),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
        ],

        const SizedBox(height: 16),
        _label('Interests', cs),
        _chipInput(
          items: _interests,
          ctrl: _interestInputCtrl,
          hint: 'Add interest & press Enter',
          cs: cs,
          onAdd: (v) { if (!_interests.contains(v)) setState(() => _interests.add(v)); },
          onRemove: (v) => setState(() => _interests.remove(v)),
        ),
      ],
    );
  }

  // ─── Step 3: Content Strategy ───

  Widget _buildStep3(ColorScheme cs) {
    final total = _educationalPct + _promotionalPct + _storytellingPct + _authorityPct;
    final ok = total == 100;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _label('Pillar Templates', cs),
        Text(
          'Tap a template to auto-fill your pillars, then customise freely.',
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        _buildPillarTemplateRow(cs),
        const SizedBox(height: 24),
        _label('Content Pillars (max 5)', cs),
        _chipInput(
          items: _pillars,
          ctrl: _pillarInputCtrl,
          hint: _pillars.length >= 5 ? 'Maximum 5 reached' : 'Add pillar & press Enter',
          cs: cs,
          enabled: _pillars.length < 5,
          onAdd: (v) {
            if (!_pillars.contains(v) && _pillars.length < 5) setState(() => _pillars.add(v));
          },
          onRemove: (v) => setState(() => _pillars.remove(v)),
        ),
        const SizedBox(height: 24),
        _label('Posting Frequency', cs),
        _frequencyGrid(cs),
        if (_postingFrequency == PostingFrequency.custom) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _customFreqCtrl,
            decoration: _deco('Custom schedule (e.g. 2x per week)', cs),
            style: TextStyle(color: cs.onSurface),
          ),
        ],
        const SizedBox(height: 24),
        _label('Content Mix', cs),
        const SizedBox(height: 4),
        _mixSlider('Educational', _educationalPct, cs, const Color(0xFF4D96FF),
            (v) => setState(() => _educationalPct = v)),
        _mixSlider('Promotional', _promotionalPct, cs, const Color(0xFFFF6B6B),
            (v) => setState(() => _promotionalPct = v)),
        _mixSlider('Storytelling', _storytellingPct, cs, const Color(0xFFC77DFF),
            (v) => setState(() => _storytellingPct = v)),
        _mixSlider('Authority', _authorityPct, cs, const Color(0xFF6BCB77),
            (v) => setState(() => _authorityPct = v)),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ok ? const Color(0xFF6BCB77).withValues(alpha: 0.15) : cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Total: $total%${ok ? ' ✓' : ' — adjust to reach 100%'}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ok ? const Color(0xFF3A9A50) : cs.error,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _frequencyGrid(ColorScheme cs) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.7,
      children: [
        _optTile('3x / week', Icons.calendar_today_rounded,
            _postingFrequency == PostingFrequency.threePerWeek, cs,
            () => setState(() => _postingFrequency = PostingFrequency.threePerWeek)),
        _optTile('5x / week', Icons.calendar_month_rounded,
            _postingFrequency == PostingFrequency.fivePerWeek, cs,
            () => setState(() => _postingFrequency = PostingFrequency.fivePerWeek)),
        _optTile('Daily', Icons.bolt_rounded,
            _postingFrequency == PostingFrequency.daily, cs,
            () => setState(() => _postingFrequency = PostingFrequency.daily)),
        _optTile('Custom', Icons.edit_calendar_rounded,
            _postingFrequency == PostingFrequency.custom, cs,
            () => setState(() => _postingFrequency = PostingFrequency.custom)),
      ],
    );
  }

  Widget _mixSlider(String label, int value, ColorScheme cs, Color color, ValueChanged<int> onChange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.18),
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                onChanged: (v) => onChange(v.toInt()),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              '$value%',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 4: Goals & Revenue ───

  Widget _buildStep4(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _label('Main Goal', cs),
        _goalGrid(cs),
        const SizedBox(height: 24),
        _label('Revenue Model', cs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _revChip('Physical', RevenueType.physicalProducts, cs),
            _revChip('Digital', RevenueType.digitalProducts, cs),
            _revChip('Services', RevenueType.services, cs),
            _revChip('Affiliate', RevenueType.affiliate, cs),
            _revChip('Sponsorships', RevenueType.sponsorships, cs),
            _revChip('Mixed', RevenueType.mixed, cs),
          ],
        ),
        const SizedBox(height: 24),
        _label('Promotion Intensity', cs),
        _intensityCard('🌱 Soft Sell', 'Low promotional pressure', PromotionIntensity.low, cs),
        _intensityCard('⚖️ Balanced', 'Mix of value & promotional content', PromotionIntensity.balanced, cs),
        _intensityCard('🔥 Aggressive', 'High conversion focus, strong CTAs', PromotionIntensity.aggressive, cs),
        const SizedBox(height: 24),
        _label('KPIs (Optional)', cs),
        TextField(
          controller: _revenueTargetCtrl,
          decoration: _deco('Monthly Revenue Target (\$)', cs),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _followerTargetCtrl,
          decoration: _deco('Follower Growth Target / month', cs),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _conversionGoalCtrl,
          decoration: _deco('Campaign Conversion Goal (%)', cs),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          style: TextStyle(color: cs.onSurface),
        ),
      ],
    );
  }

  Widget _goalGrid(ColorScheme cs) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.7,
      children: [
        _optTile('Grow Audience', Icons.people_outline_rounded,
            _mainGoal == BrandGoal.growAudience, cs,
            () => setState(() => _mainGoal = BrandGoal.growAudience)),
        _optTile('Increase Sales', Icons.trending_up_rounded,
            _mainGoal == BrandGoal.increaseSales, cs,
            () => setState(() => _mainGoal = BrandGoal.increaseSales)),
        _optTile('Build Authority', Icons.verified_outlined,
            _mainGoal == BrandGoal.buildAuthority, cs,
            () => setState(() => _mainGoal = BrandGoal.buildAuthority)),
        _optTile('Promote Products', Icons.shopping_bag_outlined,
            _mainGoal == BrandGoal.promoteProducts, cs,
            () => setState(() => _mainGoal = BrandGoal.promoteProducts)),
        _optTile('Affiliate', Icons.handshake_outlined,
            _mainGoal == BrandGoal.affiliateMarketing, cs,
            () => setState(() => _mainGoal = BrandGoal.affiliateMarketing)),
        _optTile('Personal Brand', Icons.person_outline_rounded,
            _mainGoal == BrandGoal.personalBrand, cs,
            () => setState(() => _mainGoal = BrandGoal.personalBrand)),
      ],
    );
  }

  Widget _revChip(String label, RevenueType type, ColorScheme cs) {
    final sel = _revenueTypes.contains(type);
    return FilterChip(
      label: Text(label),
      selected: sel,
      onSelected: (v) => setState(() => v ? _revenueTypes.add(type) : _revenueTypes.remove(type)),
      selectedColor: cs.primaryContainer,
      checkmarkColor: cs.onPrimaryContainer,
      labelStyle: TextStyle(
        color: sel ? cs.onPrimaryContainer : cs.onSurface,
        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _intensityCard(String label, String desc, PromotionIntensity val, ColorScheme cs) {
    final sel = _promotionIntensity == val;
    return GestureDetector(
      onTap: () => setState(() => _promotionIntensity = val),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? cs.primaryContainer : cs.surfaceContainerHighest,
          border: Border.all(color: sel ? cs.primary : cs.outlineVariant, width: sel ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? cs.onPrimaryContainer : cs.onSurface)),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 11,
                          color: sel
                              ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                              : cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (sel) Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
          ],
        ),
      ),
    );
  }

  // ─── Step 5: Advanced ───

  Widget _buildStep5(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      children: [
        _label('Positioning & Differentiation', cs),
        TextField(
          controller: _uniqueAngleCtrl,
          decoration: _deco('What makes this brand unique?', cs),
          maxLines: 2,
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _painPointCtrl,
          decoration: _deco('What problem does it solve?', cs),
          maxLines: 2,
          textInputAction: TextInputAction.next,
          style: TextStyle(color: cs.onSurface),
        ),
        const SizedBox(height: 24),
        _label('Competitors (max 3)', cs),
        _chipInput(
          items: _competitors,
          ctrl: _competitorInputCtrl,
          hint: _competitors.length >= 3 ? 'Maximum 3 reached' : 'Add competitor & press Enter',
          cs: cs,
          enabled: _competitors.length < 3,
          onAdd: (v) {
            if (!_competitors.contains(v) && _competitors.length < 3) setState(() => _competitors.add(v));
          },
          onRemove: (v) => setState(() => _competitors.remove(v)),
        ),
        const SizedBox(height: 24),
        _label('Seasonality', cs),
        _seasonCard('🔄 Always Active', 'Consistent content year-round', BrandSeasonality.alwaysActive, cs),
        _seasonCard('🌸 Seasonal', 'Active during specific periods', BrandSeasonality.seasonal, cs),
        _seasonCard('🚀 Campaign-based', 'Burst activity during campaigns only', BrandSeasonality.campaignBased, cs),
        const SizedBox(height: 24),
        _label('Smart Rotation Constraints', cs),
        _stepper(
          'Max consecutive promo posts',
          _maxConsecutivePromo, 1, 7, cs,
          (v) => setState(() => _maxConsecutivePromo = v),
        ),
        const SizedBox(height: 10),
        _stepper(
          'Min days between promotions',
          _minGapDays, 1, 14, cs,
          (v) => setState(() => _minGapDays = v),
        ),
      ],
    );
  }

  Widget _seasonCard(String label, String desc, BrandSeasonality val, ColorScheme cs) {
    final sel = _seasonality == val;
    return GestureDetector(
      onTap: () => setState(() => _seasonality = val),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? cs.primaryContainer : cs.surfaceContainerHighest,
          border: Border.all(color: sel ? cs.primary : cs.outlineVariant, width: sel ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: sel ? cs.onPrimaryContainer : cs.onSurface)),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 11,
                          color: sel
                              ? cs.onPrimaryContainer.withValues(alpha: 0.7)
                              : cs.onSurfaceVariant)),
                ],
              ),
            ),
            if (sel) Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _stepper(String label, int value, int min, int max, ColorScheme cs, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface))),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: value > min ? () => onChanged(value - 1) : null,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(Icons.remove_rounded, size: 16,
                        color: value > min ? cs.onSurface : cs.onSurfaceVariant),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text('$value',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
                InkWell(
                  onTap: value < max ? () => onChanged(value + 1) : null,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(Icons.add_rounded, size: 16,
                        color: value < max ? cs.onSurface : cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation Bar ───

  Widget _buildNavBar(ColorScheme cs) {
    return Consumer<BrandViewModel>(
      builder: (_, vm, _) => Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: vm.isSaving ? null : _nextStep,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: vm.isSaving && _step == _totalSteps - 1
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _step == _totalSteps - 1
                            ? (_isEdit ? 'Save Changes' : 'Create Brand')
                            : 'Continue',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pillar template helpers ───

  Widget _buildPillarTemplateRow(ColorScheme cs) {
    // Universal first, then selected category (if any), then the rest
    final ordered = <MapEntry<String, List<String>>>[
      MapEntry('Universal', _kPillarTemplates['Universal']!),
      if (_brandCategory != null && _kPillarTemplates.containsKey(_brandCategory))
        MapEntry(_brandCategory!, _kPillarTemplates[_brandCategory!]!),
      for (final entry in _kPillarTemplates.entries)
        if (entry.key != 'Universal' && entry.key != _brandCategory) entry,
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: ordered.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final name = ordered[index].key;
          final pillars = ordered[index].value;
          final isActive = _pillars.isNotEmpty && pillars.every((p) => _pillars.contains(p));
          final isCategoryMatch = name == _brandCategory;

          Color bg = cs.surfaceContainerHighest;
          Color border = cs.outlineVariant;
          Color titleColor = cs.onSurface;
          Color bodyColor = cs.onSurfaceVariant;
          double borderWidth = 1;

          if (isActive) {
            bg = cs.primaryContainer;
            border = cs.primary;
            titleColor = cs.onPrimaryContainer;
            bodyColor = cs.onPrimaryContainer.withValues(alpha: 0.75);
            borderWidth = 1.5;
          } else if (isCategoryMatch) {
            bg = cs.secondaryContainer;
            border = cs.secondary;
            titleColor = cs.onSecondaryContainer;
            bodyColor = cs.onSecondaryContainer.withValues(alpha: 0.75);
            borderWidth = 1.5;
          }

          return GestureDetector(
            onTap: () => _applyPillarTemplate(pillars),
            child: Container(
              width: 148,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: bg,
                border: Border.all(color: border, width: borderWidth),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_kCategoryEmojis.containsKey(name)) ...[
                        Text(_kCategoryEmojis[name]!, style: const TextStyle(fontSize: 11)),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: titleColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Icon(Icons.check_circle_rounded, size: 13, color: cs.primary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...pillars.take(3).map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $p',
                          style: TextStyle(fontSize: 10, color: bodyColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                  if (pillars.length > 3)
                    Text(
                      '+ ${pillars.length - 3} more',
                      style: TextStyle(fontSize: 9, color: bodyColor.withValues(alpha: 0.7)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _applyPillarTemplate(List<String> pillars) {
    setState(() {
      _pillars.clear();
      _pillars.addAll(pillars);
    });
  }

  // ─── Shared helpers ───

  Widget _label(String text, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 1.2),
        ),
      );

  Widget _optTile(String label, IconData icon, bool sel, ColorScheme cs, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? cs.primaryContainer : cs.surfaceContainerHighest,
          border: Border.all(color: sel ? cs.primary : cs.outlineVariant, width: sel ? 1.5 : 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: sel ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  color: sel ? cs.onPrimaryContainer : cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipInput({
    required List<String> items,
    required TextEditingController ctrl,
    required String hint,
    required ColorScheme cs,
    bool enabled = true,
    required void Function(String) onAdd,
    required void Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (items.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((item) => Chip(
                      label: Text(item, style: TextStyle(fontSize: 12, color: cs.onSurface)),
                      onDeleted: () => onRemove(item),
                      deleteIconColor: cs.onSurfaceVariant,
                      backgroundColor: cs.surfaceContainerHighest,
                      side: BorderSide(color: cs.outlineVariant),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: ctrl,
          enabled: enabled,
          decoration: _deco(hint, cs).copyWith(
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: enabled
                  ? () {
                      final v = ctrl.text.trim();
                      if (v.isNotEmpty) {
                        onAdd(v);
                        ctrl.clear();
                      }
                    }
                  : null,
            ),
          ),
          style: TextStyle(color: cs.onSurface),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              onAdd(v.trim());
              ctrl.clear();
            }
          },
        ),
      ],
    );
  }

  InputDecoration _deco(String label, ColorScheme cs) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.primary, width: 1.5)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
      );

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
