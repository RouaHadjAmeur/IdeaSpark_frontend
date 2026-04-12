# 📱 Documentation Backend - Partage d'Images sur Réseaux Sociaux

## 📋 Vue d'ensemble

Le frontend Flutter peut maintenant partager les images générées sur Instagram, TikTok et Facebook. Cette fonctionnalité utilise les endpoints backend existants et ne nécessite **AUCUNE modification backend**.

## ✅ Endpoints Backend Utilisés

### 1. Génération d'image
```http
POST /ai-images/generate
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "description": "Lela - Unlock Your Inner Radiance",
  "style": "professional",
  "category": "cosmetics"
}
```

**Réponse** :
```json
{
  "id": "507f1f77bcf86cd799439011",
  "url": "https://images.unsplash.com/photo-...",
  "prompt": "cosmetics makeup skincare beauty products...",
  "style": "professional",
  "category": "cosmetics",
  "source": "unsplash",
  "createdAt": "2026-04-11T10:30:00.000Z"
}
```

### 2. Sauvegarde dans un post
```http
PATCH /content-blocks/:id/image
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json

{
  "imageUrl": "https://images.unsplash.com/photo-..."
}
```

**Réponse** :
```json
{
  "id": "507f1f77bcf86cd799439011",
  "title": "Unlock Your Inner Radiance",
  "imageUrl": "https://images.unsplash.com/photo-...",
  "updatedAt": "2026-04-11T10:31:00.000Z"
}
```

### 3. Historique des images
```http
GET /ai-images/history
Authorization: Bearer <JWT_TOKEN>
```

**Réponse** :
```json
[
  {
    "id": "507f1f77bcf86cd799439011",
    "url": "https://images.unsplash.com/photo-...",
    "prompt": "cosmetics makeup skincare...",
    "style": "professional",
    "category": "cosmetics",
    "source": "unsplash",
    "createdAt": "2026-04-11T10:30:00.000Z"
  }
]
```

## 🔄 Workflow Frontend → Backend

### Scénario 1 : Générer et partager une image

```mermaid
sequenceDiagram
    participant User
    participant Flutter
    participant Backend
    participant Unsplash
    participant Phone
    participant Instagram

    User->>Flutter: Clique "Générer"
    Flutter->>Backend: POST /ai-images/generate
    Backend->>Unsplash: Search photos (category + style)
    Unsplash-->>Backend: Image URL
    Backend-->>Flutter: {url, id, prompt}
    Flutter->>User: Affiche l'image

    User->>Flutter: Clique "Utiliser"
    Flutter->>Backend: PATCH /content-blocks/:id/image
    Backend-->>Flutter: {imageUrl updated}
    Flutter->>User: ✅ Image sauvegardée

    User->>Flutter: Clique "Partager"
    Flutter->>Phone: Download image from URL
    Flutter->>Phone: Save to gallery
    Flutter->>Phone: Copy caption to clipboard
    Flutter->>Instagram: Open app
    User->>Instagram: Create post + paste caption
```

## 📦 Données Stockées dans MongoDB

