import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Singleton Text-to-Speech service for IdeaSpark.
///
/// Wraps [FlutterTts] with a clean, queue-safe API.
/// No UI logic lives here — only speech engine control.
///
/// Usage:
///   final tts = TextToSpeechService();
///   await tts.speak("Hello!");
class TextToSpeechService {
  // ── Singleton ──────────────────────────────────────────────────────────────

  static final TextToSpeechService _instance = TextToSpeechService._internal();

  factory TextToSpeechService() => _instance;

  TextToSpeechService._internal() {
    _init();
  }

  // ── Private state ──────────────────────────────────────────────────────────

  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  bool _isInit = false;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    if (_isInit) return;
    
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('[TTS] Error: $msg');
    });

    // Sensible defaults
    await _tts.setSpeechRate(0.50); // slightly slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    
    // Make await tts.speak() actually wait for the speech to finish
    await _tts.awaitSpeakCompletion(true);
    
    // Configure iOS audio session to mix with others and use playAndRecord
    // This is critical so TTS and STT don't steal the audio session from each other.
    await _tts.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playAndRecord,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
      ],
      IosTextToSpeechAudioMode.defaultMode,
    );

    _isInit = true;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Speak [text] aloud. Stops any ongoing speech first so there is never overlap.
  ///
  /// Keeps speeches short — callers must pass concise strings.
  Future<void> speak(String text) async {
    if (!_isInit) await _init();
    
    if (text.trim().isEmpty) return;
    // Stop any ongoing utterance to prevent overlap.
    if (_isSpeaking) {
      await _tts.stop();
    }
    _isSpeaking = true;
    final result = await _tts.speak(text);
    if (result != 1) {
      // Engine rejected the request (e.g. no language loaded).
      _isSpeaking = false;
      debugPrint('[TTS] speak() returned $result for: "$text"');
    }
  }

  /// Stop any ongoing speech immediately.
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Change the speech engine language.
  ///
  /// [langCode] — BCP-47 tag, e.g. `en-US`, `fr-FR`, `ar`.
  Future<void> setLanguage(String langCode) async {
    await _tts.setLanguage(langCode);
  }

  /// Release engine resources. Call this when the app terminates.
  Future<void> dispose() async {
    await _tts.stop();
    _isSpeaking = false;
  }
}
