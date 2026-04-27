# 🧪 Guide de Test - Fonctionnalités Créatives IA

## 📍 Où se trouvent les 3 fonctionnalités ?

### Accès dans l'application

**Méthode 1 : Via le menu latéral (Sidebar)**
1. Ouvre l'application IdeaSpark
2. Ouvre le menu latéral (☰)
3. Cherche la section "TOOLS"
4. Clique sur **"✨ Fonctionnalités Créatives IA"**

**Méthode 2 : Via le code (pour développeur)**
```dart
context.push('/creative-ai-test');
```

---

## 🎯 Les 3 Fonctionnalités

### 1. 🎣 Viral Hooks Generator (Générateur de Hooks)
**Position** : En haut de l'écran

### 2. 📊 Post Analyzer (Analyseur de Post)
**Position** : Au milieu de l'écran

### 3. ⏰ Optimal Timing Predictor (Prédicteur d'Heures)
**Position** : En bas de l'écran

---

## 🧪 Comment tester chaque fonctionnalité

### 1. 🎣 Tester le Générateur de Hooks Viraux

#### Étapes :
1. **Entrer un sujet**
   - Exemple : "café", "fitness", "voyage", "cosmétiques"
   
2. **Sélectionner un ton**
   - Fun 😄
   - Professional 💼
   - Inspirational ✨
   - Casual 😎

3. **Cliquer sur "Générer des hooks"**
   - Attendre 2-3 secondes

4. **Résultat attendu**
   - 5 hooks viraux s'affichent
   - Exemples de patterns :
     - "POV: Tu découvres le meilleur café de ta vie ☕"
     - "3 secrets pour un café parfait que personne ne te dit"
     - "Stop! Ne bois plus ton café comme ça ❌"

5. **Sélectionner un hook**
   - Clique sur un hook
   - Il s'insère automatiquement dans la caption

#### ✅ Test réussi si :
- 5 hooks sont générés
- Les hooks correspondent au sujet et au ton
- Le hook sélectionné s'insère dans la caption

---

### 2. 📊 Tester l'Analyseur de Post

#### Étapes :
1. **Écrire une caption**
   - Utilise un hook généré OU écris ta propre caption
   - Exemple : "Découvrez notre nouveau rouge à lèvres mat longue tenue 💄✨"

2. **Ajouter des hashtags**
   - Exemple : "#cosmetics #makeup #beauty #lipstick"
   - Sépare les hashtags par des espaces

3. **Sélectionner une plateforme**
   - Instagram
   - TikTok
   - Facebook
   - LinkedIn

4. **Cliquer sur "📊 Analyser le post"**
   - Attendre 2-3 secondes

5. **Résultat attendu**
   - **Score global** : 0-100
     - 🟢 Vert (80-100) : Excellent
     - 🟠 Orange (50-79) : Moyen
     - 🔴 Rouge (0-49) : Faible
   
   - **Scores détaillés** :
     - Caption : score + feedback
     - Hashtags : score + feedback
     - Timing : score + feedback
     - Structure : score + feedback
   
   - **Suggestions d'amélioration**
     - Liste de conseils pour améliorer le post
   
   - **Prédiction d'engagement**
     - 📈 Élevé (high)
     - 📊 Moyen (medium)
     - 📉 Faible (low)

#### ✅ Test réussi si :
- Le score global s'affiche (0-100)
- Les 4 scores détaillés s'affichent
- Des suggestions sont proposées
- La prédiction d'engagement est affichée

---

### 3. ⏰ Tester le Prédicteur d'Heures Optimales

#### Étapes :
1. **Chargement automatique**
   - Le timing se charge automatiquement quand tu ouvres l'écran
   - Basé sur la plateforme sélectionnée (Instagram par défaut)

2. **Changer de plateforme**
   - Sélectionne une autre plateforme (TikTok, Facebook, LinkedIn)
   - Le timing se met à jour automatiquement

