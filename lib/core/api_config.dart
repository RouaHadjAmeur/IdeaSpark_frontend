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
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://Macs-AIr-Roua.local:3000';
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

  // Product Generator (IA Finetuning) Endpoints
  static String get iaFinetuningBase => '$baseUrl/ia-finetuning';
  static String get generateProductIdeaUrl => '$iaFinetuningBase/generate';
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

  // Challenges Endpoints
  static String get challengesBase => '$baseUrl/challenges';
  static String get discoverChallengesUrl => '$challengesBase/discover/all';
  static String brandChallengesUrl(String brandId) => '$challengesBase/brand/$brandId';
  static String publishChallengeUrl(String id) => '$challengesBase/$id/publish';
  static String getBrandChallengeStatsUrl(String brandId) => '$challengesBase/brand/$brandId/stats';

  // Submissions Endpoints
  static String get submissionsBase => '$baseUrl/submissions';
  static String submitVideoUrl(String challengeId) => '$submissionsBase/challenge/$challengeId/submit';
  static String getChallengeSubmissionsUrl(String challengeId) => '$submissionsBase/challenge/$challengeId';
  static String shortlistSubmissionUrl(String id) => '$submissionsBase/$id/shortlist';
  static String declareWinnerUrl(String id) => '$submissionsBase/$id/declare-winner';
  static String submissionRevisionUrl(String id) => '$submissionsBase/$id/request-revision';
  static String get getMySubmissionsUrl => '$submissionsBase/my';
  static String rateSubmissionUrl(String id) => '$submissionsBase/$id/rate';

  // Stripe Endpoints
  static String get stripeBase => '$baseUrl/stripe';
  static String get stripeCreateSubscriptionUrl => '$stripeBase/create-subscription';
  static String get usersConfirmSubscriptionUrl => '$usersBase/confirm-subscription';

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
