# 👥 User Types & UI Routing Guide

## Overview

IdeaSpark has **two main user types** with different UIs and capabilities:

---

## 1️⃣ **Non-Premium User (Collaborator/Creator)**

### Who?
- Regular users who sign up
- Don't have premium subscription
- Can be brand owners OR regular collaborators

### What They See?
**Collaborator UI** (`challenges_screen.dart`)
- 3 tabs: DISCOVER, CHALLENGE, MY WORK

### What They Can Do?
✅ Discover available challenges  
✅ Browse challenges by type, reward, language  
✅ View full challenge briefs  
✅ Submit videos to challenges  
✅ Track submission status  
✅ Receive feedback from brands  
✅ Upload revised videos  
✅ View past wins  
✅ Get notifications  

### What They CANNOT Do?
❌ Create brands  
❌ Launch challenges  
❌ Manage submissions  
❌ Evaluate creators  
❌ Declare winners  

### Database Flags
```
isPremium: false
isBrandOwner: false (or true, but isPremium is false)
```

---

## 2️⃣ **Premium Brand Owner**

### Who?
- Users with active premium subscription
- Have `isBrandOwner = true`
- Have `isPremium = true`

### What They See?
**Brand Owner UI** (`brand_challenges_screen.dart`)
- 2 tabs: MANAGE CHALLENGES, LAUNCH CHALLENGE

### What They Can Do?
✅ Create brands  
✅ Launch challenges  
✅ View all submissions  
✅ Rate and tag submissions  
✅ Shortlist creators  
✅ Request revisions  
✅ Declare winners  
✅ View dashboard statistics  
✅ Track active campaigns  
✅ Manage rewards  

### What They CANNOT Do?
❌ Submit to challenges (they create them)  
❌ Compete with creators  

### Database Flags
```
isPremium: true
isBrandOwner: true
```

---

## 🔄 **Routing Logic**

### Current Implementation (home_screen.dart)

```dart
if (authVm.isPremiumBrandOwner) {
  // Premium Brand Owner
  return const DashboardV2Screen();  // Brand Owner UI
} else if (authVm.isBrandOwner && !authVm.isPremium) {
  // Non-Premium Brand Owner
  return const ChallengesScreen();  // Creator UI
} else {
  // Regular Collaborator/Creator
  return const ChallengesScreen();  // Creator UI
}
```

### Flow Chart

```
User Logs In
    ↓
Check isPremium && isBrandOwner
    ↓
    ├─ isPremium=true && isBrandOwner=true
    │  └─→ Show Brand Owner Dashboard
    │      (Create brands, launch challenges, manage submissions)
    │
    └─ isPremium=false OR isBrandOwner=false
       └─→ Show Collaborator/Creator UI
           (Discover challenges, submit videos, track submissions)
```

---

## 📱 **UI Comparison**

| Feature | Non-Premium | Premium Brand Owner |
|---------|------------|-------------------|
| Discover Challenges | ✅ | ❌ |
| Submit Videos | ✅ | ❌ |
| Track Submissions | ✅ | ❌ |
| Create Brands | ❌ | ✅ |
| Launch Challenges | ❌ | ✅ |
| Manage Submissions | ❌ | ✅ |
| Evaluate Creators | ❌ | ✅ |
| Declare Winners | ❌ | ✅ |
| View Dashboard | ❌ | ✅ |

---

## 🎯 **User Journey Examples**

### Example 1: Regular Creator
```
1. Sign up as regular user
2. isPremium = false, isBrandOwner = false
3. See Collaborator UI (challenges_screen.dart)
4. Browse challenges
5. Submit videos
6. Track submissions
```

### Example 2: Brand Owner (Non-Premium)
```
1. Sign up as brand owner
2. isPremium = false, isBrandOwner = true
3. See Collaborator UI (challenges_screen.dart)
4. Cannot create brands or launch challenges
5. Prompted to upgrade to premium
```

