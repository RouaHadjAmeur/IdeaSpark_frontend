import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/speech_to_text_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/llm_command_service.dart';
import '../services/command_executor.dart';
import '../view_models/settings_view_model.dart';

/// Orchestrates the foreground hands-free voice mode for IdeaSpark.
///
/// Lifecycle:
///   1. [runInitialVoiceOnboardingIfNeeded] — called once after splash.
///   2. If enabled, [startWakeListeningLoop] — repeated 4-second STT windows
///      until "listen" / "idea spark" / "hey ideaspark" is heard.
///   3. [handleWakePhraseDetected] — speaks "I'm listening" then enters
///      command capture via the normal STT session.
///   4. [handleCommandText] — parses with backend, executes, speaks reply,
///      returns to wake loop.
///
/// IMPORTANT — this is foreground-only.
/// No hidden OS background service, no permanent recording.
class HandsFreeModeController extends ChangeNotifier {
  HandsFreeModeController(this._settings);

  final SettingsViewModel _settings;
  final SpeechToTextService _stt = SpeechToTextService();
  final TextToSpeechService _tts = TextToSpeechService();
  final LlmCommandService _llm = LlmCommandService();

  // ── Exposed state ──────────────────────────────────────────────────────────

  bool _isHandsFreeEnabled = false;
  bool get isHandsFreeEnabled => _isHandsFreeEnabled;

  bool _isWakeListening = false;
  bool get isWakeListening => _isWakeListening;

  bool _isCommandListening = false;
  bool get isCommandListening => _isCommandListening;

  bool _isOnboarding = false;
  bool get isOnboarding => _isOnboarding;

  bool get isSpeaking => _tts.isSpeaking;

  String? _lastHeardText;
  String? get lastHeardText => _lastHeardText;

  String? _lastActionText;
  String? get lastActionText => _lastActionText;

  // ── Internal guards ────────────────────────────────────────────────────────

  bool _loopRunning = false;   // prevents concurrent wake loops
  bool _disposed = false;

  // ── Accepted keywords ──────────────────────────────────────────────────────

  static const List<String> _wakePhrases = [
    'listen',
    'idea spark',
    'ideaspark',
    'hey ideaspark',
  ];

  static const List<String> _yesWords = [
    'yes', 'yeah', 'yep', 'okay', 'ok', 'enable', 'sure', 'oui', 'نعم',
  ];

  static const List<String> _noWords = [
    'no', 'nope', 'non', 'لا', 'disable',
  ];

  static const List<String> _disableCommands = [
    'disable hands-free mode',
    'turn off hands-free',
    'stop hands-free mode',
    'disable hands free',
    'turn off hands free',
    'désactiver le mode mains libres',
    'إيقاف الوضع المجاني',
  ];

  // ── STEP 1 — Onboarding ───────────────────────────────────────────────────

