import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class UploadService {
  UploadService._();
  static final UploadService _instance = UploadService._();
  factory UploadService() => _instance;

  final _supabase = Supabase.instance.client;

  Future<String> uploadFile(File file, String fileName) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'messages/${timestamp}_$fileName';

    try {
      print('🚀 UploadService: Uploading to path: $path');
      
      // Ensure the file exists before uploading
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas à l\'emplacement: ${file.path}');
      }

      await _supabase.storage.from('IdeaSpark').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      print('🚀 UploadService: Upload complete, getting public URL');
      final String publicUrl = _supabase.storage.from('IdeaSpark').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      print('❌ UploadService Error: $e');
      if (e.toString().contains('Bucket not found')) {
        throw Exception('Erreur configuration: Le bucket "chat-files" n\'existe pas sur Supabase.');
      }
      rethrow;
    }
  }

  String getFileType(String fileName) {
    final extension = p.extension(fileName).toLowerCase().replaceAll('.', '');
    
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    const audioExtensions = ['m4a', 'mp3', 'ogg', 'wav'];

    if (imageExtensions.contains(extension)) {
      return 'image';
    } else if (audioExtensions.contains(extension)) {
      return 'voice';
    } else {
      return 'file';
    }
  }
}
