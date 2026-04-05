# 📋 Documentation Backend - Collaboration IdeaSpark

## Vue d'ensemble

Pour rendre la collaboration dynamique, le backend NestJS doit implémenter
les endpoints suivants. Le frontend Flutter est déjà prêt - il suffit de
connecter les services.

---

## 🗄️ Base de données (Schémas)

### Table `plan_members`
```sql
CREATE TABLE plan_members (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id     UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES users(id),
  email       VARCHAR(255) NOT NULL,
  name        VARCHAR(255) NOT NULL,
  role        ENUM('admin', 'editor', 'viewer') DEFAULT 'editor',
  status      ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
  invited_at  TIMESTAMP DEFAULT NOW(),
  accepted_at TIMESTAMP
);
```

### Table `post_comments`
```sql
CREATE TABLE post_comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     VARCHAR(255) NOT NULL,
  plan_id     UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  author_id   UUID REFERENCES users(id),
  author_name VARCHAR(255) NOT NULL,
  text        TEXT NOT NULL,
  action      ENUM('approved', 'rejected', 'commented') DEFAULT 'commented',
  created_at  TIMESTAMP DEFAULT NOW()
);
```

### Table `plan_history`
```sql
CREATE TABLE plan_history (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id     UUID NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
  author_id   UUID REFERENCES users(id),
  author_name VARCHAR(255) NOT NULL,
  action      VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  created_at  TIMESTAMP DEFAULT NOW()
);
```

---

## 🔌 Endpoints à créer

### 1. Membres du Plan

#### POST `/collaboration/invite`
Inviter un membre par email.

**Request Body:**
```json
{
  "planId": "uuid",
  "email": "membre@example.com",
  "name": "Nom Prénom",
  "role": "editor"
}
```

**Response:**
```json
{
  "id": "uuid",
  "planId": "uuid",
  "email": "membre@example.com",
  "name": "Nom Prénom",
  "role": "editor",
  "status": "pending",
  "invitedAt": "2026-03-25T10:00:00Z"
}
```

**Actions backend:**
- Créer l'entrée dans `plan_members`
- Envoyer un email d'invitation avec un lien d'acceptation
- Ajouter une entrée dans `plan_history`

---

#### GET `/collaboration/:planId/members`
Récupérer tous les membres d'un plan.

**Response:**
```json
[
  {
    "id": "uuid",
    "email": "membre@example.com",
    "name": "Nom Prénom",
    "role": "editor",
    "status": "accepted",
    "invitedAt": "2026-03-25T10:00:00Z"
  }
]
```

---

#### PATCH `/collaboration/:planId/members/:memberId`
Modifier le rôle d'un membre.

**Request Body:**
```json
{
  "role": "admin"
}
```

---

#### DELETE `/collaboration/:planId/members/:memberId`
Retirer un membre du plan.

---

#### POST `/collaboration/accept/:token`
Accepter une invitation (via le lien email).

**Response:**
```json
{
  "success": true,
  "planId": "uuid",
  "planName": "Plan Nike"
}
```

---

### 2. Commentaires sur les Posts

#### GET `/collaboration/comments/:postId`
Récupérer les commentaires d'un post.

**Response:**
```json
[
  {
    "id": "uuid",
    "postId": "post-id",
    "authorName": "Chayma",
    "text": "Super contenu !",
    "action": "approved",
    "createdAt": "2026-03-25T10:00:00Z"
  }
]
```

---

#### POST `/collaboration/comments`
Ajouter un commentaire ou une action (approuver/rejeter).

**Request Body:**
```json
{
  "postId": "post-id",
  "planId": "uuid",
  "text": "Ce post est excellent !",
  "action": "approved"
}
```

**Valeurs de `action`:**
- `"approved"` - Approuver le post
- `"rejected"` - Rejeter le post
- `"commented"` - Simple commentaire (laisser null)

---

#### DELETE `/collaboration/comments/:commentId`
Supprimer un commentaire.

---

### 3. Historique des Modifications

#### GET `/collaboration/:planId/history`
Récupérer l'historique d'un plan.

**Response:**
```json
[
  {
    "id": "uuid",
    "planId": "uuid",
    "authorName": "Chayma",
    "action": "invitation",
    "description": "membre@example.com invité comme Éditeur",
    "createdAt": "2026-03-25T10:00:00Z"
  }
]
```

---

#### POST `/collaboration/:planId/history`
Ajouter une entrée dans l'historique (appelé automatiquement par les autres endpoints).

**Request Body:**
```json
{
  "action": "plan_updated",
  "description": "Plan Nike mis à jour - Phase 1 modifiée"
}
```

---

## 📧 Service d'Email (NestJS)

### Installation
```bash
npm install @nestjs-modules/mailer nodemailer
```