### Collection `generatedimages`
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439011"),
  userId: ObjectId("507f191e810c19729de860ea"),
  url: "https://images.unsplash.com/photo-1234567890",
  prompt: "cosmetics makeup skincare beauty products lela professional",
  style: "professional",
  category: "cosmetics",
  source: "unsplash",
  createdAt: ISODate("2026-04-11T10:30:00.000Z")
}
```

### Collection `contentblocks`
```javascript
{
  _id: ObjectId("507f1f77bcf86cd799439011"),
  title: "Unlock Your Inner Radiance",
  caption: "✨ Découvrez notre nouvelle collection...",
  imageUrl: "https://images.unsplash.com/photo-1234567890", // ✅ NOUVEAU
  format: "post",
  pillar: "Product Launch",
  ctaType: "shop",
  updatedAt: ISODate("2026-04-11T10:31:00.000Z")
}
```

## 🔐 Authentification

Tous les endpoints nécessitent un JWT token valide :

```typescript
// Headers requis
{
  'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  'Content-Type': 'application/json'
}
```

Le token est automatiquement ajouté par le service Flutter `ImageGeneratorService`.

## 🌐 URLs des Images

### Format Unsplash
```
https://images.unsplash.com/photo-1234567890?ixlib=rb-4.0.3&ixid=...&w=1080&q=80
```

### Format Pexels
```
https://images.pexels.com/photos/1234567/pexels-photo-1234567.jpeg?auto=compress&cs=tinysrgb&w=1080
```

**Important** : Ces URLs sont publiques et accessibles sans authentification. Le frontend peut les télécharger directement sans passer par le backend.

## 📱 Workflow de Partage (Frontend uniquement)

Le partage sur les réseaux sociaux est géré **100% côté frontend** et ne nécessite **AUCUN appel backend supplémentaire**.

### Étapes du partage Instagram

1. **Téléchargement de l'image**
   ```dart
   // Flutter télécharge l'image depuis l'URL Unsplash/Pexels
   final response = await http.get(Uri.parse(imageUrl));
   final bytes = response.bodyBytes;
   ```

2. **Sauvegarde dans la galerie**
   ```dart
   // Flutter sauvegarde l'image dans la galerie du téléphone
   await ImageGallerySaver.saveImage(bytes);
   ```

3. **Copie de la caption**
   ```dart
   // Flutter copie la caption dans le presse-papiers
   await Clipboard.setData(ClipboardData(text: caption));
   ```

4. **Ouverture d'Instagram**
   ```dart
   // Flutter ouvre l'application Instagram
   await launchUrl(Uri.parse('instagram://'));
   ```

**Aucun appel backend n'est nécessaire pour ces étapes !**

## 🔍 Logs Backend à Surveiller

### Génération d'image
```
[AiImageGeneratorService] Generating image...
[AiImageGeneratorService] Category: cosmetics
[AiImageGeneratorService] Brand: Lela
[AiImageGeneratorService] Query: cosmetics makeup skincare beauty products lela professional
[AiImageGeneratorService] Unsplash response: 200
[AiImageGeneratorService] Image URL: https://images.unsplash.com/photo-...
[AiImageGeneratorService] Saved to database: 507f1f77bcf86cd799439011
```

### Sauvegarde dans un post
```
[ContentBlocksService] Updating image URL for block: 507f1f77bcf86cd799439011
[ContentBlocksService] New image URL: https://images.unsplash.com/photo-...
[ContentBlocksService] Block updated successfully
```

### Historique
```
[AiImageGeneratorService] Fetching history for user: 507f191e810c19729de860ea
[AiImageGeneratorService] Found 15 images
```

## 🚨 Erreurs Possibles

### 1. Clé API Unsplash invalide
```json
{
  "statusCode": 401,
  "message": "Unsplash API key is invalid",
  "error": "Unauthorized"
}
```

**Solution** : Vérifier que `UNSPLASH_ACCESS_KEY` est dans `.env`

### 2. Clé API Pexels invalide
```json
{
  "statusCode": 401,
  "message": "Pexels API key is invalid",
  "error": "Unauthorized"
}
```

**Solution** : Vérifier que `PEXELS_API_KEY` est dans `.env`

### 3. ContentBlock introuvable
```json
{
  "statusCode": 404,
  "message": "ContentBlock not found",
  "error": "Not Found"
}
```

**Solution** : Vérifier que l'ID du ContentBlock existe dans la base de données

### 4. Limite API dépassée
```json
{
  "statusCode": 429,
  "message": "Rate limit exceeded",
  "error": "Too Many Requests"
}
```

**Solution** : Attendre 1 heure (Unsplash: 50/h, Pexels: 200/h)

## 📊 Statistiques d'Utilisation

### Requêtes par endpoint (estimation)

| Endpoint | Fréquence | Charge |
|----------|-----------|--------|
| `POST /ai-images/generate` | 10-20/jour | Moyenne |
| `PATCH /content-blocks/:id/image` | 5-10/jour | Faible |
| `GET /ai-images/history` | 2-5/jour | Faible |

### Limites API externes

| Service | Limite gratuite | Fallback |
|---------|----------------|----------|
| Unsplash | 50 requêtes/heure | Pexels |
| Pexels | 200 requêtes/heure | Erreur 503 |

**Total** : 250 images gratuites par heure

## 🔧 Configuration Backend Requise

### Variables d'environnement (`.env`)
```env
# API Keys (GRATUITES)
UNSPLASH_ACCESS_KEY=VI9DMMy0GnthKS537o74cNt_IzP6NTL1w6vNvdGEt1I
PEXELS_API_KEY=is7UtaKZpxYgRNLHRFtk047RhfXgAaUVp2gEhygo796frviQU6HA2TeL

