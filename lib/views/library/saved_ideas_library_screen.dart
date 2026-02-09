import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';

class SavedIdeasLibraryScreen extends StatefulWidget {
  const SavedIdeasLibraryScreen({super.key});

  @override
  State<SavedIdeasLibraryScreen> createState() => _SavedIdeasLibraryScreenState();
}

class _SavedIdeasLibraryScreenState extends State<SavedIdeasLibraryScreen> {
  int _tabIndex = 0;
  String _typeFilterKey = 'all_types';

  static const _tabKeys = ['all', 'in_progress', 'done_count'];
  static const _typeFilterKeys = ['all_types', 'type_video', 'type_business', 'type_product', 'type_slogans'];

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
                    icon: Icon(Icons.menu_rounded, color: colorScheme.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('my_ideas'),
                      style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.search_rounded, color: colorScheme.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: List.generate(_tabKeys.length, (i) {
                  final active = _tabIndex == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _tabKeys.length - 1 ? 8 : 0),
                      child: Material(
                        color: active ? colorScheme.primary.withValues(alpha: 0.2) : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => setState(() => _tabIndex = i),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: active ? colorScheme.primary : colorScheme.outlineVariant),
                            ),
                            child: Center(
                              child: Text(
                                context.tr(_tabKeys[i]),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: active ? colorScheme.primary : colorScheme.onSurface),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _typeFilterKeys.map((key) {
                    final active = key == _typeFilterKey;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(context.tr(key)),
                        selected: active,
                        onSelected: (_) => setState(() => _typeFilterKey = key),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(fontSize: 13, color: active ? Colors.white : colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              _SavedItemCard(
                colorScheme: colorScheme,
                type: 'IDÉE VIDÉO',
                title: '5 Exercices pour Perdre du Ventre...',
                status: 'En cours',
                statusStyle: 'progress',
                meta: 'Fitness • YouTube • 3-5 min • Score: 9.2/10',
                footer: '📅 Créée le 2 Février • 📝 3 notes • 🏷️ #fitness #santé',
              ),
              const SizedBox(height: 12),
              _SavedItemCard(
                colorScheme: colorScheme,
                type: 'IDÉE BUSINESS',
                title: 'Newsletter Premium Niche',
                status: 'Nouvelle',
                statusStyle: 'new',
                meta: 'Marketing • En ligne • Budget: <5K€ • Revenus: 3-8K€/an',
                footer: '📅 Créée le 4 Février • 📝 1 note • 🏷️ #newsletter #contenu',
              ),
              const SizedBox(height: 12),
              _SavedItemCard(
                colorScheme: colorScheme,
                type: 'PRODUIT DIGITAL',
                title: 'FocusFlow - App Anti-Procrastination',
                status: 'Réalisée ✓',
                statusStyle: 'done',
                meta: 'Application • B2C • Prix: 7.99€/mois • Potentiel: 8.5/10',
                footer: '📅 Créée le 29 Janvier • 📝 8 notes • 🏷️ #app #productivité',
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(context.tr('ideas_saved_count'), style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _SavedItemCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final String type;
  final String title;
  final String status;
  final String statusStyle; // new, progress, done
  final String meta;
  final String footer;

  const _SavedItemCard({
    required this.colorScheme,
    required this.type,
    required this.title,
    required this.status,
    required this.statusStyle,
    required this.meta,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColor;
    final success = context.successColor;
    Color statusBg;
    Color statusFg;
    switch (statusStyle) {
      case 'new':
        statusBg = colorScheme.primary.withValues(alpha: 0.2);
        statusFg = colorScheme.primary;
        break;
      case 'progress':
        statusBg = accent.withValues(alpha: 0.2);
        statusFg = accent;
        break;
      case 'done':
        statusBg = success.withValues(alpha: 0.2);
        statusFg = success;
        break;
      default:
        statusBg = colorScheme.surfaceContainerHighest;
        statusFg = colorScheme.onSurface;
    }
    return Container(
      padding: const EdgeInsets.all(16),
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
                    Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                    const SizedBox(height: 6),
                    Text(title, style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusFg)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(meta, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Text(footer, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 10)), child: Text(context.tr('view')))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 10)), child: Text(context.tr('edit')))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: colorScheme.onSurface, side: BorderSide(color: colorScheme.outlineVariant), padding: const EdgeInsets.symmetric(vertical: 10)), child: Text(context.tr('share_action')))),
            ],
          ),
        ],
      ),
    );
  }
}
