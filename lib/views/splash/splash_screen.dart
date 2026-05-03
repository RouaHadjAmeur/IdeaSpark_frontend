import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/core/app_theme.dart';
import 'package:ideaspark/core/app_localizations.dart';
import 'package:ideaspark/view_models/auth_view_model.dart';
import 'package:ideaspark/services/persona_completion_service.dart';
import 'package:ideaspark/voice/hands_free_mode_controller.dart';

import 'package:ideaspark/services/call_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // ⚡ NAVIGATION IMMÉDIATE - Pas d'attente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateNext();
    });
  }

  Future<void> _navigateNext() async {
    if (_isNavigating) return;
    _isNavigating = true;

    try {
      final authVm = context.read<AuthViewModel>();

      // ⚡ TIMEOUT EXTRÊME: 200ms max pour tout
      bool loggedIn = false;
      bool onboardingDone = true;
      bool personaCompleted = true;

      try {
        // Tout en parallèle avec timeout global de 200ms
        final results = await Future.wait([
          authVm.restoreSession(),
          authVm.isOnboardingDone(),
          PersonaCompletionService.isPersonaCompleted(),
        ]).timeout(const Duration(milliseconds: 200));
        
        loggedIn = results[0];
        onboardingDone = results[1];
        personaCompleted = results[2];
      } catch (e) {
        // En cas de timeout ou erreur, valeurs par défaut
        loggedIn = false;
        onboardingDone = true;
        personaCompleted = true;
      }

      if (!mounted) return;

      // ⚡ NAVIGATION IMMÉDIATE
      if (loggedIn && onboardingDone && personaCompleted) {
        context.go('/home');
      } else if (loggedIn && !onboardingDone) {
        context.go('/onboarding');
      } else if (loggedIn && !personaCompleted) {
        final userId = authVm.userId ?? '';
        context.go('/persona-onboarding', extra: userId);
      } else {
        context.go('/login');
      }

      // ⚡ Onboarding vocal en arrière-plan (non bloquant)
      _startVoiceOnboardingInBackground();
    } catch (e) {
      // ⚡ Navigation de secours
      if (mounted) context.go('/login');
    }
  }

  void _startVoiceOnboardingInBackground() {
    Future.microtask(() {
      try {
        if (mounted) {
          context.read<HandsFreeModeController>()
              .runInitialVoiceOnboardingIfNeeded();
        }
      } catch (e) {
        // Ignore les erreurs
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ⚡ Logo ultra-simple
            Text(
              'IdeaSpark',
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            // ⚡ Indicateur minimal
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
