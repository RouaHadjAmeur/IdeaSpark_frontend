import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'video_editor_screen.dart';

class VideoEditorTestScreen extends StatefulWidget {
  const VideoEditorTestScreen({super.key});

  @override
  State<VideoEditorTestScreen> createState() => _VideoEditorTestScreenState();
}

class _VideoEditorTestScreenState extends State<VideoEditorTestScreen> {
  List<Map<String, dynamic>> _editedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEditedVideos();
  }

  Future<void> _loadEditedVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getStringList('edited_videos') ?? [];
      
      setState(() {
        _editedVideos = videosJson.map((json) {
          try {
            return jsonDecode(json) as Map<String, dynamic>;
          } catch (e) {
            print('❌ [DEBUG] Erreur décodage vidéo: $e');
            return <String, dynamic>{};
          }
        }).where((video) => video.isNotEmpty).toList();
        _isLoading = false;
      });
      
      print('📊 [DEBUG] ${_editedVideos.length} vidéos éditées chargées');
    } catch (e) {
      print('❌ [DEBUG] Erreur chargement historique: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('edited_videos');
      setState(() => _editedVideos.clear());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Historique vidéo effacé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ [DEBUG] Erreur effacement historique: $e');
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
            _buildHeader(cs),
            
            // Options de test
            _buildTestOptions(cs),
            
            // Historique des vidéos éditées
            Expanded(
              child: _buildVideoHistory(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Padding(
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
                  'Test Éditeur Vidéo',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Testez toutes les fonctionnalités d\'édition',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadEditedVideos,
            icon: Icon(Icons.refresh, color: cs.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildTestOptions(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Options de Test',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Bouton vidéo de test
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoEditorScreen(
                      videoPath: '', // Vide pour déclencher le mode test
                    ),
                  ),
                ).then((_) => _loadEditedVideos());
              },
              icon: const Icon(Icons.play_circle, size: 20),
              label: const Text('Ouvrir Éditeur Vidéo'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bouton avec vidéo de test directe
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoEditorScreen(
                      videoPath: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
                    ),
                  ),
                ).then((_) => _loadEditedVideos());
              },
              icon: const Icon(Icons.video_library, size: 18),
              label: const Text('Test avec Big Buck Bunny'),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Bouton effacer historique
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _editedVideos.isNotEmpty ? _clearHistory : null,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Effacer Historique'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoHistory(ColorScheme cs) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_editedVideos.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune vidéo éditée',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisez l\'éditeur vidéo pour créer\nvos premières vidéos éditées',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Historique (${_editedVideos.length} vidéo${_editedVideos.length > 1 ? 's' : ''})',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _editedVideos.length,
            itemBuilder: (context, index) {
              final video = _editedVideos[index];
              return _buildVideoCard(cs, video, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(ColorScheme cs, Map<String, dynamic> video, int index) {
    final createdAt = DateTime.tryParse(video['createdAt'] ?? '') ?? DateTime.now();
    final isNetworkVideo = video['originalVideoPath']?.toString().startsWith('http') ?? false;
    
    // Compter les modifications
    final modifications = <String>[];
    
    if (video['music'] != null) {
      final musicData = video['music'];
      if (musicData is Map) {
        modifications.add('🎵 ${musicData['name'] ?? 'Musique'}');
      }
    }
    
    if (video['textOverlays'] is List && (video['textOverlays'] as List).isNotEmpty) {
      modifications.add('📝 ${(video['textOverlays'] as List).length} texte(s)');
    }
    
    if (video['subtitles'] is List && (video['subtitles'] as List).isNotEmpty) {
      modifications.add('🔊 ${(video['subtitles'] as List).length} sous-titre(s)');
    }
    
    if (video['transitions'] is List && (video['transitions'] as List).isNotEmpty) {
      modifications.add('✨ ${(video['transitions'] as List).length} transition(s)');
    }
    
    final trimStart = video['trimStart'] as int? ?? 0;
    final trimEnd = video['trimEnd'] as int? ?? 0;
    if (trimStart > 0 || trimEnd > 0) {
      modifications.add('✂️ Découpe');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la carte
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isNetworkVideo ? Icons.cloud : Icons.video_file,
                    color: cs.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vidéo #${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '${_formatDate(createdAt)} • ${isNetworkVideo ? 'Réseau' : 'Local'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: cs.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            
            // Modifications appliquées
            if (modifications.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Modifications:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: modifications.map((mod) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mod,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Aucune modification appliquée',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            // Informations techniques
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID: ${video['id']?.toString().substring(0, 8) ?? 'N/A'}...',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (trimStart > 0 || trimEnd > 0)
                    Text(
                      'Découpe: ${Duration(milliseconds: trimStart).inSeconds}s - ${Duration(milliseconds: trimEnd).inSeconds}s',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }
}