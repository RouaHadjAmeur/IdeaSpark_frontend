# Backend - Nouvelles Fonctionnalités à Implémenter 🆕

## 🎯 RÉSUMÉ
Ce document détaille les **3 nouvelles fonctionnalités** à implémenter côté backend pour supporter l'éditeur d'images, l'éditeur vidéo et le partage avancé.

---

## 🖼️ 1. ÉDITEUR D'IMAGES AVANCÉ

### 📋 Fonctionnalités Requises
- **8 filtres** : Aucun, N&B, Sépia, Vintage, Froid, Chaud, Lumineux, Sombre
- **6 cadres** : Aucun, Simple, Arrondi, Ombre, Polaroid, Film
- **Superposition de texte** avec position, taille, couleur, style
- **5 effets** : Flou, Ombre, Lueur, Relief, Netteté
- **Redimensionnement** pour réseaux sociaux (Instagram, Facebook, etc.)

### 🔧 Implémentation Technique

#### Bibliothèques Nécessaires
```bash
npm install sharp canvas multer
```

#### Structure des Endpoints
```typescript
// Module: ImageEditorModule
@Controller('image-editor')
export class ImageEditorController {
  
  @Post('process')
  async processImage(@Body() dto: ProcessImageDto) {
    // Traitement complet d'une image
  }
  
  @Post('apply-filter')
  async applyFilter(@Body() dto: ApplyFilterDto) {
    // Application d'un filtre spécifique
  }
  
  @Post('add-text')
  async addTextOverlay(@Body() dto: AddTextDto) {
    // Ajout de texte sur l'image
  }
  
  @Post('resize')
  async resizeImage(@Body() dto: ResizeImageDto) {
    // Redimensionnement pour réseaux sociaux
  }
  
  @Get('history/:userId')
  async getHistory(@Param('userId') userId: string) {
    // Historique des images éditées
  }
}
```

#### DTOs (Data Transfer Objects)
```typescript
export class ProcessImageDto {
  imageUrl: string;
  filter?: ImageFilter;
  frame?: ImageFrame;
  frameColor?: number;
  textOverlays?: TextOverlayDto[];
  effects?: ImageEffect[];
  resizedWidth?: number;
  resizedHeight?: number;
}

export class TextOverlayDto {
  text: string;
  x: number; // Position 0-1
  y: number; // Position 0-1
  fontSize: number;
  color: number;
  bold: boolean;
  italic: boolean;
}

export enum ImageFilter {
  NONE = 'none',
  BLACK_AND_WHITE = 'blackAndWhite',
  SEPIA = 'sepia',
  VINTAGE = 'vintage',
  COOL = 'cool',
  WARM = 'warm',
  BRIGHT = 'bright',
  DARK = 'dark'
}
```

#### Service d'Édition
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
  
  private async applyFilter(image: Sharp, filter: ImageFilter): Promise<Sharp> {
    switch (filter) {
      case ImageFilter.BLACK_AND_WHITE:
        return image.grayscale();
      case ImageFilter.SEPIA:
        return image.tint({ r: 255, g: 240, b: 196 });
      case ImageFilter.VINTAGE:
        return image.modulate({ brightness: 0.9, saturation: 0.8 }).tint({ r: 255, g: 228, b: 181 });
      case ImageFilter.COOL:
        return image.tint({ r: 173, g: 216, b: 230 });
      case ImageFilter.WARM:
        return image.tint({ r: 255, g: 218, b: 185 });
      case ImageFilter.BRIGHT:
        return image.modulate({ brightness: 1.3 });
      case ImageFilter.DARK:
        return image.modulate({ brightness: 0.7 });
      default:
        return image;
    }
  }
  
  private async addTextOverlays(imageBuffer: Buffer, overlays: TextOverlayDto[]): Promise<Buffer> {
    const { createCanvas, loadImage } = require('canvas');
    
    // Charger l'image dans Canvas
    const img = await loadImage(imageBuffer);
    const canvas = createCanvas(img.width, img.height);
    const ctx = canvas.getContext('2d');
    
    // Dessiner l'image de base
    ctx.drawImage(img, 0, 0);
    
    // Ajouter chaque overlay de texte
    for (const overlay of overlays) {
      ctx.font = `${overlay.bold ? 'bold' : 'normal'} ${overlay.italic ? 'italic' : 'normal'} ${overlay.fontSize}px Arial`;
      ctx.fillStyle = `#${overlay.color.toString(16).padStart(6, '0')}`;
      ctx.textAlign = 'center';
      
      const x = overlay.x * img.width;
      const y = overlay.y * img.height;
      
      ctx.fillText(overlay.text, x, y);
    }
    
    return canvas.toBuffer('image/png');
  }
}
```

---

## 🎬 2. ÉDITEUR VIDÉO AVANCÉ

### 📋 Fonctionnalités Requises
- **Musique de fond** avec bibliothèque prédéfinie
- **Superposition de texte** avec timing précis
- **Sous-titres** avec timing
- **Découpage** (trim) avec début/fin
- **5 transitions** : Fondu, Glissement, Zoom, Dissolution, Balayage

### 🔧 Implémentation Technique

#### Bibliothèques Nécessaires
```bash
npm install fluent-ffmpeg @ffmpeg-installer/ffmpeg multer
```

#### Structure des Endpoints
```typescript
@Controller('video-editor')
export class VideoEditorController {
  
