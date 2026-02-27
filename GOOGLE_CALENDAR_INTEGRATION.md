# Intégration Google Calendar - IdeaSpark Flutter

## Vue d'ensemble

Cette intégration permet aux utilisateurs de synchroniser leurs plans de publication IdeaSpark avec Google Calendar. Les événements sont automatiquement créés dans le calendrier Google de l'utilisateur avec tous les détails de la publication.

## Architecture

### Fichiers créés

```
lib/
├── models/
│   └── google_calendar_tokens.dart          # Modèle pour les tokens OAuth
├── services/
│   ├── google_calendar_service.dart         # Service principal API
│   └── google_calendar_storage_service.dart # Stockage local des tokens
├── widgets/
│   ├── google_calendar_connect_button.dart  # Bouton de connexion
│   ├── google_calendar_sync_button.dart     # Bouton de synchronisation
│   └── google_calendar_integration_card.dart # Card complète
└── views/
    └── google_calendar/
        └── google_calendar_settings_screen.dart # Écran de paramètres
```

### Flux d'authentification OAuth

```
1. User clicks "Connect Google Calendar"
   ↓
2. App requests auth URL from backend
   ↓
3. User is redirected to Google OAuth page
   ↓
4. User authorizes the app
   ↓
5. Google redirects back with authorization code
   ↓
6. App exchanges code for access/refresh tokens
   ↓
7. Tokens are stored locally (SharedPreferences)
   ↓
8. User can now sync plans
```

## Utilisation

### 1. Ajouter les dépendances

Ajoutez dans `pubspec.yaml` :

```yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.2.2
  url_launcher: ^6.2.2
```

Puis exécutez :

```bash
flutter pub get
```

### 2. Configuration Android

Dans `android/app/src/main/AndroidManifest.xml`, ajoutez :

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW" />
    <data android:scheme="https" />
  </intent>
</queries>
```

### 3. Configuration iOS

Dans `ios/Runner/Info.plist`, ajoutez :

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
  <string>http</string>
</array>
```

### 4. Utilisation dans l'application

#### Option A : Card complète (Recommandé)

```dart
import 'package:ideaspark/widgets/google_calendar_integration_card.dart';

// Dans votre widget
GoogleCalendarIntegrationCard(
  planId: plan.id,
  planName: plan.name,
  authToken: userAuthToken,
  onSyncComplete: () {
    // Rafraîchir l'UI ou afficher un message
  },
)
```

#### Option B : Boutons séparés

```dart
import 'package:ideaspark/widgets/google_calendar_connect_button.dart';
import 'package:ideaspark/widgets/google_calendar_sync_button.dart';

// Bouton de connexion
GoogleCalendarConnectButton(
  authToken: userAuthToken,
  onConnected: (tokens) {
    // Sauvegarder les tokens
    setState(() {
      _googleTokens = tokens;
    });
  },
  onError: (error) {
    // Afficher l'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
)

// Bouton de synchronisation (après connexion)
GoogleCalendarSyncButton(
  planId: plan.id!,
  planName: plan.name,
  authToken: userAuthToken,
  googleTokens: _googleTokens!,
  onSyncComplete: (result) {
    print('Synced ${result.synced}/${result.total} entries');
  },
)
```

#### Option C : Écran de paramètres

```dart
import 'package:ideaspark/views/google_calendar/google_calendar_settings_screen.dart';

// Navigation vers l'écran
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GoogleCalendarSettingsScreen(
      authToken: userAuthToken,
    ),
  ),
);
```

### 5. Vérifier le statut de connexion

```dart
import 'package:ideaspark/services/google_calendar_storage_service.dart';

// Vérifier si connecté
final isConnected = await GoogleCalendarStorageService.isConnected();

if (isConnected) {
  // Afficher le bouton de sync
  final tokens = await GoogleCalendarStorageService.getTokens();
  // Utiliser les tokens
} else {
  // Afficher le bouton de connexion
}
```

## Intégration dans les vues existantes

### Dans le Strategic Content Manager

Ajoutez la card dans la vue du plan :

