/// Backend API base URL. Change for production or use env.
/// For iOS Simulator use http://localhost:3000
/// For Android Emulator use http://10.0.2.2:3000
/// For physical device use your machine's LAN IP, e.g. http://192.168.1.10:3000
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Pour Android Emulator, on utilise 10.0.2.2 au lieu de localhost
    defaultValue: 'http://localhost:3000',
  );

  static String get authBase => '$baseUrl/auth';
  static String get usersBase => '$baseUrl/users';

  // Video Generator Endpoints
  static String get videoGeneratorBase => '$baseUrl/video-generator';
  static String get generateVideoIdeasUrl => '$videoGeneratorBase/generate';
  static String get analyzeVideoImageUrl => '$videoGeneratorBase/analyze-image';
  static String get refineVideoIdeaUrl => '$videoGeneratorBase/refine';
  static String get approveVersionUrl => '$videoGeneratorBase/approve';
  static String get saveVideoIdeaUrl => '$videoGeneratorBase/save';
  static String get getHistoryUrl => '$videoGeneratorBase/history';
  static String get getFavoritesUrl => '$videoGeneratorBase/favorites';
  static String get toggleFavoriteUrl => '$videoGeneratorBase/toggle-favorite'; // Needs /id
  static String get deleteVideoIdeaUrl => '$videoGeneratorBase'; // Needs /id

  // Persona Endpoints
  static String get personaBase => '$baseUrl/persona';

  // Feature Flags for Video Generator
  static const bool useRemoteGenerationByDefault = true; // Enable OpenAI backend
  static const bool fallbackToLocalOnError = true; // Fallback to local if remote fails

  /// OAuth 2.0 Web application client ID (same value your backend uses to verify the id_token).
  /// Set via --dart-define=GOOGLE_WEB_CLIENT_ID=xxx or in code. Get it from Google Cloud Console →
  /// APIs & Services → Credentials → "Web application" client, or from your backend .env (e.g. GOOGLE_CLIENT_ID).
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '791353475220-dsu9gbd30rn14b0dmt6943j2kpaugct5.apps.googleusercontent.com',
  );
}
