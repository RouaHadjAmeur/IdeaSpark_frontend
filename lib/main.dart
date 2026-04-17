import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/theme_view_model.dart';
import 'view_models/locale_view_model.dart';
import 'services/video_generator_service.dart';
import 'services/video_idea_generator_service.dart';
import 'view_models/video_idea_generator_view_model.dart';
import 'view_models/slogan_view_model.dart';
import 'view_models/brand_view_model.dart';
import 'view_models/plan_view_model.dart';
import 'view_models/product_idea_view_model.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'view_models/settings_view_model.dart';
import 'view_models/collaboration_view_model.dart';
import 'view_models/social_view_model.dart';
import 'view_models/profile_view_model.dart';
import 'voice/hands_free_mode_controller.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase only on mobile (not web)
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await NotificationService.initialize();
  }
  
  await Supabase.initialize(
    url: 'https://ddqinbuujcpfgkoezrzg.supabase.co',
    anonKey: 'sb_publishable_Cz8zt7Bt75h6vG3_9NylEQ_81xW5gZ2',
  );
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
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => SloganViewModel()),
        ChangeNotifierProvider(create: (_) => BrandViewModel()),
        ChangeNotifierProvider(create: (_) => PlanViewModel()),
        ChangeNotifierProvider(create: (_) => ProductIdeaViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => CollaborationViewModel()),
        ChangeNotifierProvider(create: (_) => SocialViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProxyProvider<SettingsViewModel, HandsFreeModeController>(
          create: (context) => HandsFreeModeController(
            Provider.of<SettingsViewModel>(context, listen: false),
          ),
          update: (context, settings, previous) =>
              previous ?? HandsFreeModeController(settings),
        ),
        Provider(create: (_) => VideoIdeaGeneratorService()),
        ChangeNotifierProxyProvider<VideoIdeaGeneratorService, VideoIdeaGeneratorViewModel>(
          create: (context) => VideoIdeaGeneratorViewModel(
            service: Provider.of<VideoIdeaGeneratorService>(context, listen: false),
          ),
          update: (context, service, previous) => previous ?? VideoIdeaGeneratorViewModel(service: service),
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
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
