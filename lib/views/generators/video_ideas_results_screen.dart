import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoIdeasResultsScreen extends StatefulWidget {
  const VideoIdeasResultsScreen({super.key});

  @override
  State<VideoIdeasResultsScreen> createState() => _VideoIdeasResultsScreenState();
}

class _VideoIdeasResultsScreenState extends State<VideoIdeasResultsScreen> {
  String _filter = 'Toutes';
  static const _filters = ['Toutes', 'Tendance élevée', 'Originales', 'Faciles'];

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
              _buildHeader(context, colorScheme),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final active = f == _filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f),
                        selected: active,
                        onSelected: (_) => setState(() => _filter = f),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _VideoResultCard(
                colorScheme: colorScheme,
                title: '5 Exercices pour Perdre du Ventre en 10 Minutes',
                score: 9.2,
                description: 'Une routine rapide et efficace ciblant les abdominaux, parfaite pour les débutants et les personnes occupées. Format court avec démonstration claire de chaque exercice.',
                structure: const [
                  'Intro (0-15s): Problème du ventre + promesse de résultats',
                  'Corps (15s-2:30): 5 exercices avec démonstration',
                  'Conclusion (2:30-3:00): Rappel fréquence + CTA',
                ],
                hooks: const [
                  '"Stop aux abdos pendant 1h ! Voici comment perdre du ventre en seulement 10 minutes par jour..."',
                  '"Vous pensez qu\'il faut des heures de sport ? Je vais vous montrer 5 exercices qui changent tout..."',
                ],
                hashtags: const ['#fitness', '#perdredupoids', '#abdos', '#entrainement', '#ventreplat', '#10minutes'],
              ),
              const SizedBox(height: 16),
              _VideoResultCard(
                colorScheme: colorScheme,
                title: 'La Vérité sur les Compléments Alimentaires en Fitness',
                score: 8.7,
                description: 'Vidéo éducative démystifiant les compléments : lesquels sont essentiels, lesquels sont du marketing. Basée sur des études scientifiques.',
                structure: null,
                hooks: null,
                hashtags: const ['#tendance', '#éducatif', '#viralité moyenne'],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push('/loading'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: const Text('🔄 Générer Plus d\'Idées'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
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
              '3 Idées Générées',
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.settings_rounded, color: colorScheme.onSurface),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoResultCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final String title;
  final double score;
  final String description;
  final List<String>? structure;
  final List<String>? hooks;
  final List<String> hashtags;

  const _VideoResultCard({
    required this.colorScheme,
    required this.title,
    required this.score,
    required this.description,
    this.structure,
    this.hooks,
    required this.hashtags,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$score/10', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.6),
          ),
          if (structure != null) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text('Structure suggérée:', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...structure!.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(child: Text('${e.key + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(e.value, style: TextStyle(fontSize: 13, color: colorScheme.onSurface, height: 1.5))),
                    ],
                  ),
                )),
          ],
          if (hooks != null && hooks!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            Text('Hooks d\'ouverture:', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...hooks!.asMap().entries.map((e) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HOOK #${e.key + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                      const SizedBox(height: 6),
                      Text(e.value, style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.5)),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 12),
          Text('Hashtags recommandés:', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hashtags.map((h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(h, style: TextStyle(fontSize: 13, color: colorScheme.primary)),
                )).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Center(
              child: Text('📸 Suggestion miniature', style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _ActionBtn(colorScheme: colorScheme, icon: '💾', label: 'Sauvegarder')),
              const SizedBox(width: 10),
              Expanded(child: _ActionBtn(colorScheme: colorScheme, icon: '🔄', label: 'Variantes')),
              const SizedBox(width: 10),
              Expanded(child: _ActionBtn(colorScheme: colorScheme, icon: '📤', label: 'Partager')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final ColorScheme colorScheme;
  final String icon;
  final String label;

  const _ActionBtn({required this.colorScheme, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
