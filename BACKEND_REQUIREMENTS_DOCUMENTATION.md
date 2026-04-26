# Documentation Backend - Fonctionnalités Requises 🚀

## 📋 RÉSUMÉ EXÉCUTIF

Cette documentation détaille toutes les fonctionnalités backend nécessaires pour supporter l'application IdeaSpark Flutter. Le backend doit être implémenté en **NestJS** avec **MongoDB** et supporter les APIs suivantes.

---

## 🎯 FONCTIONNALITÉS DÉJÀ IMPLÉMENTÉES (100% COMPLÈTES)

### ✅ 1. GÉNÉRATEUR D'IMAGES GRATUIT
**Status:** TERMINÉ ✅  
**API:** Unsplash + Pexels

**Endpoints requis:**
```typescript
POST /ai-images/generate
GET /ai-images/history
DELETE /ai-images/:id
PATCH /content-blocks/:id/image
```

**Fonctionnalités:**
- Génération d'images via Unsplash API
- Détection automatique de catégorie
- Historique des images générées
- Sauvegarde d'images dans les posts
- Support de 7 catégories (cosmétiques, sport, mode, tech, food, travel, lifestyle)

### ✅ 2. HASHTAGS TENDANCES
**Status:** TERMINÉ ✅  
**Base de données:** 126 hashtags, 7 catégories

**Endpoints requis:**
```typescript
GET /trending-hashtags?category=cosmetics&platform=instagram
GET /trending-hashtags/generate?brandName=lela&postTitle=...&category=cosmetics
```

**Fonctionnalités:**
- 7 catégories avec hashtags spécialisés
- Cache 24h pour performance
- Détection automatique de catégorie
- Génération contextuelle (marque + titre + catégorie)

### ✅ 3. GÉNÉRATEUR VIDÉO GRATUIT
**Status:** TERMINÉ ✅  
**API:** Pexels Videos API

**Endpoints requis:**
```typescript
POST /video-generator/generate
GET /video-generator/history
GET /video-generator/:id
POST /video-generator/:id/save-to-post
DELETE /video-generator/:id
```

**Fonctionnalités:**
- Génération de vidéos via Pexels Videos API
- Support durée (15s, 30s, 60s)
- Support orientation (portrait, paysage, carré)
- Détection automatique de catégorie
- Historique et sauvegarde

---

## 🆕 NOUVELLES FONCTIONNALITÉS À IMPLÉMENTER

### 🖼️ 4. ÉDITEUR D'IMAGES AVANCÉ
**Status:** NOUVEAU - À IMPLÉMENTER

**Endpoints requis:**
```typescript
POST /image-editor/process
POST /image-editor/apply-filter
POST /image-editor/add-frame
POST /image-editor/add-text
POST /image-editor/resize
POST /image-editor/apply-effects
GET /image-editor/history/:userId
DELETE /image-editor/:id
```

**Modèle de données:**
```typescript
interface EditedImage {
  id: string;
  userId: string;
  originalUrl: string;
  editedUrl?: string;
  filter: 'none' | 'blackAndWhite' | 'sepia' | 'vintage' | 'cool' | 'warm' | 'bright' | 'dark';
  frame: 'none' | 'simple' | 'rounded' | 'shadow' | 'polaroid' | 'film';
  frameColor?: number;
  textOverlays: TextOverlay[];
  effects: ImageEffect[];
  resizedWidth?: number;
  resizedHeight?: number;
  createdAt: Date;
  updatedAt: Date;
}

interface TextOverlay {
  text: string;
  x: number; // Position 0-1
  y: number; // Position 0-1
  fontSize: number;
  color: number;
  bold: boolean;
  italic: boolean;
}

enum ImageEffect {
  none = 'none',
  blur = 'blur',
  shadow = 'shadow',
  glow = 'glow',
  emboss = 'emboss',
  sharpen = 'sharpen'
}
```

