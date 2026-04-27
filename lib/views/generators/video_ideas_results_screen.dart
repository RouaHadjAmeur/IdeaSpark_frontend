import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/video_generator_models.dart';
import 'components/video_result_card.dart';
import '../../view_models/video_idea_generator_view_model.dart';

class VideoIdeasResultsScreen extends StatelessWidget {
  final VideoRequest? request;
  final bool useRemoteGeneration;

  const VideoIdeasResultsScreen({
    super.key,
    this.request,
    this.useRemoteGeneration = true,
  });

  @override
  Widget build(BuildContext context) {
    // We use the global provider but trigger generation here if needed
    final viewModel = context.read<VideoIdeaGeneratorViewModel>();
    
    // Check if we need to generate (e.g. if current ideas are from a different request)
    if (request != null && (viewModel.lastRequest == null || viewModel.ideas.isEmpty)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.generateIdeas(request!, useRemote: useRemoteGeneration);
        });
    }

    return _VideoIdeasResultsView(useRemoteGeneration: useRemoteGeneration);
  }
}

class _VideoIdeasResultsView extends StatelessWidget {
  final bool useRemoteGeneration;

  const _VideoIdeasResultsView({required this.useRemoteGeneration});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<VideoIdeaGeneratorViewModel>(
      builder: (context, viewModel, _) {
        // Loading state
        if (viewModel.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Error state
        if (viewModel.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erreur',
                        style: GoogleFonts.syne(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        viewModel.errorMessage ?? 'Une erreur est survenue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => viewModel.regenerateIdeas(useRemote: useRemoteGeneration),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Retour'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Empty state
        if (!viewModel.hasIdeas) {
          return Scaffold(
            appBar: AppBar(title: const Text("Aucune idée")),
            body: const Center(
              child: Text("Aucune idée générée. Veuillez réessayer."),
            ),
          );
        }

        // Success state
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context,
                    colorScheme,
                    '${viewModel.ideaCount} Idées Générées',
                  ),
                  const SizedBox(height: 20),

                  // Display all idea cards with full action panel
                  ...viewModel.ideas.map(
                    (idea) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: VideoResultCard(
                        idea: idea,
                        request: viewModel.lastRequest,
                        isFavorite: idea.isFavorite,
                        onFavoriteToggle: () =>
                            viewModel.toggleFavoriteStatus(idea.id),
                        onRegenerate: () => context.replace('/loading', extra: {
                          'redirectTo': '/video-ideas-results',
                          'data': viewModel.lastRequest,
                          'useRemoteGeneration': useRemoteGeneration,
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, ColorScheme colorScheme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
