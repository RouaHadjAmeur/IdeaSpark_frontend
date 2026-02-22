import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_theme.dart';

class ProductIdeaResultScreen extends StatelessWidget {
  const ProductIdeaResultScreen({super.key});

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
                  Expanded(
                    child: Text(
                      'Idée Produit',
                      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.bookmark_outline_rounded, color: colorScheme.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: Text('📱', style: TextStyle(fontSize: 48))),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'FocusFlow - App Anti-Procrastination',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '📝 Description'),
                    const SizedBox(height: 8),
                    Text(
                      'Application mobile combinant Pomodoro intelligent, blocage de distractions, et gamification. L\'IA analyse les patterns de productivité et adapte les sessions. Intégration avec calendriers et outils (Notion, Todoist).',
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '🎯 Problème résolu'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: colorScheme.error, width: 3)),
                      ),
                      child: Text(
                        'Les professionnels et étudiants perdent 2-4h par jour en distractions. Les apps existantes sont soit trop rigides soit inefficaces.',
                        style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '⚙️ Caractéristiques principales'),
                    const SizedBox(height: 8),
                    _FeatureRow(colorScheme: colorScheme, icon: '✨', text: 'IA qui ajuste durée des sessions selon énergie'),
                    _FeatureRow(colorScheme: colorScheme, icon: '🔒', text: 'Blocage contextuel apps (réseaux en pause uniquement)'),
                    _FeatureRow(colorScheme: colorScheme, icon: '🏆', text: 'Système de points et défis hebdomadaires'),
                    _FeatureRow(colorScheme: colorScheme, icon: '📊', text: 'Analytics: temps focus, distractions évitées'),
                    _FeatureRow(colorScheme: colorScheme, icon: '🔗', text: 'Intégrations calendrier Google, Notion, Slack'),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '💵 Prix suggéré'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Freemium', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)), Text('0€', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface))]),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Premium (mensuel)', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)), Text('7.99€', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.primary))]),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Premium (annuel)', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)), Text('59.99€', style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.primary))]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '📈 Potentiel de marché'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: 0.85, minHeight: 6, backgroundColor: colorScheme.surfaceContainerHighest, valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('8.5/10', style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Marché productivité: \$50B+, apps focus: croissance 40%/an', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    _Label(colorScheme: colorScheme, text: '🔍 Analyse concurrents'),
                    const SizedBox(height: 8),
                    _CompetitorCard(colorScheme: colorScheme, name: 'Forest', detail: '4.5M users', desc: 'Gamification forte mais manque IA et intégrations pro'),
                    _CompetitorCard(colorScheme: colorScheme, name: 'Freedom', detail: '2M users', desc: 'Blocage puissant mais UX complexe'),
                    _CompetitorCard(colorScheme: colorScheme, name: 'Focusmate', detail: '500K users', desc: 'Co-working virtuel excellent mais manque features techniques'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save_rounded, size: 18), label: const Text('Sauvegarder'), style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant)))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Variantes'), style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant)))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share_rounded, size: 18), label: const Text('Partager'), style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant)))),
                      ],
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

class _Label extends StatelessWidget {
  final ColorScheme colorScheme;
  final String text;

  const _Label({required this.colorScheme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant));
  }
}

class _FeatureRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final String icon;
  final String text;

  const _FeatureRow({required this.colorScheme, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.5))),
        ],
      ),
    );
  }
}

class _CompetitorCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final String name;
  final String detail;
  final String desc;

  const _CompetitorCard({required this.colorScheme, required this.name, required this.detail, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              Text(detail, style: TextStyle(fontSize: 12, color: context.accentColor)),
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
