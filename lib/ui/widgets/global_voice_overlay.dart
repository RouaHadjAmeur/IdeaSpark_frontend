import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../voice/global_voice_controller.dart';
import '../../voice/hands_free_mode_controller.dart';
import '../../view_models/settings_view_model.dart';

/// Floating voice overlay shown on every screen.
///
/// When hands-free mode is enabled:
///   - A compact status badge above the mic button shows the current state.
///   - The user does NOT need to tap the button; the badge is informational only.
///
/// When hands-free mode is disabled:
///   - The badge is hidden.
///   - The mic button works as normal (tap-to-listen).
class GlobalVoiceOverlay extends StatefulWidget {
  const GlobalVoiceOverlay({super.key});

  @override
  State<GlobalVoiceOverlay> createState() => _GlobalVoiceOverlayState();
}

class _GlobalVoiceOverlayState extends State<GlobalVoiceOverlay> {
  Timer? _bubbleTimer;
  bool _showBubble = false;
  String? _lastDisplayedResponse;

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    super.dispose();
  }

  void _handleResponseChange(String? response) {
    if (response != null && response != _lastDisplayedResponse) {
      setState(() {
        _showBubble = true;
        _lastDisplayedResponse = response;
      });
      _bubbleTimer?.cancel();
      _bubbleTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _showBubble = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    final controller = context.watch<GlobalVoiceController>();
    final hfController = context.watch<HandsFreeModeController>();

    // The overlay should be visible if either the manual mic mode is enabled, 
    // OR the hands-free mode is active, OR we are in the middle of onboarding.
    if (!settings.voiceModeEnabled && !hfController.isHandsFreeEnabled && !hfController.isOnboarding) {
      return const SizedBox.shrink();
    }

    // Show mic-button bubble from the regular voice controller
    _handleResponseChange(controller.lastResponseText);
    // Also show confirmations spoken by hands-free controller
    if (hfController.lastActionText != null) {
      _handleResponseChange(hfController.lastActionText);
    }

    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Response bubble ──
            AnimatedOpacity(
              opacity: _showBubble ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _ResponseBubble(text: _lastDisplayedResponse),
            ),
            // ── User speech preview bubble ──
            if ((controller.isListening && controller.lastHeardText != null && controller.lastHeardText!.isNotEmpty) ||
                (hfController.isOnboarding && hfController.lastHeardText != null && hfController.lastHeardText!.isNotEmpty) ||
                (hfController.isCommandListening && hfController.lastHeardText != null && hfController.lastHeardText!.isNotEmpty))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  (hfController.isOnboarding || hfController.isCommandListening) ? hfController.lastHeardText! : controller.lastHeardText!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ── Hands-free status badge ──
            if (hfController.isHandsFreeEnabled || hfController.isOnboarding)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _HandsFreeBadge(controller: hfController),
              ),

            // ── Listening label (normal mode) ──
            if (controller.isListening && !hfController.isHandsFreeEnabled)
              const Padding(
                padding: EdgeInsets.only(bottom: 8, right: 8),
                child: Text(
                  'Listening...',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // ── Mic button ──
            GestureDetector(
              onTap: (controller.isProcessing || hfController.isHandsFreeEnabled || hfController.isOnboarding)
                  ? null // Hands-free mode: button inactive
                  : () => controller.toggleListening(context),
              child: _PulseMicButton(
                isListening: controller.isListening ||
                    hfController.isWakeListening ||
                    hfController.isCommandListening ||
                    hfController.isOnboarding,
                isProcessing: controller.isProcessing,
                isHandsFreeMode: hfController.isHandsFreeEnabled || hfController.isOnboarding,
                isOnboarding: hfController.isOnboarding,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hands-free status badge ────────────────────────────────────────────────

class _HandsFreeBadge extends StatelessWidget {
  final HandsFreeModeController controller;
  const _HandsFreeBadge({required this.controller});

  String get _label {
    if (controller.isOnboarding) return '👋 Setup Hands-Free?';
    if (controller.isSpeaking) return '🔊 Speaking';
    if (controller.isCommandListening) return '🎙 Listening…';
    if (controller.isWakeListening) return '👂 Waiting for "listen"';
    if (controller.isHandsFreeEnabled) return '✅ Hands-free on';
    return '';
  }

  Color _color(BuildContext context) {
    if (controller.isOnboarding) return Colors.purple.shade700;
    if (controller.isCommandListening) return Colors.red.shade600;
    if (controller.isWakeListening) return Colors.orange.shade700;
    if (controller.isSpeaking) return Colors.blue.shade700;
    return Colors.green.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final label = _label;
    if (label.isEmpty) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color(context).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ── Response bubble ────────────────────────────────────────────────────────

class _ResponseBubble extends StatelessWidget {
  final String? text;
  const _ResponseBubble({this.text});

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxWidth: 240),
      child: Text(
        text!,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── Pulsing mic button ─────────────────────────────────────────────────────

class _PulseMicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final bool isHandsFreeMode;
  final bool isOnboarding;

  const _PulseMicButton({
    required this.isListening,
    required this.isProcessing,
    required this.isHandsFreeMode,
    this.isOnboarding = false,
  });

  @override
  State<_PulseMicButton> createState() => _PulseMicButtonState();
}

class _PulseMicButtonState extends State<_PulseMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isListening) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !oldWidget.isListening) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hands-free active → purple; listening → red; idle → blue
    final Color baseColor = widget.isOnboarding
        ? Colors.purple
        : widget.isHandsFreeMode
            ? Colors.deepPurple
            : widget.isListening
                ? Colors.red
                : Colors.blue;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening)
              Container(
                width: 56 * _pulseAnimation.value,
                height: 56 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withValues(alpha: 0.2),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        widget.isOnboarding
                            ? Icons.help_outline
                            : widget.isHandsFreeMode
                                ? Icons.hearing
                                : Icons.mic,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
