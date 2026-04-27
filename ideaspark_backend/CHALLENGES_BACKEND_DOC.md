# IdeaSpark Challenges Backend - Complete API Documentation

## Overview

The IdeaSpark Challenges Backend is a production-ready NestJS API that powers the challenge creation, submission, and evaluation system. It handles all business logic for brand owners to launch challenges and creators to submit content.

## Base URL

- Development: `http://localhost:3000`
- Production: `https://api.ideaspark.com` (example)

## Authentication

All protected endpoints require JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

Tokens are obtained from the authentication system and should be included in all requests to protected endpoints.

## Response Format

All responses follow this format:

```json
{
  "id": "string",
  "data": {},
  "message": "string",
  "timestamp": "2026-04-19T10:00:00Z"
}
```

Errors return:

```json
{
  "statusCode": 400,
  "message": "Error description",
  "error": "BadRequest"
}
```

---

## Challenges Endpoints

### 1. Create Challenge

**POST** `/challenges`

Create a new challenge (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "title": "Unboxing Challenge — Build Your Fort",
  "description": "Show real kids building their dream cardboard fort...",
  "brandId": "brand-123",
  "videoType": "UGC",
  "minDuration": 30,
  "maxDuration": 60,
  "language": "Tunisian Darija",
  "targetAudience": "Parents 25-45",
  "evaluationCriteria": [
    "Hook must grab attention within 3 seconds",
    "Kids' reactions must appear natural",
    "Product name mentioned at least once"
  ],
  "winnerReward": 500,
  "runnerUpReward": 150,
  "maxSubmissions": 30,
  "deadline": "2026-04-28T23:59:59Z"
}
```

**Response (201):**
```json
{
  "id": "challenge-123",
  "title": "Unboxing Challenge — Build Your Fort",
  "description": "Show real kids building...",
  "brandId": "brand-123",
  "videoType": "UGC",
  "minDuration": 30,
  "maxDuration": 60,
  "language": "Tunisian Darija",
  "targetAudience": "Parents 25-45",
  "winnerReward": 500,
  "runnerUpReward": 150,
  "maxSubmissions": 30,
  "deadline": "2026-04-28T23:59:59Z",
  "status": "LIVE",
  "criteria": [
    {
      "id": "criteria-1",
      "criterion": "Hook must grab attention within 3 seconds",
      "order": 0
    }
  ],
  "createdAt": "2026-04-19T10:00:00Z",
  "updatedAt": "2026-04-19T10:00:00Z"
}
```

**Errors:**
- `400` - Invalid input
- `401` - Unauthorized
- `403` - Brand not owned by user

---

### 2. Get All Challenges

**GET** `/challenges`

Get all challenges with optional filters

**Query Parameters:**
- `status` (optional): LIVE, REVIEW, CLOSED
- `brandId` (optional): Filter by brand

**Response (200):**
```json
[
  {
    "id": "challenge-123",
    "title": "Unboxing Challenge",
    "description": "...",
    "status": "LIVE",
    "deadline": "2026-04-28T23:59:59Z",
    "winnerReward": 500,
    "submissionCount": 22,
    "brand": {
      "id": "brand-123",
      "name": "Fortika"
    }
  }
]
```

---

### 3. Get Challenge Details

**GET** `/challenges/:id`

Get full details of a specific challenge

**Response (200):**
```json
{
  "id": "challenge-123",
  "title": "Unboxing Challenge",
  "description": "...",
  "brandId": "brand-123",
  "videoType": "UGC",
  "minDuration": 30,
  "maxDuration": 60,
  "language": "Tunisian Darija",
  "targetAudience": "Parents 25-45",
  "winnerReward": 500,
  "runnerUpReward": 150,
  "maxSubmissions": 30,
  "deadline": "2026-04-28T23:59:59Z",
  "status": "LIVE",
  "criteria": [
    {
      "id": "criteria-1",
      "criterion": "Hook must grab attention within 3 seconds",
      "order": 0
    }
  ],
  "submissions": [
    {
      "id": "submission-1",
      "creatorId": "creator-1",
      "videoUrl": "https://...",
      "status": "SUBMITTED",
      "rating": 4,
      "tags": ["high energy", "authentic"],
      "createdAt": "2026-04-19T10:00:00Z"
    }
  ],
  "brand": {
    "id": "brand-123",
    "name": "Fortika"
  }
}
```

**Errors:**
- `404` - Challenge not found

---

### 4. Get Discover Challenges

**GET** `/challenges/discover`

Get public challenges for creators to discover (no auth required)

**Query Parameters:**
- `videoType` (optional): UGC, Testimonial, Tutorial, Review
- `language` (optional): Filter by language
- `minReward` (optional): Minimum reward amount

**Response (200):**
```json
[
  {
    "id": "challenge-123",
    "title": "Unboxing Challenge",
    "description": "Show real kids building...",
    "videoType": "UGC",
    "minDuration": 30,
    "maxDuration": 60,
    "language": "Tunisian Darija",
    "targetAudience": "Parents 25-45",
    "winnerReward": 500,
    "runnerUpReward": 150,
    "deadline": "2026-04-28T23:59:59Z",
    "status": "LIVE",
    "submissionCount": 22,
    "brand": {
      "id": "brand-123",
      "name": "Fortika",
      "icon": "https://..."
    },
    "criteria": [
      {
        "criterion": "Hook must grab attention within 3 seconds",
        "order": 0
      }
    ]
  }
]
```

---

### 5. Get Brand Challenges

**GET** `/challenges/brand/:brandId`

Get all challenges for a specific brand

**Response (200):**
```json
[
  {
    "id": "challenge-123",
    "title": "Unboxing Challenge",
    "status": "LIVE",
    "submissionCount": 22,
    "deadline": "2026-04-28T23:59:59Z"
  }
]
```

---

### 6. Get Dashboard Stats

**GET** `/challenges/dashboard/stats`

Get brand owner dashboard statistics

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "activeChallenges": 3,
  "totalEntries": 47,
  "shortlistedCount": 9
}
```

