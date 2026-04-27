# 📱 Documentation Frontend → Backend
## Fonctionnalités développées par Chayma Rzig

---

## 1. 📅 Google Calendar Integration

### Ce qui est fait (Frontend)
- Connexion OAuth2 via navigateur
- Stockage des tokens (access + refresh) dans SharedPreferences
- Ouverture directe de Google Calendar

### Endpoints backend existants (port 3000)
```
GET  /google-calendar/auth-url        → URL d'autorisation OAuth
GET  /google-calendar/callback        → Récupération des tokens
POST /google-calendar/create-test-event → Créer un événement test
GET  /google-calendar/events          → Lister les événements
POST /google-calendar/sync-entry      → Synchroniser une entrée
POST /google-calendar/sync-plan       → Synchroniser un plan complet
```

### Endpoints manquants à créer
```
POST /google-calendar/refresh-token
Body: { "refreshToken": "string" }
Response: { "accessToken": "string", "expiresAt": "datetime" }
```

---

## 2. 🔔 Notifications Push (Firebase)

### Ce qui est fait (Frontend)
- Firebase Messaging configuré
- Notifications locales avec `flutter_local_notifications`
- Toggle activer/désactiver les rappels par plan
- Écran de notifications in-app avec historique
- Badge sur l'icône cloche

### Ce que le backend doit faire

#### Endpoint pour enregistrer le token FCM
```
POST /notifications/register-token
Headers: Authorization: Bearer {jwt}
Body: {
  "fcmToken": "string",
  "platform": "android" | "ios"
}
Response: { "success": true }
```

#### Endpoint pour envoyer une notification
```
POST /notifications/send
Headers: Authorization: Bearer {jwt}
Body: {
  "userId": "uuid",
  "title": "string",
  "body": "string",
  "data": { "planId": "uuid", "type": "reminder" }
}
```

#### Endpoint pour les rappels planifiés
```
POST /notifications/schedule
Headers: Authorization: Bearer {jwt}
Body: {
  "planId": "uuid",
  "scheduledAt": "datetime",
  "title": "string",
  "body": "string"
}
```

#### Table `user_fcm_tokens`
```sql
CREATE TABLE user_fcm_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES users(id),
  fcm_token  TEXT NOT NULL,
  platform   VARCHAR(10),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 3. 📄 Export PDF

### Ce qui est fait (Frontend)
- Génération PDF locale avec le package `pdf`
- Export du plan complet avec phases et posts
- Impression/partage via `printing`

### Ce que le backend peut faire (optionnel)
```
POST /plans/:id/export-pdf
Headers: Authorization: Bearer {jwt}
Response: PDF file (application/pdf)
```

---

## 4. 📊 Statistiques du Plan

### Ce qui est fait (Frontend)
- Calcul local des statistiques
- Distribution par format (Reel/Carousel/Story/Post)
- Distribution par CTA (Hard/Soft/Educational)
- Top piliers de contenu
- Répartition par phase

### Endpoints backend à créer
```
GET /plans/:id/stats
Headers: Authorization: Bearer {jwt}
Response: {
  "totalPosts": 28,
  "byFormat": {
    "reel": 8,
    "carousel": 7,
    "story": 6,
    "post": 7
  },
  "byCta": {
    "hard": 10,
    "soft": 10,
    "educational": 8
  },
  "byPillar": {
    "Motivation": 8,
    "Education": 7,
    "Lifestyle": 6,
    "Product": 7
  },
  "byPhase": [
    { "weekNumber": 1, "name": "Phase 1", "count": 7 }
  ]
}
```

---

## 5. ✨ Générateur de Captions IA

### Ce qui est fait (Frontend)
- Génération locale (fallback)
- 3 versions : courte, moyenne, longue
- Hashtags par plateforme
- Emojis suggérés
- CTA personnalisé

### Endpoint backend à créer (avec Gemini/OpenAI)
```
POST /caption-generator/generate
Headers: Authorization: Bearer {jwt}
Body: {
  "postTitle": "string",
  "platform": "Instagram" | "TikTok" | "Facebook" | "LinkedIn",
  "format": "reel" | "carousel" | "story" | "post",
  "pillar": "string",
  "ctaType": "hard" | "soft" | "educational",
  "brandName": "string",
  "language": "fr" | "en" | "ar"
}
Response: {
  "short": "Caption courte...",
  "medium": "Caption moyenne...",
  "long": "Caption longue...",
  "hashtags": ["#brand", "#marketing"],
  "emojis": ["🔥", "💪", "✨"],
  "cta": "👉 Achetez maintenant !"
}
```

#### Prompt Gemini suggéré
```
Génère 3 versions de caption pour un post {platform} :
- Titre : {postTitle}
- Format : {format}
- Pilier : {pillar}
- CTA : {ctaType}
- Marque : {brandName}

