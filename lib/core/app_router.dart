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
import 'package:ideaspark/views/auth/verify_email_screen.dart';
import 'package:ideaspark/views/auth/forgot_password_screen.dart';
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
import 'package:ideaspark/views/profile/edit_profile_screen.dart';
import 'package:ideaspark/views/onboarding/persona_onboarding_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/dashboard_v2_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/brands_list_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/brand_workspace_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/calendar_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/plan_project_flow.dart';
import 'package:ideaspark/views/strategic_content_manager/ai_campaign_roadmap_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/insights_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/create_edit_brand_screen.dart';
import 'package:ideaspark/views/execution_hub/execution_hub_screen.dart';
import 'package:ideaspark/views/execution_hub/project_board_screen.dart';
import 'package:ideaspark/views/strategic_content_manager/plan_detail_screen.dart';
import 'package:ideaspark/widgets/bottom_nav_v2.dart';
import 'package:ideaspark/widgets/sidebar_navigation.dart';
import 'package:ideaspark/widgets/page_shell.dart';

import '../models/video_generator_models.dart';
import '../models/brand.dart';
import '../models/plan.dart';
import '../view_models/profile_view_model.dart';
import '../services/auth_service.dart';

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
        path: '/forgot-password',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LocaleRebuilder(builder: (_) => const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/verify-email',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          String email = '';
          bool isGoogleVerification = false;
          bool isFacebookVerification = false;
          if (extra is Map) {
            final emailValue = extra['email'];
            email = emailValue is String ? emailValue : (emailValue?.toString() ?? '');
            isGoogleVerification = extra['source'] == 'google';
            isFacebookVerification = extra['source'] == 'facebook';
          } else if (extra is String) {
            email = extra;
          }
          return LocaleRebuilder(
            builder: (_) => VerifyEmailScreen(
              email: email,
              isGoogleVerification: isGoogleVerification,
              isFacebookVerification: isFacebookVerification,
            ),
          );
        },
      ),
      GoRoute(
        path: '/persona-onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) async {
          final authService = AuthService();
          final isLoggedIn = await authService.isLoggedIn();
          if (!isLoggedIn) {
            // Redirect to login, with return path to persona onboarding
            return '/login?returnTo=/persona-onboarding';
          }
          return null; // Allow access
        },
        builder: (context, state) {
          final userId = state.extra is String ? state.extra as String : '';
          return LocaleRebuilder(
            builder: (_) => PersonaOnboardingScreen(userId: userId),
          );
        },
      ),
      GoRoute(
        path: '/loading',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          String? redirectTo;
          Object? forwardData;
          if (extra is String) {
            redirectTo = extra;
          } else if (extra is Map<String, dynamic>) {
            redirectTo = extra['redirectTo'];
            // Pass both the request and useRemoteGeneration flag
            forwardData = {
              'request': extra['data'],
              'useRemoteGeneration': extra['useRemoteGeneration'] ?? true,
            };
          }
          return LocaleRebuilder(builder: (_) => LoadingScreen(redirectTo: redirectTo, forwardData: forwardData));
        },
      ),
      GoRoute(
        path: '/video-ideas-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const VideoIdeasFormScreen()),
        ),
      ),
      GoRoute(
        path: '/video-ideas-results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          VideoRequest? request;
          bool useRemoteGeneration = true;

          if (state.extra is VideoRequest) {
            request = state.extra as VideoRequest;
          } else if (state.extra is Map) {
            final extra = state.extra as Map;
            request = extra['request'] as VideoRequest?;
            useRemoteGeneration = extra['useRemoteGeneration'] as bool? ?? true;
          }

          return PageShell(
            child: LocaleRebuilder(
              builder: (_) => VideoIdeasResultsScreen(
                request: request,
                useRemoteGeneration: useRemoteGeneration,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/business-ideas-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const BusinessIdeasFormScreen()),
        ),
      ),
      GoRoute(
        path: '/business-idea-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const BusinessIdeaDetailScreen()),
        ),
      ),
      GoRoute(
        path: '/product-ideas-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const ProductIdeasFormScreen()),
        ),
      ),
      GoRoute(
        path: '/product-idea-result',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const ProductIdeaResultScreen()),
        ),
      ),
      GoRoute(
        path: '/slogans-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const SlogansFormScreen()),
        ),
      ),
      GoRoute(
        path: '/slogans-results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const SlogansResultsScreen()),
        ),
      ),
      GoRoute(
        path: '/saved-ideas',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const SavedIdeasLibraryScreen()),
        ),
      ),
      GoRoute(
        path: '/trends',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const TrendsAnalysisScreen()),
        ),
      ),
      GoRoute(
        path: '/criteria',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final String? type = state.extra is String ? state.extra as String : null;
          return PageShell(
            child: LocaleRebuilder(builder: (_) => CriteriaScreen(type: type)),
          );
        },
      ),
      GoRoute(
        path: '/results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const ResultsScreen()),
        ),
      ),
      GoRoute(
        path: '/idea/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PageShell(
            child: LocaleRebuilder(builder: (_) => IdeaDetailScreen(id: id)),
          );
        },
      ),
      GoRoute(
        path: '/credits-shop',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(builder: (_) => const CreditsShopScreen()),
        ),
      ),
      GoRoute(
        path: '/payment',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final raw = state.extra;
          final extra = raw is Map ? raw : null;
          String? getStr(dynamic m, String k) {
            if (m == null) return null;
            final v = m[k];
            return v is String ? v : v?.toString();
          }
          return PageShell(
            child: LocaleRebuilder(
              builder: (_) => PaymentScreen(
                packName: getStr(extra, 'name'),
                credits: getStr(extra, 'credits'),
                price: getStr(extra, 'price'),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: '/project-board',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final plan = state.extra as Plan;
          return ProjectBoardScreen(plan: plan);
        },
      ),
      GoRoute(
        path: '/brand-workspace',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final brand = state.extra as Brand?;
          if (brand == null) return const SizedBox.shrink();
          return BrandWorkspaceScreen(brand: brand);
        },
      ),
      GoRoute(
        path: '/brand-form',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final brand = state.extra is Brand ? state.extra as Brand : null;
          return CreateEditBrandScreen(brand: brand);
        },
      ),
      GoRoute(
        path: '/plan-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final plan = state.extra as Plan;
          return PlanDetailScreen(plan: plan);
        },
      ),
      GoRoute(
        path: '/edit-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => PageShell(
          child: LocaleRebuilder(
            builder: (_) => ChangeNotifierProvider(
              create: (_) => ProfileViewModel(),
              child: const EditProfileScreen(),
            ),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/brands-list',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const BrandsListScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const CalendarScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ExecutionHubScreen(),
                ),
              ),
              GoRoute(
                path: '/projects-flow',
                builder: (context, state) => const PlanProjectFlow(),
              ),
              GoRoute(
                path: '/ai-campaign-roadmap',
                builder: (context, state) => const AICampaignRoadmapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const InsightsScreen(),
                ),
              ),
            ],
          ),
          // Additional branches for legacy screens that should have the shell
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

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleViewModel>();
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      return Scaffold(
        drawer: const SidebarNavigation(),
        body: navigationShell,
        bottomNavigationBar: BottomNavV2(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const SidebarNavigation(),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

