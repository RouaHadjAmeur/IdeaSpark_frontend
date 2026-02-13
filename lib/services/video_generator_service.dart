import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/video_generator_models.dart';
import '../data/libraries.dart';
import '../data/remote_data_source.dart';
import '../core/api_config.dart';

class VideoIdeaGeneratorService {
  final VideoGeneratorRemoteDataSource _remoteDataSource;

  VideoIdeaGeneratorService({
    VideoGeneratorRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? VideoGeneratorRemoteDataSource();

  
  Future<List<VideoIdea>> generateIdeas(
    VideoRequest request, {
    bool? useRemote,
  }) async {
    final shouldUseRemote = useRemote ?? ApiConfig.useRemoteGenerationByDefault;

    if (shouldUseRemote) {
      try {
        debugPrint('🚀 Generating ideas using Gemini backend...');
        final ideas = await _remoteDataSource.generateIdeas(request);
        debugPrint('✅ Successfully generated ${ideas.length} ideas from Gemini');
        return ideas;
      } catch (e) {
        debugPrint('❌ Remote generation failed: $e');

        if (ApiConfig.fallbackToLocalOnError) {
          debugPrint('⚠️ Falling back to local generation...');
          return _generateLocal(request);
        } else {
          rethrow;
        }
      }
    }

    debugPrint('🏠 Generating ideas using local templates...');
    return _generateLocal(request);
  }

  Future<Map<String, dynamic>> analyzeImage(String imagePath) async {
    return _remoteDataSource.analyzeImage(imagePath);
  }

  Future<VideoIdea> refineIdea(String ideaId, String instruction) async {
    return _remoteDataSource.refineIdea(ideaId, instruction);
  }

  Future<VideoIdea> approveVersion(String ideaId, int versionIndex) async {
    return _remoteDataSource.approveVersion(ideaId, versionIndex);
  }

  Future<VideoIdea> saveIdea(VideoIdea idea) async {
    return _remoteDataSource.saveIdea(idea);
  }

  Future<List<VideoIdea>> getHistory() async {
    return _remoteDataSource.getHistory();
  }

  Future<List<VideoIdea>> getFavorites() async {
    return _remoteDataSource.getFavorites();
  }

  Future<VideoIdea> toggleFavorite(String id) async {
    return _remoteDataSource.toggleFavorite(id);
  }

  Future<void> deleteIdea(String id) async {
    return _remoteDataSource.deleteIdea(id);
  }

  List<VideoIdea> _generateLocal(VideoRequest request) {
    final List<VideoIdea> ideas = [];
    final Random random = Random();

    // specific lists for this request
    List<String> availableHooks =
        ContentLibraries.hooks[request.language] ?? [];
    List<String> availableCTAs = ContentLibraries.ctas[request.language] ?? [];
    
    // Shuffle to ensure randomness in batch, but we could seed if we wanted strict determinism across app restarts (not required here)
    List<String> shuffledHooks = List.from(availableHooks)..shuffle(random);
    List<String> shuffledCTAs = List.from(availableCTAs)..shuffle(random);

    for (int i = 0; i < request.batchSize; i++) {
        // Fallback if we run out of unique hooks
      String rawHook = shuffledHooks[i % shuffledHooks.length];
      String rawCTA = shuffledCTAs[i % shuffledCTAs.length];

         
   
      
      Map<DurationOption, List<VideoScene>> result = ContentLibraries.getTemplates(duration: request.duration);
      List<VideoScene> scenesTemplate = result[request.duration] ?? [];
      
      // We need to DEEP COPY the scenes because we are going to modify them
      // (replacing placeholders). If we just reference, we modify the static definition.
      List<VideoScene> processedScenes = scenesTemplate.map((s) => VideoScene(
        startSec: s.startSec,
        endSec: s.endSec,
        shotType: s.shotType,
        description: s.description,
        onScreenText: _processText(s.onScreenText, request, rawHook, rawCTA),
        voiceOver: _processText(s.voiceOver, request, rawHook, rawCTA),
      )).toList();

      String title = _generateTitle(request, rawHook);
      String fullScript = processedScenes.map((s) => "(${s.startSec}-${s.endSec}s) ${s.shotType.name}: ${s.voiceOver}").join("\n\n");

      ideas.add(VideoIdea(
        id: "${DateTime.now().millisecondsSinceEpoch}_$i",
        versions: [
          VideoVersion(
            title: title,
            hook: _processText(rawHook, request, rawHook, rawCTA),
            script: fullScript,
            scenes: processedScenes,
            cta: _processText(rawCTA, request, rawHook, rawCTA),
            caption: _generateCaption(request),
            hashtags: _generateHashtags(request),
            thumbnailText: _generateThumbnailText(request, rawHook),
            filmingNotes: _generateFilmingNotes(request),
            complianceNote: _generateComplianceNote(request),
            suggestedLocations: [],
            locationHooks: [],
            createdAt: DateTime.now(),
          )
        ],
        createdAt: DateTime.now(),
      ));
    }

    return ideas;
  }

  String _processText(String template, VideoRequest request, String hook, String cta) {
    String text = template;
    
    // Core replacements
    text = text.replaceAll("[PRODUCT_NAME]", request.productName);
    text = text.replaceAll("[PRODUCT_CATEGORY]", request.productCategory);
    text = text.replaceAll("[PAIN_POINT]", request.painPoint ?? "this problem");
    text = text.replaceAll("[BENEFIT]", request.keyBenefits.isNotEmpty ? request.keyBenefits.first : "great results");
    text = text.replaceAll("[TARGET_AUDIENCE]", request.targetAudience);
    text = text.replaceAll("[OFFER]", request.offer ?? "a great deal");
    text = text.replaceAll("[BRAND_NAME]", "Brand"); // Could add to request if needed
    
    // Dynamic parts from the specific selection
    // Be careful not to replace [HOOK] with text containing [HOOK] (infinite recursion if we were recursive, but we are sequential)
    // We process the hook text ITSELF before inserting it to ensure it doesn't contain placeholders.
    // BUT, the hook itself is a template from the library ("Stop scrolling if you want [BENEFIT]").
    // So we must process the hook template first.
    
    String processedHook = _processSimple(hook, request);
    String processedCTA = _processSimple(cta, request);
    
    text = text.replaceAll("[HOOK]", processedHook); 
    text = text.replaceAll("[HOOK_TEXT]", processedHook); 
    text = text.replaceAll("[CTA]", processedCTA);
    text = text.replaceAll("[CTA_TEXT]", processedCTA);

    // Handle multiple benefits if referenced (e.g., [BENEFIT_1])
    if (request.keyBenefits.isNotEmpty) {
        text = text.replaceAll("[BENEFIT_1]", request.keyBenefits[0]);
        if (request.keyBenefits.length > 1) {
            text = text.replaceAll("[BENEFIT_2]", request.keyBenefits[1]);
        } else {
             text = text.replaceAll("[BENEFIT_2]", "more");
        }
    }
    
    // Apply Tone (Simple Logic for now)
    text = _applyTone(text, request.tone);

    return text;
  }
  
  // Process placeholders inside a hook or CTA string (which don't contain [HOOK] or [CTA])
  String _processSimple(String text, VideoRequest request) {
     String t = text;
     t = t.replaceAll("[PRODUCT_NAME]", request.productName);
     t = t.replaceAll("[PRODUCT_CATEGORY]", request.productCategory);
     t = t.replaceAll("[PAIN_POINT]", request.painPoint ?? "this problem");
     t = t.replaceAll("[BENEFIT]", request.keyBenefits.isNotEmpty ? request.keyBenefits.first : "great results");
     t = t.replaceAll("[TARGET_AUDIENCE]", request.targetAudience);
     t = t.replaceAll("[OFFER]", request.offer ?? "a great deal");
     return t;
  }

  String _applyTone(String text, VideoTone tone) {
    // In a real app, this might use an AI rewritter or dictionary.
    // Here we use simple affixes or adjustments.
    switch (tone) {
      case VideoTone.trendy:
        // Add emojis or slang if not present
        if (!text.contains("🔥")) return "$text 🔥";
        return text;
      case VideoTone.funny:
        if (!text.contains("😂")) return "$text 😂";
        return text;
      case VideoTone.luxury:
        return text.replaceAll("great", "exquisite").replaceAll("good", "premium").replaceAll("best", "finest");
      case VideoTone.directResponse:
        return text; // keep it punchy, maybe uppercase specific keywords in a refined version
      case VideoTone.emotional:
        // Prefix/Suffix?
        return text; 
      case VideoTone.professional:
        return text;
    }
  }

  String _generateTitle(VideoRequest request, String hook) {
    return "Video Idea: ${_processSimple(hook, request)}";
  }

  String _generateCaption(VideoRequest request) {
    String base = "Check out ${request.productName}! It's perfect for ${request.targetAudience}.";
    if (request.offer != null) {
        base += " Grab it now and get ${request.offer}.";
    }
    return base;
  }

  List<String> _generateHashtags(VideoRequest request) {
    // Basic generation
    List<String> tags = [
      "#${request.productName.replaceAll(' ', '')}",
      "#${request.productCategory.replaceAll(' ', '')}",
      "#fyp", 
      "#trending"
    ];
    if (request.platform == Platform.tikTok) tags.add("#tiktokmademebuyit");
    if (request.platform == Platform.instagramReels) tags.add("#reelsinstagram");
    return tags;
  }
  
  String _generateThumbnailText(VideoRequest request, String hook) {
      // Shorten hook for thumbnail
      String h = _processSimple(hook, request);
      if (h.length > 20) {
          return "${h.substring(0, 20)}...";
      }
      return h;
  }
  
  String _generateFilmingNotes(VideoRequest request) {
      return "Ensure good lighting. Keep the product in focus. Speak clearly.";
  }
  
  String _generateComplianceNote(VideoRequest request) {
      if (request.productCategory.toLowerCase().contains("skin") || 
          request.productCategory.toLowerCase().contains("health") ||
          request.productCategory.toLowerCase().contains("supplement")) {
          return "Disclaimer: Results may vary. Not medical advice.";
      }
      return "Ensure all claims are accurate.";
  }

}
