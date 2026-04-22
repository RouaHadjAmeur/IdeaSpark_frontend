## Plan: Multi-Source Visual Trends UX

Keep your current `Current Trends` theme and news flow, while adding a 3-option Trends explorer and media-first cards for YouTube, TikTok, and Instagram.

### Checklist
- [ ] Preserve existing theme language (light background, teal accents, coral triggers, red/blue location selector, Syne typography, Rising tag style)
- [ ] Add "See all trends" selector with 3 options: `YouTube trends`, `TikTok + Instagram trends`, `News`
- [ ] Keep `News` linked to current `Current Trends` page behavior
- [ ] Add visual-first cards per platform with creator, metrics, and media
- [ ] Support real media playback for short-video platforms with safe fallbacks
- [ ] Keep backend/n8n payload backward-compatible and normalized

### 1) Architecture & Screen Flow
1. Keep `Current Trends` as the News-first screen and preserve existing selectors/chips.
2. Add a selector entry point from dashboard `See all trends` that opens a 3-option picker:
   - YouTube trends
   - TikTok + Instagram trends
   - News
3. Route options to one Trends screen with an internal `viewType` filter (`news`, `youtube`, `social`) or dedicated tabs.

### 2) UI Structure (Preserve + Adapt)
1. Keep top area from your current style:
   - `Current Trends` title with Syne blocky look
   - Match banner
   - Tunisia / Global selectors (red/blue identity)
   - Category chips
2. Add Source-1-inspired controls under header:
   - Search bar
   - Filter chips: `Trending`, `Recent`, `Popular`
3. Card sections:
   - YouTube Spotlight
   - TikTok + Instagram Momentum
   - News (existing list style)

### 3) Card Design Requirements by Platform

#### A) YouTube Cards (Thumbnail-Optimized)
- Large, prominent thumbnail (16:9)
- Creator row with avatar + channel name
- Metric badges on top/bottom overlay:
  - views
  - likes
  - comments
  - duration
- Keep `🔥 Rising` style as in current theme
- Optional CTA: open YouTube URL or in-app player sheet

#### B) TikTok & Instagram Cards (Video-Dominant)
- Taller dominant cards (short-video visual priority)
- Prefer **actual video playback** when media URL is valid
- Fallback to thumbnail/poster + centered play icon if playback unavailable
- Clear creator profile row (username + avatar)
- Metric badges:
  - views
  - likes
  - optional comments
- Platform identity badge (`TikTok` / `Instagram`) in corner

### 4) Unified Data Model (Frontend)
Extend trend model with normalized media fields:
- `platform`: `youtube | tiktok | instagram | news`
- `creatorName`, `creatorAvatar`
- `thumbnailUrl`
- `videoUrl` (nullable)
- `duration` (YouTube)
- `views`, `likes`, `comments`
- `publishedAt`
- `niche`, `geo`, `viralityScore` (if available)

### 5) Backend + n8n Contract Additions
1. Keep existing news payload unchanged.
2. Add optional media fields in n8n output for social sources:
   - `platform`
   - `creatorName`, `creatorAvatar`
   - `thumbnailUrl`
   - `videoUrl`
   - `duration` (if provided)
   - `views`, `likes`, `comments`
3. Backend stores both old and new payload shapes (backward compatibility).
4. Trends API supports filtering by `viewType`/`platform` without breaking current News usage.

### 6) Media Rendering Rules (Important)
1. If `videoUrl` exists and is playable:
   - render inline video preview (muted, tap-to-play)
2. If not playable or empty:
   - render thumbnail with play icon overlay
3. If `thumbnailUrl` missing:
   - show gradient fallback card with platform icon

### 7) Performance & Reliability
- Use cached image widget for thumbnails/avatars
- Lazy-load video controllers only for visible cards
- Dispose video controllers on scroll off-screen
- Use tap-to-play default (no global autoplay) to reduce jank and data usage
- Add skeleton placeholders while loading cards

### 8) Phased Rollout

#### Phase 1
- Add `See all trends` picker + routing
- Keep News page as-is

#### Phase 2
- Implement YouTube visual cards (thumbnail-first + metrics)

#### Phase 3
- Implement TikTok/Instagram dominant cards with video fallback logic

#### Phase 4
- Enable real video playback where allowed by source URLs
- Tune filters/sorting (`Trending`, `Recent`, `Popular`)

### 9) Acceptance Criteria
- User can open picker and select one of 3 trend views
- News view remains unchanged and stable
- YouTube view shows thumbnail-heavy cards with creator + metrics + duration
- TikTok/Instagram view shows dominant visual cards with playable video when available, otherwise thumbnail fallback
- Existing theme language remains consistent across all views
- No regression in location/category selectors

