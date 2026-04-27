import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/image_download_service.dart';

class EditedImagesHistoryScreen extends StatefulWidget {
  const EditedImagesHistoryScreen({super.key});

  @override
  State<EditedImagesHistoryScreen> createState() => _EditedImagesHistoryScreenState();
}

class _EditedImagesHistoryScreenState extends State<EditedImagesHistoryScreen> {
  List<Map<String, dynamic>> _editedImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEditedImages();
  }

  Future<void> _loadEditedImages() async {
    print('🔄 [DEBUG] Chargement historique images éditées...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStrings = prefs.getStringList('edited_images_history') ?? [];
      
      print('🔄 [DEBUG] Trouvé ${historyStrings.length} items dans l\'historique');
      
      setState(() {
        _editedImages = historyStrings
            .map((str) {
              try {
                return jsonDecode(str) as Map<String, dynamic>;
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
      
      print('✅ [DEBUG] ${_editedImages.length} images chargées avec succès');
    } catch (e) {
      print('❌ [DEBUG] Erreur chargement historique: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEditedImage(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyStrings = prefs.getStringList('edited_images_history') ?? [];
      
      if (index < historyStrings.length) {
        historyStrings.removeAt(index);
        await prefs.setStringList('edited_images_history', historyStrings);
        
        setState(() {
          _editedImages.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image supprimée de l\'historique'),
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
                          'Images Éditées',
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Vos créations personnalisées',
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
                      '${_editedImages.length}',
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
                  : _editedImages.isEmpty
                      ? _buildEmptyState(cs)
                      : _buildImagesList(cs),
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
          Icon(Icons.edit_outlined, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Aucune image éditée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Éditez vos premières images pour les voir ici',
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

  Widget _buildImagesList(ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _editedImages.length,
      itemBuilder: (context, index) {
        final editedImage = _editedImages[index];
        Uint8List? imageData;
        
        // Décoder l'image depuis Base64
        try {
          final base64String = editedImage['editedDataBase64'] as String?;
          if (base64String != null) {
            imageData = base64Decode(base64String);
          }
        } catch (e) {
          print('❌ [DEBUG] Erreur décodage Base64: $e');
        }
        
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
              // Image
              if (imageData != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.memory(
                    imageData,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
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
                        Icon(Icons.edit, size: 16, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Image éditée',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(editedImage['createdAt'] ?? ''),
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
                          onPressed: () => _deleteEditedImage(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Détails de l'édition
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (editedImage['filter'] != 'ImageFilter.none')
                          _buildTag(cs, 'Filtre', Icons.filter),
                        if (editedImage['frame'] != 'ImageFrame.none')
                          _buildTag(cs, 'Cadre', Icons.border_outer),
                        if ((editedImage['textOverlays'] as int? ?? 0) > 0)
                          _buildTag(cs, 'Texte', Icons.text_fields),
                        if ((editedImage['effects'] as List?)?.isNotEmpty ?? false)
                          _buildTag(cs, 'Effets', Icons.auto_fix_high),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: imageData != null
                                ? () async {
                                    await ImageDownloadService.showShareDialogForImageData(
                                      context: context,
                                      imageData: imageData!,
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
                            onPressed: imageData != null
                                ? () async {
                                    final success = await ImageDownloadService.saveImageDataToGallery(imageData!);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success 
                                            ? '✅ Image sauvegardée dans la galerie!' 
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