import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/video_generator_service.dart';
import '../../services/video_download_service.dart';
import '../../models/video.dart';

class VideoGeneratorScreen extends StatefulWidget {
  const VideoGeneratorScreen({super.key});

  @override
  State<VideoGeneratorScreen> createState() => _VideoGeneratorScreenState();
}

class _VideoGeneratorScreenState extends State<VideoGeneratorScreen> {
  final descriptionController = TextEditingController();
  final objectController = TextEditingController();

  Video? generatedVideo;
  bool isGenerating = false;
  String selectedDuration = 'medium';
  String selectedOrientation = 'landscape';
  
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void dispose() {
    descriptionController.dispose();
    objectController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String videoUrl) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      print('❌ Error initializing video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Erreur: Impossible de charger la vidéo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateVideo() async {
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isGenerating = true);

    try {
      final video = await VideoGeneratorService.generateVideo(
        description: descriptionController.text.trim(),
        specificObject: objectController.text.trim(),
        duration: selectedDuration,
        orientation: selectedOrientation,
      );

      if (mounted) {
        setState(() {
          generatedVideo = video;
          isGenerating = false;
        });

        if (video.videoUrl.isNotEmpty) {
          await _initializeVideo(video.videoUrl);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Vidéo générée ! (${video.durationFormatted})'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareDialog(BuildContext context, ColorScheme cs) {
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
                    onTap: () => _shareToTikTok(),
                  ),
                  _buildShareButton(
                    icon: '📘',
                    label: 'Facebook',
                    onTap: () => _shareToFacebook(),
                  ),
                  _buildShareButton(
                    icon: '📷',
                    label: 'Instagram',
                    onTap: () => _shareToInstagram(),
                  ),
                  _buildShareButton(
                    icon: '𝕏',
                    label: 'Twitter',
                    onTap: () => _shareToTwitter(),
                  ),
                  _buildShareButton(
                    icon: '▶️',
                    label: 'YouTube',
                    onTap: () => _shareToYouTube(),
                  ),
                  _buildShareButton(
                    icon: '📤',
                    label: 'Partager',
                    onTap: () => _shareGeneric(),
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

  Future<void> _shareToTikTok() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎵 Téléchargement pour TikTok...'),
        backgroundColor: Colors.black,
      ),
    );
    final success = await VideoDownloadService.saveToGallery(generatedVideo!.videoUrl);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vidéo sauvegardée! Ouvre TikTok et crée un post'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareToFacebook() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📘 Téléchargement pour Facebook...'),
        backgroundColor: Colors.blue,
      ),
    );
    final success = await VideoDownloadService.saveToGallery(generatedVideo!.videoUrl);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vidéo sauvegardée! Ouvre Facebook et crée un post'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareToInstagram() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📷 Téléchargement pour Instagram...'),
        backgroundColor: Colors.pink,
      ),
    );
    final success = await VideoDownloadService.saveToGallery(generatedVideo!.videoUrl);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vidéo sauvegardée! Ouvre Instagram et crée un post'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareToTwitter() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('𝕏 Partage sur Twitter...'),
        backgroundColor: Colors.black,
      ),
    );
    await VideoDownloadService.shareVideo(generatedVideo!.videoUrl);
  }

  Future<void> _shareToYouTube() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('▶️ Téléchargement pour YouTube...'),
        backgroundColor: Colors.red,
      ),
    );
    final success = await VideoDownloadService.saveToGallery(generatedVideo!.videoUrl);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vidéo sauvegardée! Ouvre YouTube Studio'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareGeneric() async {
    Navigator.pop(context);
    await VideoDownloadService.shareVideo(generatedVideo!.videoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 22,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Générateur Vidéo',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.videocam, color: Colors.blue, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  'Générer une vidéo',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: descriptionController,
                              maxLines: 3,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                              ),
                              cursorColor: cs.primary,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                labelStyle: TextStyle(color: cs.onSurfaceVariant),
                                hintText: 'Ex: Produit cosmétique, démonstration...',
                                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: cs.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: cs.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: cs.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: cs.surfaceContainer,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: objectController,
                              style: TextStyle(
                                color: cs.onSurface,
                                fontSize: 16,
                              ),
                              cursorColor: cs.primary,
                              decoration: InputDecoration(
                                labelText: 'Objet spécifique (optionnel)',
                                labelStyle: TextStyle(color: cs.onSurfaceVariant),
                                hintText: 'Ex: rouge à lèvres, parfum, espadrille...',
                                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: cs.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: cs.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: cs.primary, width: 2),
                                ),
                                filled: true,
                                fillColor: cs.surfaceContainer,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Durée',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ('short', 'Court (<15s)'),
                                ('medium', 'Moyen (15-30s)'),
                                ('long', 'Long (>30s)'),
                              ]
                                  .map((item) {
                                final (value, label) = item;
                                final isSelected = selectedDuration == value;
                                return ChoiceChip(
                                  label: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : cs.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => selectedDuration = value);
                                  },
                                  selectedColor: cs.primary,
                                  backgroundColor: cs.surfaceContainerHighest,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Orientation',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ('portrait', '📱 Portrait'),
                                ('landscape', '🎬 Paysage'),
                                ('square', '⬜ Carré'),
                              ]
                                  .map((item) {
                                final (value, label) = item;
                                final isSelected = selectedOrientation == value;
                                return ChoiceChip(
                                  label: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white : cs.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => selectedOrientation = value);
                                  },
                                  selectedColor: cs.primary,
                                  backgroundColor: cs.surfaceContainerHighest,
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: isGenerating ? null : _generateVideo,
                                icon: isGenerating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.videocam, size: 20),
                                label: Text(
                                  isGenerating ? 'Génération...' : '🎬 Générer la vidéo',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (generatedVideo != null) ...[
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Vidéo générée',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_isVideoInitialized && _videoController != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: _videoController!.value.aspectRatio,
                                    child: Stack(
                                      children: [
                                        VideoPlayer(_videoController!),
                                        Center(
                                          child: FloatingActionButton(
                                            backgroundColor: Colors.white24,
                                            onPressed: () {
                                              setState(() {
                                                _videoController!.value.isPlaying
                                                    ? _videoController!.pause()
                                                    : _videoController!.play();
                                              });
                                            },
                                            child: Icon(
                                              _videoController!.value.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                              size: 40,
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
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Durée',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        generatedVideo!.durationFormatted,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Résolution',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        generatedVideo!.resolution,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
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
                                        generatedVideo!.source,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Par ${generatedVideo!.user}',
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
                                      onPressed: () async {
                                        final success = await VideoDownloadService.saveToGallery(generatedVideo!.videoUrl);
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
                                      icon: const Icon(Icons.download, size: 18),
                                      label: const Text('Enregistrer'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () async {
                                        // Utiliser le même système simple que les images
                                        await VideoDownloadService.showShareDialog(
                                          context: context,
                                          videoUrl: generatedVideo!.videoUrl,
                                        );
                                      },
                                      icon: const Icon(Icons.share, size: 18),
                                      label: const Text('Partager'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        backgroundColor: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