**Bibliothèques recommandées:**
- **Sharp** (Node.js) pour traitement d'images
- **Canvas** pour superpositions de texte
- **Multer** pour upload de fichiers

### 🎬 5. ÉDITEUR VIDÉO AVANCÉ
**Status:** NOUVEAU - À IMPLÉMENTER

**Endpoints requis:**
```typescript
POST /video-editor/process
POST /video-editor/add-music
POST /video-editor/add-text
POST /video-editor/add-subtitles
POST /video-editor/trim
POST /video-editor/add-transitions
GET /video-editor/history/:userId
DELETE /video-editor/:id
```

**Modèle de données:**
```typescript
interface VideoEdit {
  id: string;
  userId: string;
  originalVideoPath: string;
  editedVideoPath?: string;
  music?: VideoMusic;
  textOverlays: VideoTextOverlay[];
  subtitles: VideoSubtitle[];
  trimStart?: Duration;
  trimEnd?: Duration;
  transitions: VideoTransitionEffect[];
  createdAt: Date;
  updatedAt: Date;
}

interface VideoMusic {
  name: string;
  path: string;
}

interface VideoTextOverlay {
  text: string;
  startTime: Duration;
  endTime: Duration;
  x: number;
  y: number;
  fontSize: number;
  color: number;
}

interface VideoSubtitle {
  text: string;
  startTime: Duration;
  endTime: Duration;
}

interface VideoTransitionEffect {
  type: 'fade' | 'slide' | 'zoom' | 'dissolve' | 'wipe';
  duration: Duration;
  position: Duration;
}
```

**Bibliothèques recommandées:**
- **FFmpeg** pour traitement vidéo
- **Node-ffmpeg** wrapper pour Node.js
- **Multer** pour upload de fichiers

### 📤 6. PARTAGE AVANCÉ MULTI-PLATEFORMES
**Status:** NOUVEAU - À IMPLÉMENTER

**Endpoints requis:**
```typescript
POST /advanced-share/schedule
POST /advanced-share/share-now
GET /advanced-share/connected-accounts/:userId
POST /advanced-share/connect-account
DELETE /advanced-share/disconnect-account/:accountId
GET /advanced-share/scheduled-posts/:userId
DELETE /advanced-share/scheduled-posts/:postId
GET /advanced-share/statistics/:postId
POST /advanced-share/generate-hashtags
```

**Modèle de données:**
```typescript
interface ScheduledPost {
  id: string;
  userId: string;
  contentId: string;
  contentType: 'image' | 'video';
  contentUrl: string;
  caption: string;
  hashtags: string[];
  platforms: SocialPlatform[];
  accountIds: string[];
  scheduledTime: Date;
  status: 'scheduled' | 'published' | 'failed';
  publishedAt?: Date;
  statistics?: ShareStatistics;
  createdAt: Date;
}

interface SocialAccount {
  id: string;
  userId: string;
  platform: SocialPlatform;
  name: string;
  username: string;
  profileImageUrl?: string;
  accessToken: string;
  refreshToken?: string;
  isActive: boolean;
  connectedAt: Date;
}

enum SocialPlatform {
  instagram = 'instagram',
  tiktok = 'tiktok',
  facebook = 'facebook',
  twitter = 'twitter',
  linkedin = 'linkedin',
  youtube = 'youtube'
}

interface ShareStatistics {
  views: number;
  likes: number;
  comments: number;
  shares: number;
  reach: number;
  engagement: number;
  clickThroughRate: number;
}
```

**APIs externes requises:**
- **Instagram Basic Display API**
- **TikTok for Developers**
- **Facebook Graph API**
- **Twitter API v2**
- **LinkedIn API**
- **YouTube Data API v3**

---

## 🔧 INFRASTRUCTURE TECHNIQUE

### 📊 Base de Données MongoDB
**Collections requises:**
```typescript
// Existantes
- users
- brands
- plans
- content_blocks
- generated_images
- generated_videos
- trending_hashtags

// Nouvelles
- edited_images
- edited_videos
- scheduled_posts
- social_accounts
- share_statistics
```

