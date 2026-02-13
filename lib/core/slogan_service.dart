import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';
import 'mock_slogan_data.dart';
import '../models/slogan_model.dart';

class SloganService {
  SloganService._();

  static Future<List<SloganModel>> generateSlogans({
    required String brandName,
    required String sector,
    required String brandValues,
    required String targetAudience,
    required String tone,
    required String language,
    String? token,
    bool useMockData = false,
  }) async {
    // Mode développement : utiliser les données mockées
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 2)); // Simule le délai réseau
      return MockSloganData.generateMockSlogans();
    }

    try {
      // Récupérer automatiquement le token d'authentification
      final authService = AuthService();
      await authService.isLoggedIn(); // Charge le token depuis le stockage
      final authToken = authService.accessToken;
      
      final url = Uri.parse(ApiConfig.generateSlogansUrl);
      
      // Construire le body en n'envoyant que les propriétés acceptées par l'API
      final Map<String, dynamic> requestBody = {
        'brandName': brandName,
        'language': language,
      };

      // Ajouter optionnellement `targetAudience` si renseigné
      if (targetAudience.trim().isNotEmpty) {
        requestBody['targetAudience'] = targetAudience;
      }

      print('🚀 Envoi de la requête à: $url');
      print('📝 Données envoyées: $requestBody');
      print('🔑 Token: ${authToken != null ? "Présent (${authToken.substring(0, 20)}...)" : "Absent"}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Réponse du serveur: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> slogansJson = data['slogans'] ?? [];
        print('✅ ${slogansJson.length} slogans reçus du backend');
        return slogansJson.map((json) => SloganModel.fromJson(json)).toList();
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');

        // Fournir un message d'erreur plus explicite quand le backend relaie
        // une erreur de la Google Generative Language API indiquant qu'un
        // modèle n'est pas trouvé / supporté pour la méthode generateContent.
        final body = response.body ?? '';
        try {
          // Chercher un nom de modèle dans le message retourné (ex: models/gemini-1.5-flash)
          final match = RegExp(r"models/([\w-]+)").firstMatch(body);
          if (match != null && body.contains('not found')) {
            final modelName = match.group(1);
            print('⚠️ Backend attempted to use unsupported model "$modelName". Falling back to mock data for frontend development. Raw server body: $body');
            // Retourner des données mock plutôt que faire échouer l'app
            return MockSloganData.generateMockSlogans();
          }
        } catch (_) {
          // si l'analyse échoue, continuer vers l'exception générique
        }

        throw Exception('Failed to generate slogans: ${response.statusCode} - $body');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la génération des slogans: $e');
      // Pour certains problèmes réseau (ex: backend down, CORS, "Failed to fetch")
      // fournir automatiquement des données mock afin que l'interface reste
      // testable en développement. Les erreurs d'authentification doivent
      // cependant être remontées pour permettre une action de l'utilisateur.
      final msg = e.toString();
      if (msg.contains('Failed to fetch') || msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('XMLHttpRequest')) {
        print('ℹ️ Network/backend unreachable — returning mock slogans for now. Error: $msg');
        return MockSloganData.generateMockSlogans();
      }

      rethrow;
    }
  }

  /// Génère des slogans à partir d'un formulaire professionnel de copywriting
  static Future<List<SloganModel>> generateSlogansFromCopywriting({
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
    bool useMockData = true, // TEMPORAIRE: Activé pour tester l'interface
  }) async {
    // Mode développement : utiliser les données mockées
    if (useMockData) {
      await Future.delayed(const Duration(seconds: 2));
      return MockSloganData.generateMockSlogans();
    }

    try {
      // Récupérer automatiquement le token d'authentification
      final authService = AuthService();
      await authService.isLoggedIn();
      final authToken = authService.accessToken;
      
      final url = Uri.parse(ApiConfig.generateSlogansUrl);
      
      // Construire le prompt professionnel pour l'IA
      final String professionalPrompt = _buildCopywritingPrompt(
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

      // Pour l'instant, mapper vers les anciens champs de l'API
      final Map<String, dynamic> requestBody = {
        'brandName': promessePrincipale.isNotEmpty ? promessePrincipale : 'Marque',
        'targetAudience': usageQuotidien.isNotEmpty ? usageQuotidien : obstacleResolu,
        'language': 'fr',
        // Ajouter le prompt comme metadata si supporté
        'copywritingPrompt': professionalPrompt,
      };

      print('🚀 Envoi de la requête copywriting à: $url');
      print('📝 Données envoyées: $requestBody');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 Réponse du serveur: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final List<dynamic> slogansJson = data['slogans'] ?? [];
        print('✅ ${slogansJson.length} slogans reçus du backend');
        return slogansJson.map((json) => SloganModel.fromJson(json)).toList();
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');
        final body = response.body ?? '';
        
        // Gérer les erreurs de modèle IA
        try {
          final match = RegExp(r"models/([\w-]+)").firstMatch(body);
          if (match != null && body.contains('not found')) {
            print('⚠️ Modèle IA non supporté. Utilisation des données mock.');
            return MockSloganData.generateMockSlogans();
          }
        } catch (_) {}

        throw Exception('Failed to generate slogans: ${response.statusCode} - $body');
      }
    } catch (e) {
      print('⚠️ Erreur lors de la génération des slogans: $e');
      final msg = e.toString();
      
      // Fallback vers mock data pour les erreurs réseau
      if (msg.contains('Failed to fetch') || 
          msg.contains('SocketException') || 
          msg.contains('Connection refused') || 
          msg.contains('XMLHttpRequest')) {
        print('ℹ️ Backend unreachable — returning mock slogans');
        return MockSloganData.generateMockSlogans();
      }

      rethrow;
    }
  }

  /// Construit un prompt professionnel pour l'IA
  static String _buildCopywritingPrompt({
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
  }) {
    return """
Tu es un expert en conception-rédaction (copywriting) et en stratégie de marque. 
Ton objectif est de générer 10 slogans percutants en utilisant les données précises fournies.

1. Identité et Personnalité :
- Objectif de communication : ${objectifCommunication.isNotEmpty ? objectifCommunication : 'Non spécifié'}
- Adjectif de personnalité : ${adjectifPersonnalite.isNotEmpty ? adjectifPersonnalite : 'Non spécifié'}
- Promesse principale : ${promessePrincipale.isNotEmpty ? promessePrincipale : 'Non spécifié'}

2. Expérience et Valeur Utilisateur :
- Usage quotidien : ${usageQuotidien.isNotEmpty ? usageQuotidien : 'Non spécifié'}
- Obstacle majeur résolu (douleur client) : ${obstacleResolu.isNotEmpty ? obstacleResolu : 'Non spécifié'}
- Résultat concret immédiat : ${resultatConcret.isNotEmpty ? resultatConcret : 'Non spécifié'}

3. Positionnement Marché :
- Niveau de gamme : $niveauGamme
- Faiblesse concurrente corrigée : ${faiblesseCorrigee.isNotEmpty ? faiblesseCorrigee : 'Non spécifié'}
- Trait de caractère distinctif : ${traitDistinctif.isNotEmpty ? traitDistinctif : 'Non spécifié'}

4. Directives Rédactionnelles :
- Angle : $angle
- Pilier de communication : $pilierCommunication
- Niveau de langue : $niveauLangue

IMPORTANT: Tous les slogans doivent être DIFFÉRENTS les uns des autres et en français.

Pour chaque slogan, fournis:
1. Le slogan lui-même (court, percutant, mémorable, UNIQUE)
2. Une explication détaillée du positionnement et de la stratégie
3. Un score de mémorabilité de 0 à 100
4. Une catégorie parmi: Innovation, Émotion, Bénéfice, Aspiration, Descriptif, Provocateur, Humoristique

Réponds UNIQUEMENT avec un objet JSON valide dans ce format:
{
  "slogans": [
    {
      "slogan": "Le slogan ici",
      "explanation": "Explication détaillée ici",
      "memorabilityScore": 85,
      "category": "Innovation"
    }
  ]
}

Génère 10 slogans VARIÉS et CRÉATIFS.
""";
  }

  /// Sauvegarde un slogan dans la base de données
  static Future<SloganModel> saveSlogan(SloganModel slogan) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    // Construct whitelisted body for the strict backend DTO
    final whitelistedBody = {
      'slogan': slogan.slogan,
      'explanation': slogan.explanation,
      'memorabilityScore': slogan.memorabilityScore,
      'category': slogan.category,
    };

    final response = await http.post(
      Uri.parse(ApiConfig.saveSloganUrl),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(whitelistedBody),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SloganModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to save slogan: ${response.statusCode}');
    }
  }

  /// Récupère l'historique des slogans depuis le backend
  static Future<List<SloganModel>> getHistory() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final response = await http.get(
      Uri.parse(ApiConfig.getSloganHistoryUrl),
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SloganModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch slogan history: ${response.statusCode}');
    }
  }

  /// Récupère les slogans favoris depuis le backend
  static Future<List<SloganModel>> getSloganFavorites() async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final response = await http.get(
      Uri.parse(ApiConfig.getSloganFavoritesUrl),
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SloganModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch favorites: ${response.statusCode}');
    }
  }

  /// Bascule l'état favori d'un slogan sur le backend
  static Future<SloganModel> toggleFavorite(String sloganId) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final response = await http.post(
      Uri.parse('${ApiConfig.toggleSloganFavoriteUrl}/$sloganId'),
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SloganModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to toggle favorite: ${response.statusCode}');
    }
  }

  /// Supprime un slogan du backend
  static Future<void> deleteSlogan(String sloganId) async {
    final authService = AuthService();
    await authService.isLoggedIn();
    final authToken = authService.accessToken;

    final response = await http.delete(
      Uri.parse('${ApiConfig.deleteSloganUrl}/$sloganId'),
      headers: {
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete slogan: ${response.statusCode}');
    }
  }
}

