import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/video_generator_service.dart';
import '../../services/video_download_service.dart';
import '../../models/video.dart';
import 'video_editor_screen.dart';
import 'advanced_share_screen.dart';

class VideoHistoryScreen extends StatefulWidget {
  const VideoHistoryScreen({super.key});

  @override
  State<VideoHistoryScreen> createState() => _VideoHistoryScreenState();
}

class _VideoHistoryScreenState extends State<VideoHistoryScreen> {
  late Future<List<Video>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = VideoGeneratorService.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      'Historique Vidéos',
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
              child: FutureBuilder<List<Video>>(
                future: _videosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: cs.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: cs.onSurface),
                          ),
                        ],
                      ),
                    );
                  }

                  final videos = snapshot.data ?? [];

                  if (videos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videocam_off,
                            size: 48,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune vidéo générée',
                            style: TextStyle(
                              fontSize: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            // Ouvrir la vidéo en détail
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Thumbnail
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        video.thumbnailUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: cs.surfaceContainerHighest,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.videocam),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Infos
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Vidéo #${video.id.length > 8 ? video.id.substring(0, 8) : video.id}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.timer,
                                                size: 14,
                                                color: cs.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                video.durationFormatted,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(
                                                Icons.aspect_ratio,
                                                size: 14,
                                                color: cs.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                video.resolution,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Par ${video.user}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Icône play
                                    Icon(
                                      Icons.play_circle_outline,
                                      color: cs.primary,
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Boutons d'action
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => VideoEditorScreen(
                                                videoPath: video.videoUrl, // Using video.videoUrl instead of video.url
                                                videoId: video.id,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Éditer'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AdvancedShareScreen(
                                                contentUrl: video.videoUrl,
                                                contentType: 'video',
                                                contentId: video.id,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.share, size: 16),
                                        label: const Text('Partager'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          await VideoDownloadService.showShareDialog(
                                            context: context,
                                            videoUrl: video.videoUrl,
                                            caption: '🎬 Vidéo générée avec IdeaSpark\n\nPar ${video.user}\nDurée: ${video.durationFormatted}',
                                          );
                                        },
                                        icon: const Icon(Icons.download, size: 16),
                                        label: const Text('Télécharger'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          await VideoDownloadService.shareToSocialMedia(
                                            context: context,
                                            videoUrl: video.videoUrl,
                                            caption: '🎬 Vidéo générée avec IdeaSpark\n\nPar ${video.user}\nDurée: ${video.durationFormatted}',
                                            platform: VideoSocialPlatform.tiktok, // TikTok par défaut pour les vidéos
                                          );
                                        },
                                        icon: const Icon(Icons.share, size: 16),
                                        label: const Text('TikTok'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
