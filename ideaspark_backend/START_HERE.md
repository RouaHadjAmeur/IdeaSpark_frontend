# 🚀 Backend Setup - Start Here

## Step 1: Install Dependencies

```bash
cd ideaspark_backend
npm install
```

## Step 2: Configure Database

1. Create a PostgreSQL database:
```bash
createdb ideaspark_db
```

2. Copy and configure `.env`:
```bash
cp .env.example .env
```

3. Edit `.env` with your database URL:
```
DATABASE_URL="postgresql://user:password@localhost:5432/ideaspark_db"
JWT_SECRET="your-super-secret-key-change-this"
```

## Step 3: Setup Prisma

```bash
# Generate Prisma client
npm run prisma:generate

# Run migrations (creates tables)
npm run prisma:migrate
```

When prompted, name your migration something like `init_challenges`

## Step 4: Start Development Server

```bash
npm run start:dev
```

You should see:
```
🚀 Application is running on: http://localhost:3000
```

## Step 5: Test the API

### Create a Challenge (Brand Owner)

```bash
curl -X POST http://localhost:3000/challenges \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Unboxing Challenge",
    "description": "Show kids unboxing Fortika",
    "brandId": "brand-123",
    "videoType": "UGC",
    "minDuration": 30,
    "maxDuration": 60,
    "language": "Tunisian Darija",
    "targetAudience": "Parents 25-45",
    "evaluationCriteria": ["Hook in 3 seconds", "Natural reactions"],
    "winnerReward": 500,
    "runnerUpReward": 150,
    "maxSubmissions": 30,
    "deadline": "2026-04-28T23:59:59Z"
  }'
```

### Get Discover Challenges (Public)

```bash
curl http://localhost:3000/challenges/discover
```

### Submit Video (Creator)

```bash
curl -X POST http://localhost:3000/submissions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "challengeId": "challenge-123",
    "videoUrl": "https://example.com/video.mp4",
    "notes": "My submission"
  }'
```

## Database Schema

The backend uses these main tables:

- **Challenge** - Challenge briefs created by brand owners
- **Submission** - Videos submitted by creators
- **ChallengeCriteria** - Evaluation criteria for each challenge
- **ShortlistedCreator** - Finalists for each challenge
- **ChallengeNotification** - Notifications for users

See `prisma/schema-additions.prisma` for full schema.

## Common Commands

```bash
# View database in UI
npm run prisma:studio

# Format code
npm run format

# Lint code
npm run lint

# Run tests
npm run test

# Build for production
npm run build

# Start production server
npm run start:prod
```

## Troubleshooting

### Database Connection Error
- Check DATABASE_URL in .env
- Ensure PostgreSQL is running
- Verify database exists: `psql -l`

### JWT Token Issues
- Generate a valid JWT token from your auth system
- Include it in Authorization header: `Bearer <token>`
- Check JWT_SECRET matches your auth system

### Port Already in Use
- Change PORT in .env
- Or kill process: `lsof -ti:3000 | xargs kill -9`

## Next Steps

1. ✅ Backend running locally
2. 📱 Connect Flutter frontend to `http://localhost:3000`
3. 🔐 Implement JWT token generation in auth system
4. 📧 Setup email notifications (optional)
5. 🚀 Deploy to production

## Documentation

- `README.md` - Full API documentation
- `INTEGRATION_GUIDE.md` - Frontend integration steps
- `CHALLENGES_BACKEND_DOC.md` - Detailed API reference

## Support

For issues:
1. Check error logs in terminal
2. Review Prisma schema: `npm run prisma:studio`
3. Check database: `psql ideaspark_db`
4. Review API documentation

---

**Ready to go!** Your backend is now running. Connect your Flutter app to start testing.
