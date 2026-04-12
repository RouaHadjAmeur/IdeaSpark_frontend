import 'package:flutter/foundation.dart';

/// Backend API base URL. Change for production or use env.
/// For iOS Simulator use http://localhost:3000
/// For Android Emulator use http://10.0.2.2:3000
/// For physical device use your machine's LAN IP, e.g. http://192.168.1.10:3000
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    // TEMPORARY: Using ngrok for testing
    // return 'https://YOUR_NGROK_URL.ngrok.io'; // ← Décommentez et mettez votre URL ngrok
    // Use your PC's local IP for physical device testing
    // Change this IP if your PC's IP changes
    return 'http://192.168.1.24:3000';
  }

  static String get authBase => '$baseUrl/auth';
  static String get usersBase => '$baseUrl/users';
  static String get trendsBase => '$baseUrl/trends';
  static String getTrendsUrl({String? geo}) =>
      geo != null ? '$trendsBase?geo=$geo' : trendsBase;


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

  // Voice Command Endpoints
  static String get voiceBase => '$baseUrl/api/voice';
  static String get voiceParseUrl => '$voiceBase/parse';
  static String get voiceConfirmUrl => '$voiceBase/confirm';

  // Collaboration Endpoints
  static String get collaborationBase => '$baseUrl/collaboration';
  static String get inviteUrl => '$collaborationBase/invite';
  static String acceptInviteUrl(String id) => '$collaborationBase/invitations/$id/accept';
  static String declineInviteUrl(String id) => '$collaborationBase/invitations/$id/decline';
  static String listCollaboratorsUrl(String planId) => '$collaborationBase/plans/$planId/collaborators';
  static String removeCollaboratorUrl(String planId, String userId) => '$collaborationBase/plans/$planId/collaborators/$userId';
  static String getActivityLogUrl(String planId) => '$collaborationBase/plans/$planId/activity';
  static String get notificationsUrl => '$collaborationBase/notifications';
  static String markNotificationReadUrl(String id) => '$collaborationBase/notifications/$id/read';
  static String sharedPlansUrl(String targetId) => '$collaborationBase/shared/$targetId';

  // Social & Community
  static String get socialBase => '$baseUrl/social';
  // These depend on runtime `baseUrl` (which itself depends on platform), so expose
  // them as getters rather than compile-time constants.
  static String get socialFeed => '$baseUrl/social/feed';
  static String get socialSuggestions => '$baseUrl/social/suggestions';
  static String get socialAccept => '$baseUrl/social/accept'; // /id at end
  static String get socialPendingRequests => '$baseUrl/social/pending-requests';
  static String get publicProfile => '$baseUrl/users/public-profile'; // /id at end
  static String get socialFollowingUrl => '$socialBase/following';
  static String get socialFollowersUrl => '$socialBase/followers';
  static String followUrl(String id) => '$socialBase/follow/$id';
  static String unfollowUrl(String id) => '$socialBase/unfollow/$id';
  static String get socialFriendsUrl => '$socialBase/friends';
  static String socialFriendsByIdUrl(String id) => '$socialBase/friends/$id';

  // User Search
  static String searchUsersUrl(String query) => '$usersBase/search?q=$query';

  // Google Sign-In Web Client ID (set via --dart-define=GOOGLE_WEB_CLIENT_ID=...)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Video Generation Mode
  static const bool useRemoteGenerationByDefault = bool.fromEnvironment(
    'USE_REMOTE_GENERATION',
    defaultValue: true,
  );

  static const bool fallbackToLocalOnError = bool.fromEnvironment(
    'FALLBACK_TO_LOCAL',
    defaultValue: true,
  );
}
