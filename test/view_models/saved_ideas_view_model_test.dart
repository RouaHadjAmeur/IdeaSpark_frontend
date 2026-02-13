import 'package:flutter_test/flutter_test.dart';
import 'package:ideaspark/models/video_generator_models.dart';
import 'package:ideaspark/repositories/saved_ideas_repository.dart';
import 'package:ideaspark/view_models/saved_ideas_view_model.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'saved_ideas_view_model_test.mocks.dart';

@GenerateMocks([SavedVideoIdeasRepository])
void main() {
  group('SavedIdeasViewModel', () {
    late SavedIdeasViewModel viewModel;
    late MockSavedVideoIdeasRepository mockRepository;

    setUp(() {
      mockRepository = MockSavedVideoIdeasRepository();
      viewModel = SavedIdeasViewModel(repository: mockRepository);
    });

    test('initial state is correct', () {
      expect(viewModel.savedIdeas, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, null);
      expect(viewModel.hasError, false);
      expect(viewModel.hasSavedIdeas, false);
      expect(viewModel.savedIdeasCount, 0);
    });

    test('loadSavedIdeas sets loading state initially', () async {
      // Arrange
      final testIdeas = _createTestIdeas(2);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);

      // Act
      final loadFuture = viewModel.loadSavedIdeas();

      // Assert - check loading state before await
      expect(viewModel.isLoading, true);

      await loadFuture;
    });

    test('loadSavedIdeas updates savedIdeas list on success', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);

      // Act
      await viewModel.loadSavedIdeas();

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.savedIdeas.length, 3);
      expect(viewModel.errorMessage, null);
      expect(viewModel.hasError, false);
      expect(viewModel.hasSavedIdeas, true);
      expect(viewModel.savedIdeasCount, 3);
    });

    test('loadSavedIdeas handles errors correctly', () async {
      // Arrange
      when(mockRepository.getSavedIdeas())
          .thenThrow(Exception('Test error'));

      // Act
      await viewModel.loadSavedIdeas();

      // Assert
      expect(viewModel.isLoading, false);
      expect(viewModel.savedIdeas, isEmpty);
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, 'Erreur lors du chargement des idées sauvegardées');
    });

    test('saveIdea adds idea to list and returns true on success', () async {
      // Arrange
      final testIdea = _createTestIdea('test_1', 'Test Idea');
      when(mockRepository.saveIdea(any)).thenAnswer((_) async => {});

      // Act
      final result = await viewModel.saveIdea(testIdea);

      // Assert
      expect(result, true);
      expect(viewModel.savedIdeas.length, 1);
      expect(viewModel.savedIdeas.first.id, 'test_1');
      verify(mockRepository.saveIdea(testIdea)).called(1);
    });

    test('saveIdea handles errors and returns false', () async {
      // Arrange
      final testIdea = _createTestIdea('test_1', 'Test Idea');
      when(mockRepository.saveIdea(any)).thenThrow(Exception('Test error'));

      // Act
      final result = await viewModel.saveIdea(testIdea);

      // Assert
      expect(result, false);
      expect(viewModel.savedIdeas, isEmpty);
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, 'Erreur lors de la sauvegarde de l\'idée');
    });

    test('saveIdea does not add duplicate ideas', () async {
      // Arrange
      final testIdea = _createTestIdea('test_1', 'Test Idea');
      when(mockRepository.saveIdea(any)).thenAnswer((_) async => {});

      // Act
      await viewModel.saveIdea(testIdea);
      await viewModel.saveIdea(testIdea); // Try to save again

      // Assert
      expect(viewModel.savedIdeas.length, 1);
      verify(mockRepository.saveIdea(testIdea)).called(2);
    });

    test('removeIdea removes idea from list and returns true on success',
        () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);
      when(mockRepository.removeIdea(any)).thenAnswer((_) async => {});

      await viewModel.loadSavedIdeas();
      expect(viewModel.savedIdeas.length, 3);

      // Act
      final result = await viewModel.removeIdea('idea_1');

      // Assert
      expect(result, true);
      expect(viewModel.savedIdeas.length, 2);
      expect(viewModel.savedIdeas.any((idea) => idea.id == 'idea_1'), false);
      verify(mockRepository.removeIdea('idea_1')).called(1);
    });

    test('removeIdea handles errors and returns false', () async {
      // Arrange
      when(mockRepository.removeIdea(any)).thenThrow(Exception('Test error'));

      // Act
      final result = await viewModel.removeIdea('test_id');

      // Assert
      expect(result, false);
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage, 'Erreur lors de la suppression de l\'idée');
    });

    test('clearAllIdeas clears list and returns true on success', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);
      when(mockRepository.clearAll()).thenAnswer((_) async => {});

      await viewModel.loadSavedIdeas();
      expect(viewModel.savedIdeas.length, 3);

      // Act
      final result = await viewModel.clearAllIdeas();

      // Assert
      expect(result, true);
      expect(viewModel.savedIdeas, isEmpty);
      verify(mockRepository.clearAll()).called(1);
    });

    test('clearAllIdeas handles errors and returns false', () async {
      // Arrange
      when(mockRepository.clearAll()).thenThrow(Exception('Test error'));

      // Act
      final result = await viewModel.clearAllIdeas();

      // Assert
      expect(result, false);
      expect(viewModel.hasError, true);
      expect(viewModel.errorMessage,
          'Erreur lors de la suppression de toutes les idées');
    });

    test('isIdeaSaved returns true for saved idea', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);
      await viewModel.loadSavedIdeas();

      // Act & Assert
      expect(viewModel.isIdeaSaved('idea_0'), true);
      expect(viewModel.isIdeaSaved('idea_1'), true);
      expect(viewModel.isIdeaSaved('idea_2'), true);
    });

    test('isIdeaSaved returns false for non-existent idea', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);
      await viewModel.loadSavedIdeas();

      // Act & Assert
      expect(viewModel.isIdeaSaved('non_existent_id'), false);
    });

    test('getIdeaById returns correct idea', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);
      await viewModel.loadSavedIdeas();

      // Act
      final idea = viewModel.getIdeaById('idea_1');

      // Assert
      expect(idea, isNotNull);
      expect(idea?.id, 'idea_1');
      expect(idea?.title, 'Test Idea 1');
    });

    test('getIdeaById returns null for non-existent id', () async {
      // Arrange
      final testIdeas = _createTestIdeas(3);
      when(mockRepository.getSavedIdeas()).thenAnswer((_) async => testIdeas);
      await viewModel.loadSavedIdeas();

      // Act
      final idea = viewModel.getIdeaById('non_existent_id');

      // Assert
      expect(idea, null);
    });

    test('clearError removes error message', () async {
      // Arrange
      when(mockRepository.getSavedIdeas())
          .thenThrow(Exception('Test error'));
      await viewModel.loadSavedIdeas();

      expect(viewModel.hasError, true);

      // Act
      viewModel.clearError();

      // Assert
      expect(viewModel.hasError, false);
      expect(viewModel.errorMessage, null);
    });
  });
}

// Helper function to create test video ideas
List<VideoIdea> _createTestIdeas(int count) {
  return List.generate(
    count,
    (index) => _createTestIdea('idea_$index', 'Test Idea $index'),
  );
}

VideoIdea _createTestIdea(String id, String title) {
  return VideoIdea(
    id: id,
    versions: [
      VideoVersion(
        title: title,
        hook: 'Test hook',
        script: 'Test script',
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
  );
}
