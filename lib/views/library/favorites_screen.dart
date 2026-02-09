import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/models/idea_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static final _sampleIdeas = [
    IdeaModel(id: '1', type: 'Video', title: '5 Productivity Hacks Students', description: 'Liste rapide de 5 astuces de productivité pour étudiants avec démonstration visuelle.', score: 9.2),
    IdeaModel(id: '2', type: 'Business', title: 'Meal Prep Service Students', description: 'Service de préparation de repas sains et abordables pour étudiants universitaires.', score: 8.5),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('favorites_title'),
            style: GoogleFonts.syne(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: context.tr('filter_all'), selected: true, colorScheme: colorScheme),
                const SizedBox(width: 8),
                _FilterChip(label: context.tr('filter_business'), selected: false, colorScheme: colorScheme),
                const SizedBox(width: 8),
                _FilterChip(label: context.tr('filter_video'), selected: false, colorScheme: colorScheme),
                const SizedBox(width: 8),
                _FilterChip(label: context.tr('filter_product'), selected: false, colorScheme: colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ..._sampleIdeas.map((idea) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _IdeaCard(
              idea: idea,
              colorScheme: colorScheme,
              onTap: () => context.push('/idea/${idea.id}'),
            ),
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme colorScheme;

  const _FilterChip({required this.label, required this.selected, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  final IdeaModel idea;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _IdeaCard({required this.idea, required this.colorScheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      idea.type,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department_rounded, size: 16, color: context.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        '${idea.score}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                idea.title,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                idea.description,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.delete_outline_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                    label: Text(context.tr('remove'), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ),
                  TextButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.share_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                    label: Text(context.tr('share'), style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
