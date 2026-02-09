import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_theme.dart';

class SlogansResultsScreen extends StatelessWidget {
  const SlogansResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '10 Slogans - FocusFlow',
                      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sélectionnez vos favoris et testez-les auprès de votre audience pour valider celui qui résonne le mieux.',
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SloganCard(
                colorScheme: colorScheme,
                slogan: 'Transformez vos distractions en accomplissements',
                score: 9.2,
                analysis: 'Message de transformation et d\'empowerment. Positionne le produit comme un catalyseur de changement positif.',
                tags: ['✓ Disponible', 'Inspirant', 'Actionnable'],
              ),
              const SizedBox(height: 12),
              _SloganCard(
                colorScheme: colorScheme,
                slogan: 'Votre temps mérite mieux que le scroll',
                score: 8.8,
                analysis: 'Appel à la valeur personnelle du temps. Référence directe au comportement problématique (scroll).',
                tags: ['✓ Disponible', 'Direct'],
              ),
              const SizedBox(height: 12),
              _SloganCard(
                colorScheme: colorScheme,
                slogan: 'Focus. Flow. Fait.',
                score: 9.5,
                analysis: 'Slogan rythmé en 3 temps (très mémorable). Intègre le nom du produit. Progression logique: concentration → état optimal → résultat.',
                tags: ['✓ Disponible', 'Court', 'Percutant'],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('🔄 Générer 10 nouvelles variantes'),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Text('Vous avez sélectionné', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
                    Text('2 favoris', style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      child: const Text('📥 Exporter mes favoris'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SloganCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final String slogan;
  final double score;
  final String analysis;
  final List<String> tags;

  const _SloganCard({
    required this.colorScheme,
    required this.slogan,
    required this.score,
    required this.analysis,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slogan,
                      style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      analysis,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.secondary]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$score/10', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((t) {
              final isAvailable = t.startsWith('✓');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isAvailable ? context.successColor.withValues(alpha: 0.2) : colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isAvailable ? context.successColor : colorScheme.primary)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('⭐ Favori'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('📋 Copier'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('📤 Tester'))),
            ],
          ),
        ],
      ),
    );
  }
}
