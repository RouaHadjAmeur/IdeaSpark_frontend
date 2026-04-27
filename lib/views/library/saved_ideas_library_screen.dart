import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/models/video_generator_models.dart';
import 'package:ideaspark/models/slogan_model.dart';
import 'package:ideaspark/view_models/video_idea_generator_view_model.dart';
import 'package:ideaspark/view_models/slogan_view_model.dart';
import 'package:ideaspark/views/generators/components/video_result_card.dart';

class SavedIdeasLibraryScreen extends StatefulWidget {
  const SavedIdeasLibraryScreen({super.key});

  @override
  State<SavedIdeasLibraryScreen> createState() =>
      _SavedIdeasLibraryScreenState();
}

class _SavedIdeasLibraryScreenState extends State<SavedIdeasLibraryScreen> {
  int _tabIndex = 0; // 0=All, 1=In Progress (not approved), 2=Done (approved)
  String _typeFilter = 'all_types'; // all_types | type_video | type_slogans

  static const _tabKeys = ['all', 'in_progress', 'done_count'];
  static const _typeFilterKeys = ['all_types', 'type_video', 'type_slogans'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoIdeaGeneratorViewModel>().fetchFavorites();
      context.read<SloganViewModel>().fetchHistory();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<VideoIdeaGeneratorViewModel>().fetchFavorites(),
      context.read<SloganViewModel>().fetchHistory(),
    ]);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<VideoIdeaGeneratorViewModel, SloganViewModel>(
      builder: (context, videoVm, sloganVm, _) {
        // ─── Source data ───────────────────────────────────────────────────
        final allVideos = videoVm.favorites;
        final allSlogans =
            sloganVm.slogans.where((s) => s.isFavorite).toList();

        // ─── Tab filter ────────────────────────────────────────────────────
        // Tab 0 = All, Tab 1 = In Progress (video not approved), Tab 2 = Done
        List<VideoIdea> filteredVideos;
        List<SloganModel> filteredSlogans;

        switch (_tabIndex) {
          case 1: // In Progress → only non-approved video ideas
            filteredVideos =
                allVideos.where((v) => !v.isApproved).toList();
            filteredSlogans = [];
            break;
          case 2: // Done → approved videos + all favorite slogans
            filteredVideos =
                allVideos.where((v) => v.isApproved).toList();
            filteredSlogans = allSlogans;
            break;
          default: // All
            filteredVideos = allVideos;
            filteredSlogans = allSlogans;
        }

        // ─── Type filter ───────────────────────────────────────────────────
        final showVideo =
            _typeFilter == 'all_types' || _typeFilter == 'type_video';
        final showSlogans =
            _typeFilter == 'all_types' || _typeFilter == 'type_slogans';

        final displayVideos = showVideo ? filteredVideos : <VideoIdea>[];
        final displaySlogans =
            showSlogans ? filteredSlogans : <SloganModel>[];

        final totalCount = displayVideos.length + displaySlogans.length;
        final isLoading = (videoVm.isLoading || sloganVm.isLoading) &&
            allVideos.isEmpty &&
            allSlogans.isEmpty;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ─── Header ────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('my_ideas'),
                            style: GoogleFonts.syne(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface),
                          ),
                        ),
                        if (videoVm.isLoading || sloganVm.isLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ─── Tabs ──────────────────────────────────────────────
                    Row(
                      children: List.generate(_tabKeys.length, (i) {
                        final active = _tabIndex == i;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: i < _tabKeys.length - 1 ? 8 : 0),
                            child: Material(
                              color: active
                                  ? colorScheme.primary
                                      .withValues(alpha: 0.12)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _tabIndex = i),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                        color: active
                                            ? colorScheme.primary
                                            : colorScheme.outlineVariant),
                                  ),
                                  child: Center(
                                    child: Text(
                                      context.tr(_tabKeys[i]),
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: active
                                              ? colorScheme.primary
                                              : colorScheme.onSurface),
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

                    // ─── Type chips ────────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _typeFilterKeys.map((key) {
                          final active = key == _typeFilter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(context.tr(key)),
                              selected: active,
                              onSelected: (_) =>
                                  setState(() => _typeFilter = key),
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              selectedColor: colorScheme.primary,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                  fontSize: 13,
                                  color: active
                                      ? Colors.white
                                      : colorScheme.onSurface),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ─── Content ───────────────────────────────────────────
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (totalCount == 0)
                      _buildEmptyState(context, colorScheme)
                    else ...[
                      // Video idea cards
                      ...displayVideos.map((idea) => Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: VideoResultCard(
                              idea: idea,
                              isFavorite: idea.isFavorite,
                              onFavoriteToggle: () =>
                                  videoVm.toggleFavoriteStatus(idea.id),
                            ),
                          )),

                      // Slogan cards
                      ...displaySlogans.map((slogan) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SloganIdeaCard(
                              slogan: slogan,
                              colorScheme: colorScheme,
                              dateStr: _formatDate(slogan.createdAt),
                              onRemove: () =>
                                  sloganVm.toggleFavorite(slogan.id),
                              onCopy: () {
                                Clipboard.setData(
                                    ClipboardData(text: slogan.slogan));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Copié : "${slogan.slogan.length > 30 ? "${slogan.slogan.substring(0, 30)}…" : slogan.slogan}"'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            ),
                          )),
                    ],

                    // ─── Footer count ──────────────────────────────────────
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        '$totalCount ${context.tr('ideas_saved_count')}',
                        style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const Text('📚', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Aucune idée sauvegardée',
              style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Générez des idées et appuyez sur ❤️ pour les\nsauvegarder depuis les outils rapides.',
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slogan Idea Card ────────────────────────────────────────────────────────

class _SloganIdeaCard extends StatelessWidget {
  final SloganModel slogan;
  final ColorScheme colorScheme;
  final String dateStr;
  final VoidCallback onRemove;
  final VoidCallback onCopy;

  const _SloganIdeaCard({
    required this.slogan,
    required this.colorScheme,
    required this.dateStr,
    required this.onRemove,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final success = context.successColor;
    final isHighScore = slogan.memorabilityScore >= 8.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isHighScore
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + Score row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLOGAN · ${slogan.category.toUpperCase()}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slogan.slogan,
                      style: GoogleFonts.syne(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isHighScore
                      ? success.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        size: 12,
                        color: isHighScore ? success : colorScheme.primary),
                    const SizedBox(width: 3),
                    Text(
                      '${slogan.memorabilityScore.toStringAsFixed(1)}/10',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              isHighScore ? success : colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Explanation
          Text(
            slogan.explanation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4),
          ),
          const SizedBox(height: 8),
          // Date
          Text(
            '📅 ${context.tr('created_on')} $dateStr',
            style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 12),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: Icon(Icons.content_copy_rounded,
                      size: 14, color: colorScheme.primary),
                  label: Text('Copier',
                      style: TextStyle(color: colorScheme.primary)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.outlineVariant),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: Icon(Icons.favorite,
                      size: 14, color: colorScheme.error),
                  label: Text(context.tr('remove'),
                      style: TextStyle(color: colorScheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
