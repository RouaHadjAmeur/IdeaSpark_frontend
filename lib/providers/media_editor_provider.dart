import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/media_editor_models.dart';

/// Provider pour la gestion d'état de l'éditeur multimédia
class MediaEditorProvider extends ChangeNotifier {
  // État de l'éditeur
  EditMode _currentMode = EditMode.none;
  List<EditableTextElement> _textElements = [];
  List<DrawingStroke> _drawingStrokes = [];
  MediaFilter _currentFilter = MediaFilter.predefinedFilters[0];
  
  // État de l'interface
  bool _showUI = true;
  bool _showTrash = false;
  
  // État du texte
  Color _selectedTextColor = Colors.white;
  double _selectedFontSize = 24.0;
  TextBackgroundStyle _selectedBackgroundStyle = TextBackgroundStyle.none;
  
  // État du dessin
  Color _drawingColor = Colors.white;
  double _drawingStrokeWidth = 5.0;
  bool _isDrawing = false;
  
  // Getters
  EditMode get currentMode => _currentMode;
  List<EditableTextElement> get textElements => List.unmodifiable(_textElements);
  List<DrawingStroke> get drawingStrokes => List.unmodifiable(_drawingStrokes);
  MediaFilter get currentFilter => _currentFilter;
  bool get showUI => _showUI;
  bool get showTrash => _showTrash;
  Color get selectedTextColor => _selectedTextColor;
  double get selectedFontSize => _selectedFontSize;
  TextBackgroundStyle get selectedBackgroundStyle => _selectedBackgroundStyle;
  Color get drawingColor => _drawingColor;
  double get drawingStrokeWidth => _drawingStrokeWidth;
  bool get isDrawing => _isDrawing;

