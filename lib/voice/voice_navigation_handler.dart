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
    // ── Main shell branches (bottom-nav / sidebar) ──────────────────────────
    'HOME': _NavTarget('/home', replace: true),
    'BRANDS': _NavTarget('/brands-list', replace: true),
    'PLANS': _NavTarget('/projects-flow', replace: false),
    'FAVORITES': _NavTarget('/favorites', replace: true),
    'PROFILE': _NavTarget('/profile', replace: true),

    // ── Generator screens ────────────────────────────────────────────────────
    'GENERATOR': _NavTarget('/criteria', replace: false),
    'VIDEO_GENERATOR': _NavTarget('/video-ideas-form', replace: false),
    'SLOGAN_GENERATOR': _NavTarget('/slogans-form', replace: false),

    // ── Feature screens ──────────────────────────────────────────────────────
    'CONTENT_BLOCKS': _NavTarget('/saved-ideas', replace: false),
    'PERSONA': _NavTarget('/persona-onboarding', replace: false),
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
}

/// Internal config for a single navigation target.
class _NavTarget {
  final String path;

  /// When true, uses [context.go] (replaces current location — main branches).
  /// When false, uses [context.push] (stacks on top — sub-screens).
  final bool replace;

  const _NavTarget(this.path, {required this.replace});
}
