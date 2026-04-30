# 📚 Documentation Backend Complète - IdeaSpark

## 🎯 Vue d'Ensemble

Cette documentation complète couvre toutes les fonctionnalités backend de l'application IdeaSpark, basée sur NestJS avec MongoDB. Elle inclut les fonctionnalités existantes, les nouvelles à implémenter, et les améliorations futures.

---

## 📋 Table des Matières

1. [Fonctionnalités Existantes (100% Complètes)](#fonctionnalités-existantes)
2. [Nouvelles Fonctionnalités à Implémenter](#nouvelles-fonctionnalités)
3. [Architecture Technique](#architecture-technique)
4. [Endpoints API](#endpoints-api)
5. [Base de Données](#base-de-données)
6. [Configuration et Déploiement](#configuration-et-déploiement)
7. [Tests et Validation](#tests-et-validation)
8. [Monitoring et Performance](#monitoring-et-performance)

---

## ✅ Fonctionnalités Existantes (100% Complètes)

### 🎨 1. Générateur d'Images Gratuit
**Status:** TERMINÉ ✅  
**API:** Unsplash + Pexels

#### Endpoints Implémentés
```typescript
POST /ai-images/generate
GET /ai-images/history
DELETE /ai-images/:id
PATCH /content-blocks/:id/image
```

#### Fonctionnalités
- Génération d'images via Unsplash API
- Détection automatique de catégorie
- Historique des images générées
- Sauvegarde d'images dans les posts
- Support de 7 catégories (cosmétiques, sport, mode, tech, food, travel, lifestyle)

#### Modèle de Données
```typescript
interface GeneratedImage {
  id: string;
  userId: string;
  url: string;
  prompt: string;
  style: 'professional' | 'colorful' | 'minimalist' | 'vintage';
  category: string;
  source: 'unsplash' | 'pexels';
  createdAt: Date;
}
```

### 🔥 2. Hashtags Tendances
**Status:** TERMINÉ ✅  
**Base de données:** 126 hashtags, 7 catégories

#### Endpoints Implémentés
```typescript
GET /trending-hashtags?category=cosmetics&platform=instagram
GET /trending-hashtags/generate?brandName=lela&postTitle=...&category=cosmetics
```

#### Fonctionnalités
- 7 catégories avec hashtags spécialisés
- Cache 24h pour performance
- Détection automatique de catégorie
- Génération contextuelle (marque + titre + catégorie)

#### Base de Hashtags par Catégorie
```typescript
const staticHashtags = {
  cosmetics: ['#makeup', '#beauty', '#skincare', '#cosmetics', '#makeuptutorial'],
  sports: ['#fitness', '#workout', '#gym', '#training', '#fitnessmotivation'],
  fashion: ['#fashion', '#style', '#ootd', '#fashionblogger', '#fashionista'],
  food: ['#food', '#foodie', '#foodporn', '#instafood', '#foodblogger'],
  technology: ['#tech', '#technology', '#innovation', '#gadgets', '#techie'],
  lifestyle: ['#lifestyle', '#life', '#instagood', '#photooftheday', '#love']
};
```

### 🎬 3. Générateur Vidéo Gratuit
**Status:** TERMINÉ ✅  
**API:** Pexels Videos API

#### Endpoints Implémentés
```typescript
POST /video-generator/generate
GET /video-generator/history
GET /video-generator/:id
POST /video-generator/:id/save-to-post
DELETE /video-generator/:id
```

#### Fonctionnalités
- Génération de vidéos via Pexels Videos API
- Support durée (15s, 30s, 60s)
- Support orientation (portrait, paysage, carré)
- Détection automatique de catégorie
- Historique et sauvegarde

#### Modèle de Données
```typescript
interface GeneratedVideo {
  id: string;
  userId: string;
  url: string;
  thumbnailUrl: string;
  duration: number;
  resolution: string;
  category: string;
  orientation: 'portrait' | 'landscape' | 'square';
  source: 'pexels';
  createdAt: Date;
}
```

---

## 🆕 Nouvelles Fonctionnalités à Implémenter

### 🖼️ 4. Éditeur d'Images Avancé
**Status:** NOUVEAU - À IMPLÉMENTER
**Priorité:** HAUTE

#### Endpoints Requis
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

#### Modèle de Données
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

#### Bibliothèques Recommandées
- **Sharp** (Node.js) pour traitement d'images
- **Canvas** pour superpositions de texte
- **Multer** pour upload de fichiers

#### Implémentation Service
```typescript
@Injectable()
export class ImageEditorService {
  
  async processEditedImage(dto: ProcessImageDto): Promise<string> {
    // 1. Télécharger l'image originale
    const imageBuffer = await this.downloadImage(dto.imageUrl);
    
    // 2. Créer une instance Sharp
    let image = sharp(imageBuffer);
    
    // 3. Appliquer le filtre
    if (dto.filter && dto.filter !== ImageFilter.NONE) {
      image = await this.applyFilter(image, dto.filter);
    }
    
    // 4. Appliquer les effets
    if (dto.effects && dto.effects.length > 0) {
      image = await this.applyEffects(image, dto.effects);
    }
    
    // 5. Redimensionner si nécessaire
    if (dto.resizedWidth && dto.resizedHeight) {
      image = image.resize(dto.resizedWidth, dto.resizedHeight);
    }
    
    // 6. Ajouter le cadre
    if (dto.frame && dto.frame !== ImageFrame.NONE) {
      image = await this.addFrame(image, dto.frame, dto.frameColor);
    }
    
    // 7. Ajouter le texte (avec Canvas)
    if (dto.textOverlays && dto.textOverlays.length > 0) {
      const processedBuffer = await image.png().toBuffer();
      const finalBuffer = await this.addTextOverlays(processedBuffer, dto.textOverlays);
      
      // 8. Sauvegarder et retourner l'URL
      return await this.saveProcessedImage(finalBuffer);
    }
    
    // 8. Sauvegarder sans texte
    const finalBuffer = await image.png().toBuffer();
    return await this.saveProcessedImage(finalBuffer);
  }
}
```

### 🎬 5. Éditeur Vidéo Avancé
**Status:** NOUVEAU - À IMPLÉMENTER
**Priorité:** MOYENNE

#### Endpoints Requis
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

#### Modèle de Données
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
```

#### Bibliothèques Recommandées
- **FFmpeg** pour traitement vidéo
- **Node-ffmpeg** wrapper pour Node.js
- **Multer** pour upload de fichiers

### 📤 6. Partage Avancé Multi-Plateformes
**Status:** NOUVEAU - À IMPLÉMENTER
**Priorité:** HAUTE

#### Endpoints Requis
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

#### Modèle de Données
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
```

#### APIs Externes Requises
- **Instagram Basic Display API**
- **TikTok for Developers**
- **Facebook Graph API**
- **Twitter API v2**
- **LinkedIn API**
- **YouTube Data API v3**

### 🤝 7. Collaboration Avancée
**Status:** NOUVEAU - À IMPLÉMENTER
**Priorité:** MOYENNE

#### Endpoints Requis
```typescript
POST /collaboration/invite
GET /collaboration/:planId/members
PATCH /collaboration/:planId/members/:memberId
DELETE /collaboration/:planId/members/:memberId
POST /collaboration/accept/:token
GET /collaboration/comments/:postId
POST /collaboration/comments
DELETE /collaboration/comments/:commentId
GET /collaboration/:planId/history
POST /collaboration/:planId/history
```

#### Modèle de Données
```typescript
interface PlanMember {
  id: string;
  planId: string;
  userId?: string;
  email: string;
  name: string;
  role: 'admin' | 'editor' | 'viewer';
  status: 'pending' | 'accepted' | 'rejected';
  invitedAt: Date;
  acceptedAt?: Date;
}

interface PostComment {
  id: string;
  postId: string;
  planId: string;
  authorId?: string;
  authorName: string;
  text: string;
  action: 'approved' | 'rejected' | 'commented';
  createdAt: Date;
}
```

---

## 🏗️ Architecture Technique

### 📊 Base de Données MongoDB

#### Collections Existantes
```typescript
// Utilisateurs et authentification
- users
- brands
- plans
- content_blocks

// Génération de contenu
- generated_images
- generated_videos
- trending_hashtags
```

#### Nouvelles Collections Requises
```typescript
// Édition avancée
- edited_images
- edited_videos

// Partage social
- scheduled_posts
- social_accounts
- share_statistics

// Collaboration
- plan_members
- post_comments
- plan_history
```

### 🗂️ Stockage de Fichiers

#### Structure Recommandée
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

#### Services de Stockage
- **Local** pour développement
- **AWS S3** ou **Google Cloud Storage** pour production
- **CDN** pour distribution rapide

### 🔐 Authentification et Sécurité

#### JWT Configuration
```typescript
// Configuration JWT
const jwtConfig = {
  secret: process.env.JWT_SECRET,
  signOptions: { expiresIn: '7d' },
};
```

#### OAuth 2.0 pour Réseaux Sociaux
```typescript
const socialAuthConfig = {
  instagram: {
    clientId: process.env.INSTAGRAM_CLIENT_ID,
    clientSecret: process.env.INSTAGRAM_CLIENT_SECRET,
    redirectUri: process.env.INSTAGRAM_REDIRECT_URI
  },
  facebook: {
    appId: process.env.FACEBOOK_APP_ID,
    appSecret: process.env.FACEBOOK_APP_SECRET
  },
  // ... autres plateformes
};
```

### ⚡ Performance et Cache

#### Redis pour Cache
```typescript
// Configuration cache recommandée
const cacheConfig = {
  trending_hashtags: '24h',
  social_accounts: '1h',
  processed_images: '7 jours',
  processed_videos: '3 jours'
};
```

---

## 🔌 Endpoints API Détaillés

### Génération d'Images
```typescript
// Générer une image
POST /api/ai-images/generate
Body: {
  description: string,
  style: 'professional' | 'colorful' | 'minimalist' | 'vintage',
  category: string
}
Response: { 
  id: string,
  url: string,
  prompt: string,
  style: string,
  category: string,
  createdAt: Date 
}

// Historique des images
GET /api/ai-images/history/:userId?page=1&limit=20
Response: { 
  images: GeneratedImage[], 
  total: number, 
  page: number 
}
```

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
Response: { 
  editedImageUrl: string, 
  processedAt: Date 
}
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
Response: { 
  scheduledPostId: string, 
  scheduledAt: Date 
}

// Comptes connectés
GET /api/advanced-share/connected-accounts/:userId
Response: { accounts: SocialAccount[] }
```

---

## 🧪 Tests et Validation

### Tests Unitaires Requis
```typescript
// Éditeur d'images
describe('ImageEditorService', () => {
  it('should apply black and white filter correctly', async () => {
    const result = await imageEditorService.applyFilter(mockImage, ImageFilter.BLACK_AND_WHITE);
    expect(result).toBeDefined();
  });
  
  it('should add text overlay at correct position', async () => {
    const overlay = { text: 'Test', x: 0.5, y: 0.5, fontSize: 24, color: 0xFFFFFF };
    const result = await imageEditorService.addTextOverlays(mockBuffer, [overlay]);
    expect(result).toBeInstanceOf(Buffer);
  });
});

// Partage avancé
describe('AdvancedShareService', () => {
  it('should schedule post correctly', async () => {
    const dto = { /* mock data */ };
    const result = await advancedShareService.schedulePost(dto);
    expect(result.status).toBe('scheduled');
  });
  
  it('should generate relevant hashtags', async () => {
    const hashtags = await advancedShareService.generateContextualHashtags('cosmetics post', 'beauty');
    expect(hashtags).toContain('#beauty');
    expect(hashtags.length).toBeLessThanOrEqual(10);
  });
});
```

### Tests d'Intégration
```typescript
// Workflow complet
describe('Complete Workflow', () => {
  it('should generate image -> edit -> schedule share', async () => {
    // 1. Génération d'image
    const image = await imageGeneratorService.generate({
      description: 'Test image',
      category: 'cosmetics'
    });
    
    // 2. Édition
    const editedImage = await imageEditorService.process({
      imageUrl: image.url,
      filter: 'vintage',
      textOverlays: [{ text: 'Test', x: 0.5, y: 0.5 }]
    });
    
    // 3. Programmation partage
    const scheduledPost = await advancedShareService.schedule({
      contentUrl: editedImage.url,
      platforms: ['instagram'],
      scheduledTime: new Date()
    });
    
    expect(scheduledPost.status).toBe('scheduled');
  });
});
```

---

## 📊 Monitoring et Analytics

### Métriques à Suivre
```typescript
// Performance
const performanceMetrics = {
  imageProcessingTime: '< 5s',
  videoProcessingTime: '< 30s',
  apiResponseTime: '< 2s',
  shareSuccessRate: '> 95%'
};

// Usage
const usageMetrics = {
  imagesGeneratedPerDay: 'number',
  imagesEditedPerDay: 'number',
  videosGeneratedPerDay: 'number',
  scheduledPostsPerDay: 'number',
  mostUsedPlatforms: 'array'
};
```

### Logs Requis
```typescript
// Traitement
console.log('[ImageEditor] Processing started', { imageId, filters, effects });
console.log('[ImageEditor] Processing completed', { imageId, duration, outputSize });

// Partage social
console.log('[SocialShare] Post scheduled', { postId, platform, scheduledTime });
console.log('[SocialShare] Post published', { postId, platform, publishedAt, stats });

// Erreurs
console.error('[ImageEditor] Processing failed', { imageId, error, stack });
console.error('[SocialShare] Publication failed', { postId, platform, error });
```

---

## 🚀 Configuration et Déploiement

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
FROM node:18-alpine

# Installation des dépendances système
RUN apk add --no-cache \
    ffmpeg \
    vips-dev \
    build-base \
    python3 \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

---

## 📋 Plan d'Implémentation

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

### Phase 4: Collaboration (Priorité MOYENNE)
**Durée estimée:** 4-5 jours
1. Système d'invitations par email
2. Gestion des rôles et permissions
3. Commentaires et approbations
4. Historique des modifications
5. Notifications en temps réel

---

## ✅ Checklist de Validation

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

## 🎉 Conclusion

Cette documentation complète couvre toutes les fonctionnalités backend de IdeaSpark :

### ✅ Fonctionnalités Existantes (Prêtes)
- Générateur d'images gratuit
- Hashtags tendances
- Générateur vidéo gratuit

### 🆕 Nouvelles Fonctionnalités (À Implémenter)
- Éditeur d'images avancé
- Éditeur vidéo avancé
- Partage multi-plateformes
- Collaboration avancée

### 📊 Estimation Totale
- **Durée:** 19-23 jours de développement
- **Priorité:** Éditeur d'Images → Partage Avancé → Éditeur Vidéo → Collaboration
- **Technologies:** NestJS, MongoDB, Sharp, FFmpeg, Redis, OAuth 2.0

Le backend est conçu pour être scalable, performant et sécurisé, avec une architecture modulaire permettant d'ajouter facilement de nouvelles fonctionnalités.

---

**📅 Date de création:** 25 avril 2026  
**👨‍💻 Équipe:** Backend NestJS + MongoDB  
**🎯 Objectif:** Support complet des fonctionnalités d'édition et partage avancé  
**⏱️ Durée estimée:** 19-23 jours de développement