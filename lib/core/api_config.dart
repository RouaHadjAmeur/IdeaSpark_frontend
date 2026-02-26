/// Backend API base URL. Change for production or use env.
/// For iOS Simulator use http://localhost:3000
/// For Android Emulator use http://10.0.2.2:3000
/// For physical device use your machine's LAN IP, e.g. http://192.168.1.10:3000
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Pour Android Emulator, on utilise 10.0.2.2 au lieu de localhost
    defaultValue: 'http://10.0.2.2:3000',
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
  static String get deleteVideoIdeaUrl => videoGeneratorBase; // Needs /id

  // Persona Endpoints
  static String get personaBase => '$baseUrl/persona';

  // Slogan Generator Endpoints
  static String get sloganGeneratorBase => '$baseUrl/SloganAi';
  static String get generateSlogansUrl => '$sloganGeneratorBase/slogans/generate';
  static String get saveSloganUrl => '$sloganGeneratorBase/slogans/save';
  static String get getSloganHistoryUrl => '$sloganGeneratorBase/slogans/history';
  static String get getSloganFavoritesUrl => '$sloganGeneratorBase/slogans/favorites';
  static String get toggleSloganFavoriteUrl => '$sloganGeneratorBase/slogans/toggle-favorite'; // Needs /id
  static String get deleteSloganUrl => '$sloganGeneratorBase/slogans'; // Needs /id

  // Product Generator (IA Scratch) Endpoints
  static String get iaScratchBase => '$baseUrl/ia-scratch';
  static String get generateProductIdeaUrl => '$iaScratchBase/generate';

  // Prompt Refiner Endpoints
  static String get promptRefinerBase => '$baseUrl/prompt-refiner';
  static String get refinePromptUrl => '$promptRefinerBase/refine';

  // Brands Endpoints
  static String get brandsBase => '$baseUrl/brands';
  static String get createBrandUrl => brandsBase;
  static String get getBrandsUrl => brandsBase;
  static String brandByIdUrl(String id) => '$brandsBase/$id';

  // Plans Endpoints
  static String get plansBase => '$baseUrl/plans';
  static String get createPlanUrl => plansBase;
  static String getPlansUrl({String? brandId}) =>
      brandId != null ? '$plansBase?brandId=$brandId' : plansBase;
  static String planByIdUrl(String id) => '$plansBase/$id';
  static String generatePlanUrl(String id) => '$plansBase/$id/generate';
  static String activatePlanUrl(String id) => '$plansBase/$id/activate';
  static String get dashboardAlertsUrl => '$plansBase/dashboard-alerts';
  static String addPlanToCalendarUrl(String id) => '$plansBase/$id/add-to-calendar';
  static String getPlanCalendarUrl(String id) => '$plansBase/$id/calendar';
  static String regeneratePlanUrl(String id) => '$plansBase/$id/regenerate';
  static String updateCampaignCopyUrl(String id) => '$plansBase/$id/campaign-copy';

  // Content Blocks Endpoints
  static String get contentBlocksBase => '$baseUrl/content-blocks';
  static String get createContentBlockUrl => contentBlocksBase;
  static String listContentBlocksUrl({String? brandId, String? planId, String? status}) {
    final params = <String, String>{};
    if (brandId != null) params['brandId'] = brandId;
    if (planId  != null) params['planId']  = planId;
    if (status  != null) params['status']  = status;
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return query.isEmpty ? contentBlocksBase : '$contentBlocksBase?$query';
  }
  static String contentBlockByIdUrl(String id)        => '$contentBlocksBase/$id';
  static String updateBlockStatusUrl(String id)       => '$contentBlocksBase/$id/status';
  static String attachBlockToPlanUrl(String id)       => '$contentBlocksBase/$id/attach-plan';
  static String scheduleBlockUrl(String id)           => '$contentBlocksBase/$id/schedule';
  static String replaceBlockUrl(String id)            => '$contentBlocksBase/$id/replace';

  // AI Video Ideas (ContentBlock-compatible output)
  static String get aiVideoIdeasBase    => '$baseUrl/ai/video-ideas';
  static String get generateAiVideoIdeaUrl => '$aiVideoIdeasBase/generate';

  // AI Slogan Campaign
  static String get generateCampaignSloganUrl => '$sloganGeneratorBase/campaign';

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
