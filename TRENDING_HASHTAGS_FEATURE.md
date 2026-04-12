# 🔥 Fonctionnalité : Recherche de Hashtags et Tendances

## 🎯 Objectif

Améliorer le générateur de captions en ajoutant des hashtags et tendances actuels basés sur :
- La catégorie du post (cosmétiques, sports, mode, etc.)
- La plateforme (Instagram, TikTok, Facebook)
- Les tendances du moment
- Le pays/langue cible

## 📊 Sources de données possibles

### 1. API TikTok Creative Center (GRATUIT) ⭐ RECOMMANDÉ
**URL** : https://ads.tiktok.com/business/creativecenter/

**Avantages** :
- ✅ 100% GRATUIT
- ✅ Données en temps réel
- ✅ Hashtags tendances par pays
- ✅ Hashtags par catégorie
- ✅ Pas besoin de clé API (scraping possible)

**Données disponibles** :
- Top hashtags par pays (France, USA, etc.)
- Hashtags par catégorie (Beauty, Sports, Fashion, Food, etc.)
- Nombre de vues par hashtag
- Tendances montantes vs descendantes

**Exemple de données** :
```json
{
  "hashtags": [
    {
      "name": "#makeup",
      "views": "45.2B",
      "trend": "up",
      "category": "beauty"
    },
    {
      "name": "#skincare",
      "views": "32.1B",
      "trend": "stable",
      "category": "beauty"
    }
  ]
}
```

### 2. RapidAPI - Hashtag API (PAYANT)
**URL** : https://rapidapi.com/

**Coût** : ~$10-50/mois
**Avantages** :
- API officielle
- Données structurées
- Support multi-plateformes

**Inconvénient** : Payant

### 3. Scraping Instagram/TikTok (GRATUIT mais risqué)
**Méthode** : Scraper les pages de recherche

**Avantages** :
- ✅ Gratuit
- ✅ Données en temps réel

**Inconvénients** :
- ❌ Peut être bloqué
- ❌ Violation des ToS
- ❌ Instable

## 🚀 Solution Recommandée : TikTok Creative Center + Cache

### Architecture

```
Frontend (Flutter)
    ↓
Backend (NestJS)
    ↓
TrendingHashtagsService
    ↓
    ├─→ TikTok Creative Center (scraping)
    ├─→ Cache Redis (24h)
    └─→ Fallback : Hashtags statiques par catégorie
```

## 📦 Implémentation Backend

### 1. Module NestJS

```typescript
// src/trending-hashtags/trending-hashtags.module.ts
import { Module } from '@nestjs/common';
import { TrendingHashtagsController } from './trending-hashtags.controller';
import { TrendingHashtagsService } from './trending-hashtags.service';

@Module({
  controllers: [TrendingHashtagsController],
  providers: [TrendingHashtagsService],
  exports: [TrendingHashtagsService],
})
export class TrendingHashtagsModule {}
```

### 2. Service

