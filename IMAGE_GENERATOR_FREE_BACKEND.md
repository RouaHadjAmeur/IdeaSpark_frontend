# Backend GRATUIT: Générateur d'Images (Unsplash)

## 🎉 100% GRATUIT - Pas de carte bancaire requise!

### 1. Créer un compte Unsplash Developer (GRATUIT)

1. Allez sur: https://unsplash.com/developers
2. Cliquez sur "Register as a developer"
3. Créez une nouvelle application
4. Copiez votre **Access Key**

**Limites gratuites:**
- ✅ 50 requêtes par heure
- ✅ Illimité pour les démos
- ✅ Images haute qualité

### 2. Configuration `.env`

```bash
UNSPLASH_ACCESS_KEY=votre_access_key_ici
```

### 3. Backend NestJS (GRATUIT)

#### Service (`ai-image-generator.service.ts`)

```typescript
import { Injectable, HttpException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import axios from 'axios';

export interface GeneratedImage {
  userId: string;
  url: string;
  prompt: string;
  style: string;
  createdAt: Date;
}

@Injectable()
export class AiImageGeneratorService {
  private unsplashKey = process.env.UNSPLASH_ACCESS_KEY;

  constructor(
    @InjectModel('GeneratedImage')
    private generatedImageModel: Model<GeneratedImage>,
  ) {}

  async generateImageFree(
    userId: string,
    description: string,
    style: string,
    brandName?: string,
  ): Promise<GeneratedImage> {
    // Build search query based on description and style
    const styleKeywords = {
      minimalist: 'minimal clean simple white',
      colorful: 'colorful vibrant bright',
      professional: 'professional business corporate',
      fun: 'fun playful creative',
    };

    const query = `${description} ${styleKeywords[style] || ''}`.trim();

    try {
      // Call Unsplash API (FREE)
      const response = await axios.get('https://api.unsplash.com/photos/random', {
        params: {
          query: query,
          orientation: 'squarish',
          count: 1,
        },
        headers: {
          Authorization: `Client-ID ${this.unsplashKey}`,
        },
      });

      const photo = response.data[0];
      const imageUrl = photo.urls.regular; // High quality image

      // Save to database
      const generatedImage = new this.generatedImageModel({
        userId,
        url: imageUrl,
        prompt: query,
        style,
        createdAt: new Date(),
      });

      await generatedImage.save();

      return {
        userId,
        url: imageUrl,
        prompt: query,
        style,
        createdAt: new Date(),
      };
    } catch (error) {
      throw new HttpException(
        'Failed to fetch image from Unsplash',
        500,
      );
    }
  }

  async getHistory(userId: string): Promise<GeneratedImage[]> {
    return this.generatedImageModel
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(50)
      .exec();
  }

  async deleteImage(userId: string, imageId: string): Promise<void> {
    await this.generatedImageModel.deleteOne({ _id: imageId, userId }).exec();
  }
}
```

#### Controller (`ai-image-generator.controller.ts`)

```typescript
import {
  Controller,
  Post,
  Get,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AiImageGeneratorService } from './ai-image-generator.service';

@Controller('ai')
@UseGuards(JwtAuthGuard)
export class AiImageGeneratorController {
  constructor(private readonly service: AiImageGeneratorService) {}

  @Post('generate-image-free')
  async generateImageFree(
    @Request() req,
    @Body() body: { description: string; style: string; brandName?: string },
  ) {
    return this.service.generateImageFree(
      req.user.userId,
      body.description,
      body.style,
      body.brandName,
    );
  }

  @Get('generated-images')
  async getHistory(@Request() req) {
    return this.service.getHistory(req.user.userId);
  }

  @Delete('generated-images/:id')
  async deleteImage(@Request() req, @Param('id') id: string) {
    await this.service.deleteImage(req.user.userId, id);
    return { message: 'Image deleted successfully' };
  }
}
```

### 4. Installer axios

```bash
npm install axios
```

### 5. Test

```bash
curl -X POST http://localhost:3000/ai/generate-image-free \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "coffee latte",
    "style": "professional"
  }'
```

## Alternative: Pexels (encore plus généreux)

Si vous voulez plus de requêtes gratuites, utilisez Pexels:

```typescript
// Pexels: 200 requêtes/heure GRATUIT
const response = await axios.get('https://api.pexels.com/v1/search', {
  params: {
    query: query,
    per_page: 1,
    orientation: 'square',
  },
  headers: {
    Authorization: process.env.PEXELS_API_KEY,
  },
});

const imageUrl = response.data.photos[0].src.large;
```

Clé Pexels gratuite: https://www.pexels.com/api/

## Avantages

✅ **100% GRATUIT**
✅ **Pas de carte bancaire**
✅ **Images professionnelles haute qualité**
✅ **Parfait pour démo et production**
✅ **50-200 requêtes/heure gratuites**

## Notes

- Les images Unsplash/Pexels sont libres de droits
- Parfait pour usage commercial
- Qualité professionnelle
- Idéal pour votre validation demain!