  /// Called once after the splash completes and the main app is ready.
  ///
  /// • If onboarding was already completed, restores the previous preference.
  /// • If not, asks the user via voice and records their answer.
  Future<void> runInitialVoiceOnboardingIfNeeded() async {
    if (_disposed) return;

    // Sync with persisted settings (may not have loaded yet; wait one frame)
    await Future.delayed(const Duration(milliseconds: 500));
    if (_disposed) return;

    // TODO(testing): Forcing false so you can test the onboarding again.
    // Remove or comment out this line later if you want it to remember.
    await _settings.setHandsFreeOnboardingCompleted(false);

    if (_settings.handsFreeOnboardingCompleted) {
      // Restore mode silently.
      if (_settings.handsFreeEnabled) {
        _isHandsFreeEnabled = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 800));
        await _speak("Hands-free mode is active. Say 'listen' before each command.");
        await startWakeListeningLoop();
      }
      return;
    }

  // ── Ask the user ──
    _isOnboarding = true;
    notifyListeners();

    await _speak(
      "Welcome to IdeaSpark. "
      "Would you like to enable hands-free mode? Say yes or no.",
    );

    final answer = await _listenOnceFull();
    final accepted = _matchesYes(answer);
    final rejected = _matchesNo(answer);

    if (!accepted && !rejected) {
      // Unclear — ask once more.
      await _speak("I didn't catch that. Say yes or no.");
      final retry = await _listenOnceFull();
      if (_matchesYes(retry)) {
        await _activateHandsFree();
      } else {
        await _declineHandsFree();
      }
    } else if (accepted) {
      await _activateHandsFree();
    } else {
      await _declineHandsFree();
    }

    _isOnboarding = false;
    notifyListeners();

    // Mark onboarding complete regardless of choice.
    await _settings.setHandsFreeOnboardingCompleted(true);
  }

  Future<void> _activateHandsFree() async {
    await enableHandsFreeMode();
    await _speak(
      "Hands-free mode activated. Say 'listen' before each command.",
    );
    await startWakeListeningLoop();
  }

  Future<void> _declineHandsFree() async {
    await _speak(
      "You can use the microphone button at the bottom right anytime.",
    );
  }

  // ── STEP 2 — Enable / Disable ─────────────────────────────────────────────

  Future<void> enableHandsFreeMode() async {
    if (_disposed) return;
    _isHandsFreeEnabled = true;
    await _settings.setHandsFreeEnabled(true);
    notifyListeners();
  }

  Future<void> disableHandsFreeMode() async {
    if (_disposed) return;
    _isHandsFreeEnabled = false;
    _loopRunning = false;
    _isWakeListening = false;
    _isCommandListening = false;
    await _settings.setHandsFreeEnabled(false);
    await _stt.cancelListening();
    notifyListeners();
    await _speak("Hands-free mode turned off.");
  }

  // ── STEP 3 — Wake listening loop ──────────────────────────────────────────

  /// Starts the repeated short-window wake-word listen loop.
  ///
  /// Each window is 4 s. The loop continues until:
  ///   • A wake phrase is detected ([handleWakePhraseDetected]).
  ///   • [stopWakeListeningLoop] is called explicitly.
  ///   • The controller is disposed.
  Future<void> startWakeListeningLoop() async {
    if (_loopRunning || _disposed || !_isHandsFreeEnabled) return;
    _loopRunning = true;
    _isWakeListening = true;
    notifyListeners();

    while (_loopRunning && !_disposed && _isHandsFreeEnabled) {
      // Don't listen while TTS is playing.
      if (_tts.isSpeaking) {
        await Future.delayed(const Duration(milliseconds: 300));
        continue;
      }

      final Completer<String> completer = Completer<String>();

      await _stt.startShortListening(
        onPartial: (_) {}, // Don't act on partials in wake mode
        onFinal: (text) {
          if (!completer.isCompleted) completer.complete(text);
        },
      );

      // Wait for the window to finish or the completer to complete.
      final heard = await completer.future.timeout(
        const Duration(seconds: 6),
        onTimeout: () => '',
      );

      if (!_loopRunning || _disposed) break;

      _lastHeardText = heard;
      // Don't notifyListeners every frame — too noisy. Only on real detections.

      if (_containsWakePhrase(heard)) {
        _loopRunning = false;
        _isWakeListening = false;
        notifyListeners();
        await handleWakePhraseDetected();
        // After command phase, restart loop if still enabled.
        if (_isHandsFreeEnabled && !_disposed) {
          _loopRunning = true;
          _isWakeListening = true;
          notifyListeners();
        }
      }
      // else: no wake phrase — loop continues naturally.
    }

    _isWakeListening = false;
    _loopRunning = false;
    notifyListeners();
  }

  Future<void> stopWakeListeningLoop() async {
    _loopRunning = false;
    _isWakeListening = false;
    await _stt.cancelListening();
    notifyListeners();
  }

  // ── STEP 4 — Command phase ────────────────────────────────────────────────

  /// Called when a wake phrase was detected. Speaks "I'm listening"
  /// then captures one user command.
  Future<void> handleWakePhraseDetected() async {
    if (_disposed) return;
    await _speak("I'm listening.");

    _isCommandListening = true;
    notifyListeners();

    final commandText = await _listenOnceFull();
    _isCommandListening = false;
    notifyListeners();

    if (commandText.trim().isEmpty) {
      await _speak("I didn't catch that.");
      return;
    }

    _lastHeardText = commandText;
    notifyListeners();

    await handleCommandText(commandText);
  }

  /// Processes a captured command transcript.
  ///
  /// Checks locally for disable commands, then delegates to the backend.
  Future<void> handleCommandText(String text) async {
    if (_disposed) return;

    final lower = text.toLowerCase().trim();

    // ── Local: disable hands-free ──
    if (_disableCommands.any((cmd) => lower.contains(cmd))) {
      await disableHandsFreeMode();
      return;
    }

    // ── Backend: parse + execute ──
    try {
      final response = await _llm.parseCommand(text, {
        'timestamp': DateTime.now().toIso8601String(),
        'mode': 'hands_free',
      });

      _lastActionText = response.say;
      notifyListeners();

      // Execute actions using global router (no BuildContext needed).
      final executor = CommandExecutor.noContext();
      await executor.executeActionsNoContext(response.actions);

      await _speak(response.say);
    } catch (e) {
      debugPrint('[HandsFreeController] Backend error: $e');
      await _speak("Command not recognized.");
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Speaks [text] and waits for TTS to finish before returning.
  Future<void> _speak(String text) async {
    if (_disposed) return;
    _lastActionText = text;
    notifyListeners();
    await _tts.speak(text);
  }

  /// Listens once using the full-dictation mode (up to 8 seconds).
  /// Returns the final transcript (may be empty).
  Future<String> _listenOnceFull() async {
    final Completer<String> completer = Completer<String>();

    final available = await _stt.init();
    if (!available) {
      await _speak(
        "Microphone access is required for hands-free mode.",
      );
      if (!completer.isCompleted) completer.complete('');
      return '';
    }

    _lastHeardText = ''; // Reset preview text before listening

    await _stt.startListening(
      onPartial: (text) {
        _lastHeardText = text;
        notifyListeners();
      },
      onFinal: (text) {
        if (!completer.isCompleted) completer.complete(text);
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _stt.cancelListening(); // ensure the mic is released
        return _stt.lastWords; // return whatever partial text we gathered
      },
    );
  }

  bool _containsWakePhrase(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    return _wakePhrases.any((phrase) => lower.contains(phrase));
  }

  bool _matchesYes(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    return _yesWords.any((w) => lower.contains(w));
  }

  bool _matchesNo(String text) {
    if (text.trim().isEmpty) return false;
    final lower = text.toLowerCase();
    return _noWords.any((w) => lower.contains(w));
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    _disposed = true;
    _loopRunning = false;
    await _stt.cancelListening();
    await _tts.dispose();
    super.dispose();
  }
}