```typescript
// src/trending-hashtags/trending-hashtags.service.ts
import { Injectable } from '@nestjs/common';
import axios from 'axios';

interface TrendingHashtag {
  name: string;
  views?: string;
  trend?: 'up' | 'down' | 'stable';
  category: string;
  platform: string;
}

@Injectable()
export class TrendingHashtagsService {
  private cache: Map<string, { data: TrendingHashtag[]; timestamp: number }> = new Map();
  private CACHE_DURATION = 24 * 60 * 60 * 1000; // 24 heures

  // Hashtags statiques par catégorie (fallback)
  private staticHashtags: Record<string, string[]> = {
    cosmetics: [
      '#makeup', '#beauty', '#skincare', '#cosmetics', '#makeuptutorial',
      '#beautytips', '#glowup', '#selfcare', '#beautyblogger', '#makeuplover',
      '#skincareroutine', '#beautycommunity', '#makeupoftheday', '#beautyaddict'
    ],
    sports: [
      '#fitness', '#workout', '#gym', '#training', '#fitnessmotivation',
      '#sport', '#athlete', '#exercise', '#fitfam', '#gymlife',
      '#fitnessjourney', '#workoutmotivation', '#fitnessgirl', '#sportlife'
    ],
    fashion: [
      '#fashion', '#style', '#ootd', '#fashionblogger', '#fashionista',
      '#outfitoftheday', '#fashionstyle', '#instafashion', '#streetstyle',
      '#fashionable', '#fashionweek', '#styleinspo', '#fashionlover'
    ],
    food: [
      '#food', '#foodie', '#foodporn', '#instafood', '#foodblogger',
      '#yummy', '#delicious', '#foodphotography', '#foodstagram',
      '#foodlover', '#cooking', '#recipe', '#homemade', '#tasty'
    ],
    technology: [
      '#tech', '#technology', '#innovation', '#gadgets', '#techie',
      '#smartphone', '#coding', '#programming', '#developer', '#ai',
      '#machinelearning', '#startup', '#digital', '#future'
    ],
    lifestyle: [
      '#lifestyle', '#life', '#instagood', '#photooftheday', '#love',
      '#happy', '#motivation', '#inspiration', '#goals', '#success',
      '#positivevibes', '#mindset', '#wellness', '#selfimprovement'
    ],
  };

  /**
   * Récupérer les hashtags tendances pour une catégorie
   */
  async getTrendingHashtags(
    category: string,
    platform: string = 'instagram',
    country: string = 'FR',
  ): Promise<TrendingHashtag[]> {
    const cacheKey = `${category}_${platform}_${country}`;

    // Vérifier le cache
    const cached = this.cache.get(cacheKey);
    if (cached && Date.now() - cached.timestamp < this.CACHE_DURATION) {
      console.log(`[TrendingHashtags] Cache hit: ${cacheKey}`);
      return cached.data;
    }

    console.log(`[TrendingHashtags] Fetching fresh data: ${cacheKey}`);

    try {
      // Essayer de récupérer depuis TikTok Creative Center
      const trendingHashtags = await this.fetchFromTikTok(category, country);
      
      if (trendingHashtags.length > 0) {
        // Mettre en cache
        this.cache.set(cacheKey, {
          data: trendingHashtags,
          timestamp: Date.now(),
        });
        return trendingHashtags;
      }
    } catch (error) {
      console.error('[TrendingHashtags] Error fetching from TikTok:', error);
    }

    // Fallback : Hashtags statiques
    console.log(`[TrendingHashtags] Using static hashtags for: ${category}`);
    return this.getStaticHashtags(category, platform);
  }

  /**
   * Récupérer depuis TikTok Creative Center (scraping)
   */
  private async fetchFromTikTok(
    category: string,
    country: string,
  ): Promise<TrendingHashtag[]> {
    // Note : Cette méthode nécessite du scraping ou une API non officielle
    // Pour l'instant, on retourne un tableau vide et on utilise le fallback
    
    // TODO: Implémenter le scraping de TikTok Creative Center
    // URL: https://ads.tiktok.com/business/creativecenter/hashtag/pc/en
    
    return [];
  }

  /**
   * Récupérer les hashtags statiques par catégorie
   */
  private getStaticHashtags(
    category: string,
    platform: string,
  ): TrendingHashtag[] {
    const hashtags = this.staticHashtags[category] || this.staticHashtags['lifestyle'];
    
    return hashtags.map((name) => ({
      name,
      category,
      platform,
      trend: 'stable',
    }));
  }

  /**
   * Générer des hashtags pour un post spécifique
   */
  async generateHashtagsForPost(
    brandName: string,
    postTitle: string,
    category: string,
    platform: string = 'instagram',
  ): Promise<string[]> {
    // Récupérer les hashtags tendances
    const trending = await this.getTrendingHashtags(category, platform);

    // Sélectionner les 10 meilleurs hashtags
    const selectedHashtags = trending.slice(0, 10).map((h) => h.name);

    // Ajouter des hashtags spécifiques à la marque
    const brandHashtag = `#${brandName.toLowerCase().replace(/\s+/g, '')}`;
    selectedHashtags.push(brandHashtag);

    // Ajouter des hashtags basés sur le titre du post
    const titleWords = postTitle.toLowerCase().split(' ');
    const relevantWords = titleWords.filter((word) => word.length > 4);
    relevantWords.slice(0, 2).forEach((word) => {
      selectedHashtags.push(`#${word}`);
    });

    return selectedHashtags;
  }
}
```

### 3. Controller

```typescript
// src/trending-hashtags/trending-hashtags.controller.ts
import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { TrendingHashtagsService } from './trending-hashtags.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('trending-hashtags')
@UseGuards(JwtAuthGuard)
export class TrendingHashtagsController {
  constructor(private readonly trendingHashtagsService: TrendingHashtagsService) {}