  @Post('process')
  async processVideo(@Body() dto: ProcessVideoDto) {
    // Traitement complet d'une vidéo
  }
  
  @Post('add-music')
  async addBackgroundMusic(@Body() dto: AddMusicDto) {
    // Ajout de musique de fond
  }
  
  @Post('add-text')
  async addTextOverlay(@Body() dto: AddVideoTextDto) {
    // Ajout de texte avec timing
  }
  
  @Post('trim')
  async trimVideo(@Body() dto: TrimVideoDto) {
    // Découpage de vidéo
  }
  
  @Get('music-library')
  async getMusicLibrary() {
    // Bibliothèque de musiques disponibles
  }
}
```

#### DTOs pour Vidéo
```typescript
export class ProcessVideoDto {
  videoPath: string;
  music?: VideoMusicDto;
  textOverlays?: VideoTextOverlayDto[];
  subtitles?: VideoSubtitleDto[];
  trimStart?: number; // en secondes
  trimEnd?: number;
  transitions?: VideoTransitionDto[];
}

export class VideoTextOverlayDto {
  text: string;
  startTime: number; // en secondes
  endTime: number;
  x: number; // Position 0-1
  y: number;
  fontSize: number;
  color: number;
}

export class VideoMusicDto {
  name: string;
  path: string;
  volume?: number; // 0-1
}
```

#### Service d'Édition Vidéo
```typescript
@Injectable()
export class VideoEditorService {
  
  async processEditedVideo(dto: ProcessVideoDto): Promise<string> {
    const ffmpeg = require('fluent-ffmpeg');
    const outputPath = `processed_videos/${Date.now()}_edited.mp4`;
    
    return new Promise((resolve, reject) => {
      let command = ffmpeg(dto.videoPath);
      
      // 1. Découpage si nécessaire
      if (dto.trimStart !== undefined && dto.trimEnd !== undefined) {
        command = command
          .seekInput(dto.trimStart)
          .duration(dto.trimEnd - dto.trimStart);
      }
      
      // 2. Ajout de musique de fond
      if (dto.music) {
        command = command
          .input(dto.music.path)
          .complexFilter([
            '[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=3[a]'
          ])
          .outputOptions(['-map', '0:v', '-map', '[a]']);
      }
      
      // 3. Ajout de texte avec timing
      if (dto.textOverlays && dto.textOverlays.length > 0) {
        const textFilters = dto.textOverlays.map((overlay, index) => {
          const color = `#${overlay.color.toString(16).padStart(6, '0')}`;
          return `drawtext=text='${overlay.text}':x=${overlay.x}*w:y=${overlay.y}*h:fontsize=${overlay.fontSize}:fontcolor=${color}:enable='between(t,${overlay.startTime},${overlay.endTime})'`;
        });
        
        command = command.videoFilters(textFilters);
      }
      
      // 4. Traitement final
      command
        .output(outputPath)
        .on('end', () => resolve(outputPath))
        .on('error', reject)
        .run();
    });
  }
  
  async addBackgroundMusic(videoPath: string, musicPath: string, volume = 0.5): Promise<string> {
    const ffmpeg = require('fluent-ffmpeg');
    const outputPath = `processed_videos/${Date.now()}_with_music.mp4`;
    
    return new Promise((resolve, reject) => {
      ffmpeg(videoPath)
        .input(musicPath)
        .complexFilter([
          `[1:a]volume=${volume}[music]`,
          '[0:a][music]amix=inputs=2:duration=first[a]'
        ])
        .outputOptions(['-map', '0:v', '-map', '[a]'])
        .output(outputPath)
        .on('end', () => resolve(outputPath))
        .on('error', reject)
        .run();
    });
  }
}
```

---

## 📤 3. PARTAGE AVANCÉ MULTI-PLATEFORMES

### 📋 Fonctionnalités Requises
- **6 plateformes** : Instagram, TikTok, Facebook, Twitter, LinkedIn, YouTube
- **Multi-comptes** par plateforme
- **Programmation** de publications
- **Génération automatique** de hashtags
- **Statistiques** de partage

### 🔧 Implémentation Technique

#### Bibliothèques Nécessaires
```bash
npm install @nestjs/passport passport-oauth2 node-cron axios
```

#### Structure des Endpoints
```typescript
@Controller('advanced-share')
export class AdvancedShareController {
  