3. **Résultat attendu**
   - **Meilleurs moments** (🟢 Vert)
     - Jour (Lundi, Mardi, etc.)
     - Heure (18:00, 12:00, etc.)
     - Score (0-100)
     - Raison ("Pic d'engagement après le travail")
     - Engagement attendu ("Très élevé")
   
   - **Pires moments** (🔴 Rouge)
     - Jour
     - Heure
     - Score
     - Raison ("Très faible activité")

#### ✅ Test réussi si :
- Les meilleurs moments s'affichent (au moins 3)
- Les pires moments s'affichent (au moins 2)
- Les scores sont cohérents (meilleurs > 70, pires < 30)
- Les raisons sont affichées

---

## 🔄 Workflow complet de test

### Scénario 1 : Créer un post complet

1. **Générer un hook**
   - Sujet : "cosmétiques"
   - Ton : "fun"
   - Sélectionner un hook

2. **Compléter la caption**
   - Ajouter des détails après le hook
   - Exemple : "POV: Tu découvres le meilleur rouge à lèvres de ta vie 💄\n\nNotre nouvelle collection est enfin là ! 🎉"

3. **Ajouter des hashtags**
   - "#cosmetics #makeup #beauty #lipstick #newcollection"

4. **Analyser le post**
   - Cliquer sur "📊 Analyser le post"
   - Vérifier le score

5. **Consulter le timing optimal**
   - Scroller en bas
   - Noter les meilleurs moments pour poster

6. **Améliorer le post** (si score < 80)
   - Lire les suggestions
   - Modifier la caption ou les hashtags
   - Ré-analyser

---

## 📡 Vérifier que le backend fonctionne

### Endpoints requis

Le frontend appelle ces 3 endpoints :

1. **POST /viral-hooks/generate**
   - Pour générer les hooks

2. **POST /post-analyzer/score**
   - Pour analyser le post

3. **POST /optimal-timing/predict**
   - Pour obtenir le timing optimal

### Comment vérifier

#### Option 1 : Via l'application
- Si tu vois des erreurs rouges → Backend ne répond pas
- Si tout fonctionne → Backend OK

#### Option 2 : Via les logs
- Ouvre la console Flutter
- Cherche ces logs :
  - `🎣 [ViralHooks] Génération de hooks...`
  - `📊 [PostAnalyzer] Analyse du post...`
  - `⏰ [OptimalTiming] Prédiction du timing...`

#### Option 3 : Via Postman (test manuel)

**Test 1 : Viral Hooks**
```bash
curl -X POST "http://192.168.1.24:3000/viral-hooks/generate" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "topic": "café",
    "platform": "instagram",
    "tone": "fun",
    "count": 5
  }'
```

**Test 2 : Post Analyzer**
```bash
curl -X POST "http://192.168.1.24:3000/post-analyzer/score" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "caption": "Découvrez notre nouveau produit...",
    "hashtags": ["#fitness", "#motivation"],
    "platform": "instagram"
  }'
```

**Test 3 : Optimal Timing**
```bash
curl -X POST "http://192.168.1.24:3000/optimal-timing/predict" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "platform": "instagram",
    "contentType": "post"
  }'
```

---

## ❌ Problèmes courants

### Problème 1 : "Erreur: Timeout"
**Cause** : Backend ne répond pas
**Solution** :
1. Vérifie que le backend est démarré
2. Vérifie l'URL : `http://192.168.1.24:3000`
3. Vérifie que ton téléphone est sur le même réseau WiFi

### Problème 2 : "Erreur: 401 Unauthorized"
**Cause** : Token JWT invalide ou expiré
**Solution** :
1. Déconnecte-toi de l'app
2. Reconnecte-toi
3. Réessaye

### Problème 3 : "Aucun hook généré"
**Cause** : Module backend `viral-hooks` non déployé
**Solution** :
1. Vérifie que le module est dans le backend
2. Vérifie les logs backend
3. Redémarre le backend

