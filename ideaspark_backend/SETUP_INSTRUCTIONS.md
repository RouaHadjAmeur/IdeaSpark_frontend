# Backend Setup Instructions

Complete step-by-step guide to set up and run the IdeaSpark backend.

## Prerequisites

- Node.js 18+ ([Download](https://nodejs.org/))
- PostgreSQL 14+ ([Download](https://www.postgresql.org/download/))
- npm or yarn
- Git

## Installation Steps

### Step 1: Navigate to Backend Directory

```bash
cd ideaspark/ideaspark_backend
```

### Step 2: Install Dependencies

```bash
npm install
```

This will install all required packages listed in `package.json`.

### Step 3: Create PostgreSQL Database

Open a terminal and run:

```bash
# Create database
createdb ideaspark_db

# Verify it was created
psql -l | grep ideaspark_db
```

Or use pgAdmin GUI if you prefer.

### Step 4: Configure Environment Variables

```bash
# Copy example file
cp .env.example .env

# Edit .env with your database credentials
# Open .env in your editor and update:
DATABASE_URL="postgresql://user:password@localhost:5432/ideaspark_db"
JWT_SECRET="your-super-secret-key-change-this"
```

**Important:** Change `JWT_SECRET` to a strong random string for production.

### Step 5: Generate Prisma Client

```bash
npm run prisma:generate
```

This generates the Prisma client based on your schema.

### Step 6: Run Database Migrations

```bash
npm run prisma:migrate
```

When prompted, enter a migration name like `init_challenges`.

This creates all database tables.

### Step 7: Start Development Server

```bash
npm run start:dev
```

You should see:
```
🚀 Application is running on: http://localhost:3000
```

## Verification

### Test the API

Open a new terminal and run:

```bash
# Get public challenges (no auth needed)
curl http://localhost:3000/challenges/discover

# Should return an empty array: []
```

### View Database

In another terminal, run:

```bash
npm run prisma:studio
```

This opens a UI at `http://localhost:5555` where you can view and manage your database.

## Common Issues

### Issue: "connect ECONNREFUSED 127.0.0.1:5432"

**Solution:** PostgreSQL is not running
```bash
# macOS
brew services start postgresql

# Linux
sudo systemctl start postgresql

# Windows
# Start PostgreSQL from Services or pgAdmin
```

### Issue: "database does not exist"

**Solution:** Create the database
```bash
createdb ideaspark_db
```

### Issue: "Port 3000 already in use"

**Solution:** Change PORT in .env or kill the process
```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or change PORT in .env
PORT=3001
```

### Issue: "JWT_SECRET not set"

**Solution:** Add JWT_SECRET to .env
```
JWT_SECRET="your-secret-key-here"
```

## Development Commands

```bash
# Start development server (with auto-reload)
npm run start:dev

# Start production server
npm run start:prod

# Build for production
npm run build

# Format code
npm run format

# Lint code
npm run lint

# Run tests
npm run test

# Watch tests
npm run test:watch

# View database UI
npm run prisma:studio

# Run migrations
npm run prisma:migrate

# Generate Prisma client
npm run prisma:generate
```

## Environment Variables

Create a `.env` file with these variables:

```
# Database
DATABASE_URL="postgresql://user:password@localhost:5432/ideaspark_db"

# JWT
JWT_SECRET="your-super-secret-jwt-key-change-in-production"
JWT_EXPIRATION="24h"

# App
NODE_ENV="development"
PORT=3000
API_URL="http://localhost:3000"

# Frontend
FRONTEND_URL="http://localhost:3000"
```

## Testing Endpoints

### Get Public Challenges
```bash
curl http://localhost:3000/challenges/discover
```

### Create Challenge (requires auth token)
```bash
curl -X POST http://localhost:3000/challenges \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test Challenge",
    "description": "Test description",
    "brandId": "brand-123",
    "videoType": "UGC",
    "minDuration": 30,
    "maxDuration": 60,
    "language": "Tunisian Darija",
    "targetAudience": "Parents 25-45",
    "evaluationCriteria": ["Criteria 1"],
    "winnerReward": 500,
    "runnerUpReward": 150,
    "maxSubmissions": 30,
    "deadline": "2026-04-28T23:59:59Z"
  }'
```

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

## Database Schema

The backend uses 5 main tables:

1. **Challenge** - Challenge briefs
2. **Submission** - Video submissions
3. **ChallengeCriteria** - Evaluation criteria
4. **ShortlistedCreator** - Finalists
5. **ChallengeNotification** - Notifications

See `prisma/schema-additions.prisma` for full schema.

## API Endpoints

### Challenges (8 endpoints)
- POST /challenges
- GET /challenges
- GET /challenges/:id
- GET /challenges/discover
- GET /challenges/brand/:brandId
- GET /challenges/dashboard/stats
- PATCH /challenges/:id
- DELETE /challenges/:id

### Submissions (10 endpoints)
- POST /submissions
- GET /submissions/creator
- GET /submissions/challenge/:id
- GET /submissions/:id
- POST /submissions/:id/shortlist
- POST /submissions/:id/request-revision
- POST /submissions/:id/upload-revision
- POST /submissions/:id/declare-winner
- POST /submissions/:id/rate

See `CHALLENGES_BACKEND_DOC.md` for full API documentation.

## Next Steps

1. ✅ Backend is running
2. 🔗 Connect Flutter frontend to `http://localhost:3000`
3. 🧪 Test endpoints with Postman or curl
4. 📱 Implement API calls in Flutter
5. 🚀 Deploy to production

## Documentation

- `START_HERE.md` - Quick start guide
- `README.md` - Project overview
- `CHALLENGES_BACKEND_DOC.md` - Complete API reference
- `INTEGRATION_GUIDE.md` - Frontend integration
- `QUICK_REFERENCE.md` - API quick lookup

## Support

For issues:
1. Check error logs in terminal
2. Review `.env` configuration
3. Verify PostgreSQL is running
4. Check database exists: `psql -l`
5. Review documentation files

## Production Deployment

### Build
```bash
npm run build
```

### Environment Variables
Set these on your hosting platform:
```
DATABASE_URL=your_production_db_url
JWT_SECRET=your_production_secret
NODE_ENV=production
PORT=3000
FRONTEND_URL=your_frontend_url
```

### Start
```bash
npm run start:prod
```

---

**Ready to go!** Your backend is now running. Connect your Flutter app to start testing.
