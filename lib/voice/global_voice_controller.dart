import 'package:flutter/material.dart';
import '../services/speech_to_text_service.dart';
import '../services/llm_command_service.dart';
import '../services/command_executor.dart';
import '../models/voice_action.dart';

/// Step 6: Refined GlobalVoiceController for IdeaSpark.
///
/// Coordinates global voice commands, LLM parsing, and confirmation flows.
class GlobalVoiceController extends ChangeNotifier {
  final SpeechToTextService _stt = SpeechToTextService();
  final LlmCommandService _llm = LlmCommandService();

  // ── Properties ──

  bool _isListening = false;
  bool get isListening => _isListening;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _lastHeardText;
  String? get lastHeardText => _lastHeardText;

  String? _lastResponseText;
  String? get lastResponseText => _lastResponseText;

  // Internal state for confirmations
  VoiceParseResponse? _pendingResponse;

  // ── Methods ──

  /// Taps mic logic: if listening -> stop, if idle -> start.
  Future<void> toggleListening(BuildContext context) async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening(context);
    }
  }

  /// Starts listening for voice input.
  Future<void> startListening(BuildContext context) async {
    _lastResponseText = null;
    _lastHeardText = null;
    // Note: We don't clear _pendingResponse here because we might be 
    // starting to listen for a confirmation to that pending response.

    final available = await _stt.init();
    if (!available) {
      _lastResponseText = 'Speech recognition not available.';
      notifyListeners();
      return;
    }

    _isListening = true;
    notifyListeners();

    try {
      await _stt.startListening(
        onPartial: (text) {
          _lastHeardText = text;
          notifyListeners();
        },
        onFinal: (text) async {
          _isListening = false;
          _lastHeardText = text;
          notifyListeners();

          if (text.trim().isNotEmpty) {
            if (_pendingResponse != null) {
              await handleConfirmation(context, text);
            } else {
              await _processCommand(context, text);
            }
          }
        },
      );
    } catch (e) {
      _isListening = false;
      _lastResponseText = 'Error starting recognition: $e';
      notifyListeners();
    }
  }

  /// Manually stops listening.
  Future<void> stopListening() async {
    await _stt.stopListening();
    _isListening = false;
    notifyListeners();
  }

  /// Processes the final transcript through LLM and either executes or asks for confirmation.
  Future<void> _processCommand(BuildContext context, String text) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final response = await _llm.parseCommand(text, {
        'timestamp': DateTime.now().toIso8601String(),
      });

      _isProcessing = false;
      _lastResponseText = response.say;

      if (response.requiresConfirmation) {
        // Store the response for later execution if confirmed
        _pendingResponse = response;
      } else {
        // Execute immediately if no confirmation needed
        if (context.mounted) {
          final executor = CommandExecutor(context);
          await executor.executeActions(response.actions, response.say);
        }
      }
    } catch (e) {
      _isProcessing = false;
      _lastResponseText = 'Command failed: $e';
    }
    notifyListeners();
  }

  /// Handles user response to a confirmation request (e.g. "yes", "confirm").
  Future<void> handleConfirmation(BuildContext context, String text) async {
    if (_pendingResponse == null) return;

    final confirmed = text.toLowerCase().contains('yes') || 
                     text.toLowerCase().contains('confirm');

    if (confirmed) {
      final response = _pendingResponse!;
      _pendingResponse = null;
      if (context.mounted) {
        final executor = CommandExecutor(context);
        await executor.executeActions(response.actions, response.say);
      }
    } else {
      _pendingResponse = null;
      _lastResponseText = 'Action cancelled.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stt.dispose();
    super.dispose();
  }
}
