import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: colorScheme.onSurface,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paramètres',
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dis-nous quoi générer',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('Type', colorScheme),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: vm.type),
                      readOnly: true,
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Niche', colorScheme),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nicheController,
                      onChanged: vm.setNiche,
                      decoration: const InputDecoration(
                        hintText: 'Ex: Fitness, Beauty, Tech...',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Audience cible', colorScheme),
                    const SizedBox(height: 8),
                    _chipsRow(
                      context,
                      CriteriaViewModel.audienceOptions,
                      vm.audience,
                      vm.setAudience,
                      colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Plateforme', colorScheme),
                    const SizedBox(height: 8),
                    _chipsRow(
                      context,
                      CriteriaViewModel.platformOptions,
                      vm.platform,
                      vm.setPlatform,
                      colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Ton / Style', colorScheme),
                    const SizedBox(height: 8),
                    _chipsRow(
                      context,
                      CriteriaViewModel.toneOptions,
                      vm.tone,
                      vm.setTone,
                      colorScheme,
                    ),
                    const SizedBox(height: 20),
                    _sectionLabel('Niveau Créativité', colorScheme),
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
                          'Réaliste',
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Créatif',
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
                      child: const Text('Générer 10 idées'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/loading'),
                    child: Text(
                      'Surprise me ✨',
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
              o,
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
