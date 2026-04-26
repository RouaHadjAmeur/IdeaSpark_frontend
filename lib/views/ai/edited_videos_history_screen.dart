import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/video_download_service.dart';

class EditedVideosHistoryScreen extends StatefulWidget {
  const EditedVideosHistoryScreen({super.key});

  @override
  State<EditedVideosHistoryScreen> createState() => _EditedVideosHistoryScreenState();
}

class _EditedVideosHistoryScreenState extends State<EditedVideosHistoryScreen> {
  List<Map<String, dynamic>> _editedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEditedVideos();
  }

  Future<void> _loadEditedVideos() async {
    print('🔄 [DEBUG] Chargement historique vidéos éditées...');
    try {
      final prefs = await SharedPreferences.getInstance();
      // Chercher dans les deux clés pour compatibilité
      final historyStrings = prefs.getStringList('edited_videos') ?? 
                            prefs.getStringList('edited_videos_history') ?? [];
      
      print('🔄 [DEBUG] Trouvé ${historyStrings.length} items dans l\'historique');
      
      setState(() {
        _editedVideos = historyStrings
            .map((str) {
              try {
                final decoded = jsonDecode(str) as Map<String, dynamic>;
                print('📝 [DEBUG] Vidéo chargée: ${decoded['id']} - Textes: ${decoded['textOverlays']?.length ?? 0} - Musique: ${decoded['music']?['name'] ?? 'Aucune'}');
                return decoded;
              } catch (e) {
                print('❌ [DEBUG] Erreur décodage item: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<Map<String, dynamic>>()
            .toList();
        _isLoading = false;
      });
      
      print('✅ [DEBUG] ${_editedVideos.length} vidéos chargées avec succès');
    } catch (e) {
      print('❌ [DEBUG] Erreur chargement historique: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEditedVideo(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStrings = prefs.getStringList('edited_videos') ?? [];
      
      if (index < historyStrings.length) {
        historyStrings.removeAt(index);
        await prefs.setStringList('edited_videos', historyStrings);
        
        setState(() {
          _editedVideos.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Vidéo supprimée de l\'historique'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateVideoTitle(Map<String, dynamic> editedVideo) {
    final List<String> modifications = [];
    
    // Vérifier les modifications apportées selon le format de l'éditeur
    if (editedVideo['music'] != null) {
      final musicName = editedVideo['music']['name'] ?? 'Musique';
      modifications.add('🎵 $musicName');
    }
    
    // Compter les overlays de texte
    final textOverlays = editedVideo['textOverlays'] as List?;
    if (textOverlays != null && textOverlays.isNotEmpty) {
      final count = textOverlays.length;
      modifications.add('📝 $count texte${count > 1 ? 's' : ''}');
    }
    
    // Vérifier si c'est une vidéo réseau (test)
    final videoPath = editedVideo['originalVideoPath'] as String?;
    if (videoPath != null && videoPath.startsWith('http')) {
      modifications.add('🎬 Vidéo test');
    }
    
    // Générer le titre basé sur les modifications
    if (modifications.isEmpty) {
      return 'Vidéo sauvegardée';
    } else if (modifications.length == 1) {
      return modifications.first;
    } else if (modifications.length == 2) {
      return '${modifications[0]} + ${modifications[1]}';
    } else {
      return '${modifications[0]} + ${modifications.length - 1} autres';
    }
  }

  String _generateVideoSubtitle(Map<String, dynamic> editedVideo) {
    final List<String> details = [];
    
    // Vérifier le type de vidéo
    final videoPath = editedVideo['originalVideoPath'] as String?;
    if (videoPath != null) {
      if (videoPath.startsWith('http')) {
        if (videoPath.contains('BigBuckBunny')) {
          details.add('Big Buck Bunny');
        } else if (videoPath.contains('ElephantsDream')) {
          details.add('Elephant Dream');
        } else {
          details.add('Vidéo test');
        }
      } else {
        details.add('Vidéo importée');
      }
    }
    
    // Ajouter des détails spécifiques
    if (editedVideo['music'] != null) {
      final musicName = editedVideo['music']['name'];
      if (musicName != null) {
        details.add('Musique: $musicName');
      }
    }
    
    final textOverlays = editedVideo['textOverlays'] as List?;
    if (textOverlays != null && textOverlays.isNotEmpty) {
      details.add('${textOverlays.length} texte(s)');
    }
    
    // Ajouter la date de création
    final createdAt = editedVideo['createdAt'] as String?;
    if (createdAt != null) {
      details.add('Créée ${_formatDate(createdAt)}');
    }
    
    return details.join(' • ');
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}j';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inMinutes}min';
      }
    } catch (e) {
      return 'Récent';
    }
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
              padding: const EdgeInsets.all(16),
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
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vidéos Éditées',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Vos créations vidéo personnalisées',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_editedVideos.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _editedVideos.isEmpty
                      ? _buildEmptyState(cs)
                      : _buildVideosList(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_settings_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Aucune vidéo éditée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Éditez vos premières vidéos pour les voir ici',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideosList(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _editedVideos.length,
      itemBuilder: (context, index) {
        final editedVideo = _editedVideos[index];
        final videoPath = editedVideo['editedVideoPath'] as String?;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video thumbnail placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 48, color: cs.primary),
                      const SizedBox(height: 8),
                      Text(
                        _generateVideoTitle(editedVideo),
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.video_settings, size: 16, color: cs.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _generateVideoTitle(editedVideo),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatDate(editedVideo['createdAt'] ?? ''),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _deleteEditedVideo(index),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Sous-titre avec détails
                    Text(
                      _generateVideoSubtitle(editedVideo),
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Détails de l'édition
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Vérifier les overlays de texte
                        if ((editedVideo['textOverlays'] as List?)?.isNotEmpty ?? false)
                          _buildTag(cs, 'Texte', Icons.text_fields),
                        // Vérifier la musique
                        if (editedVideo['music'] != null)
                          _buildTag(cs, 'Musique', Icons.music_note),
                        // Vérifier si c'est une vidéo test
                        if ((editedVideo['originalVideoPath'] as String?)?.startsWith('http') ?? false)
                          _buildTag(cs, 'Vidéo test', Icons.cloud),
                        // Ajouter un tag pour l'ID
                        if (editedVideo['id'] != null)
                          _buildTag(cs, 'ID: ${(editedVideo['id'] as String).substring(0, 8)}', Icons.fingerprint),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: videoPath != null
                                ? () async {
                                    await VideoDownloadService.showShareDialog(
                                      context: context,
                                      videoUrl: videoPath,
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.share, size: 14),
                            label: const Text('Partager', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(0, 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: videoPath != null
                                ? () async {
                                    final success = await VideoDownloadService.saveToGallery(videoPath);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success 
                                            ? '✅ Vidéo sauvegardée dans la galerie!' 
                                            : '❌ Erreur lors de la sauvegarde'),
                                          backgroundColor: success ? Colors.green : Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.download, size: 14),
                            label: const Text('Sauvegarder', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(0, 28),
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
      },
    );
  }

  Widget _buildTag(ColorScheme cs, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: cs.primary),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: cs.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}