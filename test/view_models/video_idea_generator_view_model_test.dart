import 'package:flutter_test/flutter_test.dart';
import 'package:ideaspark/models/video_generator_models.dart';
import 'package:ideaspark/services/video_generator_service.dart';
import 'package:ideaspark/view_models/video_idea_generator_view_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'video_idea_generator_view_model_test.mocks.dart';

@GenerateMocks([VideoIdeaGeneratorService])
void main() {
  group('VideoIdeaGeneratorViewModel', () {
    late VideoIdeaGeneratorViewModel viewModel;
    late MockVideoIdeaGeneratorService mockService;
    late VideoRequest testRequest;

    setUp(() {
      mockService = MockVideoIdeaGeneratorService();
      viewModel = VideoIdeaGeneratorViewModel(service: mockService);

      testRequest = VideoRequest(
        platform: Platform.tikTok,
        duration: DurationOption.s30,
        goal: VideoGoal.sellProduct,
        creatorType: CreatorType.ecommerceBrand,
        tone: VideoTone.trendy,
        language: VideoLanguage.french,
        productName: 'Test Product',
        productCategory: 'Test Category',
        keyBenefits: ['Fast', 'Reliable'],
        targetAudience: 'Everyone',
        batchSize: 3,
      );
    });

    test('initial state is correct', () {
      expect(viewModel.ideas, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(viewModel.lastRequest, null);
      expect(viewModel.hasError, false);
      expect(viewModel.hasIdeas, false);
      expect(viewModel.ideaCount, 0);
    });

    test('generateIdeas sets loading state initially', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenAnswer((_) async => testIdeas);

      // Act
      final generateFuture = viewModel.generateIdeas(testRequest);

      // Assert - check loading state before await
      expect(viewModel.isLoading, true);

      await generateFuture;
    });

    test('generateIdeas updates ideas list on success', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenAnswer((_) async => testIdeas);

      // Act
      await viewModel.generateIdeas(testRequest);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.ideas.length, 3);
      expect(viewModel.errorMessage, null);
      expect(viewModel.hasError, false);
      expect(viewModel.hasIdeas, true);
      expect(viewModel.ideaCount, 3);
      expect(viewModel.lastRequest, testRequest);
    });

    test('generateIdeas handles errors correctly', () async {
      // Arrange
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenThrow(Exception('Test error'));

      // Act
      await viewModel.generateIdeas(testRequest);

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.ideas, isEmpty);
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage,
          'Une erreur est survenue lors de la génération. Veuillez réessayer.');
    });

    test('regenerateIdeas uses last request', () async {
      // Arrange
      final testIdeas = _createTestIdeas(2);
      final newTestIdeas = _createTestIdeas(3);
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenAnswer((_) async => testIdeas);

      // First generation
      await viewModel.generateIdeas(testRequest);
      expect(viewModel.ideas.length, 2);

      // Setup new ideas for regeneration
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenAnswer((_) async => newTestIdeas);

      // Act
      await viewModel.regenerateIdeas();

      // Assert
      expect(viewModel.ideas.length, 3);
      verify(mockService.generateIdeas(testRequest, useRemote: false)).called(2);
    });

    test('regenerateIdeas sets error when no last request exists', () async {
      // Act
      await viewModel.regenerateIdeas();

      // Assert
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, 'Aucune requête précédente trouvée');
    });

    test('clearError removes error message', () async {
      // Arrange
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenThrow(Exception('Test error'));
      await viewModel.generateIdeas(testRequest);

      expect(viewModel.hasError, true);

      // Act
      viewModel.clearError();

      // Assert
      expect(viewModel.hasError, false);
      expect(viewModel.errorMessage, null);
    });

    test('clearIdeas resets all state', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenAnswer((_) async => testIdeas);
      await viewModel.generateIdeas(testRequest);

      // Act
      viewModel.clearIdeas();

      // Assert
      expect(viewModel.ideas, isEmpty);
      expect(viewModel.lastRequest, null);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
    });

    test('getIdeaById returns correct idea', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenAnswer((_) async => testIdeas);
      await viewModel.generateIdeas(testRequest);

      // Act
      final idea = viewModel.getIdeaById('idea_1');

      // Assert
      expect(idea, isNotNull);
      expect(idea?.id, 'idea_1');
    });

    test('getIdeaById returns null for non-existent id', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockService.generateIdeas(any, useRemote: anyNamed('useRemote')))
          .thenAnswer((_) async => testIdeas);
      await viewModel.generateIdeas(testRequest);

      // Act
      final idea = viewModel.getIdeaById('non_existent_id');

      // Assert
      expect(idea, null);
    });

    test('generateIdeas with useRemote=true passes parameter to service',
        () async {
      // Arrange
      final testIdeas = _createTestIdeas(1);
      when(mockService.generateIdeas(any, useRemote: true))
          .thenAnswer((_) async => testIdeas);

      // Act
      await viewModel.generateIdeas(testRequest, useRemote: true);

      // Assert
      verify(mockService.generateIdeas(testRequest, useRemote: true)).called(1);
    });
  });
}

// Helper function to create test video ideas
List<VideoIdea> _createTestIdeas(int count) {
  return List.generate(
    count,
    (index) => VideoIdea(
      id: 'idea_$index',
      versions: [
        VideoVersion(
          title: 'Test Idea $index',
          hook: 'Test hook $index',
          script: 'Test script $index',
          scenes: [
            VideoScene(
              startSec: 0,
              endSec: 5,
              shotType: SceneType.aRoll,
              description: 'Scene description',
              onScreenText: 'On screen text',
              voiceOver: 'Voice over',
            ),
          ],
          cta: 'Test CTA',
          caption: 'Test caption',
          hashtags: ['#test', '#idea'],
          thumbnailText: 'Thumbnail',
          filmingNotes: 'Filming notes',
          complianceNote: 'Compliance note',
          suggestedLocations: [],
          locationHooks: [],
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
    ),
  );
}
