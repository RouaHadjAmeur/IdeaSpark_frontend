import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/settings_view_model.dart';
import 'view_models/social_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'voice/global_voice_controller.dart';
import 'voice/hands_free_mode_controller.dart';
import 'ui/widgets/global_voice_overlay.dart';
import 'services/deep_link_service.dart';
//import 'services/notification_service.dart';

import 'view_models/theme_view_model.dart';
import 'view_models/locale_view_model.dart';
import 'view_models/plan_view_model.dart';
import 'view_models/brand_view_model.dart';
import 'view_models/collaboration_view_model.dart';
import 'view_models/slogan_view_model.dart';
import 'view_models/product_idea_view_model.dart';
import 'view_models/video_idea_generator_view_model.dart';
import 'services/video_generator_service.dart';
import 'view_models/challenge_view_model.dart';
import 'voice/global_voice_controller.dart';
import 'ui/widgets/global_voice_overlay.dart';
import 'services/call_service.dart';
import 'modules/chat/call_screen.dart';
import 'core/app_router.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on mobile (not web)
  /*if (!kIsWeb) {
    try {
     // await Firebase.initializeApp();
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Firebase initialization skipped: $e');
    }
  }
  */
  await Supabase.initialize(
    url: 'https://ddqinbuujcpfgkoezrzg.supabase.co',
    anonKey: 'sb_publishable_Cz8zt7Bt75h6vG3_9NylEQ_81xW5gZ2',
  );

  // Stripe — replace with your pk_test_... key or set via --dart-define=STRIPE_PK=...
  Stripe.publishableKey = const String.fromEnvironment(
    'STRIPE_PK',
    defaultValue: 'pk_test_51TKlzw5Egul17oc8KCy66arOwtslJqYI0NRFlVWUcQPtIHrgmAZxztZ6rwF20SVHYgm5Yv4vQdZSct0zEOsd1xvx00x0gVs9Ha',
  );
  await Stripe.instance.applySettings();
  // Initialize deep link service for OAuth callbacks
  await DeepLinkService().init();
  runApp(const IdeaSparkApp());
}

/// Router créé une seule fois pour éviter un redémarrage de l'app au changement de thème.
class IdeaSparkApp extends StatefulWidget {
  const IdeaSparkApp({super.key});

  @override
  State<IdeaSparkApp> createState() => _IdeaSparkAppState();
}

class _IdeaSparkAppState extends State<IdeaSparkApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void initState() {
    super.initState();
    _initCallListener();
  }

  void _initCallListener() {
    final callService = CallService();
    // Start listening globally for incoming calls
    callService.onIncomingCall.listen((data) {
      print('📱 Global Call Listener: Received call request for ${data['callerName']}');
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CallScreen(
              remoteUserId: data['callerId']!,
              remoteUserName: data['callerName']!,
              isIncoming: true,
              isVideoButton: data['type'] == 'video',
            ),
          ),
        );
      } else {
        print('❌ Global Call Listener: Navigator context is null, cannot show call screen');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => SloganViewModel()),
        ChangeNotifierProvider(create: (_) => BrandViewModel()),
        ChangeNotifierProvider(create: (_) => PlanViewModel()),
        ChangeNotifierProvider(create: (_) => ProductIdeaViewModel()),
        ChangeNotifierProvider(create: (_) => CollaborationViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => SocialViewModel()),
        Provider(create: (_) => VideoIdeaGeneratorService()),
        ChangeNotifierProxyProvider<VideoIdeaGeneratorService, VideoIdeaGeneratorViewModel>(
          create: (context) => VideoIdeaGeneratorViewModel(
            service: Provider.of<VideoIdeaGeneratorService>(context, listen: false),
          ),
          update: (context, service, previous) => previous ?? VideoIdeaGeneratorViewModel(service: service),
        ),
        ChangeNotifierProvider(create: (_) => GlobalVoiceController()),
        ChangeNotifierProvider(create: (_) => ChallengeViewModel()),
        ChangeNotifierProxyProvider<SettingsViewModel, HandsFreeModeController>(
          create: (ctx) => HandsFreeModeController(
            Provider.of<SettingsViewModel>(ctx, listen: false),
          ),
          update: (ctx, settings, previous) =>
              previous ?? HandsFreeModeController(settings),
        ),
      ],
      child: Consumer2<ThemeViewModel, LocaleViewModel>(
        builder: (context, themeVm, localeVm, _) {
          return MaterialApp.router(
            title: 'IdeaSpark',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeVm.themeMode,
            locale: localeVm.flutterLocale,
            routerConfig: _router,
            builder: (context, child) {
              // Key forces the whole route subtree to rebuild when locale changes (dynamic language switch).
              return KeyedSubtree(
                key: ValueKey(localeVm.locale),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(decoration: TextDecoration.none),
                  child: Stack(
                    children: [
                      child ?? const SizedBox.shrink(),
                      const GlobalVoiceOverlay(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