---

### 7. Update Challenge

**PATCH** `/challenges/:id`

Update a challenge (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:** (all fields optional)
```json
{
  "title": "Updated Title",
  "description": "Updated description",
  "status": "REVIEW"
}
```

**Response (200):** Updated challenge object

**Errors:**
- `401` - Unauthorized
- `403` - Not challenge owner
- `404` - Challenge not found

---

### 8. Delete Challenge

**DELETE** `/challenges/:id`

Delete a challenge (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Challenge deleted successfully"
}
```

**Errors:**
- `401` - Unauthorized
- `403` - Not challenge owner
- `404` - Challenge not found

---

## Submissions Endpoints

### 1. Create Submission

**POST** `/submissions`

Submit a video to a challenge (Creator)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "challengeId": "challenge-123",
  "videoUrl": "https://example.com/video.mp4",
  "notes": "My submission notes"
}
```

**Response (201):**
```json
{
  "id": "submission-123",
  "challengeId": "challenge-123",
  "creatorId": "creator-123",
  "videoUrl": "https://example.com/video.mp4",
  "notes": "My submission notes",
  "status": "SUBMITTED",
  "rating": null,
  "tags": [],
  "feedback": null,
  "createdAt": "2026-04-19T10:00:00Z",
  "updatedAt": "2026-04-19T10:00:00Z",
  "creator": {
    "id": "creator-123",
    "displayName": "Salma Khelifi",
    "email": "salma@example.com"
  },
  "challenge": {
    "id": "challenge-123",
    "title": "Unboxing Challenge"
  }
}
```

**Errors:**
- `400` - Challenge deadline passed or max submissions reached
- `401` - Unauthorized
- `404` - Challenge not found

---

### 2. Get Creator Submissions

**GET** `/submissions/creator`

Get all submissions by the authenticated creator

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
[
  {
    "id": "submission-123",
    "challengeId": "challenge-123",
    "videoUrl": "https://...",
    "status": "SHORTLISTED",
    "rating": 4,
    "tags": ["high energy", "authentic"],
    "feedback": null,
    "createdAt": "2026-04-19T10:00:00Z",
    "challenge": {
      "id": "challenge-123",
      "title": "Unboxing Challenge",
      "brand": {
        "id": "brand-123",
        "name": "Fortika"
      }
    }
  }
]
```

---

### 3. Get Challenge Submissions

**GET** `/submissions/challenge/:challengeId`

Get all submissions for a challenge (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
[
  {
    "id": "submission-123",
    "creatorId": "creator-123",
    "videoUrl": "https://...",
    "status": "SUBMITTED",
    "rating": null,
    "tags": [],
    "feedback": null,
    "createdAt": "2026-04-19T10:00:00Z",
    "creator": {
      "id": "creator-123",
      "displayName": "Salma Khelifi",
      "email": "salma@example.com"
    }
  }
]
```

**Errors:**
- `401` - Unauthorized
- `403` - Not challenge owner
- `404` - Challenge not found

---

### 4. Get Submission Details

**GET** `/submissions/:id`

Get details of a specific submission

**Response (200):**
```json
{
  "id": "submission-123",
  "challengeId": "challenge-123",
  "creatorId": "creator-123",
  "videoUrl": "https://...",
  "status": "SUBMITTED",
  "rating": null,
  "tags": [],
  "feedback": null,
  "createdAt": "2026-04-19T10:00:00Z",
  "creator": {
    "id": "creator-123",
    "displayName": "Salma Khelifi"
  }
}
```

---

### 5. Shortlist Submission

**POST** `/submissions/:id/shortlist`

Add submission to shortlist (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "challengeId": "challenge-123"
}
```

**Response (201):**
```json
{
  "id": "shortlist-123",
  "submissionId": "submission-123",
  "challengeId": "challenge-123",
  "creatorId": "creator-123",
  "createdAt": "2026-04-19T10:00:00Z"
}
```

**Errors:**
- `401` - Unauthorized
- `403` - Not challenge owner
- `404` - Submission or challenge not found

---

### 6. Request Revision

**POST** `/submissions/:id/request-revision`

Request creator to revise their submission (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "challengeId": "challenge-123",
  "feedback": "Great energy but the hook is too slow. We need the kids' reaction in the first 2 seconds."
}
```

**Response (200):**
```json
{
  "id": "submission-123",
  "status": "REVISION_NEEDED",
  "feedback": "Great energy but the hook is too slow...",
  "updatedAt": "2026-04-19T10:00:00Z"
}
```

---

### 7. Upload Revision

**POST** `/submissions/:id/upload-revision`

Upload revised video (Creator only)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "videoUrl": "https://example.com/video-revised.mp4"
}
```

**Response (200):**
```json
{
  "id": "submission-123",
  "videoUrl": "https://example.com/video-revised.mp4",
  "status": "SUBMITTED",
  "updatedAt": "2026-04-19T10:00:00Z"
}
```

**Errors:**
- `401` - Unauthorized
- `403` - Not submission creator
- `404` - Submission not found

---

### 8. Declare Winner

**POST** `/submissions/:id/declare-winner`

Declare submission as winner (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "challengeId": "challenge-123"
}
```

