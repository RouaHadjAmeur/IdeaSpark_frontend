# IdeaSpark Backend - Challenges System

Production-ready NestJS backend for the IdeaSpark challenges platform. Handles challenge creation, submission management, and creator evaluation.

## Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL 14+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Setup environment
cp .env.example .env
# Edit .env with your database credentials

# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# Start development server
npm run start:dev
```

The API will be available at `http://localhost:3000`

## Project Structure

```
src/
├── main.ts                 # Application entry point
├── app.module.ts          # Root module
├── auth/                  # JWT authentication
│   ├── guards/
│   ├── strategies/
│   └── auth.module.ts
├── challenges/            # Challenge management
│   ├── dto/
│   ├── challenges.service.ts
│   ├── challenges.controller.ts
│   └── challenges.module.ts
├── submissions/           # Submission handling
│   ├── dto/
│   ├── submissions.service.ts
│   ├── submissions.controller.ts
│   └── submissions.module.ts
└── prisma/               # Database
    ├── prisma.service.ts
    └── prisma.module.ts
```

## API Endpoints

### Challenges

- `POST /challenges` - Create challenge (Brand Owner)
- `GET /challenges` - List all challenges
- `GET /challenges/:id` - Get challenge details
- `GET /challenges/discover` - Get public challenges for creators
- `GET /challenges/brand/:brandId` - Get brand's challenges
- `GET /challenges/dashboard/stats` - Get dashboard statistics
- `PATCH /challenges/:id` - Update challenge (Brand Owner)
- `DELETE /challenges/:id` - Delete challenge (Brand Owner)

### Submissions

- `POST /submissions` - Submit video (Creator)
- `GET /submissions/creator` - Get creator's submissions
- `GET /submissions/challenge/:challengeId` - Get challenge submissions (Brand Owner)
- `GET /submissions/:id` - Get submission details
- `POST /submissions/:id/shortlist` - Shortlist submission (Brand Owner)
- `POST /submissions/:id/request-revision` - Request revision (Brand Owner)
- `POST /submissions/:id/upload-revision` - Upload revised video (Creator)
- `POST /submissions/:id/declare-winner` - Declare winner (Brand Owner)
- `POST /submissions/:id/rate` - Rate submission (Brand Owner)

## Database Schema

### Challenge
- id, title, description, brandId, videoType, minDuration, maxDuration
- language, targetAudience, winnerReward, runnerUpReward, maxSubmissions
- deadline, status, createdBy, createdAt, updatedAt

### Submission
- id, challengeId, creatorId, videoUrl, notes, status
- rating, tags, feedback, winnerDeclaredAt, createdAt, updatedAt

### ChallengeCriteria
- id, challengeId, criterion, order, createdAt

### ShortlistedCreator
- id, submissionId, challengeId, creatorId, createdAt

### ChallengeNotification
- id, challengeId, userId, type, message, read, createdAt

## Authentication

All protected endpoints require JWT token in Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Environment Variables

```
DATABASE_URL=postgresql://user:password@localhost:5432/ideaspark_db
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRATION=24h
NODE_ENV=development
PORT=3000
FRONTEND_URL=http://localhost:3000
```

## Development

```bash
# Format code
npm run format

# Lint
npm run lint

# Run tests
npm run test

# Watch tests
npm run test:watch

# View database
npm run prisma:studio
```

## Deployment

```bash
# Build
npm run build

# Start production
npm run start:prod
```

## Key Features

✅ Challenge CRUD operations  
✅ Submission management  
✅ Creator shortlisting  
✅ Revision request workflow  
✅ Winner declaration  
✅ Rating and tagging system  
✅ Dashboard statistics  
✅ JWT authentication  
✅ Input validation with DTOs  
✅ Error handling  

## Support

For issues or questions, refer to the documentation files or contact the development team.
