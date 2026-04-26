import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/edited_image.dart';
import '../../services/image_editor_service.dart';

class ImageEditorScreen extends StatefulWidget {
  final String imageUrl;
  final String? imageId;

  const ImageEditorScreen({
    super.key,
    required this.imageUrl,
    this.imageId,
  });

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  EditedImage? _editedImage;
  Uint8List? _currentImageData;
  bool _isProcessing = false;
  int _selectedTabIndex = 0;

  // Controllers pour le texte
  final _textController = TextEditingController();
  double _textX = 0.5;
  double _textY = 0.5;
  double _fontSize = 24.0;
  Color _textColor = Colors.white;
  bool _textBold = false;
  bool _textItalic = false;

  @override
  void initState() {
    super.initState();
    _initializeImage();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _initializeImage() {
    _editedImage = EditedImage(
      id: widget.imageId ?? const Uuid().v4(),
      originalUrl: widget.imageUrl,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _importFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        // Créer une nouvelle image éditée avec le fichier local
        setState(() {
          _editedImage = EditedImage(
            id: const Uuid().v4(),
            originalUrl: image.path, // Utiliser le chemin local
            createdAt: DateTime.now(),
          );
          _currentImageData = null; // Reset pour forcer le rechargement
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image importée de la galerie!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de l\'importation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _applyChanges() async {
    if (_editedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      final imageUrl = _editedImage!.originalUrl;
      
      if (!imageUrl.startsWith('http')) {
        // Fichier local - traitement local avec la bibliothèque image
        await _processLocalImage();
      } else {
        // URL réseau - utiliser le service backend
        final processedData = await ImageEditorService.processEditedImage(_editedImage!);
        setState(() {
          _currentImageData = processedData;
        });
      }
      
      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processLocalImage() async {
    try {
      final imageUrl = _editedImage!.originalUrl;
      final file = File(imageUrl);
      final imageBytes = await file.readAsBytes();
      
      // Décoder l'image
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Impossible de décoder l\'image');
      
      img.Image processedImage = image;
      
      // Appliquer le filtre
      if (_editedImage!.filter != ImageFilter.none) {
        processedImage = _applyFilterLocal(processedImage, _editedImage!.filter);
      }
      
      // Encoder l'image traitée
      final processedBytes = Uint8List.fromList(img.encodePng(processedImage));
      
      setState(() {
        _currentImageData = processedBytes;
      });
    } catch (e) {
      throw Exception('Erreur traitement local: $e');
    }
  }

  img.Image _applyFilterLocal(img.Image image, ImageFilter filter) {
    switch (filter) {
      case ImageFilter.blackAndWhite:
        return img.grayscale(image);
      case ImageFilter.sepia:
        return img.sepia(image);
      case ImageFilter.vintage:
        var result = img.sepia(image);
        result = img.contrast(result, contrast: 0.8);
        return result;
      case ImageFilter.cool:
        return img.adjustColor(image, saturation: 1.1, hue: 0.1);
      case ImageFilter.warm:
        return img.adjustColor(image, saturation: 1.2, hue: -0.1);
      case ImageFilter.bright:
        return img.adjustColor(image, brightness: 1.2);
      case ImageFilter.dark:
        return img.adjustColor(image, brightness: 0.7);
      default:
        return image;
    }
  }

  void _updateFilter(ImageFilter filter) {
    setState(() {
      _editedImage = _editedImage!.copyWith(filter: filter);
    });
    _applyChanges();
  }

  void _updateFrame(ImageFrame frame, Color? color) {
    setState(() {
      _editedImage = _editedImage!.copyWith(
        frame: frame,
        frameColor: color?.value,
      );
    });
    _applyChanges();
  }

  void _addText() {
    if (_textController.text.trim().isEmpty) return;

    final textOverlay = TextOverlay(
      text: _textController.text.trim(),
      x: _textX,
      y: _textY,
      fontSize: _fontSize,
      color: _textColor.value,
      bold: _textBold,
      italic: _textItalic,
    );

    setState(() {
      final currentOverlays = List<TextOverlay>.from(_editedImage!.textOverlays);
      currentOverlays.add(textOverlay);
      _editedImage = _editedImage!.copyWith(textOverlays: currentOverlays);
    });

    _applyChanges();
    _textController.clear();
  }

  void _updateSize(String platform, String type) {
    final size = SocialMediaSizes.getSizeForPlatform(platform, type);
    setState(() {
      _editedImage = _editedImage!.copyWith(
        resizedWidth: size['width'],
        resizedHeight: size['height'],
      );
    });
    _applyChanges();
  }

  void _updateEffect(ImageEffect effect, bool enabled) {
    final currentEffects = List<ImageEffect>.from(_editedImage!.effects);
    
    if (enabled && !currentEffects.contains(effect)) {
      currentEffects.add(effect);
    } else if (!enabled) {
      currentEffects.remove(effect);
    }

    setState(() {
      _editedImage = _editedImage!.copyWith(effects: currentEffects);
    });
    _applyChanges();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                // Header
                _buildHeader(cs),
                
                // Image Preview
                Expanded(
                  flex: 3,
                  child: _buildImagePreview(cs),
                ),
                
                // Tools Tabs
                _buildToolsTabs(cs),
                
                // Tools Content
                Expanded(
                  flex: 2,
                  child: _buildToolsContent(cs),
                ),
                
                // Action Buttons
                _buildActionButtons(cs),
              ],
            ),
          ),
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
                  'Éditeur d\'Images',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  'Filtres, cadres, texte et effets',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Bouton d'importation
          GestureDetector(
            onTap: _importFromGallery,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                border: Border.all(color: cs.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.photo_library, size: 18, color: cs.primary),
            ),
          ),
          const SizedBox(width: 8),
          if (_isProcessing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _currentImageData != null
            ? Image.memory(
                _currentImageData!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              )
            : _buildOriginalImage(cs),
      ),
    );
  }