  /// Changer le mode d'édition
  void setMode(EditMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  /// Basculer la visibilité de l'UI
  void toggleUI() {
    _showUI = !_showUI;
    notifyListeners();
  }

  /// Afficher/masquer la poubelle
  void setTrashVisibility(bool visible) {
    _showTrash = visible;
    notifyListeners();
  }

  /// Ajouter un élément de texte
  void addTextElement(EditableTextElement element) {
    _textElements.add(element);
    notifyListeners();
  }

  /// Mettre à jour un élément de texte
  void updateTextElement(String id, EditableTextElement updatedElement) {
    final index = _textElements.indexWhere((e) => e.id == id);
    if (index != -1) {
      _textElements[index] = updatedElement;
      notifyListeners();
    }
  }

  /// Supprimer un élément de texte
  void removeTextElement(String id) {
    _textElements.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Mettre à jour la position d'un élément de texte
  void updateTextElementPosition(String id, Offset position) {
    final index = _textElements.indexWhere((e) => e.id == id);
    if (index != -1) {
      _textElements[index] = _textElements[index].copyWith(position: position);
      notifyListeners();
    }
  }

  /// Mettre à jour la transformation d'un élément de texte
  void updateTextElementTransform(String id, Matrix4 transform) {
    final index = _textElements.indexWhere((e) => e.id == id);
    if (index != -1) {
      _textElements[index] = _textElements[index].copyWith(transform: transform);
      notifyListeners();
    }
  }

  /// Changer la couleur du texte sélectionné
  void setSelectedTextColor(Color color) {
    _selectedTextColor = color;
    notifyListeners();
  }

  /// Changer la taille de police sélectionnée
  void setSelectedFontSize(double size) {
    _selectedFontSize = size;
    notifyListeners();
  }

  /// Changer le style de background sélectionné
  void setSelectedBackgroundStyle(TextBackgroundStyle style) {
    _selectedBackgroundStyle = style;
    notifyListeners();
  }

  /// Changer le filtre actuel
  void setCurrentFilter(MediaFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// Commencer un nouveau trait de dessin
  void startDrawing(Offset point) {
    _isDrawing = true;
    final newStroke = DrawingStroke(
      points: [point],
      color: _drawingColor,
      strokeWidth: _drawingStrokeWidth,
    );
    _drawingStrokes.add(newStroke);
    notifyListeners();
  }

  /// Continuer le trait de dessin actuel
  void continueDrawing(Offset point) {
    if (_isDrawing && _drawingStrokes.isNotEmpty) {
      final currentStroke = _drawingStrokes.last;
      final updatedPoints = List<Offset>.from(currentStroke.points)..add(point);
      
      _drawingStrokes[_drawingStrokes.length - 1] = DrawingStroke(
        points: updatedPoints,
        color: currentStroke.color,
        strokeWidth: currentStroke.strokeWidth,
      );
      notifyListeners();
    }
  }

  /// Terminer le trait de dessin actuel
  void endDrawing() {
    _isDrawing = false;
    notifyListeners();
  }

  /// Changer la couleur de dessin
  void setDrawingColor(Color color) {
    _drawingColor = color;
    notifyListeners();
  }

  /// Changer la largeur du trait de dessin
  void setDrawingStrokeWidth(double width) {
    _drawingStrokeWidth = width;
    notifyListeners();
  }

  /// Annuler le dernier trait de dessin
  void undoLastStroke() {
    if (_drawingStrokes.isNotEmpty) {
      _drawingStrokes.removeLast();
      notifyListeners();
    }
  }

  /// Effacer tous les traits de dessin
  void clearDrawing() {
    _drawingStrokes.clear();
    notifyListeners();
  }

  /// Réinitialiser l'éditeur
  void reset() {
    _currentMode = EditMode.none;
    _textElements.clear();
    _drawingStrokes.clear();
    _currentFilter = MediaFilter.predefinedFilters[0];
    _showUI = true;
    _showTrash = false;
    _selectedTextColor = Colors.white;
    _selectedFontSize = 24.0;
    _selectedBackgroundStyle = TextBackgroundStyle.none;
    _drawingColor = Colors.white;
    _drawingStrokeWidth = 5.0;
    _isDrawing = false;
    notifyListeners();
  }

  /// Obtenir l'état sérialisé pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'textElements': _textElements.map((e) => {
        'id': e.id,
        'text': e.text,
        'color': e.color.value,
        'fontSize': e.fontSize,
        'fontWeight': e.fontWeight.index,
        'backgroundStyle': e.backgroundStyle.index,
        'backgroundColor': e.backgroundColor.value,
        'position': {'dx': e.position.dx, 'dy': e.position.dy},
        'size': {'width': e.size.width, 'height': e.size.height},
        'transform': e.transform.storage,
      }).toList(),
      'drawingStrokes': _drawingStrokes.map((s) => {
        'points': s.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'color': s.color.value,
        'strokeWidth': s.strokeWidth,
      }).toList(),
      'currentFilter': _currentFilter.name,
    };
  }

  /// Restaurer l'état depuis les données sérialisées
  void fromJson(Map<String, dynamic> json) {
    // Restaurer les éléments de texte
    _textElements = (json['textElements'] as List? ?? []).map((e) {
      return EditableTextElement(
        id: e['id'],
        text: e['text'],
        color: Color(e['color']),
        fontSize: e['fontSize'].toDouble(),
        fontWeight: FontWeight.values[e['fontWeight']],
        backgroundStyle: TextBackgroundStyle.values[e['backgroundStyle']],
        backgroundColor: Color(e['backgroundColor']),
        position: Offset(e['position']['dx'], e['position']['dy']),
        size: Size(e['size']['width'], e['size']['height']),
        transform: Matrix4.fromList(List<double>.from(e['transform'])),
      );
    }).toList();

    // Restaurer les traits de dessin
    _drawingStrokes = (json['drawingStrokes'] as List? ?? []).map((s) {
      return DrawingStroke(
        points: (s['points'] as List).map((p) => Offset(p['dx'], p['dy'])).toList(),
        color: Color(s['color']),
        strokeWidth: s['strokeWidth'].toDouble(),
      );
    }).toList();

    // Restaurer le filtre
    final filterName = json['currentFilter'] as String?;
    if (filterName != null) {
      _currentFilter = MediaFilter.predefinedFilters.firstWhere(
        (f) => f.name == filterName,
        orElse: () => MediaFilter.predefinedFilters[0],
      );
    }

    notifyListeners();
  }
}