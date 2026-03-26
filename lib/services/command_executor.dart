import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../models/voice_action.dart';
import '../voice/voice_navigation_handler.dart';

class CommandExecutor {
  final BuildContext context;
  final FlutterTts _tts = FlutterTts();

  CommandExecutor(this.context);

  Future<void> executeActions(List<VoiceAction> actions, String say) async {
    await _tts.speak(say);

    for (final action in actions) {
      await _executeSingleAction(action);
    }
  }

  Future<void> _executeSingleAction(VoiceAction action) async {
    switch (action.intent) {
      case 'NAVIGATE':
        if (action.destination != null) {
          VoiceNavigationHandler.navigate(action.destination!);
        }
        break;

      case 'GO_BACK':
        if (context.canPop()) context.pop();
        break;

      case 'GENERATE_IDEA':
        VoiceNavigationHandler.navigate('GENERATOR');
        break;

      case 'SAVE_IDEA':
      case 'UNSAVE_IDEA':
      case 'READ_IDEA':
      case 'DELETE_IDEA':
        debugPrint('[CommandExecutor] ${action.intent} index=${action.index}');
        // Delegate to the active ViewModel via a shared event bus or provider.
        // Example: context.read<IdeaViewModel>().saveIdea(action.index);
        break;

      default:
        debugPrint('[CommandExecutor] Unknown intent: ${action.intent}');
    }
  }
}
