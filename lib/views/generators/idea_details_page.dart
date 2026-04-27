import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_localizations.dart';
import '../../models/video_generator_models.dart';
import '../../view_models/video_idea_generator_view_model.dart';

class IdeaDetailsPage extends StatefulWidget {
  final String ideaId;

  const IdeaDetailsPage({super.key, required this.ideaId});

  @override
  State<IdeaDetailsPage> createState() => _IdeaDetailsPageState();
}

class _IdeaDetailsPageState extends State<IdeaDetailsPage> {
  final TextEditingController _refineController = TextEditingController();

  @override
  void dispose() {
    _refineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Consumer<VideoIdeaGeneratorViewModel>(
      builder: (context, viewModel, child) {
        final idea = viewModel.getIdeaById(widget.ideaId);
        
        if (idea == null) {
          return Scaffold(body: Center(child: Text(context.tr('idea_not_found'))));
        }

        final currentVersion = idea.currentVersion;
        final remainingTries = viewModel.getRemainingTries(idea.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(currentVersion.title),
            actions: [
               IconButton(
                onPressed: () => viewModel.toggleFavoriteStatus(idea.id),
                icon: Icon(
                  idea.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: idea.isFavorite ? Colors.red : null,
                ),
                tooltip: context.tr('favorite'),
              ),
               if (!idea.isApproved)
                TextButton.icon(
                  onPressed: () => viewModel.approveVersion(idea.id, idea.currentVersionIndex),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  label: Text(context.tr('approve'), style: const TextStyle(color: Colors.green)),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Icon(Icons.verified, color: Colors.blue),
                ),
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    if (idea.productImageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          idea.productImageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Version Selector
                    if (idea.versions.length > 1) ...[
                      _buildSectionHeader(context.tr('version_history')),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(idea.versions.length, (index) {
                            final isCurrent = index == idea.currentVersionIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text("${context.tr('version')} ${index + 1}"),
                                selected: isCurrent,
                                onSelected: (selected) {
                                  if (selected) viewModel.switchVersionLocal(idea.id, index);
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildSectionHeader("HOOK (0-3s)"),
                    _buildHighlightBox(currentVersion.hook, colorScheme.primaryContainer.withValues(alpha: 0.3)),

                    const SizedBox(height: 16),
                    _buildSectionHeader(context.tr('execution_plan').toUpperCase()),
                    ...currentVersion.scenes.map((scene) => _buildSceneCard(scene, colorScheme, context)),

                    const SizedBox(height: 16),
                    if (currentVersion.suggestedLocations.isNotEmpty) ...[
                      _buildSectionHeader(context.tr('suggested_locations')),
                      ...currentVersion.suggestedLocations.map((loc) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.location_on),
                          title: Text(loc),
                        ),
                      )),
                      const SizedBox(height: 16),
                    ],

                    _buildSectionHeader("CALL TO ACTION"),
                    _buildHighlightBox(currentVersion.cta, colorScheme.secondaryContainer.withValues(alpha: 0.3)),

                    const SizedBox(height: 16),
                    _buildSectionHeader(context.tr('caption').toUpperCase()),
                    _buildHighlightBox(
                      "${currentVersion.caption}\n\n${currentVersion.hashtags.join(' ')}",
                      colorScheme.surfaceContainerHighest
                    ),

                    const SizedBox(height: 16),
                    _buildSectionHeader(context.tr('filming_notes').toUpperCase()),
                    Text("• ${currentVersion.filmingNotes}", style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              
              // Refinement Input Area
              if (!idea.isApproved)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (viewModel.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: LinearProgressIndicator(),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _refineController,
                                decoration: InputDecoration(
                                  hintText: remainingTries > 0 
                                    ? "${context.tr('refine_hint')} ($remainingTries ${context.tr('remaining_tries')})"
                                    : context.tr('limit_reached'),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                enabled: !viewModel.isLoading && remainingTries > 0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: (viewModel.isLoading || remainingTries <= 0) 
                                ? null 
                                : () {
                                    if (_refineController.text.isNotEmpty) {
                                      viewModel.refineIdea(idea.id, _refineController.text);
                                      _refineController.clear();
                                    }
                                  },
                              icon: const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: Colors.grey,
          letterSpacing: 1.2
        ),
      ),
    );
  }

  Widget _buildHighlightBox(String text, Color color) {
      return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)),
      );
  }

  Widget _buildSceneCard(VideoScene scene, ColorScheme colorScheme, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                        "${scene.startSec}-${scene.endSec}s", 
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                    ),
                ),
                const SizedBox(width: 12),
                Text(
                    scene.shotType.name.toUpperCase(), 
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: colorScheme.secondary)
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(scene.description, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            const Divider(height: 24),
            if (scene.onScreenText.isNotEmpty) ...[
                _buildSubtleInfo("TEXTE ÉCRAN", scene.onScreenText, Icons.text_fields),
                const SizedBox(height: 8),
            ],
            _buildSubtleInfo("AUDIO / VOIX-OFF", scene.voiceOver, Icons.mic),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtleInfo(String label, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