  @Post('schedule')
  async schedulePost(@Body() dto: SchedulePostDto) {
    // Programmer une publication
  }
  
  @Post('share-now')
  async shareNow(@Body() dto: ShareNowDto) {
    // Partager immédiatement
  }
  
  @Get('connected-accounts/:userId')
  async getConnectedAccounts(@Param('userId') userId: string) {
    // Comptes connectés de l'utilisateur
  }
  
  @Post('connect-account')
  async connectSocialAccount(@Body() dto: ConnectAccountDto) {
    // Connecter un nouveau compte
  }
  
  @Post('generate-hashtags')
  async generateHashtags(@Body() dto: GenerateHashtagsDto) {
    // Génération automatique de hashtags
  }
  
  @Get('statistics/:postId')
  async getShareStatistics(@Param('postId') postId: string) {
    // Statistiques d'un post partagé
  }
}
```

#### DTOs pour Partage
```typescript
export class SchedulePostDto {
  contentId: string;
  contentType: 'image' | 'video';
  contentUrl: string;
  caption: string;
  hashtags: string[];
  platforms: SocialPlatform[];
  accountIds: string[];
  scheduledTime: Date;
}

export class ConnectAccountDto {
  userId: string;
  platform: SocialPlatform;
  accessToken: string;
  refreshToken?: string;
  accountInfo: {
    name: string;
    username: string;
    profileImageUrl?: string;
  };
}

export enum SocialPlatform {
  INSTAGRAM = 'instagram',
  TIKTOK = 'tiktok',
  FACEBOOK = 'facebook',
  TWITTER = 'twitter',
  LINKEDIN = 'linkedin',
  YOUTUBE = 'youtube'
}
```

#### Service de Partage Avancé
```typescript
@Injectable()
export class AdvancedShareService {
  
  async schedulePost(dto: SchedulePostDto): Promise<ScheduledPost> {
    // 1. Créer l'entrée en base
    const scheduledPost = await this.scheduledPostRepository.create({
      ...dto,
      status: 'scheduled',
      createdAt: new Date()
    });
    
    // 2. Programmer l'exécution avec node-cron
    const cronTime = this.dateToCron(dto.scheduledTime);
    cron.schedule(cronTime, async () => {
      await this.executeScheduledPost(scheduledPost.id);
    });
    
    return scheduledPost;
  }
  
  async shareToInstagram(accountId: string, contentUrl: string, caption: string): Promise<any> {
    const account = await this.socialAccountRepository.findById(accountId);
    
    // 1. Upload du média
    const mediaResponse = await axios.post(
      `https://graph.instagram.com/v18.0/${account.instagramUserId}/media`,
      {
        image_url: contentUrl,
        caption: caption,
        access_token: account.accessToken
      }
    );
    
    // 2. Publication du média
    const publishResponse = await axios.post(
      `https://graph.instagram.com/v18.0/${account.instagramUserId}/media_publish`,
      {
        creation_id: mediaResponse.data.id,
        access_token: account.accessToken
      }
    );
    
    return publishResponse.data;
  }
  