  Widget _buildOriginalImage(ColorScheme cs) {
    final imageUrl = _editedImage?.originalUrl ?? widget.imageUrl;
    
    // Vérifier si c'est un fichier local ou une URL
    if (imageUrl.startsWith('http')) {
      // Image réseau
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stack) => Center(
          child: Icon(Icons.error_outline, size: 48, color: cs.error),
        ),
      );
    } else {
      // Fichier local
      return Image.file(
        File(imageUrl),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stack) => Center(
          child: Icon(Icons.error_outline, size: 48, color: cs.error),
        ),
      );
    }
  }

  Widget _buildToolsTabs(ColorScheme cs) {
    final tabs = [
      {'icon': Icons.filter, 'label': 'Filtres'},
      {'icon': Icons.border_outer, 'label': 'Cadres'},
      {'icon': Icons.text_fields, 'label': 'Texte'},
      {'icon': Icons.photo_size_select_large, 'label': 'Taille'},
      {'icon': Icons.auto_fix_high, 'label': 'Effets'},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedTabIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      size: 20,
                      color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tab['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildToolsContent(ColorScheme cs) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildFiltersTab(cs);
      case 1:
        return _buildFramesTab(cs);
      case 2:
        return _buildTextTab(cs);
      case 3:
        return _buildSizeTab(cs);
      case 4:
        return _buildEffectsTab(cs);
      default:
        return Container();
    }
  }

  Widget _buildFiltersTab(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtres',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: ImageFilter.values.length,
              itemBuilder: (context, index) {
                final filter = ImageFilter.values[index];
                final isSelected = _editedImage?.filter == filter;

                return GestureDetector(
                  onTap: () => _updateFilter(filter),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getFilterLabel(filter),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFramesTab(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cadres',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: ImageFrame.values.length,
              itemBuilder: (context, index) {
                final frame = ImageFrame.values[index];
                final isSelected = _editedImage?.frame == frame;

                return GestureDetector(
                  onTap: () => _updateFrame(frame, Colors.black),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getFrameLabel(frame),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter du texte',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Tapez votre texte...',
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Taille: ${_fontSize.round()}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 48,
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _textBold,
                        onChanged: (value) => setState(() => _textBold = value ?? false),
                      ),
                      const Flexible(child: Text('Gras')),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _textItalic,
                        onChanged: (value) => setState(() => _textItalic = value ?? false),
                      ),
                      const Flexible(child: Text('Italique')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addText,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter le texte'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeTab(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Redimensionner pour',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: SocialMediaSizes.sizes.entries.map((platformEntry) {
                final platform = platformEntry.key;
                final types = platformEntry.value;

                return ExpansionTile(
                  title: Text(platform),
                  children: types.entries.map((typeEntry) {
                    final type = typeEntry.key;
                    final size = SocialMediaSizes.getSizeForPlatform(platform, type);

                    return ListTile(
                      title: Text(type),
                      subtitle: Text('${size['width']}x${size['height']}'),
                      onTap: () => _updateSize(platform, type),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectsTab(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Effets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: ImageEffect.values.length,
              itemBuilder: (context, index) {
                final effect = ImageEffect.values[index];
                if (effect == ImageEffect.none) return Container();

                final isEnabled = _editedImage?.effects.contains(effect) ?? false;

                return SwitchListTile(
                  title: Text(_getEffectLabel(effect)),
                  value: isEnabled,
                  onChanged: (value) => _updateEffect(effect, value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _currentImageData != null
                  ? () async {
                      // Sauvegarde automatique dans l'historique
                      await _saveToHistory();
                      // Retourner à l'écran précédent avec les données
                      Navigator.pop(context, _currentImageData);
                    }
                  : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Terminer'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToHistory() async {
    print('🔄 [DEBUG] _saveToHistory appelée');
    print('🔄 [DEBUG] _currentImageData: ${_currentImageData != null}');
    print('🔄 [DEBUG] _editedImage: ${_editedImage != null}');
    
    if (_currentImageData == null || _editedImage == null) {
      print('❌ [DEBUG] Données manquantes pour sauvegarde');
      return;
    }

    try {
      // Créer un objet pour l'historique des images éditées
      final editedImageHistory = {
        'id': _editedImage!.id,
        'originalUrl': _editedImage!.originalUrl,
        'editedDataBase64': base64Encode(_currentImageData!), // Encoder en Base64
        'filter': _editedImage!.filter.toString(),
        'frame': _editedImage!.frame.toString(),
        'textOverlays': _editedImage!.textOverlays.length,
        'effects': _editedImage!.effects.map((e) => e.toString()).toList(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      print('🔄 [DEBUG] Objet créé: ${editedImageHistory.keys}');

      // Sauvegarder dans SharedPreferences (historique local)
      final prefs = await SharedPreferences.getInstance();
      final existingHistory = prefs.getStringList('edited_images_history') ?? [];
      
      print('🔄 [DEBUG] Historique existant: ${existingHistory.length} items');
      
      // Ajouter la nouvelle image éditée
      existingHistory.insert(0, jsonEncode(editedImageHistory));
      
      // Limiter à 50 images pour éviter de surcharger
      if (existingHistory.length > 50) {
        existingHistory.removeRange(50, existingHistory.length);
      }
      
      await prefs.setStringList('edited_images_history', existingHistory);
      
      print('✅ [DEBUG] Sauvegardé! Nouvel historique: ${existingHistory.length} items');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image sauvegardée dans l\'historique!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Erreur sauvegarde historique: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur sauvegarde: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getFilterLabel(ImageFilter filter) {
    switch (filter) {
      case ImageFilter.none:
        return 'Aucun';
      case ImageFilter.blackAndWhite:
        return 'N&B';
      case ImageFilter.sepia:
        return 'Sépia';
      case ImageFilter.vintage:
        return 'Vintage';
      case ImageFilter.cool:
        return 'Froid';
      case ImageFilter.warm:
        return 'Chaud';
      case ImageFilter.bright:
        return 'Lumineux';
      case ImageFilter.dark:
        return 'Sombre';
    }
  }

  String _getFrameLabel(ImageFrame frame) {
    switch (frame) {
      case ImageFrame.none:
        return 'Aucun';
      case ImageFrame.simple:
        return 'Simple';
      case ImageFrame.rounded:
        return 'Arrondi';
      case ImageFrame.shadow:
        return 'Ombre';
      case ImageFrame.polaroid:
        return 'Polaroid';
      case ImageFrame.film:
        return 'Film';
    }
  }

  String _getEffectLabel(ImageEffect effect) {
    switch (effect) {
      case ImageEffect.none:
        return 'Aucun';
      case ImageEffect.blur:
        return 'Flou';
      case ImageEffect.shadow:
        return 'Ombre';
      case ImageEffect.glow:
        return 'Lueur';
      case ImageEffect.emboss:
        return 'Relief';
      case ImageEffect.sharpen:
        return 'Netteté';
    }
  }
}