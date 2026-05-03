/// Backend API base URL. Change for production or use env.
/// For Android Emulator use http://10.0.2.2:3000
/// For iOS Simulator / Web use http://localhost:3000
/// For physical device use your machine's LAN IP, e.g. http://192.168.1.10:3000
class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    // TEMPORARY: Using ngrok for testing
    // return 'https://YOUR_NGROK_URL.ngrok.io'; // ← Décommentez et mettez votre URL ngrok
    // Use the correct network IP where backend is accessible
    // Backend confirmed working on this IP with all modules loaded
    return 'http://10.0.2.2:3000';
  }

  static String get authBase => '$baseUrl/auth';
  static String get usersBase => '$baseUrl/users';
  static String get trendsBase => '$baseUrl/trends';
  static String getTrendsUrl({String? geo}) =>
      geo != null ? '$trendsBase?geo=$geo' : trendsBase;


  // Video Generator Endpoints
  static String get videoGeneratorBase => '$baseUrl/video-generator';
<<<<<<< HEAD
=======
  static String get searchVideoUrl => '$videoGeneratorBase/search';
>>>>>>> wassim
  static String get generateVideoIdeasUrl => '$videoGeneratorBase/generate';
  static String get analyzeVideoImageUrl => '$videoGeneratorBase/analyze-image';
  static String get refineVideoIdeaUrl => '$videoGeneratorBase/refine';
  static String get approveVersionUrl => '$videoGeneratorBase/approve';
  static String get saveVideoIdeaUrl => '$videoGeneratorBase/save';
  static String get getHistoryUrl => '$videoGeneratorBase/history';
  static String get getFavoritesUrl => '$videoGeneratorBase/favorites';
  static String get toggleFavoriteUrl => '$videoGeneratorBase/toggle-favorite'; // Needs /id
  static String get deleteVideoIdeaUrl => videoGeneratorBase; // Needs /id
  static String get searchVideoUrl => '$videoGeneratorBase/search';

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

  // Product Generator (IA Finetuning) Endpoints
  static String get iaFinetuningBase => '$baseUrl/ia-finetuning';
  static String get generateProductIdeaUrl => '$iaFinetuningBase/generate';
<<<<<<< HEAD
=======
  static String get decomposePromptUrl => '$iaFinetuningBase/decompose';