**Response (200):**
```json
{
  "id": "submission-123",
  "status": "WINNER",
  "winnerDeclaredAt": "2026-04-19T10:00:00Z",
  "updatedAt": "2026-04-19T10:00:00Z"
}
```

**Errors:**
- `401` - Unauthorized
- `403` - Not challenge owner
- `404` - Submission or challenge not found

---

### 9. Rate Submission

**POST** `/submissions/:id/rate`

Rate and tag a submission (Brand Owner only)

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "rating": 4,
  "tags": ["high energy", "authentic", "hook <3s"]
}
```

**Response (200):**
```json
{
  "id": "submission-123",
  "rating": 4,
  "tags": ["high energy", "authentic", "hook <3s"],
  "updatedAt": "2026-04-19T10:00:00Z"
}
```

---

## Data Models

### Challenge
```typescript
{
  id: string;
  title: string;
  description: string;
  brandId: string;
  videoType: string;
  minDuration: number;
  maxDuration: number;
  language: string;
  targetAudience: string;
  winnerReward: number;
  runnerUpReward: number;
  maxSubmissions: number;
  deadline: Date;
  status: 'LIVE' | 'REVIEW' | 'CLOSED';
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}
```

### Submission
```typescript
{
  id: string;
  challengeId: string;
  creatorId: string;
  videoUrl: string;
  notes?: string;
  status: 'SUBMITTED' | 'SHORTLISTED' | 'REVISION_NEEDED' | 'WINNER';
  rating?: number;
  tags: string[];
  feedback?: string;
  winnerDeclaredAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

### ChallengeCriteria
```typescript
{
  id: string;
  challengeId: string;
  criterion: string;
  order: number;
  createdAt: Date;
}
```

### ShortlistedCreator
```typescript
{
  id: string;
  submissionId: string;
  challengeId: string;
  creatorId: string;
  createdAt: Date;
}
```

---

## Error Codes

| Code | Message | Description |
|------|---------|-------------|
| 400 | Bad Request | Invalid input or validation error |
| 401 | Unauthorized | Missing or invalid JWT token |
| 403 | Forbidden | User doesn't have permission |
| 404 | Not Found | Resource not found |
| 500 | Internal Server Error | Server error |

---

## Rate Limiting

Currently no rate limiting. Implement based on your needs.

---

## Pagination

Currently no pagination. Add `limit` and `offset` query parameters if needed.

---

## Webhooks

Currently no webhooks. Consider implementing for:
- Challenge created
- Submission received
- Winner declared
- Revision requested

---

## Version History

- **v1.0.0** (2026-04-19) - Initial release

---

## Support

For API issues or questions, contact the development team.
