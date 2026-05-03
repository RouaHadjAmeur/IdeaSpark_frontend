<<<<<<< HEAD
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/slogan_model.dart';

/// Service de stockage persistant pour les slogans favoris
/// Utilise SharedPreferences pour sauvegarder les slogans favoris complets
class FavoritesStorageService {
  static const String _favoritesKey = 'favorite_slogans';

  /// Sauvegarde la liste complète des slogans favoris
  Future<void> saveFavorites(List<SloganModel> favoriteSlogans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = favoriteSlogans.map((s) => s.toJson()).toList();
      await prefs.setString(_favoritesKey, jsonEncode(jsonList));
      print('✅ ${favoriteSlogans.length} slogans favoris sauvegardés');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des favoris: $e');
    }
  }

  /// Récupère la liste des slogans favoris sauvegardés
  Future<List<SloganModel>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('📥 Aucun favori trouvé dans le stockage');
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final slogans = jsonList.map((json) => SloganModel.fromJson(json)).toList();
      print('📥 ${slogans.length} slogans favoris chargés depuis le stockage');
      return slogans;
    } catch (e) {
      print('❌ Erreur lors du chargement des favoris: $e');
      return [];
    }
  }

  /// Ajoute un slogan aux favoris et sauvegarde
  Future<void> addFavorite(SloganModel slogan) async {
    try {
      final favorites = await getFavorites();
      
      // Vérifier si le slogan n'est pas déjà dans les favoris
      if (!favorites.any((s) => s.id == slogan.id)) {
        favorites.add(slogan.copyWith(isFavorite: true));
        await saveFavorites(favorites);
        print('⭐ Favori ajouté: ${slogan.slogan}');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du favori: $e');
    }
  }

  /// Retire un slogan des favoris et sauvegarde
  Future<void> removeFavorite(String sloganId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((s) => s.id == sloganId);
      await saveFavorites(favorites);
      print('☆ Favori retiré: $sloganId');
    } catch (e) {
      print('❌ Erreur lors du retrait du favori: $e');
    }
  }

  /// Vérifie si un slogan est dans les favoris
  Future<bool> isFavorite(String sloganId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((s) => s.id == sloganId);
    } catch (e) {
      print('❌ Erreur lors de la vérification du favori: $e');
      return false;
    }
  }

  /// Efface tous les favoris
  Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      print('🗑️ Tous les favoris ont été effacés');
    } catch (e) {
      print('❌ Erreur lors de l\'effacement des favoris: $e');
    }
  }

  /// Retourne le nombre de favoris sauvegardés
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}

=======
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/slogan_model.dart';

/// Service de stockage persistant pour les slogans favoris
/// Utilise SharedPreferences pour sauvegarder les slogans favoris complets
class FavoritesStorageService {
  static const String _favoritesKey = 'favorite_slogans';

  /// Sauvegarde la liste complète des slogans favoris
  Future<void> saveFavorites(List<SloganModel> favoriteSlogans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = favoriteSlogans.map((s) => s.toJson()).toList();
      await prefs.setString(_favoritesKey, jsonEncode(jsonList));
      print('✅ ${favoriteSlogans.length} slogans favoris sauvegardés');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde des favoris: $e');
    }
  }

  /// Récupère la liste des slogans favoris sauvegardés
  Future<List<SloganModel>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        print('📥 Aucun favori trouvé dans le stockage');
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final slogans = jsonList.map((json) => SloganModel.fromJson(json)).toList();
      print('📥 ${slogans.length} slogans favoris chargés depuis le stockage');
      return slogans;
    } catch (e) {
      print('❌ Erreur lors du chargement des favoris: $e');
      return [];
    }
  }

  /// Ajoute un slogan aux favoris et sauvegarde
  Future<void> addFavorite(SloganModel slogan) async {
    try {
      final favorites = await getFavorites();
      
      // Vérifier si le slogan n'est pas déjà dans les favoris
      if (!favorites.any((s) => s.id == slogan.id)) {
        favorites.add(slogan.copyWith(isFavorite: true));
        await saveFavorites(favorites);
        print('⭐ Favori ajouté: ${slogan.slogan}');
      }
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du favori: $e');
    }
  }

  /// Retire un slogan des favoris et sauvegarde
  Future<void> removeFavorite(String sloganId) async {
    try {
      final favorites = await getFavorites();
      favorites.removeWhere((s) => s.id == sloganId);
      await saveFavorites(favorites);
      print('☆ Favori retiré: $sloganId');
    } catch (e) {
      print('❌ Erreur lors du retrait du favori: $e');
    }
  }

  /// Vérifie si un slogan est dans les favoris
  Future<bool> isFavorite(String sloganId) async {
    try {
      final favorites = await getFavorites();
      return favorites.any((s) => s.id == sloganId);
    } catch (e) {
      print('❌ Erreur lors de la vérification du favori: $e');
      return false;
    }
  }

  /// Efface tous les favoris
  Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      print('🗑️ Tous les favoris ont été effacés');
    } catch (e) {
      print('❌ Erreur lors de l\'effacement des favoris: $e');
    }
  }

  /// Retourne le nombre de favoris sauvegardés
  Future<int> getFavoritesCount() async {
    final favorites = await getFavorites();
    return favorites.length;
  }
}

>>>>>>> wassim