```dart
// Dans lib/views/strategic_content_manager/plan_detail_screen.dart

Column(
  children: [
    // ... autres widgets du plan
    
    const SizedBox(height: 16),
    
    // Google Calendar Integration
    GoogleCalendarIntegrationCard(
      planId: widget.plan.id,
      planName: widget.plan.name,
      authToken: _authToken,
    ),
    
    // ... reste du contenu
  ],
)
```

### Dans les paramètres du profil

Ajoutez un lien vers l'écran de paramètres :

```dart
// Dans lib/views/profile/profile_screen.dart

ListTile(
  leading: const Icon(Icons.calendar_today),
  title: const Text('Google Calendar'),
  subtitle: const Text('Synchroniser vos publications'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleCalendarSettingsScreen(
          authToken: _authToken,
        ),
      ),
    );
  },
)
```

## API Backend

### Endpoints utilisés

1. **GET /google-calendar/auth-url**
   - Obtient l'URL d'autorisation Google OAuth
   - Requiert: JWT token
   - Retourne: `{ "authUrl": "https://..." }`

2. **GET /google-calendar/callback?code=xxx**
   - Échange le code d'autorisation contre des tokens
   - Requiert: JWT token, code d'autorisation
   - Retourne: `{ "accessToken": "...", "refreshToken": "..." }`

3. **POST /google-calendar/sync-entry**
   - Synchronise une entrée de calendrier
   - Requiert: JWT token, calendarEntryId, accessToken, refreshToken
   - Retourne: Success/Error

4. **POST /google-calendar/sync-plan**
   - Synchronise toutes les entrées d'un plan
   - Requiert: JWT token, planId, accessToken, refreshToken
   - Retourne: `{ "total": 10, "synced": 9, "failed": 1, "errors": [...] }`

## Gestion des erreurs

Le service gère automatiquement :

- ✅ Erreurs réseau (timeout, connexion)
- ✅ Erreurs d'authentification (401)
- ✅ Erreurs d'autorisation (403)
- ✅ Tokens expirés
- ✅ Erreurs serveur (5xx)

Les messages d'erreur sont traduits en français et affichés à l'utilisateur.

## Stockage des tokens

Les tokens OAuth sont stockés localement avec `SharedPreferences` :

- **Sécurité** : Les tokens sont stockés de manière sécurisée sur l'appareil
- **Persistance** : Les tokens persistent entre les sessions
- **Expiration** : Le service vérifie automatiquement l'expiration

## Tests

### Tests unitaires

```dart
// test/services/google_calendar_service_test.dart
test('should get auth URL successfully', () async {
  final service = GoogleCalendarService();
  final result = await service.getAuthUrl('test-token');
  
  expect(result.isSuccess, true);
  expect(result.data, contains('https://accounts.google.com'));
});
```

### Tests d'intégration

```dart
// test/integration/google_calendar_flow_test.dart
testWidgets('complete Google Calendar flow', (tester) async {
  // 1. Afficher le bouton de connexion
  await tester.pumpWidget(MyApp());
  expect(find.text('Connecter Google Calendar'), findsOneWidget);
  
  // 2. Cliquer sur le bouton
  await tester.tap(find.text('Connecter Google Calendar'));
  await tester.pumpAndSettle();
  
  // 3. Vérifier que l'URL s'ouvre
  // ...
});
```

## Prochaines étapes

- [ ] Ajouter l'icône Google Calendar dans `assets/images/`
- [ ] Configurer les identifiants OAuth sur Google Cloud Console
- [ ] Tester le flux complet sur Android et iOS
- [ ] Ajouter des analytics pour suivre l'utilisation
- [ ] Implémenter le refresh automatique des tokens expirés
- [ ] Ajouter la possibilité de choisir le calendrier cible

## Support

Pour toute question ou problème :

1. Vérifiez que le backend est démarré (`http://localhost:3000`)
2. Vérifiez les logs de l'application
3. Consultez la documentation Google Calendar API
4. Vérifiez les identifiants OAuth sur Google Cloud Console

## Ressources

- [Google Calendar API Documentation](https://developers.google.com/calendar/api/guides/overview)
- [OAuth 2.0 for Mobile Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Flutter url_launcher Package](https://pub.dev/packages/url_launcher)
- [Flutter shared_preferences Package](https://pub.dev/packages/shared_preferences)
