import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/view_models/settings_view_model.dart';
import 'package:ideaspark/services/speech_to_text_service.dart';

/// A reusable microphone button widget for voice input.
///
/// It integrates with [SpeechToTextService] and honors the
/// [SettingsViewModel.voiceInputEnabled] toggle.
class VoiceMicButton extends StatefulWidget {
  /// Callback triggered when final speech recognition result is ready.
  final Function(String text) onTextRecognized;

  /// Optional flag to indicate if text should be appended (handled by parent).
  final bool appendMode;

  /// Optional speech locale override (e.g., 'en_US', 'fr_FR').
  final String? localeId;

  const VoiceMicButton({
    super.key,
    required this.onTextRecognized,
    this.appendMode = true,
    this.localeId,
  });

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  final SpeechToTextService _sttService = SpeechToTextService();
  bool _isListening = false;
  String _partialText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    // Ensure listening stops and animation is cleaned up
    if (_isListening) {
      _sttService.stopListening();
    }
    _pulseController.dispose();
    super.dispose();
  }

  // ── Recognition Logic ──

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    final bool available = await _sttService.init();
    
    if (!mounted) return;

    if (!available) {
      _showErrorSnackbar('Speech recognition not available.');
      return;
    }

    setState(() {
      _isListening = true;
      _partialText = '';
    });
    _pulseController.repeat(reverse: true);

    try {
      await _sttService.startListening(
        localeId: widget.localeId,
        onPartial: (text) {
          setState(() => _partialText = text);
        },
        onFinal: (text) {
          if (mounted) {
            _stopPulse();
            setState(() => _isListening = false);
            widget.onTextRecognized(text);
          }
        },
      );
    } catch (e) {
      _handleError('Error starting voice recognition.');
    }
  }

  Future<void> _stopListening() async {
    await _sttService.stopListening();
    _stopPulse();
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _stopPulse() {
    _pulseController.stop();
    _pulseController.reset();
  }

  void _handleError(String message) {
    _stopPulse();
    if (mounted) {
      setState(() => _isListening = false);
      _showErrorSnackbar(message);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    // 1) Visibility Check
    final settings = context.watch<SettingsViewModel>();
    if (!settings.voiceInputEnabled) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleListening,
          onLongPressStart: (_) => _startListening(),
          onLongPressEnd: (_) => _stopListening(),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isListening 
                        ? Colors.red.withValues(alpha: 0.1) 
                        : colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic,
                    color: _isListening ? Colors.red : colorScheme.primary,
                    size: 28,
                  ),
                ),
              );
            },
          ),
        ),
        if (_isListening) ...[
          const SizedBox(height: 8),
          Text(
            'Listening...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_partialText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _partialText,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
