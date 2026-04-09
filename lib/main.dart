import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_theme.dart';
import 'core/navigation_service.dart';
import 'view_models/auth_view_model.dart';
import 'view_models/home_view_model.dart';
import 'view_models/theme_view_model.dart';
import 'view_models/locale_view_model.dart';
import 'view_models/settings_view_model.dart';
import 'services/video_generator_service.dart';
import 'view_models/video_idea_generator_view_model.dart';
import 'view_models/slogan_view_model.dart';
import 'view_models/brand_view_model.dart';
import 'view_models/plan_view_model.dart';
import 'view_models/product_idea_view_model.dart';
import 'voice/global_voice_controller.dart';
import 'ui/widgets/global_voice_overlay.dart';
import 'services/call_service.dart';
import 'modules/chat/call_screen.dart';
import 'core/app_router.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ddqinbuujcpfgkoezrzg.supabase.co',
    anonKey: 'sb_publishable_Cz8zt7Bt75h6vG3_9NylEQ_81xW5gZ2',
  );
  runApp(const IdeaSparkApp());
}

/// Router créé une seule fois pour éviter un redémarrage de l'app au changement de thème.
class IdeaSparkApp extends StatefulWidget {
  const IdeaSparkApp({super.key});

  @override
  State<IdeaSparkApp> createState() => _IdeaSparkAppState();
}

class _IdeaSparkAppState extends State<IdeaSparkApp> {
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
        Provider(create: (_) => VideoIdeaGeneratorService()),
        ChangeNotifierProxyProvider<VideoIdeaGeneratorService, VideoIdeaGeneratorViewModel>(
          create: (context) => VideoIdeaGeneratorViewModel(
            service: Provider.of<VideoIdeaGeneratorService>(context, listen: false),
          ),
          update: (context, service, previous) => previous ?? VideoIdeaGeneratorViewModel(service: service),
        ),
        ChangeNotifierProvider(create: (_) => GlobalVoiceController()),
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
            routerConfig: appRouter,
            builder: (context, child) {
              // Key forces the whole route subtree to rebuild when locale changes (dynamic language switch).
              return KeyedSubtree(
                key: ValueKey(localeVm.locale),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(decoration: TextDecoration.none),
                  child: Stack(
                    children: [
                      if (child != null) child,
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
