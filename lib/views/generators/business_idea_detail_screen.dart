import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_theme.dart';

class BusinessIdeaDetailScreen extends StatelessWidget {
  const BusinessIdeaDetailScreen({super.key});

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
                      'Détails de l\'Idée',
                      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.star_outline_rounded, color: colorScheme.onSurface),
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
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(
                      'Newsletter Premium Niche',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text('Marketing de Contenu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    _SectionTitle(colorScheme: colorScheme, title: '📝 Description du modèle'),
                    const SizedBox(height: 8),
                    Text(
                      'Création d\'une newsletter spécialisée sur un sujet de niche (cryptomonnaies, investissement immobilier, parentalité consciente, etc.) avec un modèle freemium. Version gratuite pour attirer l\'audience, version premium (5-20€/mois) avec analyses approfondies, outils exclusifs et communauté privée.\n\nLe modèle repose sur la création régulière de contenu de qualité (2-3 fois/semaine) et l\'automatisation via des outils comme Substack, ConvertKit ou Ghost.',
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(colorScheme: colorScheme, title: '🎯 Marché cible'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['Professionnels 30-45 ans', 'Revenus moyens-élevés', 'Passionnés du sujet', 'Actifs sur LinkedIn']
                          .map((c) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: colorScheme.primary),
                                ),
                                child: Text(c, style: TextStyle(fontSize: 13, color: colorScheme.primary)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(colorScheme: colorScheme, title: '✨ Proposition de valeur unique'),
                    const SizedBox(height: 8),
                    Text(
                      'Synthèse ultra-qualitative de l\'information dispersée sur le web, économisant 5-10h de recherche par semaine aux abonnés. Analyses actionables et sans bullshit.',
                      style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(colorScheme: colorScheme, title: '💰 Revenus potentiels'),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _RevenueBlock(colorScheme: colorScheme, label: 'Mois 6', value: '500-1.5K€'),
                        Text('→', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        _RevenueBlock(colorScheme: colorScheme, label: 'Année 1', value: '3-8K€'),
                        Text('→', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        _RevenueBlock(colorScheme: colorScheme, label: 'Année 2', value: '10-30K€'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Basé sur 200-500 abonnés premium à 15€/mois', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    _SectionTitle(colorScheme: colorScheme, title: '📊 Canaux de vente'),
                    const SizedBox(height: 8),
                    _NumberedItem(colorScheme: colorScheme, n: 1, text: 'LinkedIn pour le contenu gratuit et l\'acquisition'),
                    _NumberedItem(colorScheme: colorScheme, n: 2, text: 'SEO via articles de blog invités'),
                    _NumberedItem(colorScheme: colorScheme, n: 3, text: 'Podcasts et webinaires comme invité expert'),
                    _NumberedItem(colorScheme: colorScheme, n: 4, text: 'Partenariats avec influenceurs de la niche'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Niveau de difficulté', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.accentColor)),
                              Text('Intermédiaire', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SectionTitle(colorScheme: colorScheme, title: '🚀 5 Premières actions'),
                    const SizedBox(height: 8),
                    _ActionStep(colorScheme: colorScheme, range: 'Jour 1-7', text: 'Valider la niche via Google Trends et Reddit, identifier 3 concurrents'),
                    _ActionStep(colorScheme: colorScheme, range: 'Jour 8-14', text: 'Créer compte Substack/ConvertKit, designer template newsletter'),
                    _ActionStep(colorScheme: colorScheme, range: 'Jour 15-30', text: 'Publier 4 éditions gratuites, construire liste email initiale (objectif: 100 inscrits)'),
                    _ActionStep(colorScheme: colorScheme, range: 'Mois 2', text: 'Lancer version premium avec bonus exclusifs pour early adopters'),
                    _ActionStep(colorScheme: colorScheme, range: 'Mois 3-6', text: 'Optimiser conversion gratuit→payant, tester prix et offres groupées'),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save_rounded, size: 18), label: const Text('Sauvegarder'), style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant)))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf_rounded, size: 18), label: const Text('Export PDF'), style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant)))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share_rounded, size: 18), label: const Text('Partager'), style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant)))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 18)),
                  child: const Text('🔄 Voir d\'autres idées similaires'),
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

class _SectionTitle extends StatelessWidget {
  final ColorScheme colorScheme;
  final String title;

  const _SectionTitle({required this.colorScheme, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant));
  }
}

class _RevenueBlock extends StatelessWidget {
  final ColorScheme colorScheme;
  final String label;
  final String value;

  const _RevenueBlock({required this.colorScheme, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        Text(value, style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.primary)),
      ],
    );
  }
}

class _NumberedItem extends StatelessWidget {
  final ColorScheme colorScheme;
  final int n;
  final String text;

  const _NumberedItem({required this.colorScheme, required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.5))),
        ],
      ),
    );
  }
}

class _ActionStep extends StatelessWidget {
  final ColorScheme colorScheme;
  final String range;
  final String text;

  const _ActionStep({required this.colorScheme, required this.range, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: context.successColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text('✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.successColor))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.5),
                children: [
                  TextSpan(text: '$range: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
