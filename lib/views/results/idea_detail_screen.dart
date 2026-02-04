import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/widgets/variation_bottom_sheet.dart';

class IdeaDetailScreen extends StatelessWidget {
  final String id;

  const IdeaDetailScreen({super.key, required this.id});

  static const _steps = [
    'Filme ta routine matinale actuelle (désordre, rush)',
    'Filme la version améliorée (organisée, calme)',
    'Ajoute des transitions rapides entre les deux',
    'Musique motivante trending sur TikTok',
    'CTA: "Quelle routine veux-tu transformer?"',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTextStyle(
      style: TextStyle(decoration: TextDecoration.none),
      child: SingleChildScrollView(
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
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Morning Routine Transformation',
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.transparent,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.share_rounded, size: 18, color: colorScheme.primary),
              label: Text(context.tr('share'), style: TextStyle(color: colorScheme.primary, decoration: TextDecoration.none)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outlineVariant),
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _DetailSection(
            title: context.tr('why_it_works'),
            colorScheme: colorScheme,
            content: context.tr('why_content'),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: context.tr('execution_plan'),
            colorScheme: colorScheme,
            child: Column(
              children: _steps.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.6, decoration: TextDecoration.none),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: context.tr('suggested_hashtags'),
            colorScheme: colorScheme,
            content: '#morningroutine #productivity #students #transformation #motivation #studytok #thatgirl',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(context.tr('save_idea'), style: TextStyle(decoration: TextDecoration.none, color: colorScheme.onPrimary)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (ctx) => const VariationBottomSheet(),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.outlineVariant),
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(context.tr('create_variations'), style: TextStyle(decoration: TextDecoration.none, color: colorScheme.primary)),
            ),
          ),
        ],
      ),
    ));
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String? content;
  final Widget? child;
  final ColorScheme colorScheme;

  const _DetailSection({required this.title, required this.colorScheme, this.content, this.child});

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
          Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          if (content != null)
            Text(
              content!,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.6, decoration: TextDecoration.none),
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
