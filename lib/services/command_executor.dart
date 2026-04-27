import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/voice_action.dart';
import '../voice/voice_navigation_handler.dart';
import 'text_to_speech_service.dart';

/// Executes a list of [VoiceAction]s resolved by the backend parser.
///
/// Two construction modes:
///   • [CommandExecutor(context)] — uses a live [BuildContext] for actions
///     that need it (e.g. context.pop). Used by the manual mic-button flow.
///   • [CommandExecutor.noContext()] — uses the global [appRouter] for
///     navigation. Used by [HandsFreeModeController] where no BuildContext
///     is available. This fixes the "No GoRouter found in context" crash.
class CommandExecutor {
  final BuildContext? _context;
  final TextToSpeechService _tts = TextToSpeechService();

  /// Creates an executor bound to a [BuildContext] (manual mic flow).
  CommandExecutor(BuildContext context) : _context = context;

  /// Creates an executor that does NOT require a BuildContext.
  ///
  /// Navigation uses the global [appRouter] instance from [navigation_service.dart].
  CommandExecutor.noContext() : _context = null;

  // ── Context-aware execution (mic button) ──────────────────────────────────

  /// Executes [actions], speaks [say] via TTS, then performs each action.
  /// Requires a valid [BuildContext] — do not use from hands-free controller.
  Future<void> executeActions(List<VoiceAction> actions, String say) async {
    await _tts.speak(say);
    for (final action in actions) {
      await _executeSingleAction(action);
    }
  }

  // ── Context-free execution (hands-free) ───────────────────────────────────

  /// Executes [actions] using the global [appRouter].
  /// Safe to call from any async context without a [BuildContext].
  Future<void> executeActionsNoContext(List<VoiceAction> actions) async {
    for (final action in actions) {
      await _executeSingleAction(action);
    }
  }

  // ── Core action dispatcher ─────────────────────────────────────────────────

  Future<void> _executeSingleAction(VoiceAction action) async {
    switch (action.intent) {
      case 'NAVIGATE':
        if (action.destination != null) {
          VoiceNavigationHandler.navigate(action.destination!);
        }
        break;

      case 'GO_BACK':
        final ctx = _context;
        if (ctx != null && ctx.mounted && ctx.canPop()) {
          ctx.pop();
        } else {
          // Fallback when no context: try canPop via the router delegate.
          final router = VoiceNavigationHandler.routerForBack;
          if (router != null) {
            try {
              router.pop();
            } catch (_) {
              // Silently ignore if nothing to pop.
            }
          }
        }
        break;

      case 'GENERATE_IDEA':
        VoiceNavigationHandler.navigate('GENERATOR');
        break;

      case 'SAVE_IDEA':
      case 'UNSAVE_IDEA':
      case 'READ_IDEA':
      case 'DELETE_IDEA':
        debugPrint('[CommandExecutor] ${action.intent} index=${action.index}');
        // Delegate to active ViewModel via shared event bus or Provider.
        break;

      default:
        debugPrint('[CommandExecutor] Unknown intent: ${action.intent}');
    }
  }
}
