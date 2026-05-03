import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screenshot/screenshot.dart';
import '../../models/media_editor_models.dart';
import '../../models/edited_image.dart';

/// Éditeur d'images avancé inspiré des Stories Instagram
class AdvancedImageEditorScreen extends StatefulWidget {
  final String imageUrl;
  final String? imageId;

  const AdvancedImageEditorScreen({
    super.key,
    required this.imageUrl,
    this.imageId,
  });

  @override
  State<AdvancedImageEditorScreen> createState() => _AdvancedImageEditorScreenState();
}

class _AdvancedImageEditorScreenState extends State<AdvancedImageEditorScreen>
    with TickerProviderStateMixin {
  
  // Controllers et état
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _textController = TextEditingController();
  late AnimationController _uiAnimationController;
  late AnimationController _trashAnimationController;
  
  // État de l'éditeur
  EditMode _currentMode = EditMode.none;
  List<EditableTextElement> _textElements = [];
  List<DrawingStroke> _drawingStrokes = [];
  MediaFilter _currentFilter = MediaFilter.predefinedFilters[0];
  
  // État du texte en cours d'édition
  String? _editingTextId;
  Color _selectedTextColor = Colors.white;
  double _selectedFontSize = 24.0;
  TextBackgroundStyle _selectedBackgroundStyle = TextBackgroundStyle.none;
  
  // État du dessin
  bool _isDrawing = false;
  Color _drawingColor = Colors.white;
  double _drawingStrokeWidth = 5.0;
  List<Offset> _currentStroke = [];
  
  // État de l'interface
  bool _showUI = true;
  bool _showTrash = false;
  Offset? _trashPosition;
  
  // Image
  Uint8List? _imageData;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadImage();
  }

  void _initializeControllers() {
    _uiAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _trashAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _uiAnimationController.forward();
  }

  @override
  void dispose() {
    _uiAnimationController.dispose();
    _trashAnimationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      if (widget.imageUrl.startsWith('http')) {
        // Charger depuis URL
        final response = await HttpClient().getUrl(Uri.parse(widget.imageUrl));
        final bytes = await response.close();
        final data = await bytes.fold<List<int>>([], (previous, element) => previous..addAll(element));
        setState(() {
          _imageData = Uint8List.fromList(data);
        });
      } else {
        // Charger depuis fichier local
        final file = File(widget.imageUrl);
        final data = await file.readAsBytes();
        setState(() {
          _imageData = data;
        });
      }
    } catch (e) {
      _showError('Erreur de chargement: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Basculer la visibilité de l'interface utilisateur
  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    
    if (_showUI) {
      _uiAnimationController.forward();
    } else {
      _uiAnimationController.reverse();
    }
    
    // Feedback haptique
    HapticFeedback.lightImpact();
  }

  /// Ajouter un nouvel élément de texte
  void _addTextElement() {
    final newElement = EditableTextElement(
      id: const Uuid().v4(),
      text: 'Nouveau texte',
      color: _selectedTextColor,
      fontSize: _selectedFontSize,
      backgroundStyle: _selectedBackgroundStyle,
      position: const Offset(0.5, 0.5), // Centre de l'écran
    );
    
    setState(() {
      _textElements.add(newElement);
      _editingTextId = newElement.id;
      _currentMode = EditMode.text;
    });
    
    // Ouvrir le clavier pour édition
    _showTextEditDialog(newElement);
    
    HapticFeedback.mediumImpact();
  }

  /// Afficher le dialogue d'édition de texte
  void _showTextEditDialog(EditableTextElement element) {
    _textController.text = element.text;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTextEditPanel(element),
    );
  }

  /// Construire le panneau d'édition de texte
  Widget _buildTextEditPanel(EditableTextElement element) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Champ de texte
          TextField(
            controller: _textController,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              hintText: 'Tapez votre texte...',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            autofocus: true,
            maxLines: null,
          ),
          
          const SizedBox(height: 20),
          
          // Sélecteur de couleur
          _buildColorSelector(),
          
          const SizedBox(height: 20),
          
          // Styles de background
          _buildBackgroundStyleSelector(),
          
          const SizedBox(height: 20),
          
          // Slider de taille de police
          Row(
            children: [
              Icon(Icons.text_fields, color: Colors.white, size: 20),
              Expanded(
                child: Slider(
                  value: _selectedFontSize,
                  min: 12,
                  max: 72,
                  divisions: 30,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {
                    setState(() {
                      _selectedFontSize = value;
                    });
                  },
                ),
              ),
              Text(
                '${_selectedFontSize.round()}',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteTextElement(element.id);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                  child: Text('Supprimer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _updateTextElement(element.id);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: Text('Valider'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire le sélecteur de couleur
  Widget _buildColorSelector() {
    final colors = [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Couleur du texte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: colors.map((color) {
            final isSelected = _selectedTextColor == color;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTextColor = color;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: color == Colors.white ? Colors.black : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Construire le sélecteur de style de background
  Widget _buildBackgroundStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style de fond',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBackgroundStyleOption(
              TextBackgroundStyle.none,
              'Aucun',
              Icons.text_fields,
            ),
            _buildBackgroundStyleOption(
              TextBackgroundStyle.solid,
              'Opaque',
              Icons.rectangle,
            ),
            _buildBackgroundStyleOption(
              TextBackgroundStyle.semiTransparent,
              'Semi-transparent',
              Icons.rectangle_outlined,
            ),
            _buildBackgroundStyleOption(
              TextBackgroundStyle.outline,
              'Contour',
              Icons.border_style,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundStyleOption(
    TextBackgroundStyle style,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedBackgroundStyle == style;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBackgroundStyle = style;
        });
        HapticFeedback.selectionClick();
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Mettre à jour un élément de texte
  void _updateTextElement(String id) {
    final index = _textElements.indexWhere((e) => e.id == id);
    if (index != -1) {
      setState(() {
        _textElements[index] = _textElements[index].copyWith(
          text: _textController.text,
          color: _selectedTextColor,
          fontSize: _selectedFontSize,
          backgroundStyle: _selectedBackgroundStyle,
        );
      });
    }
  }

  /// Supprimer un élément de texte
  void _deleteTextElement(String id) {
    setState(() {
      _textElements.removeWhere((e) => e.id == id);
    });
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Screenshot(
          controller: _screenshotController,
          child: Stack(
            children: [
              // Image de fond avec filtre
              _buildImageBackground(),
              
              // Éléments de texte
              ..._textElements.map(_buildTextElement),
              
              // Traits de dessin
              if (_drawingStrokes.isNotEmpty) _buildDrawingLayer(),
              
              // Zone poubelle (visible seulement lors du déplacement)
              if (_showTrash) _buildTrashZone(),
              
              // Interface utilisateur
              if (_showUI) _buildUIOverlay(),
              
              // Bouton pour masquer/afficher l'UI
              Positioned(
                top: 16,
                right: 16,
                child: _buildUIToggleButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construire l'arrière-plan de l'image avec filtre
  Widget _buildImageBackground() {
    if (_imageData == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[900],
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    Widget imageWidget = Image.memory(
      _imageData!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );

    // Appliquer le filtre si nécessaire
    if (_currentFilter.filter != null) {
      imageWidget = ColorFiltered(
        colorFilter: _currentFilter.filter!,
        child: imageWidget,
      );
    }

    return GestureDetector(
      onTap: _toggleUI,
      child: imageWidget,
    );
  }

  /// Construire un élément de texte avec gestes
  Widget _buildTextElement(EditableTextElement element) {
    return Positioned.fill(
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _showTrash = true;
          });
          _trashAnimationController.forward();
        },
        onPanUpdate: (details) {
          // Mettre à jour la position de l'élément
          final renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          final screenSize = MediaQuery.of(context).size;
          
          final newPosition = Offset(
            localPosition.dx / screenSize.width,
            localPosition.dy / screenSize.height,
          );
          
          setState(() {
            final index = _textElements.indexWhere((e) => e.id == element.id);
            if (index != -1) {
              _textElements[index] = _textElements[index].copyWith(
                position: newPosition,
              );
            }
          });
        },
        onPanEnd: (details) {
          setState(() {
            _showTrash = false;
          });
          _trashAnimationController.reverse();
          
          // Vérifier si l'élément est sur la poubelle
          if (_isOverTrash(element.position)) {
            _deleteTextElement(element.id);
          }
        },
        onTap: () => _showTextEditDialog(element),
        child: Transform(
          transform: element.transform,
          child: Positioned(
            left: element.position.dx * MediaQuery.of(context).size.width - 50,
            top: element.position.dy * MediaQuery.of(context).size.height - 25,
            child: _buildStyledText(element),
          ),
        ),
      ),
    );
  }

  /// Construire le texte avec style
  Widget _buildStyledText(EditableTextElement element) {
    Widget textWidget = Text(
      element.text,
      style: TextStyle(
        color: element.color,
        fontSize: element.fontSize,
        fontWeight: element.fontWeight,
      ),
    );

    // Appliquer le style de background
    switch (element.backgroundStyle) {
      case TextBackgroundStyle.solid:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: element.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: textWidget,
        );
      
      case TextBackgroundStyle.semiTransparent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: element.backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: textWidget,
        );
      
      case TextBackgroundStyle.outline:
        return Stack(
          children: [
            // Contour
            Text(
              element.text,
              style: TextStyle(
                fontSize: element.fontSize,
                fontWeight: element.fontWeight,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2
                  ..color = element.backgroundColor,
              ),
            ),
            // Texte principal
            textWidget,
          ],
        );
      
      default:
        return textWidget;
    }
  }

  /// Construire la couche de dessin
  Widget _buildDrawingLayer() {
    return CustomPaint(
      size: Size.infinite,
      painter: DrawingPainter(_drawingStrokes),
    );
  }

  /// Construire la zone poubelle
  Widget _buildTrashZone() {
    return AnimatedBuilder(
      animation: _trashAnimationController,
      builder: (context, child) {
        return Positioned(
          bottom: 100 * _trashAnimationController.value,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Construire l'overlay de l'interface utilisateur
  Widget _buildUIOverlay() {
    return AnimatedBuilder(
      animation: _uiAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _uiAnimationController.value,
          child: Column(
            children: [
              // Barre d'outils du haut
              _buildTopToolbar(),
              
              const Spacer(),
              
              // Barre d'outils du bas
              _buildBottomToolbar(),
            ],
          ),
        );
      },
    );
  }

  /// Construire la barre d'outils du haut
  Widget _buildTopToolbar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildToolButton(
            icon: Icons.close,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          _buildToolButton(
            icon: Icons.download,
            onTap: _exportImage,
          ),
        ],
      ),
    );
  }

  /// Construire la barre d'outils du bas
  Widget _buildBottomToolbar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Filtres
          if (_currentMode == EditMode.filter) _buildFilterSelector(),
          
          const SizedBox(height: 16),
          
          // Boutons principaux
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildModeButton(
                icon: Icons.text_fields,
                label: 'Texte',
                mode: EditMode.text,
                onTap: _addTextElement,
              ),
              _buildModeButton(
                icon: Icons.brush,
                label: 'Dessin',
                mode: EditMode.draw,
                onTap: () => setState(() => _currentMode = EditMode.draw),
              ),
              _buildModeButton(
                icon: Icons.filter,
                label: 'Filtres',
                mode: EditMode.filter,
                onTap: () => setState(() => _currentMode = EditMode.filter),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire le sélecteur de filtres
  Widget _buildFilterSelector() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: MediaFilter.predefinedFilters.length,
        itemBuilder: (context, index) {
          final filter = MediaFilter.predefinedFilters[index];
          final isSelected = _currentFilter.name == filter.name;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentFilter = filter;
              });
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildFilterPreview(filter),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Construire l'aperçu d'un filtre
  Widget _buildFilterPreview(MediaFilter filter) {
    if (_imageData == null) {
      return Container(color: Colors.grey);
    }

    Widget preview = Image.memory(
      _imageData!,
      fit: BoxFit.cover,
      width: 60,
      height: 60,
    );

    if (filter.filter != null) {
      preview = ColorFiltered(
        colorFilter: filter.filter!,
        child: preview,
      );
    }

    return preview;
  }

  /// Construire un bouton d'outil
  Widget _buildToolButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  /// Construire un bouton de mode
  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required EditMode mode,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentMode == mode;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construire le bouton de basculement de l'UI
  Widget _buildUIToggleButton() {
    return GestureDetector(
      onTap: _toggleUI,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _showUI ? Icons.visibility_off : Icons.visibility,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  /// Vérifier si un élément est au-dessus de la poubelle
  bool _isOverTrash(Offset position) {
    // Logique de détection de collision avec la zone poubelle
    final screenHeight = MediaQuery.of(context).size.height;
    final trashY = screenHeight - 180; // Position approximative de la poubelle
    
    return position.dy * screenHeight > trashY;
  }

  /// Exporter l'image finale
  Future<void> _exportImage() async {
    try {
      // Masquer l'UI temporairement
      setState(() {
        _showUI = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Capturer l'écran
      final imageFile = await _screenshotController.capture();
      
      if (imageFile != null) {
        // Sauvegarder l'image
        // Ici tu peux utiliser ton service de sauvegarde existant
        
        _showError('✅ Image exportée avec succès!');
      }
      
      // Réafficher l'UI
      setState(() {
        _showUI = true;
      });
      
    } catch (e) {
      _showError('Erreur d\'export: $e');
      setState(() {
        _showUI = true;
      });
    }
  }
}

/// Painter personnalisé pour le dessin à main levée
class DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length > 1) {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        
        canvas.drawPath(path, stroke.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}