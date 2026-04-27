import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiPlanLoadingScreen extends StatelessWidget {
  final String brandName;
  const AiPlanLoadingScreen({super.key, required this.brandName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AiPlanLoadingView(brandName: brandName),
    );
  }
}

class AiPlanLoadingView extends StatefulWidget {
  final String brandName;
  const AiPlanLoadingView({super.key, required this.brandName});

  @override
  State<AiPlanLoadingView> createState() => _AiPlanLoadingViewState();
}

class _AiPlanLoadingViewState extends State<AiPlanLoadingView> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  int _messageIndex = 0;
  late Timer _messageTimer;

  final List<String> _messages = [
    "Analyzing Brand Identity...",
    "Scanning Market Trends...",
    "Predicting Audience Engagement...",
    "Defining Strategic Phases...",
    "Optimizing Post Frequency...",
    "Assembling Content Pillars...",
    "Vetting Emotional Triggers...",
    "Finalizing Strategic Roadmap...",
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
          // ─── Background Grains/Glows ──────────────────────────────────────
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.2,
            child: _GlowCircle(color: cs.primary.withValues(alpha: 0.15), size: 400),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.2,
            child: _GlowCircle(color: cs.secondary.withValues(alpha: 0.1), size: 300),
          ),

          // ─── Content ──────────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pulsing Centerpiece
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer rotating ring
                    RotationTransition(
                      turns: _rotateController,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 20,
                              left: 80,
                              child: _OrbitDot(color: cs.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Middle pulse
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.1).animate(CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOutSine,
                      )),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              cs.primary.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Core Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),

                // Text Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        'FORGING STRATEGY',
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.primary.withValues(alpha: 0.5),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.brandName.toUpperCase(),
                        style: GoogleFonts.syne(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Animated Message
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.2),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          _messages[_messageIndex],
                          key: ValueKey<int>(_messageIndex),
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Progress Bar
                SizedBox(
                  width: 160,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ESTIMATED WAIT: 15-20 SEC',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.3),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Footer ───────────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'DO NOT CLOSE THE APPLICATION',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.2),
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _OrbitDot extends StatelessWidget {
  final Color color;
  const _OrbitDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
        ],
      ),
    );
  }
}
