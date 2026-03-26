import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/view_models/settings_view_model.dart';
import 'package:ideaspark/view_models/locale_view_model.dart';
import 'package:ideaspark/services/speech_to_text_service.dart';
import 'package:ideaspark/core/app_localizations.dart';

/// A small mic button that can be placed inside (or next to) a text field.
///
/// When [SettingsViewModel.voiceInputEnabled] is false the widget renders
/// nothing (SizedBox.shrink).  When tapped it toggles listening on/off via
/// [SpeechToTextService] and writes recognised text into [controller].
class VoiceMicButton extends StatefulWidget {
  /// The text controller to fill with recognised speech.
  final TextEditingController controller;

  /// When `true` and the field already has content, new speech is appended
  /// after a space instead of replacing the existing text.
  final bool appendMode;

  const VoiceMicButton({
    super.key,
    required this.controller,
    this.appendMode = true,
  });

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  final SpeechToTextService _stt = SpeechToTextService();
  bool _listening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  /// We keep a snapshot of the text that existed *before* listening started
  /// so we can append properly without duplicating previous content.
  String _preListeningText = '';

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
  }

  @override
  void dispose() {
    _stt.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Actions ──

  Future<void> _toggle() async {
    if (_listening) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    // Capture context-dependent values before async gap
    final sttNotAvailableMsg = context.tr('stt_not_available');
    final locale = context.read<LocaleViewModel>().locale;

    final ok = await _stt.init();
    if (!mounted) return;
    if (!ok) {
      _showError(sttNotAvailableMsg);
      return;
    }

    // Resolve STT locale from app language
    final localeId = await _stt.bestLocaleFor(locale);
    if (!mounted) return;

    // Remember current text for append mode
    _preListeningText = widget.controller.text;

    setState(() => _listening = true);
    _pulseController.repeat(reverse: true);

    await _stt.startListening(
      localeId: localeId,
      onPartial: _onPartial,
      onFinal: _onFinal,
    );

    // If startListening returned immediately with an error
    if (_stt.lastError != null) {
      _handleError(_stt.lastError!);
    }
  }

  Future<void> _stop() async {
    await _stt.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _listening = false);
  }

  // ── Callbacks ──

  void _onPartial(String words) {
    if (!mounted) return;
    _applyText(words);
  }

  void _onFinal(String words) {
    if (!mounted) return;
    _applyText(words);
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _listening = false);
  }

  void _applyText(String words) {
    if (widget.appendMode && _preListeningText.isNotEmpty) {
      widget.controller.text = '$_preListeningText $words';
    } else {
      widget.controller.text = words;
    }
    // Move cursor to end
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
  }

  void _handleError(String error) {
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _listening = false);

    if (error.contains('error_permission') ||
        error.contains('error_not_allowed')) {
      _showError(context.tr('stt_permission_denied'));
    } else {
      _showError(context.tr('stt_error'));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white,
                size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<SettingsViewModel>().voiceInputEnabled;
    if (!enabled) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _listening ? _pulseAnimation.value : 1.0,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _listening
                    ? colorScheme.error.withValues(alpha: 0.15)
                    : colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _listening ? Icons.stop_rounded : Icons.mic_rounded,
                size: 20,
                color: _listening ? colorScheme.error : colorScheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}
