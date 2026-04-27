import 'package:flutter/foundation.dart';
import '../models/video_generator_models.dart';
import '../repositories/saved_ideas_repository.dart';

/// ViewModel for managing saved video ideas
/// Handles loading, saving, and removing ideas using SavedVideoIdeasRepository
class SavedIdeasViewModel extends ChangeNotifier {
  final SavedVideoIdeasRepository _repository;

  // State
  List<VideoIdea> _savedIdeas = [];
  bool _isLoading = false;
  String? _errorMessage;

  SavedIdeasViewModel({
    required SavedVideoIdeasRepository repository,
  }) : _repository = repository;

  // Getters
  List<VideoIdea> get savedIdeas => _savedIdeas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasError => _errorMessage != null;
  bool get hasSavedIdeas => _savedIdeas.isNotEmpty;
  int get savedIdeasCount => _savedIdeas.length;

  /// Load all saved ideas from repository
  Future<void> loadSavedIdeas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ideas = await _repository.getSavedIdeas();
      _savedIdeas = ideas;
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error loading saved ideas: $e');
      _errorMessage = 'Erreur lors du chargement des idées sauvegardées';
      _savedIdeas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save a video idea
  Future<bool> saveIdea(VideoIdea idea) async {
    try {
      await _repository.saveIdea(idea);

      // Check if already in list to avoid duplicates
      if (!_savedIdeas.any((savedIdea) => savedIdea.id == idea.id)) {
        _savedIdeas.add(idea);
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error saving idea: $e');
      _errorMessage = 'Erreur lors de la sauvegarde de l\'idée';
      notifyListeners();
      return false;
    }
  }

  /// Remove a saved idea by ID
  Future<bool> removeIdea(String id) async {
    try {
      await _repository.removeIdea(id);
      _savedIdeas.removeWhere((idea) => idea.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error removing idea: $e');
      _errorMessage = 'Erreur lors de la suppression de l\'idée';
      notifyListeners();
      return false;
    }
  }

  /// Clear all saved ideas
  Future<bool> clearAllIdeas() async {
    try {
      await _repository.clearAll();
      _savedIdeas.clear();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing all ideas: $e');
      _errorMessage = 'Erreur lors de la suppression de toutes les idées';
      notifyListeners();
      return false;
    }
  }

  /// Check if an idea is already saved
  bool isIdeaSaved(String id) {
    return _savedIdeas.any((idea) => idea.id == id);
  }

  /// Get saved idea by ID
  VideoIdea? getIdeaById(String id) {
    try {
      return _savedIdeas.firstWhere((idea) => idea.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