>>>>>>> wassim
  static String get saveProductIdeaUrl => '$iaFinetuningBase/product-ideas/save';
  static String get getProductIdeasHistoryUrl => '$iaFinetuningBase/product-ideas/history';
  static String get getProductIdeasFavoritesUrl => '$iaFinetuningBase/product-ideas/favorites';
  static String toggleProductIdeaFavoriteUrl(String id) => '$iaFinetuningBase/product-ideas/toggle-favorite/$id';
  static String deleteProductIdeaUrl(String id) => '$iaFinetuningBase/product-ideas/$id';

  // Prompt Refiner Endpoints
  static String get promptRefinerBase => '$baseUrl/prompt-refiner';
  static String get refinePromptUrl => '$promptRefinerBase/refine';

  // Traces Endpoints
  static String get productIdeaTraceUrl => '$iaFinetuningBase/traces/product-idea';
  static String get promptRefinerTraceUrl => '$iaFinetuningBase/traces/prompt-refiner';
  static String get tracesStatsUrl => '$iaFinetuningBase/traces/stats';

  // Brands Endpoints
  static String get brandsBase => '$baseUrl/brands';
  static String get createBrandUrl => brandsBase;
  static String get getBrandsUrl => brandsBase;
  static String brandByIdUrl(String id) => '$brandsBase/$id';

  // Brand Collaboration Endpoints
  static String inviteBrandCollaboratorUrl(String brandId) => '$brandsBase/$brandId/collaborators/invite';
  static String listBrandCollaboratorsUrl(String brandId) => '$brandsBase/$brandId/collaborators';
  static String removeBrandCollaboratorUrl(String brandId, String userId) => '$brandsBase/$brandId/collaborators/$userId';
  static String acceptBrandInviteUrl(String id) => '$brandsBase/invitations/$id/accept';
  static String declineBrandInviteUrl(String id) => '$brandsBase/invitations/$id/decline';
  static String get myBrandCollaborationsUrl => '$brandsBase/my/collaborations';
  static String get myPendingBrandInvitationsUrl => '$brandsBase/my/pending-invitations';

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
  static String planDNAUrl(String id) => '$plansBase/$id/dna';
  static String aiProjectInsightsUrl(String id) => '$plansBase/$id/ai-insights';
  static String generateHookUrl(String planId, String blockId) => '$plansBase/$planId/generate-hook/$blockId';
  static String generateCaptionUrl(String planId, String blockId) => '$plansBase/$planId/generate-caption/$blockId';

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
  static String updateChecklistUrl(String id)         => '$contentBlocksBase/$id/checklist';
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

  // Comments
  static String getCommentsUrl(String postId) => '$collaborationBase/posts/$postId/comments';
  static String get addCommentUrl => '$collaborationBase/comments';

  // Tasks & Deliverables
  static String listTasksUrl(String planId) => '$collaborationBase/plans/$planId/tasks';
  static String createTaskUrl(String planId) => '$collaborationBase/plans/$planId/tasks';
  static String updateTaskUrl(String taskId) => '$collaborationBase/tasks/$taskId';
  static String submitDeliverableUrl(String taskId) => '$collaborationBase/tasks/$taskId/deliverables';
  static String reviewDeliverableUrl(String id) => '$collaborationBase/deliverables/$id/review';

  // Social & Community
  static String get socialBase => '$baseUrl/social';
  static String get youtubeTrendsBase => '$baseUrl/youtube-trends';
  static String youtubeTrendsUrl({
    String? format,
    String? sort,
    String? search,
    int? limit,
  }) {
    final params = <String, String>{};
    if (format != null && format.isNotEmpty) params['format'] = format;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (limit != null && limit > 0) params['limit'] = '$limit';
    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return query.isEmpty ? youtubeTrendsBase : '$youtubeTrendsBase?$query';
  }
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

  // YouTube Auth & Publishing Endpoints
  static String get youtubeAuthBase => '$baseUrl/youtube-auth';
  static String get youtubeStartUrl => '$youtubeAuthBase/start';
  static String get youtubeMeUrl => '$youtubeAuthBase/me';
  static String get youtubeDisconnectUrl => '$youtubeAuthBase/disconnect';
  static String get youtubePublishUrl => '$youtubeAuthBase/publish';
  static String get youtubePublishUploadUrl => '$youtubeAuthBase/publish-upload';

  // Instagram Auth & Publishing Endpoints
  static String get instagramAuthBase => '$baseUrl/instagram-auth';
  static String get instagramStartUrl => '$instagramAuthBase/start';
  static String get instagramMeUrl => '$instagramAuthBase/me';
  static String get instagramDisconnectUrl => '$instagramAuthBase/disconnect';
  static String get instagramPublishUrl => '$instagramAuthBase/publish';
  static String get instagramPublishUploadUrl => '$instagramAuthBase/publish-upload';

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

  // YouTube Auth & Publishing Endpoints
  static String get youtubeAuthBase => '$baseUrl/youtube-auth';
  static String get youtubeStartUrl => '$youtubeAuthBase/start';
  static String get youtubeMeUrl => '$youtubeAuthBase/me';
  static String get youtubeDisconnectUrl => '$youtubeAuthBase/disconnect';
  static String get youtubePublishUrl => '$youtubeAuthBase/publish';
  static String get youtubePublishUploadUrl => '$youtubeAuthBase/publish-upload';

  // Instagram Auth & Publishing Endpoints
  static String get instagramAuthBase => '$baseUrl/instagram-auth';
  static String get instagramStartUrl => '$instagramAuthBase/start';
  static String get instagramMeUrl => '$instagramAuthBase/me';
  static String get instagramDisconnectUrl => '$instagramAuthBase/disconnect';
  static String get instagramPublishUrl => '$instagramAuthBase/publish';
  static String get instagramPublishUploadUrl => '$instagramAuthBase/publish-upload';
}