  /**
   * GET /trending-hashtags
   * Récupérer les hashtags tendances pour une catégorie
   */
  @Get()
  async getTrendingHashtags(
    @Query('category') category: string,
    @Query('platform') platform: string = 'instagram',
    @Query('country') country: string = 'FR',
  ) {
    return this.trendingHashtagsService.getTrendingHashtags(
      category,
      platform,
      country,
    );
  }

  /**
   * GET /trending-hashtags/generate
   * Générer des hashtags pour un post spécifique
   */
  @Get('generate')
  async generateHashtags(
    @Query('brandName') brandName: string,
    @Query('postTitle') postTitle: string,
    @Query('category') category: string,
    @Query('platform') platform: string = 'instagram',
  ) {
    const hashtags = await this.trendingHashtagsService.generateHashtagsForPost(
      brandName,
      postTitle,
      category,
      platform,
    );

    return { hashtags };
  }
}
```

### 4. Intégration avec le générateur de captions

```typescript
// src/caption-generator/caption-generator.service.ts
import { Injectable } from '@nestjs/common';
import { TrendingHashtagsService } from '../trending-hashtags/trending-hashtags.service';

@Injectable()
export class CaptionGeneratorService {
  constructor(
    private readonly trendingHashtagsService: TrendingHashtagsService,
  ) {}

  async generateCaption(
    brandName: string,
    postTitle: string,
    category: string,
    platform: string,
  ): Promise<string> {
    // Générer la caption de base (existant)
    const baseCaption = `✨ ${postTitle}\n\n📢 Découvrez notre nouvelle collection !`;

    // Récupérer les hashtags tendances
    const hashtags = await this.trendingHashtagsService.generateHashtagsForPost(
      brandName,
      postTitle,
      category,
      platform,
    );

    // Combiner caption + hashtags
    const fullCaption = `${baseCaption}\n\n${hashtags.join(' ')}`;

    return fullCaption;
  }
}
```

## 📱 Implémentation Frontend

### 1. Service Flutter

```dart
// lib/services/trending_hashtags_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/api_config.dart';
import '../services/auth_service.dart';

class TrendingHashtag {
  final String name;
  final String? views;
  final String? trend;
  final String category;
  final String platform;

  TrendingHashtag({
    required this.name,
    this.views,
    this.trend,
    required this.category,
    required this.platform,
  });

  factory TrendingHashtag.fromJson(Map<String, dynamic> json) {
    return TrendingHashtag(
      name: json['name'] ?? '',
      views: json['views'],
      trend: json['trend'],
      category: json['category'] ?? '',
      platform: json['platform'] ?? '',
    );
  }
}

class TrendingHashtagsService {
  static Future<List<TrendingHashtag>> getTrendingHashtags({
    required String category,
    String platform = 'instagram',
    String country = 'FR',
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/trending-hashtags?category=$category&platform=$platform&country=$country',
      );

      print('📊 [TrendingHashtags] Fetching: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 [TrendingHashtags] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final hashtags = data.map((json) => TrendingHashtag.fromJson(json)).toList();
        print('✅ [TrendingHashtags] Received ${hashtags.length} hashtags');
        return hashtags;
      } else {
        throw Exception('Failed to fetch trending hashtags: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [TrendingHashtags] Error: $e');
      rethrow;
    }
  }

  static Future<List<String>> generateHashtags({
    required String brandName,
    required String postTitle,
    required String category,
    String platform = 'instagram',
  }) async {
    try {
      final token = AuthService().accessToken;
      if (token == null) throw Exception('Not authenticated');

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/trending-hashtags/generate?brandName=$brandName&postTitle=$postTitle&category=$category&platform=$platform',
      );

      print('📊 [TrendingHashtags] Generating hashtags: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📊 [TrendingHashtags] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<String> hashtags = List<String>.from(data['hashtags'] ?? []);
        print('✅ [TrendingHashtags] Generated ${hashtags.length} hashtags');
        return hashtags;
      } else {
        throw Exception('Failed to generate hashtags: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [TrendingHashtags] Error: $e');
      rethrow;
    }
  }
}
```

### 2. Intégration dans le générateur de captions

```dart
// lib/views/content/caption_generator_screen.dart
// Ajouter un bouton pour rafraîchir les hashtags

