import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class EditedVideosHistoryScreen extends StatefulWidget {
  const EditedVideosHistoryScreen({super.key});

  @override
  State<EditedVideosHistoryScreen> createState() => _EditedVideosHistoryScreenState();
}

class _EditedVideosHistoryScreenState extends State<EditedVideosHistoryScreen> {
  List<Map<String, dynamic>> _videosEditees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerHistorique();
  }

  Future<void> _chargerHistorique() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historiqueJson = prefs.getStringList('edited_videos_history') ?? [];
      
      setState(() {
        _videosEditees = historiqueJson
            .map((json) => jsonDecode(json) as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
      
      print('📱 [DEBUG] Historique vidéos chargé: ${_videosEditees.length} items');
    } catch (e) {
      print('❌ [DEBUG] Erreur chargement historique: $e');
      setState(() {
        _isLoading = false;
      });
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
                      'Vidéos Éditées',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  // Bouton de rafraîchissement
                  GestureDetector(
                    onTap: _chargerHistorique,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _videosEditees.isEmpty
                      ? _construireEtatVide(cs)
                      : _construireListeVideos(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireEtatVide(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: cs.onSurfaceVariant,
          ),
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
            'Éditez des vidéos pour les voir ici',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/video-generator'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Créer une vidéo'),
          ),
        ],
      ),
    );
  }

  Widget _construireListeVideos(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _videosEditees.length,
      itemBuilder: (context, index) {
        final video = _videosEditees[index];
        return _construireCarteVideo(video, cs, index);
      },
    );
  }

  Widget _construireCarteVideo(Map<String, dynamic> video, ColorScheme cs, int index) {
    final createdAt = DateTime.tryParse(video['createdAt'] ?? '') ?? DateTime.now();
    final timeAgo = _obtenirTempsEcoule(createdAt);
    
    // Décoder l'image Base64
    Uint8List? imageBytes;
    try {
      if (video['editedDataBase64'] != null) {
        imageBytes = base64Decode(video['editedDataBase64']);
      }
    } catch (e) {
      print('❌ Erreur décodage image: $e');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Rééditer la vidéo
          if (video['originalUrl'] != null) {
            context.push('/video-editor', extra: {
              'videoUrl': video['originalUrl'],
              'videoId': video['id'],
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Aperçu de la vidéo éditée
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _construireIconeParDefaut(cs);
                              },
                            )
                          : _construireIconeParDefaut(cs),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Informations
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vidéo Éditée #${index + 1}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (video['textOverlays'] != null && video['textOverlays'] > 0) ...[
                              Icon(
                                Icons.text_fields,
                                size: 14,
                                color: cs.primary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${video['textOverlays']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (video['drawings'] != null && video['drawings'] > 0) ...[
                              Icon(
                                Icons.brush,
                                size: 14,
                                color: cs.secondary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${video['drawings']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (video['filter'] != null && video['filter'] != 'Aucun') ...[
                              Icon(
                                Icons.filter_vintage,
                                size: 14,
                                color: cs.tertiary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Filtre',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.tertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Icône d'édition
                  Icon(
                    Icons.edit_rounded,
                    color: cs.primary,
                    size: 24,
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
                        if (video['originalUrl'] != null) {
                          context.push('/video-editor', extra: {
                            'videoUrl': video['originalUrl'],
                            'videoId': video['id'],
                          });
                        }
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Rééditer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _supprimerVideo(index),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Supprimer'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: cs.error,
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
  }

  Widget _construireIconeParDefaut(ColorScheme cs) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.video_library_rounded,
        color: cs.onSurfaceVariant,
        size: 32,
      ),
    );
  }

  String _obtenirTempsEcoule(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  Future<void> _supprimerVideo(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer la vidéo'),
          content: const Text('Êtes-vous sûr de vouloir supprimer cette vidéo éditée ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final historiqueJson = prefs.getStringList('edited_videos_history') ?? [];
        
        if (index < historiqueJson.length) {
          historiqueJson.removeAt(index);
          await prefs.setStringList('edited_videos_history', historiqueJson);
          
          setState(() {
            _videosEditees.removeAt(index);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Vidéo supprimée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}