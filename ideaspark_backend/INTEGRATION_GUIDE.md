# Frontend Integration Guide

Complete guide to integrate the Flutter frontend with the NestJS backend.

## 1. Backend Setup

First, ensure backend is running:

```bash
cd ideaspark_backend
npm install
npm run prisma:generate
npm run prisma:migrate
npm run start:dev
```

Backend will be at: `http://localhost:3000`

## 2. Flutter Configuration

### Update API Base URL

In your Flutter app, update the API service:

```dart
// lib/services/api_service.dart
class ApiService {
  static const String baseUrl = 'http://localhost:3000'; // Development
  // static const String baseUrl = 'https://api.ideaspark.com'; // Production
  
  static Future<Response> get(String endpoint) async {
    final token = await _getAuthToken();
    return http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
```

## 3. API Integration Points

### Challenges Screen (Collaborator)

#### Discover Challenges
```dart
// GET /challenges/discover
Future<List<Challenge>> getDiscoverChallenges() async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/challenges/discover'),
  );
  // Parse and return challenges
}
```

#### Get Challenge Details
```dart
// GET /challenges/:id
Future<Challenge> getChallengeDetails(String challengeId) async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/challenges/$challengeId'),
  );
  // Parse and return challenge
}
```

#### Submit Video
```dart
// POST /submissions
Future<Submission> submitVideo(String challengeId, String videoUrl) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/submissions'),
    headers: {'Authorization': 'Bearer $token'},
    body: jsonEncode({
      'challengeId': challengeId,
      'videoUrl': videoUrl,
    }),
  );
  // Parse and return submission
}
```

#### Get Creator Submissions
```dart
// GET /submissions/creator
Future<List<Submission>> getMySubmissions() async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/submissions/creator'),
    headers: {'Authorization': 'Bearer $token'},
  );
  // Parse and return submissions
}
```

### Brand Owner Dashboard

#### Create Challenge
```dart
// POST /challenges
Future<Challenge> createChallenge(CreateChallengeDto dto) async {
  final response = await http.post(
    Uri.parse('http://localhost:3000/challenges'),
    headers: {'Authorization': 'Bearer $token'},
    body: jsonEncode(dto.toJson()),
  );
  // Parse and return challenge
}
```

#### Get Dashboard Stats
```dart
// GET /challenges/dashboard/stats
Future<DashboardStats> getDashboardStats() async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/challenges/dashboard/stats'),
    headers: {'Authorization': 'Bearer $token'},
  );
  // Parse and return stats
}
```

#### Get Challenge Submissions
```dart
// GET /submissions/challenge/:challengeId
Future<List<Submission>> getChallengeSubmissions(String challengeId) async {
  final response = await http.get(
    Uri.parse('http://localhost:3000/submissions/challenge/$challengeId'),
    headers: {'Authorization': 'Bearer $token'},
  );
  // Parse and return submissions
}
```

#### Shortlist Creator
```dart
// POST /submissions/:id/shortlist
Future<void> shortlistSubmission(String submissionId, String challengeId) async {
  await http.post(
    Uri.parse('http://localhost:3000/submissions/$submissionId/shortlist'),
    headers: {'Authorization': 'Bearer $token'},
    body: jsonEncode({'challengeId': challengeId}),
  );
}
```

#### Request Revision
```dart
// POST /submissions/:id/request-revision
Future<void> requestRevision(String submissionId, String challengeId, String feedback) async {
  await http.post(
    Uri.parse('http://localhost:3000/submissions/$submissionId/request-revision'),
    headers: {'Authorization': 'Bearer $token'},
    body: jsonEncode({
      'challengeId': challengeId,
      'feedback': feedback,
    }),
  );
}
```

#### Declare Winner
```dart
// POST /submissions/:id/declare-winner
Future<void> declareWinner(String submissionId, String challengeId) async {
  await http.post(
    Uri.parse('http://localhost:3000/submissions/$submissionId/declare-winner'),
    headers: {'Authorization': 'Bearer $token'},
    body: jsonEncode({'challengeId': challengeId}),
  );
}
```

