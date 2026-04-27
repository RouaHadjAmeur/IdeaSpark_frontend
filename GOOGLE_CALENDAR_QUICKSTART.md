# Google Calendar - Guide de démarrage rapide

## 🚀 Installation (5 minutes)

### 1. Dépendances déjà installées ✅

Les packages nécessaires sont déjà dans votre projet :
- `http` - Pour les appels API
- `shared_preferences` - Pour stocker les tokens
- `url_launcher` - Pour ouvrir le navigateur

### 2. Configuration Google Cloud Console

1. Allez sur https://console.cloud.google.com/
2. Créez un nouveau projet ou sélectionnez un projet existant
3. Activez l'API Google Calendar :
   - Menu → APIs & Services → Library
   - Recherchez "Google Calendar API"
   - Cliquez sur "Enable"

4. Créez des identifiants OAuth 2.0 :
   - Menu → APIs & Services → Credentials
   - Cliquez sur "Create Credentials" → "OAuth client ID"
   - Type d'application : "Web application"
   - Nom : "IdeaSpark Backend"
   - Authorized redirect URIs : `http://localhost:3000/google-calendar/callback`
   - Cliquez sur "Create"

5. Copiez le Client ID et Client Secret

6. Configurez le backend :
   - Ouvrez le fichier `.env` du backend
   - Ajoutez :
     ```
     GOOGLE_CLIENT_ID=votre_client_id
     GOOGLE_CLIENT_SECRET=votre_client_secret
     GOOGLE_REDIRECT_URI=http://localhost:3000/google-calendar/callback
     ```

### 3. Testez l'intégration

```bash
# Démarrez le backend
cd backend
npm start

# Démarrez l'app Flutter
cd ../frontend
flutter run
```

## 📱 Utilisation dans l'app

### Option 1 : Ajouter dans un plan existant

```dart
// Dans votre écran de détail de plan
import 'package:ideaspark/widgets/google_calendar_integration_card.dart';

// Ajoutez la card
GoogleCalendarIntegrationCard(
  planId: plan.id!,
  planName: plan.name,
  authToken: userToken,
)
```

### Option 2 : Ajouter dans les paramètres

```dart
// Dans votre écran de profil/paramètres
import 'package:ideaspark/views/google_calendar/google_calendar_settings_screen.dart';

ListTile(
  leading: Icon(Icons.calendar_today),
  title: Text('Google Calendar'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoogleCalendarSettingsScreen(
          authToken: userToken,
        ),
      ),
    );
  },
)
```

## 🎯 Exemple complet

Voici un exemple complet d'intégration dans un écran de plan :

```dart
import 'package:flutter/material.dart';
import 'package:ideaspark/models/plan.dart';
import 'package:ideaspark/widgets/google_calendar_integration_card.dart';

class PlanDetailScreen extends StatelessWidget {
  final Plan plan;
  final String authToken;

  const PlanDetailScreen({
    required this.plan,
    required this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Informations du plan
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('${plan.phases.length} phases'),
                    Text('${plan.durationWeeks} semaines'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Google Calendar Integration
            GoogleCalendarIntegrationCard(
              planId: plan.id!,
              planName: plan.name,
              authToken: authToken,
              onSyncComplete: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Plan synchronisé avec succès !'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            
            // Reste du contenu...
          ],
        ),
      ),
    );
  }
}
```

## 🔧 Dépannage

### Problème : "Impossible de se connecter au serveur"

**Solution :**
1. Vérifiez que le backend est démarré sur `http://localhost:3000`
2. Sur émulateur Android, utilisez `http://10.0.2.2:3000`
3. Vérifiez votre fichier `lib/core/api_config.dart`

### Problème : "Erreur d'autorisation Google"

**Solution :**
1. Vérifiez que l'API Google Calendar est activée
2. Vérifiez les identifiants OAuth dans le backend
3. Vérifiez l'URI de redirection dans Google Cloud Console

### Problème : "Tokens expirés"

**Solution :**
Les tokens sont automatiquement rafraîchis. Si le problème persiste :
```dart
import 'package:ideaspark/services/google_calendar_storage_service.dart';

// Déconnectez et reconnectez
await GoogleCalendarStorageService.clearTokens();
// Puis reconnectez via l'interface
```

## 📊 Vérifier le statut

```dart
import 'package:ideaspark/services/google_calendar_storage_service.dart';

// Vérifier si connecté
final isConnected = await GoogleCalendarStorageService.isConnected();
print('Google Calendar connecté: $isConnected');

// Récupérer les tokens
final tokens = await GoogleCalendarStorageService.getTokens();
if (tokens != null) {
  print('Access token: ${tokens.accessToken.substring(0, 20)}...');
  print('Expiré: ${tokens.isExpired}');
}
```

## 🎨 Personnalisation

### Changer le style du bouton

```dart
GoogleCalendarConnectButton(
  authToken: userToken,
  onConnected: (tokens) { /* ... */ },
  buttonText: 'Connecter mon calendrier',
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
)
```

### Masquer l'icône

```dart
GoogleCalendarSyncButton(
  planId: planId,
  planName: planName,
  authToken: userToken,
  googleTokens: tokens,
  showIcon: false,
  buttonText: 'Synchroniser',
)
```

## 📚 Ressources

- [Documentation complète](./GOOGLE_CALENDAR_INTEGRATION.md)
- [Google Calendar API](https://developers.google.com/calendar/api)
- [OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)

## ✅ Checklist

- [ ] Backend configuré avec les identifiants Google
- [ ] API Google Calendar activée
- [ ] Dépendances Flutter installées (`flutter pub get`)
- [ ] Widget ajouté dans l'interface
- [ ] Test de connexion réussi
- [ ] Test de synchronisation réussi

## 🎉 C'est tout !

Votre intégration Google Calendar est maintenant prête à l'emploi !
