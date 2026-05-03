import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/media_editor_models.dart';

/// Widget de canvas pour le dessin à main levée avec outils avancés
class DrawingCanvasWidget extends StatefulWidget {
  final List<DrawingStroke> strokes;
  final Color currentColor;
  final double currentStrokeWidth;
  final Function(DrawingStroke) onStrokeAdded;
  final Function() onUndo;
  final Function() onClear;
  final Function(Color) onColorChanged;
  final Function(double) onStrokeWidthChanged;

  const DrawingCanvasWidget({
    super.key,
    required this.strokes,
    required this.currentColor,
    required this.currentStrokeWidth,
    required this.onStrokeAdded,
    required this.onUndo,
    required this.onClear,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
  });

  @override
  State<DrawingCanvasWidget> createState() => _DrawingCanvasWidgetState();
}

class _DrawingCanvasWidgetState extends State<DrawingCanvasWidget> {
  List<Offset> _currentStroke = [];
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Canvas de dessin
        Positioned.fill(
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: DrawingCanvasPainter(
                strokes: widget.strokes,
                currentStroke: _currentStroke,
                currentColor: widget.currentColor,
                currentStrokeWidth: widget.currentStrokeWidth,
              ),
              size: Size.infinite,
            ),
          ),
        ),
        
        // Barre d'outils de dessin
        Positioned(
          top: 60,
          right: 16,
          child: _buildDrawingToolbar(),
        ),
      ],
    );
  }

  /// Construire la barre d'outils de dessin
  Widget _buildDrawingToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sélecteur de couleur
          _buildColorPalette(),
          
          const SizedBox(height: 12),
          
          // Slider de taille de pinceau
          _buildBrushSizeSlider(),
          
          const SizedBox(height: 12),
          
          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Construire la palette de couleurs
  Widget _buildColorPalette() {
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
      children: [
        Text(
          'Couleur',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: colors.map((color) {
            final isSelected = widget.currentColor == color;
            return GestureDetector(
              onTap: () {
                widget.onColorChanged(color);
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color == Colors.white ? Colors.black : Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Construire le slider de taille de pinceau
  Widget _buildBrushSizeSlider() {
    return Column(
      children: [
        Text(
          'Taille',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        // Aperçu de la taille
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              width: widget.currentStrokeWidth,
              height: widget.currentStrokeWidth,
              decoration: BoxDecoration(
                color: widget.currentColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Slider
        SizedBox(
          width: 120,
          child: Slider(
            value: widget.currentStrokeWidth,
            min: 2,
            max: 20,
            divisions: 18,
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
            onChanged: (value) {
              widget.onStrokeWidthChanged(value);
              HapticFeedback.selectionClick();
            },
          ),
        ),
      ],
    );
  }

  /// Construire les boutons d'action
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Bouton Annuler
        _buildToolButton(
          icon: Icons.undo,
          label: 'Annuler',
          onTap: widget.strokes.isNotEmpty ? widget.onUndo : null,
        ),
        
        const SizedBox(height: 8),
        
        // Bouton Effacer tout
        _buildToolButton(
          icon: Icons.clear,
          label: 'Effacer',
          onTap: widget.strokes.isNotEmpty ? widget.onClear : null,
        ),
      ],
    );
  }

  /// Construire un bouton d'outil
  Widget _buildToolButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white24 : Colors.white12,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.white38,
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Début du trait de dessin
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _currentStroke = [details.localPosition];
    });
    
    HapticFeedback.lightImpact();
  }

  /// Continuation du trait de dessin
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDrawing) {
      setState(() {
        _currentStroke.add(details.localPosition);
      });
    }
  }

  /// Fin du trait de dessin
  void _onPanEnd(DragEndDetails details) {
    if (_isDrawing && _currentStroke.isNotEmpty) {
      final stroke = DrawingStroke(
        points: List.from(_currentStroke),
        color: widget.currentColor,
        strokeWidth: widget.currentStrokeWidth,
      );
      
      widget.onStrokeAdded(stroke);
      
      setState(() {
        _isDrawing = false;
        _currentStroke.clear();
      });
      
      HapticFeedback.mediumImpact();
    }
  }
}

/// Painter personnalisé pour le canvas de dessin
class DrawingCanvasPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;

  DrawingCanvasPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner tous les traits terminés
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke.points, stroke.paint);
    }
    
    // Dessiner le trait en cours
    if (currentStroke.isNotEmpty) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      
      _drawStroke(canvas, currentStroke, paint);
    }
  }

  /// Dessiner un trait avec lissage
  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    
    if (points.length == 1) {
      // Point unique
      canvas.drawCircle(points.first, paint.strokeWidth / 2, paint);
      return;
    }
    
    // Créer un chemin lissé
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    if (points.length == 2) {
      // Ligne simple
      path.lineTo(points.last.dx, points.last.dy);
    } else {
      // Courbe lissée avec des courbes de Bézier
      for (int i = 1; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        
        // Point de contrôle pour le lissage
        final controlPoint = Offset(
          (current.dx + next.dx) / 2,
          (current.dy + next.dy) / 2,
        );
        
        path.quadraticBezierTo(
          current.dx,
          current.dy,
          controlPoint.dx,
          controlPoint.dy,
        );
      }
      
      // Terminer avec le dernier point
      path.lineTo(points.last.dx, points.last.dy);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget pour l'aperçu du pinceau
class BrushPreview extends StatelessWidget {
  final Color color;
  final double size;

  const BrushPreview({
    super.key,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}