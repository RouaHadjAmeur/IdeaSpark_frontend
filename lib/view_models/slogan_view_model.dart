import 'package:flutter/material.dart';
import '../models/slogan_model.dart';
import '../core/slogan_service.dart';
import '../core/favorites_storage_service.dart';

class SloganViewModel extends ChangeNotifier {
  List<SloganModel> _slogans = [];
  bool _isLoading = false;
  String? _error;
  final FavoritesStorageService _favoritesStorage = FavoritesStorageService();

  List<SloganModel> get slogans => _slogans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Retourne uniquement les slogans marqués comme favoris
  List<SloganModel> get favoriteSlogans => _slogans.where((s) => s.isFavorite).toList();

  Future<void> generateSlogans({
    required String brandName,
    required String sector,
    required String brandValues,
    required String targetAudience,
    required String tone,
    required String language,
    String? token,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _slogans = await SloganService.generateSlogans(
        brandName: brandName,
        sector: sector,
        brandValues: brandValues,
        targetAudience: targetAudience,
        tone: tone,
        language: language,
      );
      
      // Sauvegarder automatiquement les nouveaux slogans sur le backend
      for (int i = 0; i < _slogans.length; i++) {
        try {
          final saved = await SloganService.saveSlogan(_slogans[i]);
          _slogans[i] = saved;
        } catch (e) {
          print('⚠️ Erreur sauvegarde auto: $e');
        }
      }

      await _loadFavoriteStates();
      _error = null;
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        _error = 'Authentification requise. Veuillez vous connecter.';
      } else {
        _error = errorMessage.replaceAll('Exception: ', '');
      }
      _slogans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Génère des slogans à partir des champs professionnels de copywriting
  Future<void> generateSlogansFromCopywritingForm({
    required String objectifCommunication,
    required String adjectifPersonnalite,
    required String promessePrincipale,
    required String usageQuotidien,
    required String obstacleResolu,
    required String resultatConcret,
    required String niveauGamme,
    required String faiblesseCorrigee,
    required String traitDistinctif,
    required String angle,
    required String pilierCommunication,
    required String niveauLangue,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _slogans = await SloganService.generateSlogansFromCopywriting(
        objectifCommunication: objectifCommunication,
        adjectifPersonnalite: adjectifPersonnalite,
        promessePrincipale: promessePrincipale,
        usageQuotidien: usageQuotidien,
        obstacleResolu: obstacleResolu,
        resultatConcret: resultatConcret,
        niveauGamme: niveauGamme,
        faiblesseCorrigee: faiblesseCorrigee,
        traitDistinctif: traitDistinctif,
        angle: angle,
        pilierCommunication: pilierCommunication,
        niveauLangue: niveauLangue,
      );
      
      // Sauvegarder automatiquement les nouveaux slogans sur le backend
      for (int i = 0; i < _slogans.length; i++) {
        try {
          final saved = await SloganService.saveSlogan(_slogans[i]);
          _slogans[i] = saved;
        } catch (e) {
          print('⚠️ Erreur sauvegarde auto: $e');
        }
      }

      await _loadFavoriteStates();
      _error = null;
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        _error = 'Authentification requise. Veuillez vous connecter.';
      } else {
        _error = errorMessage.replaceAll('Exception: ', '');
      }
      _slogans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// Charge l'état des favoris depuis le backend (ou stockage local en fallback)
  Future<void> fetchHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _slogans = await SloganService.getHistory();
      _error = null;
    } catch (e) {
      print('⚠️ Erreur lors du chargement de l\'historique: $e');
      _error = 'Impossible de charger l\'historique.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge l'état des favoris depuis le stockage pour les slogans actuels
  Future<void> _loadFavoriteStates() async {
    try {
      final favoriteSlogans = await SloganService.getSloganFavorites();
      final favoriteSloganTexts = favoriteSlogans.map((s) => s.slogan).toList();
      
      // Mettre à jour l'état favori pour chaque slogan
      for (int i = 0; i < _slogans.length; i++) {
        if (favoriteSloganTexts.contains(_slogans[i].slogan)) {
          _slogans[i] = _slogans[i].copyWith(isFavorite: true);
        }
      }
      
      print('✅ États favoris restaurés pour ${_slogans.length} slogans');
    } catch (e) {
      print('⚠️ Erreur lors du chargement des états favoris: $e');
    }
  }

  /// Bascule l'état favori d'un slogan et sauvegarde sur le backend
  Future<void> toggleFavorite(String sloganId) async {
    final index = _slogans.indexWhere((s) => s.id == sloganId);
    if (index != -1) {
      try {
        // Optimistic UI update
        final oldSlogan = _slogans[index];
        final newFavoriteState = !oldSlogan.isFavorite;
        
        _slogans[index] = oldSlogan.copyWith(isFavorite: newFavoriteState);
        notifyListeners();

        if (newFavoriteState) {
          // Si on ajoute en favori et que c'est un nouveau slogan (pas d'ID backend encore)
          // on le sauvegarde d'abord. Les slogans reçus de generate ont des IDs temporaires.
          // Pour simplifier, on utilise l'ID retourné par toggleFavorite du backend si possible.
          // Mais notre toggleFavorite backend attend un ID existant.
          
          // SOLUTION: Si le slogan n'est pas dans l'historique backend, on le save d'abord.
          // Pour l'instant on va utiliser toggleFavorite direct si l'ID ressemble à un MongoDB ID.
          if (oldSlogan.id.length < 20) { // Probablement un mock ID
             final saved = await SloganService.saveSlogan(oldSlogan.copyWith(isFavorite: true));
             _slogans[index] = saved;
          } else {
             await SloganService.toggleFavorite(oldSlogan.id);
          }
        } else {
          await SloganService.toggleFavorite(oldSlogan.id);
        }
      } catch (e) {
        print('❌ Erreur toggleFavorite: $e');
        // Rollback on error if needed
      }
      notifyListeners();
    }
  }

  /// Sauvegarde un slogan
  Future<void> saveSlogan(SloganModel slogan) async {
    try {
      await SloganService.saveSlogan(slogan);
    } catch (e) {
      print('❌ Erreur saveSlogan: $e');
    }
  }


  /// Retourne le nombre total de favoris sauvegardés (tous slogans confondus)
  Future<int> getTotalFavoritesCount() async {
    return await _favoritesStorage.getFavoritesCount();
  }

  /// Efface tous les favoris sauvegardés
  Future<void> clearAllFavorites() async {
    await _favoritesStorage.clearFavorites();
    
    // Mettre à jour l'état des slogans actuels
    for (int i = 0; i < _slogans.length; i++) {
      if (_slogans[i].isFavorite) {
        _slogans[i] = _slogans[i].copyWith(isFavorite: false);
      }
    }
    
    notifyListeners();
  }

  void clearSlogans() {
    _slogans = [];
    _error = null;
    notifyListeners();
  }
}