Retourne un JSON avec : short (max 50 mots), medium (max 100 mots),
long (max 200 mots), hashtags (10 max), emojis (5 max), cta (1 phrase).
```

---

## 6. 🔖 Templates de Plans

### Ce qui est fait (Frontend)
- Sauvegarde locale dans SharedPreferences
- Affichage de la liste des templates
- Suppression de templates

### Endpoints backend à créer
```
POST /plan-templates
Headers: Authorization: Bearer {jwt}
Body: {
  "name": "string",
  "description": "string",
  "durationWeeks": 4,
  "postingFrequency": 7,
  "totalPosts": 28,
  "planId": "uuid"  // plan source
}

GET /plan-templates
Headers: Authorization: Bearer {jwt}
Response: [ { "id": "uuid", "name": "...", ... } ]

DELETE /plan-templates/:id
Headers: Authorization: Bearer {jwt}
```

#### Table `plan_templates`
```sql
CREATE TABLE plan_templates (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID REFERENCES users(id),
  name              VARCHAR(255) NOT NULL,
  description       TEXT,
  duration_weeks    INT,
  posting_frequency INT,
  total_posts       INT,
  created_at        TIMESTAMP DEFAULT NOW()
);
```

---

## 7. 📤 Partage de Plan

### Ce qui est fait (Frontend)
- Partage via `share_plus` (WhatsApp, Email, etc.)
- Génération d'un texte formaté avec les détails du plan

### Endpoint backend à créer (lien partageable)
```
POST /plans/:id/share
Headers: Authorization: Bearer {jwt}
Response: {
  "shareUrl": "https://ideaspark.app/plans/shared/abc123",
  "expiresAt": "2026-04-25T00:00:00Z"
}

GET /plans/shared/:token
Response: Plan public (sans authentification)
```

---

## 8. 👁️ Aperçu du Post

### Ce qui est fait (Frontend)
- Aperçu Instagram (feed, stories)
- Aperçu TikTok
- Aperçu Facebook
- Génération locale des hashtags et CTA

### Pas d'endpoint backend nécessaire
(Tout est calculé côté Flutter)

---

## 9. 👥 Collaboration (voir COLLABORATION_BACKEND_DOC.md)

### Résumé des endpoints
```
POST   /collaboration/invite
GET    /collaboration/:planId/members
PATCH  /collaboration/:planId/members/:memberId
DELETE /collaboration/:planId/members/:memberId
GET    /collaboration/comments/:postId
POST   /collaboration/comments
DELETE /collaboration/comments/:commentId
GET    /collaboration/:planId/history
```

---

## 📁 Fichiers Flutter créés

```
lib/
├── models/
│   ├── google_calendar_tokens.dart
│   └── collaboration.dart
├── services/
│   ├── google_calendar_service.dart
│   ├── google_calendar_storage_service.dart
│   ├── notification_service.dart
│   ├── in_app_notification_service.dart
│   ├── caption_generator_service.dart
│   ├── pdf_export_service.dart
│   └── collaboration_service.dart
├── views/
│   ├── settings/
│   │   └── google_calendar_token_screen.dart
│   ├── notifications/
│   │   └── notifications_screen.dart
│   ├── content/
│   │   ├── post_preview_screen.dart
│   │   └── caption_generator_screen.dart
│   ├── templates/
│   │   └── plan_templates_screen.dart
│   ├── analytics/
│   │   └── plan_stats_screen.dart
│   └── collaboration/
│       ├── collaboration_screen.dart
│       └── post_comments_screen.dart
```

---

## 🔧 Packages Flutter ajoutés

```yaml
# pubspec.yaml
firebase_core: ^3.6.0
firebase_messaging: ^15.1.3
flutter_local_notifications: ^17.2.2
share_plus: ^10.1.4
pdf: ^3.11.1
printing: ^5.13.1
```

---

## 🔑 Variables d'environnement backend nécessaires

```env
# Firebase Admin SDK (pour envoyer des notifications)
FIREBASE_PROJECT_ID=deaspark-8e635
FIREBASE_PRIVATE_KEY=...
FIREBASE_CLIENT_EMAIL=...

# Email (pour les invitations)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@ideaspark.app
SMTP_PASS=...

# App URL (pour les liens d'invitation)
APP_URL=https://ideaspark.app
```

---

## 📊 Priorité d'implémentation

| Fonctionnalité | Priorité | Complexité | Impact |
|----------------|----------|------------|--------|
| Caption Generator (Gemini) | 🔴 Haute | Faible | Élevé |
| Notifications FCM | 🔴 Haute | Moyenne | Élevé |
| Collaboration | 🟡 Moyenne | Élevée | Élevé |
| Templates | 🟡 Moyenne | Faible | Moyen |
| Statistiques | 🟢 Basse | Faible | Moyen |
| Partage (lien) | 🟢 Basse | Moyenne | Moyen |

---

**Développeur Frontend :** Chayma Rzig  
**Date :** Mars 2026  
**Branche GitHub :** `chayma` sur `RouaHadjAmeur/IdeaSpark_frontend`
