import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Clean, production-ready speech-to-text service for IdeaSpark.
///
/// Implements a singleton pattern and handles initialisation, permissions,
/// locale selection, and recognition results.
class SpeechToTextService {
  // ── Singleton Pattern ──

  static final SpeechToTextService _instance = SpeechToTextService._internal();

  factory SpeechToTextService() => _instance;

  SpeechToTextService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;
  String? _lastError;

  // ── Public Getters ──

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;
  String get lastWords => _speech.lastRecognizedWords;
  String? get lastError => _lastError;

  // ── Public Methods ──

  /// Initialise the speech engine. Returns `true` if available.
  Future<bool> init() async {
    if (_isAvailable && !_speech.hasError) return true;

    try {
      _isAvailable = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: false,
      );
    } catch (e) {
      _isAvailable = false;
      _lastError = e.toString();
    }

    return _isAvailable;
  }

  /// Start listening for speech.
  ///
  /// [localeId] — e.g. `en_US`, `fr_FR`, `ar_TN`.
  /// [onPartial] — called as words are recognised (live preview).
  /// [onFinal]   — called once the engine considers the phrase final.
  Future<void> startListening({
    String? localeId,
    required void Function(String partialText) onPartial,
    required void Function(String finalText) onFinal,
  }) async {
    _lastError = null;

    if (!_isAvailable) {
      final ok = await init();
      if (!ok) {
        _lastError = 'speech_not_available';
        return;
      }
    }

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onFinal(result.recognizedWords);
        } else {
          onPartial(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 30),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Stop listening and finalise.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancel recognition without returning a result.
  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  /// Returns all locales supported by the on-device speech engine.
  Future<List<stt.LocaleName>> getSupportedLocales() async {
    if (!_isAvailable) await init();
    return _speech.locales();
  }

  /// Maps the app's language code to a speech-engine locale id.
  ///
  /// Prefers:
  /// - `en_US`
  /// - `fr_FR`
  /// - `ar_TN`
  /// - Fallback to system default if not found.
  Future<String?> bestLocaleFor(String appLang) async {
    final locales = await getSupportedLocales();
    if (locales.isEmpty) return null;

    // Preferred mapping
    final preferred = <String, String>{
      'fr': 'fr_FR',
      'en': 'en_US',
      'ar': 'ar_TN',
    };

    final target = preferred[appLang];
    if (target == null) return null;

    // Check if preferred is available
    final ids = locales.map((l) => l.localeId).toSet();
    if (ids.contains(target)) return target;

    // Try prefix match (e.g. ar → ar_*)
    try {
      return locales
          .firstWhere((l) => l.localeId.toLowerCase().startsWith(appLang))
          .localeId;
    } catch (_) {
      return null; // Let the engine use system default
    }
  }

  // ── Private Handlers ──

  void _onError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;
  }

  void _onStatus(String status) {
    // Can be used for logging internally.
  }

  // ── Cleanup ──

  Future<void> dispose() async {
    await _speech.cancel();
    _isAvailable = false;
  }
}
