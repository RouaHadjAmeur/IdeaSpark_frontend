import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/locale_view_model.dart';
import 'package:ideaspark/widgets/locale_rebuilder.dart';
import 'package:ideaspark/views/splash/splash_screen.dart';
import 'package:ideaspark/views/onboarding/onboarding_screen.dart';
import 'package:ideaspark/views/auth/login_screen.dart';
import 'package:ideaspark/views/auth/signup_screen.dart';
import 'package:ideaspark/views/home/home_screen.dart';
import 'package:ideaspark/views/criteria/criteria_screen.dart';
import 'package:ideaspark/views/loading/loading_screen.dart';
import 'package:ideaspark/views/results/results_screen.dart';
import 'package:ideaspark/views/results/idea_detail_screen.dart';
import 'package:ideaspark/views/library/favorites_screen.dart';
import 'package:ideaspark/views/library/history_screen.dart';
import 'package:ideaspark/views/profile/profile_screen.dart';
import 'package:ideaspark/views/credits/credits_shop_screen.dart';
import 'package:ideaspark/views/credits/payment_screen.dart';
import 'package:ideaspark/views/generators/video_ideas_form_screen.dart';
import 'package:ideaspark/views/generators/video_ideas_results_screen.dart';
import 'package:ideaspark/views/generators/business_ideas_form_screen.dart';
import 'package:ideaspark/views/generators/business_idea_detail_screen.dart';
import 'package:ideaspark/views/generators/product_ideas_form_screen.dart';
import 'package:ideaspark/views/generators/product_idea_result_screen.dart';
import 'package:ideaspark/views/generators/slogans_form_screen.dart';
import 'package:ideaspark/views/generators/slogans_results_screen.dart';
import 'package:ideaspark/views/library/saved_ideas_library_screen.dart';
import 'package:ideaspark/views/trends/trends_analysis_screen.dart';
final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const SignUpScreen()),
      ),
      GoRoute(
        path: '/loading',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final redirectTo = state.extra as String?;
          return LocaleRebuilder(builder: (_) => LoadingScreen(redirectTo: redirectTo));
        },
      ),
      GoRoute(
        path: '/video-ideas-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const VideoIdeasFormScreen()),
      ),
      GoRoute(
        path: '/video-ideas-results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const VideoIdeasResultsScreen()),
      ),
      GoRoute(
        path: '/business-ideas-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const BusinessIdeasFormScreen()),
      ),
      GoRoute(
        path: '/business-idea-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const BusinessIdeaDetailScreen()),
      ),
      GoRoute(
        path: '/product-ideas-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const ProductIdeasFormScreen()),
      ),
      GoRoute(
        path: '/product-idea-result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const ProductIdeaResultScreen()),
      ),
      GoRoute(
        path: '/slogans-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const SlogansFormScreen()),
      ),
      GoRoute(
        path: '/slogans-results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const SlogansResultsScreen()),
      ),
      GoRoute(
        path: '/saved-ideas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const SavedIdeasLibraryScreen()),
      ),
      GoRoute(
        path: '/trends',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const TrendsAnalysisScreen()),
      ),
      GoRoute(
        path: '/criteria',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final type = state.extra as String?;
          return LocaleRebuilder(builder: (_) => CriteriaScreen(type: type));
        },
      ),
      GoRoute(
        path: '/results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const ResultsScreen()),
      ),
      GoRoute(
        path: '/idea/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return LocaleRebuilder(builder: (_) => IdeaDetailScreen(id: id));
        },
      ),
      GoRoute(
        path: '/credits-shop',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const CreditsShopScreen()),
      ),
      GoRoute(
        path: '/payment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return LocaleRebuilder(
            builder: (_) => PaymentScreen(
              packName: extra?['name'],
              credits: extra?['credits'],
              price: extra?['price'],
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: LocaleRebuilder(builder: (_) => const HomeScreen()),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: LocaleRebuilder(builder: (_) => const FavoritesScreen()),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: LocaleRebuilder(builder: (_) => const HistoryScreen()),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: LocaleRebuilder(builder: (_) => const ProfileScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: context.tr('nav_home'),
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => navigationShell.goBranch(0),
                  colorScheme: colorScheme,
                ),
                _NavItem(
                  icon: Icons.favorite_rounded,
                  label: context.tr('nav_favorites'),
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => navigationShell.goBranch(1),
                  colorScheme: colorScheme,
                ),
                _NavItem(
                  icon: Icons.history_rounded,
                  label: context.tr('nav_history'),
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => navigationShell.goBranch(2),
                  colorScheme: colorScheme,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: context.tr('nav_profile'),
                  isSelected: navigationShell.currentIndex == 3,
                  onTap: () => navigationShell.goBranch(3),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
