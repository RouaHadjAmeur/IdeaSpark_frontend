import 'package:flutter/material.dart';
import '../models/product_idea_model.dart';
import '../services/product_idea_service.dart';

class ProductIdeaViewModel extends ChangeNotifier {
  ProductIdeaResult? _idea;
  bool _isLoading = false;
  String? _error;
  
  // États pour les idées sauvegardées
  List<SavedProductIdea> _savedIdeas = [];
  List<SavedProductIdea> _favoriteIdeas = [];
  bool _isSaving = false;
  bool _isLoadingHistory = false;
  bool _isLoadingFavorites = false;
  String? _saveError;
  bool _isCurrentIdeaSaved = false;

  ProductIdeaResult? get idea => _idea;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<SavedProductIdea> get savedIdeas => _savedIdeas;
  List<SavedProductIdea> get favoriteIdeas => _favoriteIdeas;
  bool get isSaving => _isSaving;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingFavorites => _isLoadingFavorites;
  String? get saveError => _saveError;
  bool get isCurrentIdeaSaved => _isCurrentIdeaSaved;

  Future<void> generateProductIdea({
    required String besoin,
    double? temperature,
    int? maxTokens,
  }) async {
    _isLoading = true;
    _error = null;
    _isCurrentIdeaSaved = false; // Réinitialiser l'état de sauvegarde
    notifyListeners();

    try {
      _idea = await ProductIdeaService.generateProductIdea(
        besoin: besoin,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _idea = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _idea = null;
    _error = null;
    _isLoading = false;
    _isCurrentIdeaSaved = false; // Réinitialiser l'état de sauvegarde
    notifyListeners();
  }

  // Méthodes CRUD pour les idées sauvegardées
  Future<void> saveCurrentIdea() async {
    if (_idea == null || _isCurrentIdeaSaved) return;

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final savedIdea = await ProductIdeaService.saveProductIdea(
        besoin: _idea!.besoin,
        produit: _idea!.produit,
        rawOutput: _idea!.rawOutput,
        durationSeconds: _idea!.durationSeconds,
        modelLoaded: _idea!.modelLoaded,
      );
      
      // Ajouter à la liste des idées sauvegardées
      _savedIdeas.insert(0, savedIdea);
      _isCurrentIdeaSaved = true; // Marquer comme sauvegardée
      _saveError = null;
    } catch (e) {
      _saveError = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedIdeas() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      _savedIdeas = await ProductIdeaService.getProductIdeasHistory();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadFavoriteIdeas() async {
    _isLoadingFavorites = true;
    notifyListeners();

    try {
      _favoriteIdeas = await ProductIdeaService.getProductIdeasFavorites();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final updatedIdea = await ProductIdeaService.toggleProductIdeaFavorite(id);
      
      // Mettre à jour dans les deux listes
      _updateIdeaInList(_savedIdeas, updatedIdea);
      _updateIdeaInList(_favoriteIdeas, updatedIdea);
      
      // Rafraîchir la liste des favoris
      await loadFavoriteIdeas();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteIdea(String id) async {
    try {
      await ProductIdeaService.deleteProductIdea(id);
      
      // Supprimer des deux listes
      _savedIdeas.removeWhere((idea) => idea.id == id);
      _favoriteIdeas.removeWhere((idea) => idea.id == id);
      
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void _updateIdeaInList(List<SavedProductIdea> list, SavedProductIdea updatedIdea) {
    final index = list.indexWhere((idea) => idea.id == updatedIdea.id);
    if (index != -1) {
      list[index] = updatedIdea;
    }
  }

  void clearSaveError() {
    _saveError = null;
    notifyListeners();
  }
}
