import 'package:flutter_test/flutter_test.dart';
import 'package:ideaspark/models/video_generator_models.dart';
import 'package:ideaspark/services/video_generator_service.dart';

void main() {
  group('VideoIdeaGeneratorService Tests', () {
    late VideoIdeaGeneratorService service;

    setUp(() {
      service = VideoIdeaGeneratorService();
    });

    test('Should generate requested number of ideas (batch)', () async {
      final request = VideoRequest(
        platform: Platform.tikTok,
        duration: DurationOption.s15,
        goal: VideoGoal.sellProduct,
        creatorType: CreatorType.ecommerceBrand,
        tone: VideoTone.trendy,
        language: VideoLanguage.english,
        productName: "SuperGel",
        productCategory: "Skincare",
        keyBenefits: ["Clears acne", "Glowy skin"],
        targetAudience: "Teens",
        batchSize: 5,
      );

      final ideas = await service.generateIdeas(request, useRemote: false);

      expect(ideas.length, 5);
      expect(ideas.first.scenes.isNotEmpty, true);
    });

    test('Video scenes duration should sum up to total duration', () async {
        final request = VideoRequest(
            platform: Platform.tikTok,
            duration: DurationOption.s15,
            goal: VideoGoal.sellProduct,
            creatorType: CreatorType.ecommerceBrand,
            tone: VideoTone.trendy,
            language: VideoLanguage.english,
            productName: "Test",
            productCategory: "Test",
            keyBenefits: [],
            targetAudience: "Test",
            batchSize: 1,
        );

        final ideas = await service.generateIdeas(request, useRemote: false);
        final idea = ideas.first;
        
        // Calculate total duration from scenes
        int totalDuration = 0;
        // Assuming scenes are sequential and endSec of one is start of next or max
        // In our model we store interval. Logic: (end - start).
        for(var scene in idea.scenes) {
            totalDuration += (scene.endSec - scene.startSec);
        }
        
        expect(totalDuration, 15);
    });
    
    test('Should replace placeholders in generated script', () async {
         final request = VideoRequest(
            platform: Platform.tikTok,
            duration: DurationOption.s15,
            goal: VideoGoal.sellProduct,
            creatorType: CreatorType.ecommerceBrand,
            tone: VideoTone.trendy,
            language: VideoLanguage.english,
            productName: "MagicVacuum",
            productCategory: "Home Appliance",
            keyBenefits: ["Strong suction"],
            targetAudience: "Homeowners",
            batchSize: 1,
        );

        final ideas = await service.generateIdeas(request, useRemote: false);
        final idea = ideas.first;

        // Verify product name is in the script
        expect(idea.script.contains("MagicVacuum"), true);
        // Verify no placeholder brackets remain
        expect(idea.script.contains("[PRODUCT_NAME]"), false);
        expect(idea.script.contains("[PRODUCT_CATEGORY]"), false);
        expect(idea.script.contains("[TARGET_AUDIENCE]"), false);
    });
    
     test('Batch generation should vary hooks/CTAs if possible', () async {
        // We need a request that allows for variation. 
        // With current deterministic logic it iterates through hooks.
         final request = VideoRequest(
            platform: Platform.tikTok,
            duration: DurationOption.s15,
            goal: VideoGoal.sellProduct,
            creatorType: CreatorType.ecommerceBrand,
            tone: VideoTone.trendy,
            language: VideoLanguage.english,
            productName: "Test",
            productCategory: "Test",
            keyBenefits: [],
            targetAudience: "Test",
            batchSize: 2,
        );
        
        final ideas = await service.generateIdeas(request, useRemote: false);
        
        // Hooks might be different
        bool differentHooks = ideas[0].hook != ideas[1].hook;
        expect(differentHooks, true);
    });

  });
}
