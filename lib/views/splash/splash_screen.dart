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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late AnimationController _bubble1Controller;
  late AnimationController _bubble2Controller;
  Timer? _navigationTimer;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.8, curve: Curves.elasticOut),
      ),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Bulle 1 : montée lente + balancement horizontal fluide
    _bubble1Controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    // Bulle 2 : décalée en phase pour effet naturel
    _bubble2Controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    _entranceController.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    // Délai réduit de 800ms à 400ms
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    try {
      final authVm = context.read<AuthViewModel>();

      // Timeout réduit de 3s à 1.5s pour la session
      final loggedIn = await authVm.restoreSession()
          .timeout(const Duration(milliseconds: 1500), onTimeout: () => false);
      if (!mounted) return;

      if (loggedIn) {
        // Initialize call service as soon as we are logged in
        CallService().connect();

        // Timeout réduit de 2s à 1s pour l'onboarding
        final onboardingDone = await authVm.isOnboardingDone()
            .timeout(const Duration(seconds: 1), onTimeout: () => true);
        if (!mounted) return;

        if (onboardingDone) {
          // Timeout réduit de 2s à 1s pour le persona
          final personaCompleted = await PersonaCompletionService.isPersonaCompleted()
              .timeout(const Duration(seconds: 1), onTimeout: () => true);
          if (!mounted) return;

          if (personaCompleted) {
            context.go('/home');
            // Lancer l'onboarding vocal en arrière-plan (non bloquant)
            Future.microtask(() {
              if (mounted) {
                context.read<HandsFreeModeController>().runInitialVoiceOnboardingIfNeeded();
              }
            });
          } else {
            final userId = authVm.userId ?? '';
            context.go('/persona-onboarding', extra: userId);
          }
        } else {
          context.go('/onboarding');
        }
      } else {
        context.go('/login');
      }
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }





  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              colorScheme.surface,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.5 + _glowAnimation.value * 0.3,
                      colors: [
                        colorScheme.primary.withValues(
                          alpha: 0.15 * _glowAnimation.value,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_bubble1Controller, _bubble2Controller]),
              builder: (context, child) {
                return Stack(
                  children: [
                    _buildMovingBubble(
                      size: size,
                      t: _bubble1Controller.value,
                      bubbleSize: 48,
                      swayAmplitude: 50,
                      phase: 0,
                      baseOpacity: 0.5,
                      primary: colorScheme.primary,
                    ),
                    _buildMovingBubble(
                      size: size,
                      t: _bubble2Controller.value,
                      bubbleSize: 32,
                      swayAmplitude: 70,
                      phase: 0.4,
                      baseOpacity: 0.35,
                      primary: colorScheme.primary,
                    ),
                  ],
                );
              },
            ),
            Center(
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                colorScheme.primary,
                                context.accentColor,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              context.tr('app_name'),
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.6 + _glowAnimation.value * 0.4,
                                child: Text(
                                  context.tr('splash_tagline'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurfaceVariant,
                                    letterSpacing: 4,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovingBubble({
    required Size size,
    required double t,
    required double bubbleSize,
    required double swayAmplitude,
    double phase = 0,
    double baseOpacity = 0.5,
    required Color primary,
  }) {
    final y = size.height + bubbleSize - (t * (size.height + bubbleSize * 2));
    final sway = sin(t * 2 * pi + phase);
    final x = size.width * 0.5 + swayAmplitude * sway;
    final opacity = (baseOpacity * (0.7 + 0.3 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0))).clamp(0.2, 0.9);

    return Positioned(
      left: x - bubbleSize / 2,
      top: y - bubbleSize / 2,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: bubbleSize,
          height: bubbleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                primary.withValues(alpha: 0.9),
                primary.withValues(alpha: 0.4),
                primary.withValues(alpha: 0.1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.4),
                blurRadius: bubbleSize * 0.35,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
