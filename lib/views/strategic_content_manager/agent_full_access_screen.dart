import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../services/video_download_service.dart';
import '../../view_models/agent_full_access_view_model.dart';
import '../../models/video_generator_models.dart';
import '../../models/product_idea_model.dart';
import '../../models/video.dart';
import 'package:ideaspark/models/slogan_model.dart';
import 'package:ideaspark/views/generators/components/video_result_card.dart';

class AgentFullAccessScreen extends StatefulWidget {
  const AgentFullAccessScreen({super.key});

  @override
  State<AgentFullAccessScreen> createState() => _AgentFullAccessScreenState();
}

class _AgentFullAccessScreenState extends State<AgentFullAccessScreen> {
  final TextEditingController _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _processPrompt(AgentFullAccessViewModel viewModel) async {
    if (_promptController.text.isEmpty) return;
    await viewModel.processFullAccess(_promptController.text);
  }

  void _showShareDialog(BuildContext context, ColorScheme cs, Video video) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Partager sur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildShareButton(
                    icon: '🎵',
                    label: 'TikTok',
                    onTap: () => _handleShareAction(context, 'TikTok', video),
                  ),
                  _buildShareButton(
                    icon: '📘',
                    label: 'Facebook',
                    onTap: () => _handleShareAction(context, 'Facebook', video),
                  ),
                  _buildShareButton(
                    icon: '📷',
                    label: 'Instagram',
                    onTap: () => _handleShareAction(context, 'Instagram', video),
                  ),
                  _buildShareButton(
                    icon: '𝕏',
                    label: 'Twitter',
                    onTap: () => _handleShareAction(context, 'Twitter', video),
                  ),
                  _buildShareButton(
                    icon: '▶️',
                    label: 'YouTube',
                    onTap: () => _handleShareAction(context, 'YouTube', video),
                  ),
                  _buildShareButton(
                    icon: '📤',
                    label: 'Partager',
                    onTap: () => _handleShareAction(context, 'Partager', video),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShareAction(BuildContext context, String platform, Video video) async {
    Navigator.pop(context);
    final cs = Theme.of(context).colorScheme;

    if (platform == 'Twitter' || platform == 'Partager') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform...'),
          backgroundColor: Colors.black,
        ),
      );
      await VideoDownloadService.shareVideo(video.videoUrl);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement pour $platform...'),
        backgroundColor: platform == 'TikTok' ? Colors.black :
                       platform == 'Facebook' ? Colors.blue :
                       platform == 'Instagram' ? Colors.pink : Colors.red,
      ),
    );

    final success = await VideoDownloadService.saveToGallery(video.videoUrl);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Vidéo sauvegardée! Ouvre $platform et crée un post'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AgentFullAccessViewModel(),
      child: Consumer<AgentFullAccessViewModel>(
        builder: (context, viewModel, child) {
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Agent Full Access',
                style: GoogleFonts.syne(fontWeight: FontWeight.w700),
              ),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(colorScheme),
                  const SizedBox(height: 24),
                  Text(
                    'Votre Vision Stratégique',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _promptController,
                    maxLines: 5,
                    enabled: !viewModel.isLoading,
                    decoration: InputDecoration(
                      hintText: 'Ex: J\'ai une marque de café bio tunisien, je cible les jeunes 20-30 ans sur Instagram...',
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading ? null : () => _processPrompt(viewModel),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Lancer l\'Orchestration IA'),
                    ),
                  ),
                  if (viewModel.error != null) ...[
                    const SizedBox(height: 20),
                    _buildErrorCard(viewModel.error!, colorScheme),
                  ],
                    if (viewModel.decomposeResponse != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      '1. Plan de Décomposition',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAgentPromptCard(
                      'Video Agent',
                      '🎬',
                      viewModel.decomposeResponse!.result.videoPrompt,
                      colorScheme,
                      isLoading: viewModel.isVideoLoading,
                    ),
                    _buildAgentPromptCard(
                      'Slogan Agent',
                      '✍️',
                      viewModel.decomposeResponse!.result.sloganPrompt,
                      colorScheme,
                      isLoading: viewModel.isSlogansLoading,
                    ),
                    _buildAgentPromptCard(
                      'Product Agent',
                      '🚀',
                      viewModel.decomposeResponse!.result.productIdeaPrompt,
                      colorScheme,
                      isLoading: viewModel.isProductLoading,
                    ),
                  ],
                  if (viewModel.isSlogansLoading || viewModel.isVideoLoading || viewModel.isProductLoading ||
                      viewModel.slogans != null || viewModel.videoIdea != null || viewModel.productIdea != null) ...[
                    const SizedBox(height: 32),
                    Text(
                      '2. Résultats de la Stratégie IA',
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Voici les actifs générés pour votre projet :',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Slogans Section
                    if (viewModel.isSlogansLoading)
                      _buildSectionLoading('✍️ Slogans Stratégiques', colorScheme)
                    else if (viewModel.slogans != null)
                      _buildSlogansResult(viewModel.slogans!, colorScheme),
                    
                    const SizedBox(height: 24),
                    
                    // Video Section
                    if (viewModel.isVideoLoading)
                      _buildSectionLoading('🎬 Concept Vidéo', colorScheme)
                    else if (viewModel.videoIdea != null)
                      _buildVideoResult(viewModel.videoIdea!, viewModel.generatedVideo, colorScheme),
                    
                    const SizedBox(height: 24),
                    
                    // Product Section
                    if (viewModel.isProductLoading)
                      _buildSectionLoading('🚀 Idée Produit', colorScheme)
                    else if (viewModel.productIdea != null)
                      _buildProductResult(viewModel.productIdea!, colorScheme),
                    
                    if (!viewModel.isSlogansLoading && !viewModel.isVideoLoading && !viewModel.isProductLoading &&
                        (viewModel.slogans != null || viewModel.videoIdea != null || viewModel.productIdea != null)) ...[
                      const SizedBox(height: 32),
                      _buildFinalPlanCard(colorScheme),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLoading(String title, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, colorScheme),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Génération en cours...',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'L\'Agent Full Access décompose votre idée et mobilise simultanément nos experts IA spécialisés.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPromptCard(String name, String icon, String prompt, ColorScheme colorScheme, {bool isLoading = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLoading ? colorScheme.primary : colorScheme.outlineVariant,
          width: isLoading ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                name,
                style: GoogleFonts.syne(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.check_circle, color: colorScheme.primary, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mission déléguée :',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prompt,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlogansResult(List<SloganModel> slogans, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('✍️ Slogans Stratégiques', colorScheme),
        const SizedBox(height: 12),
        ...slogans.map((slogan) => _SloganCard(
              slogan: slogan,
              colorScheme: colorScheme,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: slogan.slogan));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Slogan copié !')),
                );
              },
            )),
      ],
    );
  }

  Widget _buildVideoResult(VideoIdea video, Video? generatedVideo, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🎬 Concept Vidéo', colorScheme),
        const SizedBox(height: 12),
        VideoResultCard(
          idea: video,
          isFavorite: false,
          onFavoriteToggle: () {},
        ),
        if (generatedVideo != null) ...[
          const SizedBox(height: 16),
          _ActualVideoCard(
            video: generatedVideo,
            onSave: () async {
              final success = await VideoDownloadService.saveToGallery(generatedVideo.videoUrl);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? '✅ Vidéo sauvegardée dans la galerie!' 
                      : '❌ Erreur lors du téléchargement'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            onShare: () => _showShareDialog(context, colorScheme, generatedVideo),
          ),
        ],
      ],
    );
  }

  Widget _buildProductResult(ProductIdeaResult productIdea, ColorScheme colorScheme) {
    final idea = productIdea;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🚀 Idée Produit', colorScheme),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text('📱', style: TextStyle(fontSize: 48))),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  idea.produit.nomDuProduit,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 20),
              Divider(height: 1, color: colorScheme.outlineVariant),
              const SizedBox(height: 16),
              _Label(colorScheme: colorScheme, text: '📝 Description'),
              const SizedBox(height: 8),
              Text(
                idea.produit.solution,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant, height: 1.6),
              ),
              const SizedBox(height: 16),
              _Label(colorScheme: colorScheme, text: '🎯 Problème résolu'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: colorScheme.error, width: 3)),
                ),
                child: Text(
                  idea.produit.probleme,
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.6),
                ),
              ),
              const SizedBox(height: 16),
              _Label(colorScheme: colorScheme, text: '⚙️ Caractéristiques principales'),
              const SizedBox(height: 8),
              _FeatureRow(colorScheme: colorScheme, icon: '👥', text: 'Cible: ${idea.produit.cible}'),
              _FeatureRow(colorScheme: colorScheme, icon: '💶', text: 'Modèle économique: ${idea.produit.modeleEconomique}'),
              _FeatureRow(colorScheme: colorScheme, icon: '🧪', text: 'MVP: ${idea.produit.mvp}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Text(
      title,
      style: GoogleFonts.syne(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFinalPlanCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'Stratégie Consolidée',
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Votre stratégie IA est maintenant prête. Vous pouvez retrouver chaque élément dans ses rubriques respectives pour approfondir.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
              ),
              child: const Text('Terminer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SloganCard extends StatelessWidget {
  final SloganModel slogan;
  final ColorScheme colorScheme;
  final VoidCallback onCopy;

  const _SloganCard({
    required this.slogan,
    required this.colorScheme,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  slogan.slogan,
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            slogan.explanation,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Score: ${slogan.memorabilityScore}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActualVideoCard extends StatefulWidget {
  final Video video;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const _ActualVideoCard({
    required this.video,
    required this.onSave,
    required this.onShare,
  });

  @override
  State<_ActualVideoCard> createState() => _ActualVideoCardState();
}

class _ActualVideoCardState extends State<_ActualVideoCard> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl));
    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Error initializing video player: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Vidéo Réelle Générée',
                  style: GoogleFonts.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (_isInitialized && _controller != null)
            ClipRRect(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.video.durationFormatted,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
              ),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          
          // Video Info & Buttons (copied from VideoGeneratorScreen)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primary.withOpacity(0.1),
                      child: Text(
                        widget.video.user.isNotEmpty ? widget.video.user[0].toUpperCase() : '?',
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Source',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            widget.video.source,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Par ${widget.video.user}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onSave,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Enregistrer'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: widget.onShare,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Partager'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final ColorScheme colorScheme;
  final String text;

  const _Label({required this.colorScheme, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant));
  }
}

class _FeatureRow extends StatelessWidget {
  final ColorScheme colorScheme;
  final String icon;
  final String text;

  const _FeatureRow({required this.colorScheme, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: colorScheme.onSurface, height: 1.5))),
        ],
      ),
    );
  }
}