### Problème 4 : "Score toujours 0"
**Cause** : Module backend `post-analyzer` non déployé
**Solution** :
1. Vérifie que le module est dans le backend
2. Vérifie que Gemini API est configurée
3. Vérifie les logs backend

### Problème 5 : "Timing ne se charge pas"
**Cause** : Module backend `optimal-timing` non déployé
**Solution** :
1. Vérifie que le module est dans le backend
2. Vérifie les logs backend
3. Redémarre le backend

---

## ✅ Checklist de test complète

### Générateur de Hooks
- [ ] Entrer un sujet
- [ ] Sélectionner un ton
- [ ] Générer 5 hooks
- [ ] Sélectionner un hook
- [ ] Vérifier qu'il s'insère dans la caption

### Analyseur de Post
- [ ] Écrire une caption
- [ ] Ajouter des hashtags
- [ ] Sélectionner une plateforme
- [ ] Analyser le post
- [ ] Vérifier le score global
- [ ] Vérifier les 4 scores détaillés
- [ ] Vérifier les suggestions
- [ ] Vérifier la prédiction d'engagement

### Prédicteur de Timing
- [ ] Vérifier le chargement automatique
- [ ] Changer de plateforme
- [ ] Vérifier la mise à jour automatique
- [ ] Vérifier les meilleurs moments (vert)
- [ ] Vérifier les pires moments (rouge)
- [ ] Vérifier les scores et raisons

### Tests d'intégration
- [ ] Workflow complet (hook → caption → analyse → timing)
- [ ] Tester sur Instagram
- [ ] Tester sur TikTok
- [ ] Tester sur Facebook
- [ ] Tester sur LinkedIn

---

## 📱 Test sur téléphone

### Prérequis
1. Backend démarré sur `http://192.168.1.24:3000`
2. Téléphone sur le même réseau WiFi
3. Application installée sur le téléphone

### Étapes
1. Ouvre l'app sur ton téléphone (Oppo CPH2727)
2. Connecte-toi
3. Ouvre le menu latéral
4. Clique sur "✨ Fonctionnalités Créatives IA"
5. Suis les étapes de test ci-dessus

---

## 🎉 Résultat attendu

Si tout fonctionne correctement :

1. **Hooks** : 5 hooks viraux générés en 2-3 secondes
2. **Analyse** : Score 0-100 avec détails et suggestions
3. **Timing** : Meilleurs et pires moments affichés

**L'écran devrait ressembler à ça :**

```
┌─────────────────────────────────────┐
│ ← Fonctionnalités Créatives IA      │
├─────────────────────────────────────┤
│                                     │
│ 🎣 Générateur de Hooks Viraux       │
│ [Sujet: café] [Ton: fun]            │
│ [Générer des hooks]                 │
│                                     │
│ ✓ POV: Tu découvres le meilleur...  │
│ ✓ 3 secrets pour un café parfait... │
│ ✓ Stop! Ne bois plus ton café...    │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ ✏️ Votre Post                        │
│ [Plateforme: Instagram]             │
│ [Caption: ...]                      │
│ [Hashtags: #café #coffee]           │
│ [📊 Analyser le post]               │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ 📊 Score: 85/100 🟢                 │
│ Caption: 90/100                     │
│ Hashtags: 80/100                    │
│ Suggestions: Ajoutez un CTA...      │
│ Engagement: 📈 Élevé                │
│                                     │
├─────────────────────────────────────┤
│                                     │
│ ⏰ Meilleurs moments pour poster    │
│ 🟢 Lundi 18:00 (Score: 95)          │
│ 🟢 Mercredi 12:00 (Score: 88)       │
│ 🔴 Dimanche 03:00 (Score: 15)       │
│                                     │
└─────────────────────────────────────┘
```

---

## 📞 Support

Si tu rencontres un problème :

1. Vérifie les logs Flutter (console)
2. Vérifie les logs backend
3. Vérifie que le backend répond (Postman)
4. Vérifie que tu es connecté (JWT token valide)

---

**Bon test ! 🚀**

**Prêt pour la démo demain ! 💪**