### Example 3: Premium Brand Owner
```
1. Sign up as brand owner
2. Purchase premium subscription
3. isPremium = true, isBrandOwner = true
4. See Brand Owner UI (brand_challenges_screen.dart)
5. Create brands
6. Launch challenges
7. Manage submissions
8. Declare winners
```

---

## 💳 **Premium Upgrade Flow**

### When User Upgrades to Premium

1. User clicks "Upgrade to Premium"
2. Stripe payment sheet opens
3. User completes payment
4. Backend verifies payment
5. Backend sets `isPremium = true`
6. App refreshes
7. User sees Brand Owner UI

### Code Location
- Payment: `lib/view_models/profile_view_model.dart`
- Confirmation: `lib/services/auth_service.dart` → `confirmSubscription()`

---

## 🔐 **Backend Validation**

### API Endpoints Protection

**Brand Owner Only Endpoints:**
```
POST   /challenges/create
GET    /challenges/brand/:brandId
PATCH  /challenges/:challengeId
DELETE /challenges/:challengeId
POST   /submissions/:submissionId/shortlist
POST   /submissions/:submissionId/request-revision
POST   /submissions/:submissionId/declare-winner
```

**Creator Only Endpoints:**
```
POST   /submissions/create
POST   /submissions/:submissionId/upload-revision
GET    /submissions/creator/:creatorId
```

**Public Endpoints:**
```
GET    /challenges/discover/all
GET    /challenges/:challengeId
```

---

## 📊 **Database Schema**

### User Model
```
User {
  id: string
  email: string
  displayName: string
  role: UserRole (brandOwner | collaborator)
  isPremium: boolean
  subscription: {
    status: string
    expiresAt: date
  }
}
```

### Relevant Getters (AuthViewModel)
```dart
bool get isBrandOwner => userRole == UserRole.brandOwner
bool get isPremium => currentUser?.isPremium ?? false
bool get isPremiumBrandOwner => isBrandOwner && isPremium
```

---

## 🎨 **UI Files**

### Collaborator/Creator UI
- **File:** `lib/views/collaboration/challenges_screen.dart`
- **Tabs:** DISCOVER, CHALLENGE, MY WORK
- **For:** Non-premium users, regular creators

### Brand Owner UI
- **File:** `lib/views/collaboration/brand_challenges_screen.dart`
- **Tabs:** MANAGE CHALLENGES, LAUNCH CHALLENGE
- **For:** Premium brand owners

### Routing
- **File:** `lib/views/home/home_screen.dart`
- **Logic:** Routes based on `isPremium` and `isBrandOwner`

---

## ✅ **Implementation Checklist**

- [x] Collaborator UI created (`challenges_screen.dart`)
- [x] Brand Owner UI created (`brand_challenges_screen.dart`)
- [x] Routing logic implemented (`home_screen.dart`)
- [x] Backend endpoints documented
- [x] User type flags in database
- [x] Premium upgrade flow
- [ ] Test with different user types
- [ ] Verify API protection
- [ ] Test payment flow

---

## 🧪 **Testing Different User Types**

### Test Case 1: Regular Creator
```
1. Create account with role=collaborator
2. Set isPremium=false
3. Verify sees Collaborator UI
4. Verify can discover challenges
5. Verify can submit videos
```

### Test Case 2: Non-Premium Brand Owner
```
1. Create account with role=brandOwner
2. Set isPremium=false
3. Verify sees Collaborator UI
4. Verify cannot create brands
5. Verify sees upgrade prompt
```

### Test Case 3: Premium Brand Owner
```
1. Create account with role=brandOwner
2. Set isPremium=true
3. Verify sees Brand Owner UI
4. Verify can create brands
5. Verify can launch challenges
```

---

## 📞 **Support**

For questions about user types:
1. Check this guide
2. Review `home_screen.dart` routing logic
3. Check `auth_view_model.dart` for user flags
4. Review backend API documentation

---

**Version:** 1.0.0  
**Last Updated:** March 2026  
**Status:** Complete