  async generateContextualHashtags(content: string, category: string): Promise<string[]> {
    // 1. Hashtags de base par catégorie
    const baseHashtags = await this.getHashtagsByCategory(category);
    
    // 2. Analyse du contenu pour hashtags spécifiques
    const contentKeywords = this.extractKeywords(content);
    const contextualHashtags = this.mapKeywordsToHashtags(contentKeywords);
    
    // 3. Combinaison et limitation
    const allHashtags = [...baseHashtags, ...contextualHashtags];
    return this.selectBestHashtags(allHashtags, 10);
  }
}
```

#### Modèles de Base de Données
```typescript
// Schema MongoDB pour posts programmés
export const ScheduledPostSchema = new Schema({
  userId: { type: String, required: true },
  contentId: { type: String, required: true },
  contentType: { type: String, enum: ['image', 'video'], required: true },
  contentUrl: { type: String, required: true },
  caption: { type: String, required: true },
  hashtags: [{ type: String }],
  platforms: [{ type: String, enum: Object.values(SocialPlatform) }],
  accountIds: [{ type: String }],
  scheduledTime: { type: Date, required: true },
  status: { type: String, enum: ['scheduled', 'published', 'failed'], default: 'scheduled' },
  publishedAt: { type: Date },
  statistics: {
    views: { type: Number, default: 0 },
    likes: { type: Number, default: 0 },
    comments: { type: Number, default: 0 },
    shares: { type: Number, default: 0 }
  },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Schema pour comptes sociaux
export const SocialAccountSchema = new Schema({
  userId: { type: String, required: true },
  platform: { type: String, enum: Object.values(SocialPlatform), required: true },
  name: { type: String, required: true },
  username: { type: String, required: true },
  profileImageUrl: { type: String },
  accessToken: { type: String, required: true },
  refreshToken: { type: String },
  tokenExpiresAt: { type: Date },
  isActive: { type: Boolean, default: true },
  connectedAt: { type: Date, default: Date.now }
});
```

---

## 🔐 CONFIGURATION OAUTH

### Variables d'Environnement Requises
```bash
# Instagram
INSTAGRAM_CLIENT_ID=your_instagram_client_id
INSTAGRAM_CLIENT_SECRET=your_instagram_client_secret
INSTAGRAM_REDIRECT_URI=http://localhost:3000/auth/instagram/callback

# TikTok
TIKTOK_CLIENT_KEY=your_tiktok_client_key
TIKTOK_CLIENT_SECRET=your_tiktok_client_secret

# Facebook
FACEBOOK_APP_ID=your_facebook_app_id
FACEBOOK_APP_SECRET=your_facebook_app_secret

# Twitter
TWITTER_API_KEY=your_twitter_api_key
TWITTER_API_SECRET=your_twitter_api_secret

# LinkedIn
LINKEDIN_CLIENT_ID=your_linkedin_client_id
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret

# YouTube
YOUTUBE_CLIENT_ID=your_youtube_client_id
YOUTUBE_CLIENT_SECRET=your_youtube_client_secret
```

### Configuration Passport.js
```typescript
@Injectable()
export class InstagramStrategy extends PassportStrategy(Strategy, 'instagram') {
  constructor() {
    super({
      clientID: process.env.INSTAGRAM_CLIENT_ID,
      clientSecret: process.env.INSTAGRAM_CLIENT_SECRET,
      callbackURL: process.env.INSTAGRAM_REDIRECT_URI,
      scope: ['user_profile', 'user_media']
    });
  }
  
  async validate(accessToken: string, refreshToken: string, profile: any): Promise<any> {
    return {
      accessToken,
      refreshToken,
      profile
    };
  }
}
```

---

## 📊 TESTS ET VALIDATION

### Tests Unitaires
```typescript
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

---

## 🚀 DÉPLOIEMENT

### Docker Configuration
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

### Performance et Monitoring
```typescript
// Métriques à surveiller
- Temps de traitement d'images: < 5 secondes
- Temps de traitement vidéo: < 30 secondes
- Taux de succès des publications: > 95%
- Temps de réponse API: < 2 secondes
- Utilisation mémoire: < 2GB par processus
- Utilisation CPU: < 80% en moyenne
```

---

## ✅ CHECKLIST D'IMPLÉMENTATION

### Phase 1: Éditeur d'Images (3-4 jours)
- [ ] Installation et configuration Sharp.js
- [ ] Implémentation des 8 filtres
- [ ] Système de cadres (6 types)
- [ ] Superposition de texte avec Canvas
- [ ] Système d'effets (5 types)
- [ ] Redimensionnement pour réseaux sociaux
- [ ] API endpoints et DTOs
- [ ] Tests unitaires
- [ ] Documentation API

### Phase 2: Partage Avancé (5-6 jours)
- [ ] Configuration OAuth pour 6 plateformes
- [ ] Système de gestion des comptes connectés
- [ ] Programmation de publications avec cron
- [ ] APIs de publication pour chaque plateforme
- [ ] Génération automatique de hashtags
- [ ] Collecte de statistiques
- [ ] Gestion des erreurs et retry
- [ ] Tests d'intégration
- [ ] Documentation OAuth

### Phase 3: Éditeur Vidéo (7-8 jours)
- [ ] Installation et configuration FFmpeg
- [ ] Système de musique de fond
- [ ] Superposition de texte avec timing
- [ ] Système de sous-titres
- [ ] Découpage de vidéos
- [ ] Transitions et effets
- [ ] Optimisation performance
- [ ] Tests de traitement
- [ ] Documentation complète

---

**📅 Date:** 25 avril 2026  
**⏱️ Durée totale estimée:** 15-18 jours  
**🎯 Priorité:** Éditeur d'Images → Partage Avancé → Éditeur Vidéo