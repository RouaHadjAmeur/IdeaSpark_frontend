# Backend: Endpoint pour sauvegarder l'image dans un ContentBlock

## 📍 Endpoint à ajouter

```
PATCH /content-blocks/:id/image
```

## 🎯 Objectif

Sauvegarder l'URL d'une image générée dans un ContentBlock spécifique.

## 📥 Request

### Headers
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

### Body
```json
{
  "imageUrl": "https://images.unsplash.com/photo-..."
}
```

## 📤 Response

### Success (200 OK)
```json
{
  "_id": "block123",
  "title": "Post title",
  "pillar": "Education",
  "format": "post",
  "ctaType": "soft",
  "imageUrl": "https://images.unsplash.com/photo-...",
  "status": "draft",
  ...
}
```

### Error (404 Not Found)
```json
{
  "error": "ContentBlock not found"
}
```

### Error (401 Unauthorized)
```json
{
  "error": "Unauthorized"
}
```

## 🔧 Implémentation NestJS

### Controller (`content-blocks.controller.ts`)

```typescript
import { Controller, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ContentBlocksService } from './content-blocks.service';

@Controller('content-blocks')
@UseGuards(JwtAuthGuard)
export class ContentBlocksController {
  constructor(private readonly contentBlocksService: ContentBlocksService) {}

  @Patch(':id/image')
  async updateImage(
    @Param('id') id: string,
    @Body('imageUrl') imageUrl: string,
  ) {
    return this.contentBlocksService.updateImage(id, imageUrl);
  }
}
```

### Service (`content-blocks.service.ts`)

```typescript
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ContentBlock } from './schemas/content-block.schema';

@Injectable()
export class ContentBlocksService {
  constructor(
    @InjectModel('ContentBlock')
    private contentBlockModel: Model<ContentBlock>,
  ) {}

  async updateImage(id: string, imageUrl: string): Promise<ContentBlock> {
    const block = await this.contentBlockModel.findByIdAndUpdate(
      id,
      { imageUrl },
      { new: true }, // Return updated document
    );

    if (!block) {
      throw new NotFoundException(`ContentBlock with ID ${id} not found`);
    }

    console.log(`✅ Image saved to ContentBlock ${id}: ${imageUrl}`);
    return block;
  }
}
```

### Schema (`content-block.schema.ts`)

Assurez-vous que le champ `imageUrl` existe dans votre schéma:

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema({ timestamps: true })
export class ContentBlock extends Document {
  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  pillar: string;

  @Prop()
  productId?: string;

  @Prop({ required: true, enum: ['reel', 'carousel', 'story', 'post'] })
  format: string;

  @Prop({ required: true, enum: ['soft', 'hard', 'educational'] })
  ctaType: string;

  @Prop()
  emotionalTrigger?: string;

  @Prop({ default: 0 })
  recommendedDayOffset: number;

  @Prop()
  recommendedTime?: string;

  @Prop({ default: 'draft', enum: ['draft', 'scheduled', 'edited'] })
  status: string;

  @Prop() // ← IMPORTANT: Ajoutez ce champ
  imageUrl?: string;
}

export const ContentBlockSchema = SchemaFactory.createForClass(ContentBlock);
```

## 🧪 Test

### Avec curl:
```bash
curl -X PATCH http://localhost:3000/content-blocks/block123/image \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"imageUrl":"https://images.unsplash.com/photo-123"}'
```

### Avec Postman:
1. Method: PATCH
2. URL: `http://localhost:3000/content-blocks/block123/image`
3. Headers:
   - `Authorization: Bearer YOUR_JWT_TOKEN`
   - `Content-Type: application/json`
4. Body (raw JSON):
```json
{
  "imageUrl": "https://images.unsplash.com/photo-123"
}
```

## ✅ Vérification

Après l'implémentation, vous devriez voir dans les logs Flutter:
```
💾 [Flutter] Saving image to post...
📍 [Flutter] ContentBlock ID: block123
🖼️ [Flutter] Image URL: https://images.unsplash.com/photo-...
✅ [Flutter] Save response: 200
```

Et dans les logs backend:
```
✅ Image saved to ContentBlock block123: https://images.unsplash.com/photo-...
```

## 🎯 Résultat

Une fois implémenté:
1. L'utilisateur génère une image
2. Clique sur "Utiliser"
3. L'image est sauvegardée dans le ContentBlock
4. La miniature apparaît dans la liste des posts
5. L'image est persistée en base de données

