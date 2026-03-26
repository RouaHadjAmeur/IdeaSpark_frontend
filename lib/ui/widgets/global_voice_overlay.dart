import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../voice/global_voice_controller.dart';
import '../../view_models/settings_view_model.dart';

/// Step 7: Refined GlobalVoiceOverlay for IdeaSpark.
///
/// Features:
/// - Floating mic overlay on all screens.
/// - Pulse/Glow animation while listening.
/// - Integrated Loading indicator during processing.
/// - Response bubble with 3-second auto-hide.
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
      _bubbleTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showBubble = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsViewModel>();
    if (!settings.voiceModeEnabled) return const SizedBox.shrink();

    final controller = context.watch<GlobalVoiceController>();
    
    // Trigger bubble logic if response text changes
    _handleResponseChange(controller.lastResponseText);

    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Response Bubble ──
            AnimatedOpacity(
              opacity: _showBubble ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _ResponseBubble(text: controller.lastResponseText),
            ),
            
            const SizedBox(height: 8),

            // ── Listening Indicator ──
            if (controller.isListening)
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

            // ── Mic Button ──
            GestureDetector(
              onTap: controller.isProcessing 
                  ? null 
                  : () => controller.toggleListening(context),
              child: _PulseMicButton(
                isListening: controller.isListening,
                isProcessing: controller.isProcessing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _PulseMicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;

  const _PulseMicButton({
    required this.isListening,
    required this.isProcessing,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    // Spec colors: Blue for Idle, Red for Listening
    final Color baseColor = widget.isListening ? Colors.red : Colors.blue;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse Ring
            if (widget.isListening)
              Container(
                width: 56 * _pulseAnimation.value,
                height: 56 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withValues(alpha: 0.2),
                ),
              ),
            
            // Main Button
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
                    : const Icon(
                        Icons.mic,
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
