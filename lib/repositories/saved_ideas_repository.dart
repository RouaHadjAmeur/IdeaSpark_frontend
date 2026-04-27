import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_generator_models.dart';

class SavedVideoIdeasRepository {
  static const String _storageKey = 'saved_video_ideas';

  Future<void> saveIdea(VideoIdea idea) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList(_storageKey) ?? [];
    
    // Check if already saved to avoid duplicates
    if (savedStrings.any((s) => _getId(s) == idea.id)) {
        return; 
    }

    savedStrings.add(jsonEncode(idea.toJson()));
    await prefs.setStringList(_storageKey, savedStrings);
  }

  Future<List<VideoIdea>> getSavedIdeas() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList(_storageKey) ?? [];
    
    return savedStrings
        .map((s) => VideoIdea.fromJson(jsonDecode(s)))
        .toList();
  }

  Future<void> removeIdea(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedStrings = prefs.getStringList(_storageKey) ?? [];
    
    savedStrings.removeWhere((s) => _getId(s) == id);
    
    await prefs.setStringList(_storageKey, savedStrings);
  }
  
  Future<void> clearAll() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
  }
  
  String _getId(String jsonString) {
      try {
          return jsonDecode(jsonString)['id'];
      } catch (e) {
          return "";
      }
  }
}
