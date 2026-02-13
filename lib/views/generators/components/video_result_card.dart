import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_localizations.dart';
import '../../../models/video_generator_models.dart';
import '../../../view_models/video_idea_generator_view_model.dart';
import 'package:provider/provider.dart';
import '../idea_details_page.dart';

/// Reusable video result card component
/// Displays a video idea with actions (save, copy, view details)
class VideoResultCard extends StatelessWidget {
  final VideoIdea idea;
  final VoidCallback? onSaved;

  const VideoResultCard({
    super.key,
    required this.idea,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          // Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  idea.title,
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Caption
          Text(
            idea.caption,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 12),

          // Scenes preview
          Text(
            'Structure:',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...idea.scenes.take(3).map((scene) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${scene.startSec}-${scene.endSec}s',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scene.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (idea.scenes.length > 3)
            Text(
              "... (${idea.scenes.length - 3} plus)",
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),

          const SizedBox(height: 16),

          // Hook preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOOK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  idea.hook,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Hashtags
          Text(
            'Hashtags:',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: idea.hashtags.take(5).map((h) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  h,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  colorScheme: colorScheme,
                  icon: idea.isFavorite ? Icons.favorite : Icons.favorite_border,
                  label: idea.isFavorite ? context.tr('favorited') : context.tr('favorite'),
                  onTap: () {
                    context.read<VideoIdeaGeneratorViewModel>().toggleFavoriteStatus(idea.id);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  colorScheme: colorScheme,
                  icon: Icons.copy,
                  label: 'Copier',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: idea.script));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Script copié !")),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  colorScheme: colorScheme,
                  icon: Icons.visibility,
                  label: 'Détails',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => IdeaDetailsPage(ideaId: idea.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final ColorScheme colorScheme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.colorScheme,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