ElevatedButton.icon(
  onPressed: () async {
    setState(() => _isLoadingHashtags = true);
    
    try {
      final hashtags = await TrendingHashtagsService.generateHashtags(
        brandName: widget.brandName,
        postTitle: widget.block.title,
        category: _detectCategory(widget.brandName),
        platform: _selectedPlatform,
      );
      
      setState(() {
        _generatedHashtags = hashtags;
        _isLoadingHashtags = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${hashtags.length} hashtags tendances ajoutés !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoadingHashtags = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  },
  icon: Icon(Icons.trending_up),
  label: Text('Hashtags Tendances'),
)
```

## 🎨 UI/UX Améliorations

### 1. Afficher les hashtags avec indicateur de tendance

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _generatedHashtags.map((hashtag) {
    return Chip(
      avatar: Icon(
        Icons.trending_up,
        size: 16,
        color: Colors.green,
      ),
      label: Text(hashtag),
      backgroundColor: Colors.blue.withOpacity(0.1),
    );
  }).toList(),
)
```

### 2. Bouton "Copier tous les hashtags"

```dart
IconButton(
  icon: Icon(Icons.copy),
  onPressed: () {
    final hashtagsText = _generatedHashtags.join(' ');
    Clipboard.setData(ClipboardData(text: hashtagsText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📋 Hashtags copiés !')),
    );
  },
)
```

## 📊 Exemple de résultat

### Avant (sans tendances)
```
✨ Unlock Your Inner Radiance

📢 Découvrez notre nouvelle collection !

#lela #makeup #beauty #skincare
```

### Après (avec tendances)
```
✨ Unlock Your Inner Radiance

📢 Découvrez notre nouvelle collection !

#makeup #beauty #skincare #cosmetics #makeuptutorial #beautytips #glowup #selfcare #beautyblogger #makeuplover #lela #unlock #radiance
```

## ✅ Checklist d'implémentation

### Backend
- [ ] Créer le module `TrendingHashtagsModule`
- [ ] Créer le service `TrendingHashtagsService`
- [ ] Créer le controller `TrendingHashtagsController`
- [ ] Ajouter les hashtags statiques par catégorie
- [ ] Implémenter le cache (24h)
- [ ] Tester les endpoints avec Postman
- [ ] Intégrer avec le générateur de captions existant

### Frontend
- [ ] Créer le service `TrendingHashtagsService`
- [ ] Ajouter le bouton "Hashtags Tendances" dans le générateur de captions
- [ ] Afficher les hashtags avec indicateur de tendance
- [ ] Ajouter le bouton "Copier tous les hashtags"
- [ ] Tester sur téléphone physique

### Optionnel (Avancé)
- [ ] Implémenter le scraping de TikTok Creative Center
- [ ] Ajouter Redis pour le cache distribué
- [ ] Ajouter des statistiques (hashtags les plus utilisés)
- [ ] Permettre à l'utilisateur de sauvegarder ses hashtags favoris

## 🚀 Prochaines étapes

1. **Phase 1** : Implémenter avec hashtags statiques (1-2h)
2. **Phase 2** : Ajouter le cache (30min)
3. **Phase 3** : Intégrer dans le générateur de captions (1h)
4. **Phase 4** : Tester sur téléphone (30min)
5. **Phase 5** (Optionnel) : Implémenter le scraping TikTok (2-3h)

**Temps total estimé** : 3-4 heures pour la version de base

## 💡 Avantages

✅ Captions plus pertinents et actuels
✅ Meilleure visibilité sur les réseaux sociaux
✅ Hashtags adaptés à chaque plateforme
✅ Gain de temps pour l'utilisateur
✅ 100% GRATUIT (avec hashtags statiques)

Voulez-vous que je commence l'implémentation ? 🚀
