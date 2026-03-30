import 'package:flutter/foundation.dart';
import '../core/navigation_service.dart';

/// Central voice navigation handler.
///
/// Maps every canonical backend destination name (from the server route registry)
/// to its corresponding GoRouter path.
///
/// Rules:
///  - This is the ONLY place that maps backend destinations to app routes.
///  - Never put destination→path logic in widgets, controllers, or other services.
///  - To add a new voice-navigable screen: add ONE entry to [_routeMap] below.
///  - Use [context.go] for main shell branches (bottom-nav screens).
///  - Use [context.push] for sub-screens that sit on top of the navigation stack.
class VoiceNavigationHandler {
  VoiceNavigationHandler._();

  /// Maps backend canonical destination names → GoRouter paths.
  /// Kept as a plain const map so it is easy to audit and extend.
  static const Map<String, _NavTarget> _routeMap = {
    // ── Auth & Onboarding ───────────────────────────────────────────────────
    'SPLASH': _NavTarget('/splash', replace: true),
    'ONBOARDING': _NavTarget('/onboarding', replace: true),
    'PERSONA': _NavTarget('/persona-onboarding', replace: false),
    'LOGIN': _NavTarget('/login', replace: true),
    'SIGNUP': _NavTarget('/signup', replace: true),
    'FORGOT_PASSWORD': _NavTarget('/forgot-password', replace: false),
    'VERIFY_EMAIL': _NavTarget('/verify-email', replace: false),

    // ── Main shell branches (bottom-nav / sidebar) ──────────────────────────
    'HOME': _NavTarget('/home', replace: true),
    'BRANDS': _NavTarget('/brands-list', replace: true),
    'CALENDAR': _NavTarget('/calendar', replace: true),
    'PROJECTS': _NavTarget('/projects', replace: true),
    'INSIGHTS': _NavTarget('/insights', replace: true),
    'FAVORITES': _NavTarget('/favorites', replace: true),
    'HISTORY': _NavTarget('/history', replace: true),
    'PROFILE': _NavTarget('/profile', replace: true),

    // ── Generator screens ────────────────────────────────────────────────────
    'GENERATOR': _NavTarget('/criteria', replace: false),
    'RESULTS': _NavTarget('/results', replace: false),
    'IDEA_DETAIL': _NavTarget('/idea/new', replace: false), // Fallback, normally needs :id argument
    'VIDEO_GENERATOR': _NavTarget('/video-ideas-form', replace: false),
    'VIDEO_IDEAS_RESULTS': _NavTarget('/video-ideas-results', replace: false),
    'BUSINESS_IDEAS_FORM': _NavTarget('/business-ideas-form', replace: false),
    'BUSINESS_IDEA_DETAIL': _NavTarget('/business-idea-detail', replace: false),
    'PRODUCT_IDEAS_FORM': _NavTarget('/product-ideas-form', replace: false),
    'PRODUCT_IDEA_RESULT': _NavTarget('/product-idea-result', replace: false),
    'SLOGAN_GENERATOR': _NavTarget('/slogans-form', replace: false),
    'SLOGANS_RESULTS': _NavTarget('/slogans-results', replace: false),

    // ── Strategic Content / Brands ──────────────────────────────────────────
    'BRAND_WORKSPACE': _NavTarget('/brand-workspace', replace: false),
    'BRAND_FORM': _NavTarget('/brand-form', replace: false),
    'PROJECT_BOARD': _NavTarget('/project-board', replace: false),
    'PLANS': _NavTarget('/projects-flow', replace: false),
    'AI_CAMPAIGN_ROADMAP': _NavTarget('/ai-campaign-roadmap', replace: false),
    'PLAN_DETAIL': _NavTarget('/plan-detail', replace: false),

    // ── Feature screens ──────────────────────────────────────────────────────
    'CONTENT_BLOCKS': _NavTarget('/saved-ideas', replace: false),
    'TRENDS': _NavTarget('/trends', replace: false),
    'CREDITS_SHOP': _NavTarget('/credits-shop', replace: false),
    'PAYMENT': _NavTarget('/payment', replace: false),
    'EDIT_PROFILE': _NavTarget('/edit-profile', replace: false),
    'SETTINGS': _NavTarget('/profile', replace: true), // settings live inside profile for now
  };

  /// Navigates to the screen that corresponds to [destination].
  ///
  /// [destination] must be a canonical name from the backend route registry
  /// (e.g. "PROFILE", "BRANDS"). Unknown names are logged and silently ignored.
  static void navigate(String destination) {
    final target = _routeMap[destination];

    if (target == null) {
      debugPrint('[VoiceNav] Unknown destination: "$destination" — ignored');
      return;
    }

    if (target.replace) {
      appRouter.go(target.path);
    } else {
      appRouter.push(target.path);
    }
  }

  /// Returns true when [destination] is a known, navigable route.
  static bool isKnown(String destination) => _routeMap.containsKey(destination);

  /// Exposes the global router so [CommandExecutor.noContext] can call pop()
  /// without a [BuildContext].
  static dynamic get routerForBack => appRouter;
}

/// Internal config for a single navigation target.
class _NavTarget {
  final String path;

  /// When true, uses [context.go] (replaces current location — main branches).
  /// When false, uses [context.push] (stacks on top — sub-screens).
  final bool replace;

  const _NavTarget(this.path, {required this.replace});
}
