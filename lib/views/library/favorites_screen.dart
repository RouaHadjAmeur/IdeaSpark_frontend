import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/services/favorites_storage_service.dart';

import 'package:ideaspark/models/slogan_model.dart';

import 'package:ideaspark/view_models/video_idea_generator_view_model.dart';
import 'package:ideaspark/view_models/slogan_view_model.dart';
import 'package:ideaspark/views/generators/components/video_result_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedFilter = 'Tous';

  bool _isLoadingSlogans = false;

  @override
  void initState() {
    super.initState();

    // Load video and slogan favorites (from ViewModels)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoIdeaGeneratorViewModel>().fetchFavorites();
      context.read<SloganViewModel>().fetchHistory();
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<SloganViewModel>().fetchHistory(),
      context.read<VideoIdeaGeneratorViewModel>().fetchFavorites(),
    ]);
  }

  bool _showSlogans() => _selectedFilter == 'Tous' || _selectedFilter == 'Slogans';
  bool _showVideos() => _selectedFilter == 'Tous' || _selectedFilter == 'Video';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<VideoIdeaGeneratorViewModel, SloganViewModel>(
      builder: (context, videoVm, sloganVm, _) {
        final videoFavorites = videoVm.favorites;
        final favoriteSlogans = sloganVm.slogans.where((s) => s.isFavorite).toList();
        final isLoadingSlogans = sloganVm.isLoading;

        return RefreshIndicator(
          onRefresh: _refreshAll,
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
                const SizedBox(height: 16),

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: context.tr('filter_all'),
                        selected: _selectedFilter == 'Tous',
                        colorScheme: colorScheme,
                        onTap: () => setState(() => _selectedFilter = 'Tous'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Slogans',
                        selected: _selectedFilter == 'Slogans',
                        colorScheme: colorScheme,
                        onTap: () => setState(() => _selectedFilter = 'Slogans'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: context.tr('type_video'),
                        selected: _selectedFilter == 'Video',
                        colorScheme: colorScheme,
                        onTap: () => setState(() => _selectedFilter = 'Video'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // =========================
                // SLOGANS FAVORITES SECTION
                // =========================
                if (_showSlogans()) ...[
                  Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        'Slogans Favoris (${favoriteSlogans.length})',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (isLoadingSlogans)
                    const Center(child: Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    ))
                  else if (favoriteSlogans.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('⭐', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun slogan favori',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Générez des slogans et marquez vos préférés',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ), 
                      ),
                    )
                  else    
                    ...favoriteSlogans.map((slogan) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _SloganCard(
                            slogan: slogan,
                            colorScheme: colorScheme,
                            onRemove: () async {
                              await sloganVm.toggleFavorite(slogan.id);
                            },
                            onCopy: () {
                              Clipboard.setData(ClipboardData(text: slogan.slogan));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Copié: ${slogan.slogan.substring(0, slogan.slogan.length > 25 ? 25 : slogan.slogan.length)}...',
                                        ),
                                      ),
                                    ],
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                        )),
                  const SizedBox(height: 24),
                ],

                // =========================
                // VIDEO FAVORITES SECTION
                // =========================
                if (_showVideos()) ...[
                  Row(
                    children: [
                      const Text('🎬', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '${context.tr('type_video')} Favoris (${videoFavorites.length})',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (videoVm.isLoading && videoFavorites.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (videoFavorites.isEmpty)
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
                    ...videoFavorites.map((idea) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: VideoResultCard(
                            idea: idea,
                            isFavorite: idea.isFavorite,
                            onFavoriteToggle: () =>
                                videoVm.toggleFavoriteStatus(idea.id),
                          ),
                        )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    );
  }
}

// --------------------
// SLOGAN CARD (same as yours)
// --------------------
class _SloganCard extends StatelessWidget {
  final SloganModel slogan;
  final ColorScheme colorScheme;
  final VoidCallback onRemove;
  final VoidCallback onCopy;

  const _SloganCard({
    required this.slogan,
    required this.colorScheme,
    required this.onRemove,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.primaryContainer.withOpacity(0.3),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Slogan',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${slogan.memorabilityScore.toStringAsFixed(1)}/10',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              slogan.slogan,
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              slogan.explanation,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onRemove,
                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: colorScheme.error),
                  label: Text(
                    context.tr('remove'),
                    style: TextStyle(fontSize: 12, color: colorScheme.error),
                  ),
                ),
                TextButton.icon(
                  onPressed: onCopy,
                  icon: Icon(Icons.content_copy_rounded, size: 16, color: colorScheme.primary),
                  label: Text(
                    'Copier',
                    style: TextStyle(fontSize: 12, color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