## 4. Data Models

Create Dart models matching backend DTOs:

```dart
// lib/models/challenge.dart
class Challenge {
  final String id;
  final String title;
  final String description;
  final String brandId;
  final String videoType;
  final int minDuration;
  final int maxDuration;
  final String language;
  final String targetAudience;
  final int winnerReward;
  final int runnerUpReward;
  final int maxSubmissions;
  final DateTime deadline;
  final String status;
  final List<String> evaluationCriteria;
  final int submissionCount;

  Challenge({
    required this.id,
    required this.title,
    // ... other fields
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      // ... parse other fields
    );
  }
}
```

```dart
// lib/models/submission.dart
class Submission {
  final String id;
  final String challengeId;
  final String creatorId;
  final String videoUrl;
  final String status; // SUBMITTED, SHORTLISTED, REVISION_NEEDED, WINNER
  final int? rating;
  final List<String> tags;
  final String? feedback;
  final DateTime createdAt;

  Submission({
    required this.id,
    required this.challengeId,
    // ... other fields
  });

  factory Submission.fromJson(Map<String, dynamic> json) {
    return Submission(
      id: json['id'],
      challengeId: json['challengeId'],
      // ... parse other fields
    );
  }
}
```

## 5. Error Handling

```dart
Future<void> handleApiError(Response response) {
  if (response.statusCode == 401) {
    // Unauthorized - refresh token or redirect to login
  } else if (response.statusCode == 403) {
    // Forbidden - user doesn't have permission
  } else if (response.statusCode == 404) {
    // Not found
  } else if (response.statusCode == 400) {
    // Bad request - validation error
    final error = jsonDecode(response.body);
    throw Exception(error['message']);
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
}
```

## 6. Authentication Flow

1. User logs in → Get JWT token from auth system
2. Store token in secure storage
3. Include token in all API requests
4. If token expires → Refresh token or redirect to login

```dart
// lib/services/secure_storage.dart
class SecureStorage {
  static const _tokenKey = 'auth_token';
  
  static Future<void> saveToken(String token) async {
    await FlutterSecureStorage().write(key: _tokenKey, value: token);
  }
  
  static Future<String?> getToken() async {
    return await FlutterSecureStorage().read(key: _tokenKey);
  }
  
  static Future<void> deleteToken() async {
    await FlutterSecureStorage().delete(key: _tokenKey);
  }
}
```

## 7. Testing Endpoints

Use Postman or curl to test:

```bash
# Get all challenges
curl http://localhost:3000/challenges

# Get discover challenges
curl http://localhost:3000/challenges/discover

# Create challenge (requires auth)
curl -X POST http://localhost:3000/challenges \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","description":"Test",...}'
```

## 8. Deployment

### Backend Deployment (Heroku/Railway/Render)

```bash
# Build
npm run build

# Set environment variables on hosting platform
DATABASE_URL=your_production_db
JWT_SECRET=your_production_secret

# Deploy
git push heroku main
```

### Update Flutter API URL

```dart
// For production
static const String baseUrl = 'https://your-api-domain.com';
```

## 9. Common Issues

### CORS Errors
- Backend CORS is configured in `main.ts`
- Ensure FRONTEND_URL in .env matches your Flutter app URL

### 401 Unauthorized
- Check JWT token is valid
- Verify token is included in Authorization header
- Check JWT_SECRET matches

### 404 Not Found
- Verify endpoint path is correct
- Check resource ID exists in database

### 400 Bad Request
- Validate request body matches DTO
- Check all required fields are present
- Review error message in response

## 10. Next Steps

1. ✅ Backend running
2. ✅ Flutter models created
3. ✅ API service implemented
4. 🧪 Test endpoints with Postman
5. 🔗 Connect UI to API
6. 🚀 Deploy to production

---

For detailed API documentation, see `CHALLENGES_BACKEND_DOC.md`
