# Quick Reference - API Endpoints

## Challenges

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/challenges` | ✅ | Create challenge |
| GET | `/challenges` | ❌ | List all challenges |
| GET | `/challenges/:id` | ❌ | Get challenge details |
| GET | `/challenges/discover` | ❌ | Get public challenges |
| GET | `/challenges/brand/:brandId` | ✅ | Get brand challenges |
| GET | `/challenges/dashboard/stats` | ✅ | Get dashboard stats |
| PATCH | `/challenges/:id` | ✅ | Update challenge |
| DELETE | `/challenges/:id` | ✅ | Delete challenge |

## Submissions

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/submissions` | ✅ | Submit video |
| GET | `/submissions/creator` | ✅ | Get my submissions |
| GET | `/submissions/challenge/:id` | ✅ | Get challenge submissions |
| GET | `/submissions/:id` | ❌ | Get submission details |
| POST | `/submissions/:id/shortlist` | ✅ | Shortlist submission |
| POST | `/submissions/:id/request-revision` | ✅ | Request revision |
| POST | `/submissions/:id/upload-revision` | ✅ | Upload revised video |
| POST | `/submissions/:id/declare-winner` | ✅ | Declare winner |
| POST | `/submissions/:id/rate` | ✅ | Rate submission |

## Common Request Headers

```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

## Common Response Codes

- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Server Error

## Example Requests

### Create Challenge
```bash
curl -X POST http://localhost:3000/challenges \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Challenge Title",
    "description": "Description",
    "brandId": "brand-id",
    "videoType": "UGC",
    "minDuration": 30,
    "maxDuration": 60,
    "language": "Tunisian Darija",
    "targetAudience": "Parents 25-45",
    "evaluationCriteria": ["Criteria 1", "Criteria 2"],
    "winnerReward": 500,
    "runnerUpReward": 150,
    "maxSubmissions": 30,
    "deadline": "2026-04-28T23:59:59Z"
  }'
```

### Get Discover Challenges
```bash
curl http://localhost:3000/challenges/discover
```

### Submit Video
```bash
curl -X POST http://localhost:3000/submissions \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "challengeId": "challenge-id",
    "videoUrl": "https://example.com/video.mp4",
    "notes": "My submission"
  }'
```

### Get My Submissions
```bash
curl http://localhost:3000/submissions/creator \
  -H "Authorization: Bearer TOKEN"
```

### Shortlist Submission
```bash
curl -X POST http://localhost:3000/submissions/submission-id/shortlist \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"challengeId": "challenge-id"}'
```

### Request Revision
```bash
curl -X POST http://localhost:3000/submissions/submission-id/request-revision \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "challengeId": "challenge-id",
    "feedback": "Please improve the hook"
  }'
```

### Declare Winner
```bash
curl -X POST http://localhost:3000/submissions/submission-id/declare-winner \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"challengeId": "challenge-id"}'
```

### Rate Submission
```bash
curl -X POST http://localhost:3000/submissions/submission-id/rate \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 4,
    "tags": ["high energy", "authentic"]
  }'
```

## Environment Variables

```
DATABASE_URL=postgresql://user:password@localhost:5432/ideaspark_db
JWT_SECRET=your-secret-key
JWT_EXPIRATION=24h
NODE_ENV=development
PORT=3000
FRONTEND_URL=http://localhost:3000
```

## Useful Commands

```bash
# Start dev server
npm run start:dev

# View database
npm run prisma:studio

# Run migrations
npm run prisma:migrate

# Format code
npm run format

# Lint code
npm run lint

# Run tests
npm run test

# Build
npm run build

# Start production
npm run start:prod
```

## Status Values

### Challenge Status
- `LIVE` - Active, accepting submissions
- `REVIEW` - Deadline passed, reviewing submissions
- `CLOSED` - Challenge completed

### Submission Status
- `SUBMITTED` - Initial submission
- `SHORTLISTED` - Added to finalists
- `REVISION_NEEDED` - Brand requested changes
- `WINNER` - Declared as winner

## Video Types
- UGC
- Testimonial
- Tutorial
- Review

## Languages
- Tunisian Darija
- French
- English
- Arabic

---

For full documentation, see `CHALLENGES_BACKEND_DOC.md`
