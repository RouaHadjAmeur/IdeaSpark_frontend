import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/models/video_generator_models.dart';
import 'package:ideaspark/view_models/video_idea_generator_view_model.dart';
import 'package:ideaspark/views/generators/idea_details_page.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoIdeaGeneratorViewModel>().fetchFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<VideoIdeaGeneratorViewModel>(
      builder: (context, viewModel, child) {
        final favorites = viewModel.favorites;
        
        return RefreshIndicator(
          onRefresh: () => viewModel.fetchFavorites(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 24),
                
                if (viewModel.isLoading && favorites.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (favorites.isEmpty)
                   Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        "Aucun favori pour le moment.",
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...favorites.map((idea) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _IdeaCard(
                      idea: idea,
                      colorScheme: colorScheme,
                      onTap: () {
                         Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => IdeaDetailsPage(ideaId: idea.id),
                          ),
                        );
                      },
                      onToggleFavorite: () => viewModel.toggleFavoriteStatus(idea.id),
                    ),
                  )),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _IdeaCard extends StatelessWidget {
  final VideoIdea idea;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _IdeaCard({
    required this.idea, 
    required this.colorScheme, 
    required this.onTap,
    required this.onToggleFavorite,
  });

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
                      context.tr('type_video'),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                   if (idea.isApproved)
                    const Icon(Icons.verified, color: Colors.blue, size: 16),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                idea.currentVersion.title,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                idea.currentVersion.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onToggleFavorite,
                    icon: Icon(Icons.favorite, size: 16, color: colorScheme.primary),
                    label: Text(context.tr('remove'), style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // Basic sharing logic
                    },
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
