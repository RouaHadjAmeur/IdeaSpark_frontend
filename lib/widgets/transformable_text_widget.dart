import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/media_editor_models.dart';

/// Widget de texte transformable avec gestes avancés (pinch-to-zoom, rotation, déplacement)
class TransformableTextWidget extends StatefulWidget {
  final EditableTextElement element;
  final Function(EditableTextElement) onUpdate;
  final Function(String) onDelete;
  final Function(EditableTextElement) onEdit;
  final Function(bool) onDragStateChanged;
  final Function(Offset) onPositionChanged;

  const TransformableTextWidget({
    super.key,
    required this.element,
    required this.onUpdate,
    required this.onDelete,
    required this.onEdit,
    required this.onDragStateChanged,
    required this.onPositionChanged,
  });

  @override
  State<TransformableTextWidget> createState() => _TransformableTextWidgetState();
}

class _TransformableTextWidgetState extends State<TransformableTextWidget> {
  late Matrix4 _transform;
  late Offset _position;
  
  // État des gestes
  bool _isDragging = false;
  bool _isScaling = false;
  bool _isRotating = false;
  
  // Valeurs initiales pour les transformations
  double _initialScale = 1.0;
  double _currentScale = 1.0;
  double _initialRotation = 0.0;
  double _currentRotation = 0.0;
  Offset _initialFocalPoint = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    _transform = Matrix4.copy(widget.element.transform);
    _position = widget.element.position;
  }

  @override
  void didUpdateWidget(TransformableTextWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.id != widget.element.id) {
      _transform = Matrix4.copy(widget.element.transform);
      _position = widget.element.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx * MediaQuery.of(context).size.width - 50,
      top: _position.dy * MediaQuery.of(context).size.height - 25,
      child: GestureDetector(
        // Gestion du tap simple pour édition
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onEdit(widget.element);
        },
        
        // Gestion du déplacement
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        
        child: Transform(
          transform: _transform,
          alignment: Alignment.center,
          child: GestureDetector(
            // Gestion des gestes multi-touch (pinch-to-zoom et rotation)
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // Bordure visible pendant l'édition
                border: _isDragging || _isScaling || _isRotating
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: _buildStyledText(),
            ),
          ),
        ),
      ),
    );
  }

  /// Construire le texte avec style appliqué
  Widget _buildStyledText() {
    Widget textWidget = Text(
      widget.element.text,
      style: TextStyle(
        color: widget.element.color,
        fontSize: widget.element.fontSize,
        fontWeight: widget.element.fontWeight,
      ),
      textAlign: TextAlign.center,
    );

    // Appliquer le style de background selon le type sélectionné
    switch (widget.element.backgroundStyle) {
      case TextBackgroundStyle.solid:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.element.backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: textWidget,
        );
      
      case TextBackgroundStyle.semiTransparent:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.element.backgroundColor.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: textWidget,
        );
      
      case TextBackgroundStyle.outline:
        return Stack(
          children: [
            // Contour noir pour la lisibilité
            Text(
              widget.element.text,
              style: TextStyle(
                fontSize: widget.element.fontSize,
                fontWeight: widget.element.fontWeight,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..color = Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            // Texte principal
            textWidget,
          ],
        );
      
      default: // TextBackgroundStyle.none
        return textWidget;
    }
  }

  /// Début du déplacement (pan)
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    
    widget.onDragStateChanged(true);
    HapticFeedback.mediumImpact();
  }

  /// Mise à jour du déplacement
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isScaling && !_isRotating) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final screenSize = MediaQuery.of(context).size;
        final localPosition = renderBox.globalToLocal(details.globalPosition);
        
        final newPosition = Offset(
          (localPosition.dx / screenSize.width).clamp(0.0, 1.0),
          (localPosition.dy / screenSize.height).clamp(0.0, 1.0),
        );
        
        setState(() {
          _position = newPosition;
        });
        
        widget.onPositionChanged(newPosition);
      }
    }
  }

  /// Fin du déplacement
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    
    widget.onDragStateChanged(false);
    
    // Mettre à jour l'élément avec la nouvelle position
    final updatedElement = widget.element.copyWith(
      position: _position,
      transform: _transform,
    );
    
    widget.onUpdate(updatedElement);
    HapticFeedback.lightImpact();
  }

  /// Début des gestes de transformation (scale/rotate)
  void _onScaleStart(ScaleStartDetails details) {
    _initialScale = _currentScale;
    _initialRotation = _currentRotation;
    _initialFocalPoint = details.focalPoint;
    
    setState(() {
      _isScaling = true;
    });
    
    HapticFeedback.mediumImpact();
  }

  /// Mise à jour des transformations
  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 2) {
      // Gestes à deux doigts : zoom et rotation
      setState(() {
        // Mise à jour de l'échelle (pinch-to-zoom)
        _currentScale = (_initialScale * details.scale).clamp(0.5, 3.0);
        
        // Mise à jour de la rotation (rotation à deux doigts)
        _currentRotation = _initialRotation + details.rotation;
        
        // Appliquer les transformations à la matrice
        _transform = Matrix4.identity()
          ..scale(_currentScale)
          ..rotateZ(_currentRotation);
      });
      
      // Feedback haptique léger pendant la transformation
      if (details.scale != 1.0 || details.rotation != 0.0) {
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Fin des transformations
  void _onScaleEnd(ScaleEndDetails details) {
    setState(() {
      _isScaling = false;
      _isRotating = false;
    });
    
    // Mettre à jour l'élément avec les nouvelles transformations
    final updatedElement = widget.element.copyWith(
      position: _position,
      transform: _transform,
    );
    
    widget.onUpdate(updatedElement);
    HapticFeedback.mediumImpact();
  }
}

/// Widget pour afficher les guides d'alignement
class AlignmentGuides extends StatelessWidget {
  final List<EditableTextElement> elements;
  final String? activeElementId;

  const AlignmentGuides({
    super.key,
    required this.elements,
    this.activeElementId,
  });

  @override
  Widget build(BuildContext context) {
    if (activeElementId == null) return const SizedBox.shrink();
    
    final activeElement = elements.firstWhere(
      (e) => e.id == activeElementId,
      orElse: () => elements.first,
    );
    
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    final elementX = activeElement.position.dx * screenSize.width;
    final elementY = activeElement.position.dy * screenSize.height;
    
    // Tolérance pour l'alignement
    const tolerance = 10.0;
    
    List<Widget> guides = [];
    
    // Guide vertical central
    if ((elementX - centerX).abs() < tolerance) {
      guides.add(
        Positioned(
          left: centerX - 1,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            color: Colors.yellow.withOpacity(0.8),
          ),
        ),
      );
    }
    
    // Guide horizontal central
    if ((elementY - centerY).abs() < tolerance) {
      guides.add(
        Positioned(
          top: centerY - 1,
          left: 0,
          right: 0,
          child: Container(
            height: 2,
            color: Colors.yellow.withOpacity(0.8),
          ),
        ),
      );
    }
    
    // Guides d'alignement avec d'autres éléments
    for (final otherElement in elements) {
      if (otherElement.id == activeElementId) continue;
      
      final otherX = otherElement.position.dx * screenSize.width;
      final otherY = otherElement.position.dy * screenSize.height;
      
      // Alignement vertical
      if ((elementX - otherX).abs() < tolerance) {
        guides.add(
          Positioned(
            left: otherX - 1,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: Colors.blue.withOpacity(0.6),
            ),
          ),
        );
      }
      
      // Alignement horizontal
      if ((elementY - otherY).abs() < tolerance) {
        guides.add(
          Positioned(
            top: otherY - 1,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              color: Colors.blue.withOpacity(0.6),
            ),
          ),
        );
      }
    }
    
    return Stack(children: guides);
  }
}