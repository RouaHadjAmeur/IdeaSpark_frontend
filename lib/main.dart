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
// Lazy imports - chargés seulement quand nécessaire
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
  
  // ⚡ OPTIMISATION EXTRÊME: Initialisation minimale seulement
  try {
    // Supabase - critique seulement
    await Supabase.initialize(
      url: 'https://ddqinbuujcpfgkoezrzg.supabase.co',
      anonKey: 'sb_publishable_Cz8zt7Bt75h6vG3_9NylEQ_81xW5gZ2',
    );
  } catch (e) {
    // Continue même si Supabase échoue
  }
  
  // ⚡ TOUT LE RESTE EN ARRIÈRE-PLAN (non bloquant)
  _initializeBackgroundServices();
  
  // ⚡ DÉMARRAGE IMMÉDIAT
  runApp(const IdeaSparkApp());
}

// ⚡ Services en arrière-plan (non bloquant)
void _initializeBackgroundServices() {
  Future.microtask(() async {
    try {
      if (!kIsWeb) {
        await Firebase.initializeApp();
        await NotificationService.initialize();
      }
      await DeepLinkService().init();
    } catch (e) {
      // Ignore les erreurs des services non critiques
    }
  });
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
        // ⚡ OPTIMISATION EXTRÊME: Providers minimaux seulement
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        
        // ⚡ Providers secondaires - chargés à la demande
        ChangeNotifierProvider.value(value: _getLazySloganViewModel()),
        ChangeNotifierProvider.value(value: _getLazyBrandViewModel()),
        ChangeNotifierProvider.value(value: _getLazyPlanViewModel()),
        ChangeNotifierProvider.value(value: _getLazyProductIdeaViewModel()),
        ChangeNotifierProvider.value(value: _getLazySettingsViewModel()),
        ChangeNotifierProvider.value(value: _getLazyCollaborationViewModel()),
        ChangeNotifierProvider.value(value: _getLazySocialViewModel()),
        ChangeNotifierProvider.value(value: _getLazyProfileViewModel()),
        
        // ⚡ Services complexes - initialisés à la demande
        Provider.value(value: _getLazyVideoIdeaGeneratorService()),
        ChangeNotifierProvider.value(value: _getLazyVideoIdeaGeneratorViewModel()),
        ChangeNotifierProvider.value(value: _getLazyHandsFreeModeController()),
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

  // ⚡ LAZY LOADING: ViewModels créés seulement quand nécessaire
  static SloganViewModel? _sloganViewModel;
  static BrandViewModel? _brandViewModel;
  static PlanViewModel? _planViewModel;
  static ProductIdeaViewModel? _productIdeaViewModel;
  static SettingsViewModel? _settingsViewModel;
  static CollaborationViewModel? _collaborationViewModel;
  static SocialViewModel? _socialViewModel;
  static ProfileViewModel? _profileViewModel;
  static VideoIdeaGeneratorService? _videoIdeaGeneratorService;
  static VideoIdeaGeneratorViewModel? _videoIdeaGeneratorViewModel;
  static HandsFreeModeController? _handsFreeModeController;

  SloganViewModel _getLazySloganViewModel() {
    return _sloganViewModel ??= SloganViewModel();
  }

  BrandViewModel _getLazyBrandViewModel() {
    return _brandViewModel ??= BrandViewModel();
  }

  PlanViewModel _getLazyPlanViewModel() {
    return _planViewModel ??= PlanViewModel();
  }

  ProductIdeaViewModel _getLazyProductIdeaViewModel() {
    return _productIdeaViewModel ??= ProductIdeaViewModel();
  }

  SettingsViewModel _getLazySettingsViewModel() {
    return _settingsViewModel ??= SettingsViewModel();
  }

  CollaborationViewModel _getLazyCollaborationViewModel() {
    return _collaborationViewModel ??= CollaborationViewModel();
  }

  SocialViewModel _getLazySocialViewModel() {
    return _socialViewModel ??= SocialViewModel();
  }

  ProfileViewModel _getLazyProfileViewModel() {
    return _profileViewModel ??= ProfileViewModel();
  }

  VideoIdeaGeneratorService _getLazyVideoIdeaGeneratorService() {
    return _videoIdeaGeneratorService ??= VideoIdeaGeneratorService();
  }

  VideoIdeaGeneratorViewModel _getLazyVideoIdeaGeneratorViewModel() {
    return _videoIdeaGeneratorViewModel ??= VideoIdeaGeneratorViewModel(
      service: _getLazyVideoIdeaGeneratorService(),
    );
  }

  HandsFreeModeController _getLazyHandsFreeModeController() {
    return _handsFreeModeController ??= HandsFreeModeController(
      _getLazySettingsViewModel(),
    );
  }
}
