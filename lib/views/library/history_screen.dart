import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/video_idea_generator_view_model.dart';
import 'package:ideaspark/views/generators/components/video_result_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoIdeaGeneratorViewModel>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<VideoIdeaGeneratorViewModel>(
      builder: (context, viewModel, _) {
        final history = viewModel.history;

        return RefreshIndicator(
          onRefresh: () => viewModel.fetchHistory(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('history_title'),
                  style: GoogleFonts.syne(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                if (viewModel.isLoading && history.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (history.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Text('📋', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun historique pour le moment.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...history.map(
                    (idea) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: VideoResultCard(
                        idea: idea,
                        isFavorite: idea.isFavorite,
                        onFavoriteToggle: () =>
                            viewModel.toggleFavoriteStatus(idea.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