### 🗂️ Stockage de Fichiers
**Structure recommandée:**
```
/storage
  /images
    /original
    /edited
    /thumbnails
  /videos
    /original
    /edited
    /thumbnails
  /music
    /tracks
  /temp
    /processing
```

**Services de stockage:**
- **Local** pour développement
- **AWS S3** ou **Google Cloud Storage** pour production
- **CDN** pour distribution rapide

### 🔐 Authentification et Sécurité
**OAuth 2.0 pour réseaux sociaux:**
```typescript
// Configuration requise
const socialAuthConfig = {
  instagram: {
    clientId: process.env.INSTAGRAM_CLIENT_ID,
    clientSecret: process.env.INSTAGRAM_CLIENT_SECRET,
    redirectUri: process.env.INSTAGRAM_REDIRECT_URI
  },
  // ... autres plateformes
};
```

### ⚡ Performance et Cache
**Redis pour cache:**
```typescript
// Cache recommandé
- trending_hashtags: 24h
- social_accounts: 1h
- processed_images: 7 jours
- processed_videos: 3 jours
```

---

## 📋 PLAN D'IMPLÉMENTATION

### Phase 1: Éditeur d'Images (Priorité HAUTE)
**Durée estimée:** 3-4 jours
1. Setup Sharp.js pour traitement d'images
2. Implémentation des filtres de base
3. Système de cadres et superpositions
4. API de redimensionnement
5. Tests et optimisation

### Phase 2: Partage Avancé (Priorité HAUTE)
**Durée estimée:** 5-6 jours
1. Configuration OAuth pour chaque plateforme
2. Système de programmation de posts
3. Génération automatique de hashtags
4. Statistiques de partage
5. Interface de gestion des comptes

### Phase 3: Éditeur Vidéo (Priorité MOYENNE)
**Durée estimée:** 7-8 jours
1. Setup FFmpeg et traitement vidéo
2. Système de superpositions et sous-titres
3. Intégration de musique
4. Transitions et effets
5. Optimisation performance

---

## 🔗 ENDPOINTS DÉTAILLÉS

### Éditeur d'Images
```typescript
// Traitement d'image
POST /api/image-editor/process
Body: {
  imageUrl: string,
  filter?: string,
  frame?: string,
  textOverlays?: TextOverlay[],
  effects?: string[],
  resize?: { width: number, height: number }
}
Response: { editedImageUrl: string, processedAt: Date }

// Historique
GET /api/image-editor/history/:userId?page=1&limit=20
Response: { images: EditedImage[], total: number, page: number }
```

### Partage Avancé
```typescript
// Programmer une publication
POST /api/advanced-share/schedule
Body: {
  contentUrl: string,
  contentType: 'image' | 'video',
  caption: string,
  hashtags: string[],
  platforms: string[],
  accountIds: string[],
  scheduledTime: Date
}
Response: { scheduledPostId: string, scheduledAt: Date }

// Comptes connectés
GET /api/advanced-share/connected-accounts/:userId
Response: { accounts: SocialAccount[] }
```

### Éditeur Vidéo
```typescript
// Traitement vidéo
POST /api/video-editor/process
Body: {
  videoPath: string,
  music?: VideoMusic,
  textOverlays?: VideoTextOverlay[],
  subtitles?: VideoSubtitle[],
  trim?: { start: number, end: number },
  transitions?: VideoTransitionEffect[]
}
Response: { editedVideoPath: string, processedAt: Date }
```

---

## 🧪 TESTS ET VALIDATION

