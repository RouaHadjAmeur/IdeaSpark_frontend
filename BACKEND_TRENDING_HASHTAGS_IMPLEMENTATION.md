# 🔥 Backend - Implémentation Hashtags Tendances

## 📋 Vue d'ensemble

Le frontend Flutter appelle maintenant 2 nouveaux endpoints pour récupérer les hashtags tendances. Voici comment les implémenter dans le backend NestJS.

## 🚀 Implémentation Rapide (30 minutes)

### 1. Créer le module

```bash
cd backend
nest g module trending-hashtags
nest g service trending-hashtags
nest g controller trending-hashtags
```

### 2. Service (`src/trending-hashtags/trending-hashtags.service.ts`)

```typescript
import { Injectable } from '@nestjs/common';

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

  // Hashtags statiques par catégorie
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

    console.log(`[TrendingHashtags] Using static hashtags for: ${category}`);
    const hashtags = this.getStaticHashtags(category, platform);

    // Mettre en cache
    this.cache.set(cacheKey, {
      data: hashtags,
      timestamp: Date.now(),
    });

    return hashtags;
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

### 3. Controller (`src/trending-hashtags/trending-hashtags.controller.ts`)

```typescript
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

### 4. Module (`src/trending-hashtags/trending-hashtags.module.ts`)

```typescript
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

### 5. Ajouter le module dans `app.module.ts`

```typescript
import { TrendingHashtagsModule } from './trending-hashtags/trending-hashtags.module';

@Module({
  imports: [
    // ... autres modules
    TrendingHashtagsModule,
  ],
})
export class AppModule {}
```

## 🧪 Tests

### Test 1 : Récupérer les hashtags tendances

```bash
curl -X GET "http://192.168.1.24:3000/trending-hashtags?category=cosmetics&platform=instagram" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Résultat attendu** :
```json
[
  {
    "name": "#makeup",
    "category": "cosmetics",
    "platform": "instagram",
    "trend": "stable"
  },
  {
    "name": "#beauty",
    "category": "cosmetics",
    "platform": "instagram",
    "trend": "stable"
  }
  // ... 12 autres hashtags
]
```

### Test 2 : Générer des hashtags pour un post

```bash
curl -X GET "http://192.168.1.24:3000/trending-hashtags/generate?brandName=Lela&postTitle=Unlock%20Your%20Inner%20Radiance&category=cosmetics&platform=instagram" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Résultat attendu** :
```json
{
  "hashtags": [
    "#makeup",
    "#beauty",
    "#skincare",
    "#cosmetics",
    "#makeuptutorial",
    "#beautytips",
    "#glowup",
    "#selfcare",
    "#beautyblogger",
    "#makeuplover",
    "#lela",
    "#unlock",
    "#radiance"
  ]
}
```

## 📊 Logs Backend

Ajoutez ces logs pour le debug :

```typescript
console.log(`[TrendingHashtags] Request: category=${category}, platform=${platform}`);
console.log(`[TrendingHashtags] Cache hit: ${cacheKey}`);
console.log(`[TrendingHashtags] Generated ${hashtags.length} hashtags`);
```

## 🔐 Authentification

Les deux endpoints nécessitent un JWT token valide :

```typescript
@UseGuards(JwtAuthGuard)
```

Le token est automatiquement envoyé par le service Flutter.

## ⚡ Performance

### Cache
- Durée : 24 heures
- Clé : `${category}_${platform}_${country}`
- Stockage : En mémoire (Map)

### Optimisation future
Si vous voulez un cache distribué (Redis) :

```typescript
import { Injectable } from '@nestjs/common';
import { InjectRedis } from '@nestjs-modules/ioredis';
import Redis from 'ioredis';

@Injectable()
export class TrendingHashtagsService {
  constructor(@InjectRedis() private readonly redis: Redis) {}

  async getTrendingHashtags(category: string, platform: string) {
    const cacheKey = `trending:${category}:${platform}`;
    
    // Vérifier Redis
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    // Générer les hashtags
    const hashtags = this.getStaticHashtags(category, platform);

    // Sauvegarder dans Redis (24h)
    await this.redis.setex(cacheKey, 86400, JSON.stringify(hashtags));

    return hashtags;
  }
}
```

## 📝 Catégories supportées

| Catégorie | Hashtags | Exemples |
|-----------|----------|----------|
| `cosmetics` | 14 | #makeup, #beauty, #skincare |
| `sports` | 14 | #fitness, #workout, #gym |
| `fashion` | 13 | #fashion, #style, #ootd |
| `food` | 14 | #food, #foodie, #foodporn |
| `technology` | 14 | #tech, #innovation, #ai |
| `lifestyle` | 14 | #lifestyle, #motivation, #goals |

**Fallback** : Si la catégorie n'existe pas, utilise `lifestyle`

## 🎯 Workflow complet

```
1. User clique "🔥 Hashtags Tendances"
   ↓
2. Flutter appelle GET /trending-hashtags/generate
   ↓
3. Backend vérifie le cache (24h)
   ↓
4. Si cache vide : génère les hashtags statiques
   ↓
5. Ajoute hashtag de marque (#lela)
   ↓
6. Ajoute hashtags du titre (#unlock, #radiance)
   ↓
7. Retourne 13 hashtags
   ↓
8. Flutter affiche avec icône 🔥
   ↓
9. User copie tous les hashtags
```

## ✅ Checklist d'implémentation

- [ ] Créer le module `TrendingHashtagsModule`
- [ ] Créer le service `TrendingHashtagsService`
- [ ] Créer le controller `TrendingHashtagsController`
- [ ] Ajouter les hashtags statiques (6 catégories)
- [ ] Implémenter le cache en mémoire
- [ ] Ajouter le module dans `app.module.ts`
- [ ] Tester avec curl ou Postman
- [ ] Vérifier les logs backend
- [ ] Tester depuis l'app Flutter

## 🚀 Temps d'implémentation

- **Service** : 10 minutes
- **Controller** : 5 minutes
- **Module** : 2 minutes
- **Tests** : 10 minutes
- **Total** : ~30 minutes

## 📞 Support

Si vous rencontrez un problème :

1. Vérifiez les logs backend : `npm run start:dev`
2. Testez avec curl pour isoler le problème
3. Vérifiez que le JWT token est valide
4. Vérifiez que le module est bien importé dans `app.module.ts`

**Tout est prêt côté frontend !** Il ne reste plus qu'à implémenter le backend. 🚀