### Template d'invitation
```html
<!-- invitation.hbs -->
<h1>Vous avez été invité à collaborer sur IdeaSpark</h1>
<p>{{inviterName}} vous invite à rejoindre le plan "{{planName}}"</p>
<p>Votre rôle : <strong>{{role}}</strong></p>
<a href="{{acceptUrl}}">Accepter l'invitation</a>
```

### Service
```typescript
// collaboration.service.ts
async inviteMember(planId: string, dto: InviteDto, inviterId: string) {
  const token = crypto.randomUUID();
  
  // Sauvegarder en DB
  const member = await this.prisma.planMember.create({
    data: {
      planId,
      email: dto.email,
      name: dto.name,
      role: dto.role,
      status: 'pending',
      inviteToken: token,
    }
  });

  // Envoyer l'email
  await this.mailerService.sendMail({
    to: dto.email,
    subject: 'Invitation à collaborer sur IdeaSpark',
    template: 'invitation',
    context: {
      inviterName: 'Votre équipe',
      planName: plan.name,
      role: dto.role,
      acceptUrl: `${process.env.APP_URL}/collaboration/accept/${token}`,
    },
  });

  // Historique
  await this.addHistory(planId, inviterId, 'invitation',
    `${dto.email} invité comme ${dto.role}`);

  return member;
}
```

---

## 🔄 Mise à jour du Frontend Flutter

Une fois le backend prêt, modifiez `lib/services/collaboration_service.dart` :

```dart
// Remplacer SharedPreferences par des appels HTTP

Future<List<CollabMember>> getMembers(String planId) async {
  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/collaboration/$planId/members'),
    headers: {'Authorization': 'Bearer $token'},
  );
  final list = jsonDecode(response.body) as List;
  return list.map((e) => CollabMember.fromJson(e)).toList();
}

Future<void> inviteMember(String planId, CollabMember member) async {
  await http.post(
    Uri.parse('${ApiConfig.baseUrl}/collaboration/invite'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'planId': planId,
      'email': member.email,
      'name': member.name,
      'role': member.role.name,
    }),
  );
}
```

---

## 📡 Endpoints à ajouter dans `api_config.dart`

```dart
// Collaboration
static String get collaborationBase => '$baseUrl/collaboration';
static String inviteMemberUrl() => '$collaborationBase/invite';
static String getMembersUrl(String planId) => '$collaborationBase/$planId/members';
static String updateMemberUrl(String planId, String memberId) =>
    '$collaborationBase/$planId/members/$memberId';
static String deleteMemberUrl(String planId, String memberId) =>
    '$collaborationBase/$planId/members/$memberId';
static String getCommentsUrl(String postId) => '$collaborationBase/comments/$postId';
static String addCommentUrl() => '$collaborationBase/comments';
static String getHistoryUrl2(String planId) => '$collaborationBase/$planId/history';
```

---

## 🔐 Sécurité

### Guards NestJS
```typescript
// Vérifier que l'utilisateur a accès au plan
@UseGuards(JwtAuthGuard, PlanMemberGuard)
@Get(':planId/members')
async getMembers(@Param('planId') planId: string) { ... }
```

### Permissions par rôle
| Action | Admin | Éditeur | Lecteur |
|--------|-------|---------|---------|
| Voir les membres | ✅ | ✅ | ✅ |
| Inviter | ✅ | ❌ | ❌ |
| Changer les rôles | ✅ | ❌ | ❌ |
| Commenter | ✅ | ✅ | ✅ |
| Approuver/Rejeter | ✅ | ✅ | ❌ |
| Voir l'historique | ✅ | ✅ | ✅ |

---

## 📊 Résumé des fichiers à créer côté backend

```
src/
  collaboration/
    collaboration.module.ts
    collaboration.controller.ts
    collaboration.service.ts
    dto/
      invite-member.dto.ts
      add-comment.dto.ts
    entities/
      plan-member.entity.ts
      post-comment.entity.ts
      plan-history.entity.ts
    guards/
      plan-member.guard.ts
    templates/
      invitation.hbs
```

---

## ✅ Checklist d'implémentation

- [ ] Créer les tables en base de données
- [ ] Créer le module `CollaborationModule`
- [ ] Implémenter les endpoints (invite, members, comments, history)
- [ ] Configurer le service d'email (Nodemailer)
- [ ] Créer le template d'email d'invitation
- [ ] Ajouter les guards de sécurité
- [ ] Mettre à jour `api_config.dart` dans Flutter
- [ ] Remplacer SharedPreferences par les appels HTTP dans `collaboration_service.dart`
- [ ] Tester avec Postman

---

**Auteur :** Chayma Rzig  
**Date :** Mars 2026  
**Version :** 1.0.0