### Tests Unitaires Requis
```typescript
// Éditeur d'images
- Filtres: application correcte de chaque filtre
- Cadres: génération et positionnement
- Texte: superposition et formatage
- Redimensionnement: ratios et qualité

// Partage avancé
- OAuth: connexion et déconnexion
- Programmation: création et exécution
- Hashtags: génération contextuelle
- Statistiques: collecte et agrégation

// Éditeur vidéo
- Musique: synchronisation et mixage
- Texte: timing et positionnement
- Sous-titres: génération et formatage
- Transitions: application et durée
```

### Tests d'Intégration
```typescript
// Workflow complet
1. Génération d'image → Édition → Partage programmé
2. Génération de vidéo → Édition → Partage immédiat
3. Connexion compte social → Publication → Statistiques
```

---

## 📊 MONITORING ET ANALYTICS

### Métriques à Suivre
```typescript
// Performance
- Temps de traitement d'images (< 5s)
- Temps de traitement vidéo (< 30s)
- Taux de succès des publications (> 95%)
- Temps de réponse API (< 2s)

// Usage
- Nombre d'images éditées/jour
- Nombre de vidéos éditées/jour
- Nombre de publications programmées
- Plateformes les plus utilisées
```

### Logs Requis
```typescript
// Traitement
- Début/fin de traitement
- Erreurs de traitement
- Temps d'exécution
- Ressources utilisées

// Partage social
- Tentatives de publication
- Succès/échecs par plateforme
- Erreurs d'authentification
- Statistiques collectées
```

---

## 🚀 DÉPLOIEMENT

### Variables d'Environnement
```bash
# Base de données
MONGODB_URI=mongodb+srv://...
REDIS_URL=redis://...

# Stockage
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET_NAME=...

# APIs externes
UNSPLASH_ACCESS_KEY=...
PEXELS_API_KEY=...

# Réseaux sociaux
INSTAGRAM_CLIENT_ID=...
INSTAGRAM_CLIENT_SECRET=...
FACEBOOK_APP_ID=...
FACEBOOK_APP_SECRET=...
TIKTOK_CLIENT_KEY=...
TIKTOK_CLIENT_SECRET=...
TWITTER_API_KEY=...
TWITTER_API_SECRET=...
LINKEDIN_CLIENT_ID=...
LINKEDIN_CLIENT_SECRET=...
YOUTUBE_CLIENT_ID=...
YOUTUBE_CLIENT_SECRET=...

# Traitement
FFMPEG_PATH=/usr/bin/ffmpeg
MAX_IMAGE_SIZE=10MB
MAX_VIDEO_SIZE=100MB
PROCESSING_TIMEOUT=300s
```

### Configuration Docker
```dockerfile
# Dockerfile pour backend
FROM node:18-alpine

# Installation FFmpeg
RUN apk add --no-cache ffmpeg

# Installation Sharp
RUN apk add --no-cache \
    vips-dev \
    build-base \
    python3

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

---

## ✅ CHECKLIST DE VALIDATION

### Avant Mise en Production
- [ ] Tous les endpoints implémentés et testés
- [ ] OAuth configuré pour toutes les plateformes
- [ ] Traitement d'images fonctionnel (Sharp.js)
- [ ] Traitement vidéo fonctionnel (FFmpeg)
- [ ] Système de cache Redis opérationnel
- [ ] Stockage de fichiers configuré (S3/GCS)
- [ ] Monitoring et logs en place
- [ ] Tests d'intégration passés
- [ ] Performance validée (< 5s images, < 30s vidéos)
- [ ] Sécurité validée (authentification, autorisation)

### Tests Frontend-Backend
- [ ] Génération d'images → Édition → Partage
- [ ] Génération de vidéos → Édition → Partage
- [ ] Connexion comptes sociaux
- [ ] Programmation de publications
- [ ] Collecte de statistiques
- [ ] Gestion d'erreurs

---

**📅 Date de création:** 25 avril 2026  
**👨‍💻 Équipe:** Backend NestJS + MongoDB  
**🎯 Objectif:** Support complet des fonctionnalités d'édition et partage avancé  
**⏱️ Durée estimée:** 15-18 jours de développement