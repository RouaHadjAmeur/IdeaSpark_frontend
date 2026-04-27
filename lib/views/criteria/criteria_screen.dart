import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/criteria_view_model.dart';

class CriteriaScreen extends StatefulWidget {
  final String? type;

  const CriteriaScreen({super.key, this.type});

  @override
  State<CriteriaScreen> createState() => _CriteriaScreenState();
}

class _CriteriaScreenState extends State<CriteriaScreen> {
  final _nicheController = TextEditingController();

  @override
  void dispose() {
    _nicheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChangeNotifierProvider(
      create: (_) => CriteriaViewModel(initialType: null)
        ..setTypeFromId(widget.type),
      child: Stack(
        children: [
          Consumer<CriteriaViewModel>(
            builder: (context, vm, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('settings'),
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('tell_us_what'),
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel(context.tr('type'), colorScheme),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: vm.type),
                      readOnly: true,
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel(context.tr('niche'), colorScheme),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nicheController,
                      onChanged: vm.setNiche,
                      decoration: InputDecoration(
                        hintText: context.tr('niche_hint'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel(context.tr('target_audience'), colorScheme),
                    const SizedBox(height: 8),
                    _chipsRow(
                      context,
                      'audience',
                      CriteriaViewModel.audienceOptions,
                      vm.audience,
                      vm.setAudience,
                      colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel(context.tr('platform'), colorScheme),
                    const SizedBox(height: 8),
                    _chipsRow(
                      context,
                      'platform',
                      CriteriaViewModel.platformOptions,
                      vm.platform,
                      vm.setPlatform,
                      colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel(context.tr('tone_style'), colorScheme),
                    const SizedBox(height: 8),
                    _chipsRow(
                      context,
                      'tone',
                      CriteriaViewModel.toneOptions,
                      vm.tone,
                      vm.setTone,
                      colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel(context.tr('creativity_level'), colorScheme),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: colorScheme.primary,
                        inactiveTrackColor: colorScheme.surfaceContainerHighest,
                        thumbColor: colorScheme.primary,
                      ),
                      child: Slider(
                        value: vm.creativity,
                        onChanged: vm.setCreativity,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('realistic'),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          context.tr('creative'),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/loading'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.tr('generate_10')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/loading'),
                    child: Text(
                      context.tr('surprise_me'),
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, ColorScheme colorScheme) {
    return Text(
      text,
      style: GoogleFonts.syne(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget _chipsRow(
    BuildContext context,
    String category,
    List<String> options,
    String selected,
    ValueChanged<String> onSelect,
    ColorScheme colorScheme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onSelect(o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              context.trOption(category, o),
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
