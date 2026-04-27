import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class VoiceRecorderService {
  VoiceRecorderService._();
  static final VoiceRecorderService _instance = VoiceRecorderService._();
  factory VoiceRecorderService() => _instance;

  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory tempDir = await getTemporaryDirectory();
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String filePath = p.join(tempDir.path, 'voice_$timestamp.m4a');

        const config = RecordConfig();
        await _audioRecorder.start(config, path: filePath);
        print('🎙️ Recording started: $filePath');
      } else {
        print('❌ Microphone permission denied');
      }
    } catch (e) {
      print('❌ Error starting recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      final String? path = await _audioRecorder.stop();
      print('🛑 Recording stopped: $path');
      return path;
    } catch (e) {
      print('❌ Error stopping recording: $e');
      return null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