# MongoDB
MONGODB_URI=mongodb+srv://rouahadjameur_db_user:u8kt1379YXWd4zCZ@spark.wwnh1wj.mongodb.net/ideaspark

# JWT
JWT_SECRET=your-secret-key

# Server
PORT=3000
HOST=0.0.0.0
```

### Modules NestJS
```typescript
// app.module.ts
@Module({
  imports: [
    MongooseModule.forRoot(process.env.MONGODB_URI),
    AiImageGeneratorModule,  // ✅ Module de génération d'images
    ContentBlocksModule,     // ✅ Module de gestion des posts
    AuthModule,              // ✅ Module d'authentification
  ],
})
export class AppModule {}
```

## 🧪 Tests Backend

### Test 1 : Générer une image
```bash
curl -X POST http://192.168.1.24:3000/ai-images/generate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Lela - Unlock Your Inner Radiance",
    "style": "professional",
    "category": "cosmetics"
  }'
```

**Résultat attendu** : Status 201, URL d'image Unsplash

### Test 2 : Sauvegarder dans un post
```bash
curl -X PATCH http://192.168.1.24:3000/content-blocks/507f1f77bcf86cd799439011/image \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "imageUrl": "https://images.unsplash.com/photo-1234567890"
  }'
```

**Résultat attendu** : Status 200, ContentBlock mis à jour

### Test 3 : Récupérer l'historique
```bash
curl -X GET http://192.168.1.24:3000/ai-images/history \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Résultat attendu** : Status 200, Array d'images

## 📝 Notes Importantes

### 1. Pas de modification backend nécessaire
Le partage sur les réseaux sociaux est géré **100% côté frontend**. Le backend n'a **rien à faire** pour cette fonctionnalité.

### 2. URLs publiques
Les URLs Unsplash/Pexels sont publiques et peuvent être téléchargées directement par le frontend sans authentification.

### 3. Pas de stockage d'images
Le backend ne stocke **pas les fichiers images**, seulement les URLs. Les images restent hébergées sur Unsplash/Pexels.

### 4. Pas de proxy nécessaire
Le frontend télécharge les images directement depuis Unsplash/Pexels, pas besoin de passer par le backend.

### 5. Permissions gérées par le frontend
Les permissions photos (Android/iOS) sont gérées automatiquement par Flutter, pas besoin de configuration backend.

## ✅ Checklist Backend

- [x] Module `AiImageGeneratorModule` créé
- [x] Service avec logique de catégorie prioritaire
- [x] Controller avec 3 endpoints (generate, history, delete)
- [x] Endpoint de sauvegarde dans ContentBlock
- [x] Clés API Unsplash et Pexels dans `.env`
- [x] MongoDB connecté
- [x] JWT authentification fonctionnelle
- [x] CORS configuré pour `http://192.168.1.24:3000`
- [x] Backend écoute sur `0.0.0.0:3000`

## 🎉 Résumé

Le backend est **100% prêt** pour le partage d'images sur les réseaux sociaux. Aucune modification n'est nécessaire car :

1. ✅ Les endpoints de génération et sauvegarde existent déjà
2. ✅ Les URLs d'images sont publiques (Unsplash/Pexels)
3. ✅ Le partage est géré côté frontend (téléchargement, galerie, clipboard, ouverture d'apps)
4. ✅ Pas besoin de proxy ou de stockage d'images

**Le backend n'a qu'à continuer de fonctionner normalement !** 🚀

---

## 📞 Support

Si vous rencontrez un problème :

1. Vérifiez les logs backend (terminal NestJS)
2. Vérifiez que les clés API sont dans `.env`
3. Vérifiez que MongoDB est connecté
4. Vérifiez que le backend écoute sur `0.0.0.0:3000`

**Tout devrait fonctionner parfaitement !** ✨
