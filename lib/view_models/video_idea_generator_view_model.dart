import 'package:flutter/foundation.dart';
import '../models/video_generator_models.dart';
import '../services/video_generator_service.dart';

/// ViewModel for Video Ideas Generation and Results
/// Manages the generation process, loading state, and error handling
class VideoIdeaGeneratorViewModel extends ChangeNotifier {
  final VideoIdeaGeneratorService _service;

  // State
  List<VideoIdea> _ideas = [];
  List<VideoIdea> _history = [];
  List<VideoIdea> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;
  VideoRequest? _lastRequest;

  VideoIdeaGeneratorViewModel({
    required VideoIdeaGeneratorService service,
  }) : _service = service;

  // Getters
  List<VideoIdea> get ideas => _ideas;
  List<VideoIdea> get history => _history;
  List<VideoIdea> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  VideoRequest? get lastRequest => _lastRequest;

  bool get hasError => _errorMessage != null;
  bool get hasIdeas => _ideas.isNotEmpty;
  int get ideaCount => _ideas.length;

  /// Generate ideas from a VideoRequest
  Future<void> generateIdeas(VideoRequest request, {bool useRemote = false}) async {
    _lastRequest = request;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final generatedIdeas = await _service.generateIdeas(request, useRemote: useRemote);
      // Filter out ideas with empty versions to prevent RangeError
      _ideas = generatedIdeas.where((idea) => idea.versions.isNotEmpty).toList();

      // If they were generated locally (fallback), save them to backend history
      if (_ideas.isNotEmpty && _ideas.first.id.contains('_')) {
        debugPrint('Auto-saving local fallback ideas to backend...');
        for (int i = 0; i < _ideas.length; i++) {
          try {
            final saved = await _service.saveIdea(_ideas[i]);
            _ideas[i] = saved;
          } catch (e) {
            debugPrint('Error auto-saving fallback idea: $e');
          }
        }
      }

      _errorMessage = null;
    } catch (e) {
      debugPrint('Error generating ideas: $e');
      _errorMessage = 'Une erreur est survenue lors de la génération. Veuillez réessayer.';
      _ideas = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Regenerate ideas using the last request
  Future<void> regenerateIdeas({bool useRemote = false}) async {
    if (_lastRequest != null) {
      await generateIdeas(_lastRequest!, useRemote: useRemote);
    }
  }

  /// Get remaining refinement tries for an idea
  int getRemainingTries(String ideaId) {
    final idea = getIdeaById(ideaId);
    if (idea == null) return 0;
    return 4 - idea.versions.length; // Max 4 versions (Original + 3 tries)
  }

  /// Refine an existing idea
  Future<void> refineIdea(String ideaId, String instruction) async {
    final idea = getIdeaById(ideaId);
    if (idea == null) return;

    if (getRemainingTries(ideaId) <= 0) {
      _errorMessage = 'Nombre maximum de raffinements atteint (3)';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      VideoIdea? targetIdea = getIdeaById(ideaId);
      if (targetIdea == null) return;

      // Handle mock IDs from local fallback
      if (ideaId.contains('_')) { // Local IDs are timestamp_index
        debugPrint('Saving local idea to backend before refinement: $ideaId');
        final savedIdea = await _service.saveIdea(targetIdea);
        // Replace in list to update ID
        final idx = _ideas.indexWhere((i) => i.id == ideaId);
        if (idx != -1) _ideas[idx] = savedIdea;
        ideaId = savedIdea.id;
      }

      final updatedIdea = await _service.refineIdea(ideaId, instruction);
      
      // Update the idea in our local list
      final index = _ideas.indexWhere((i) => i.id == ideaId);
      if (index != -1) {
        _ideas[index] = updatedIdea;
      }
      
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error refining idea: $e');
      _errorMessage = 'Échec du raffinement. Veuillez réessayer.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve a specific version of an idea
  Future<void> approveVersion(String ideaId, int versionIndex) async {
    _isLoading = true;
    notifyListeners();

    try {
      VideoIdea? targetIdea = getIdeaById(ideaId);
      if (targetIdea == null) return;

      // Handle mock IDs
      if (ideaId.contains('_')) {
        debugPrint('Saving local idea to backend before approval: $ideaId');
        final savedIdea = await _service.saveIdea(targetIdea);
        final idx = _ideas.indexWhere((i) => i.id == ideaId);
        if (idx != -1) _ideas[idx] = savedIdea;
        ideaId = savedIdea.id;
      }

      final updatedIdea = await _service.approveVersion(ideaId, versionIndex);
      
      final index = _ideas.indexWhere((i) => i.id == ideaId);
      if (index != -1) {
        _ideas[index] = updatedIdea;
      }
    } catch (e) {
      debugPrint('Error approving version: $e');
      _errorMessage = 'Échec de l\'approbation.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Locally switch viewed version (without API call, for preview)
  void switchVersionLocal(String ideaId, int versionIndex) {
    final index = _ideas.indexWhere((i) => i.id == ideaId);
    if (index != -1) {
        final idea = _ideas[index];
        _ideas[index] = VideoIdea(
            id: idea.id,
            versions: idea.versions,
            currentVersionIndex: versionIndex,
            productImageUrl: idea.productImageUrl,
            userId: idea.userId,
            isApproved: idea.isApproved,
            createdAt: idea.createdAt,
        );
        notifyListeners();
    }
  }

  /// Fetch generation history
  Future<void> fetchHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _history = await _service.getHistory();
    } catch (e) {
      debugPrint('Error fetching history: $e');
      _errorMessage = 'Échec du chargement de l\'historique.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch favorite ideas
  Future<void> fetchFavorites() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _favorites = await _service.getFavorites();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      _errorMessage = 'Échec du chargement des favoris.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle favorite status of an idea
  Future<void> toggleFavoriteStatus(String ideaId) async {
    try {
      VideoIdea? targetIdea = getIdeaById(ideaId);
      if (targetIdea == null) return;

      // Handle mock IDs
      if (ideaId.contains('_')) {
        debugPrint('Saving local idea to backend before toggling favorite: $ideaId');
        final savedIdea = await _service.saveIdea(targetIdea);
        // IMPORTANT: update local references first so _updateIdeaInLists works with new ID
        _updateIdeaInListsManual(ideaId, savedIdea);
        ideaId = savedIdea.id;
      }

      final updatedIdea = await _service.toggleFavorite(ideaId);
      
      // Update in all lists if present
      _updateIdeaInLists(updatedIdea);
      
      // If it was toggled from favorites screen, we might need to refresh favorites
      if (updatedIdea.isFavorite) {
         if (!_favorites.any((i) => i.id == updatedIdea.id)) {
           _favorites.insert(0, updatedIdea);
         }
      } else {
         _favorites.removeWhere((i) => i.id == updatedIdea.id);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _errorMessage = 'Erreur lors de la modification des favoris.';
      notifyListeners();
    }
  }

  void _updateIdeaInListsManual(String oldId, VideoIdea updatedIdea) {
    // Replace by ID because the ID itself changed
    int idx = _ideas.indexWhere((i) => i.id == oldId);
    if (idx != -1) _ideas[idx] = updatedIdea;
    
    idx = _history.indexWhere((i) => i.id == oldId);
    if (idx != -1) _history[idx] = updatedIdea;
    
    idx = _favorites.indexWhere((i) => i.id == oldId);
    if (idx != -1) _favorites[idx] = updatedIdea;
  }

  /// Delete an idea
  Future<void> deleteIdea(String ideaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteIdea(ideaId);
      
      _ideas.removeWhere((i) => i.id == ideaId);
      _history.removeWhere((i) => i.id == ideaId);
      _favorites.removeWhere((i) => i.id == ideaId);
      
      _errorMessage = null;
    } catch (e) {
      debugPrint('Error deleting idea: $e');
      _errorMessage = 'Échec de la suppression.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateIdeaInLists(VideoIdea updatedIdea) {
    // Update in ideas
    int idx = _ideas.indexWhere((i) => i.id == updatedIdea.id);
    if (idx != -1) _ideas[idx] = updatedIdea;
    
    // Update in history
    idx = _history.indexWhere((i) => i.id == updatedIdea.id);
    if (idx != -1) _history[idx] = updatedIdea;
    
    // Update in favorites
    idx = _favorites.indexWhere((i) => i.id == updatedIdea.id);
    if (idx != -1) _favorites[idx] = updatedIdea;
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear all ideas and reset state
  void clearIdeas() {
    _ideas = [];
    _errorMessage = null;
    _isLoading = false;
    _lastRequest = null;
    notifyListeners();
  }

  /// Get idea by ID
  VideoIdea? getIdeaById(String id) {
    try {
      return _ideas.firstWhere((idea) => idea.id == id, orElse: () => 
             _history.firstWhere((idea) => idea.id == id, orElse: () =>
             _favorites.firstWhere((idea) => idea.id == id)));
    } catch (e) {
      return null;
    }
  }
}
