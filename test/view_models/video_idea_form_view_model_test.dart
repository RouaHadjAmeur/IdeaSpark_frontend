import 'package:flutter_test/flutter_test.dart';
import 'package:ideaspark/models/video_generator_models.dart';
import 'package:ideaspark/services/video_generator_service.dart';
import 'package:ideaspark/view_models/video_idea_form_view_model.dart';
import 'package:mockito/annotations.dart';

import 'video_idea_form_view_model_test.mocks.dart';

@GenerateMocks([VideoIdeaGeneratorService])
void main() {
  group('VideoIdeaFormViewModel', () {
    late VideoIdeaFormViewModel viewModel;
    late MockVideoIdeaGeneratorService mockService;

    setUp(() {
      mockService = MockVideoIdeaGeneratorService();
      viewModel = VideoIdeaFormViewModel(service: mockService);
    });

    test('initial state is correct', () {
      expect(viewModel.productName, '');
      expect(viewModel.productCategory, '');
      expect(viewModel.targetAudience, '');
      expect(viewModel.keyBenefits, '');
      expect(viewModel.price, '');
      expect(viewModel.offer, '');
      expect(viewModel.painPoint, '');
      expect(viewModel.selectedPlatform, Platform.tikTok);
      expect(viewModel.selectedDuration, DurationOption.s30);
      expect(viewModel.selectedGoal, VideoGoal.sellProduct);
      expect(viewModel.selectedTone, VideoTone.trendy);
      expect(viewModel.selectedLanguage, VideoLanguage.french);
      expect(viewModel.validationError, null);
      expect(viewModel.canGenerate(), false);
    });

    test('canGenerate returns false when product name is empty', () {
      viewModel.updateProductName('');
      expect(viewModel.canGenerate(), false);
    });

    test('canGenerate returns true when product name is not empty', () {
      viewModel.updateProductName('Test Product');
      expect(viewModel.canGenerate(), true);
    });

    test('updateProductName updates the product name', () {
      viewModel.updateProductName('Super Product');
      expect(viewModel.productName, 'Super Product');
    });

    test('updateProductCategory updates the category', () {
      viewModel.updateProductCategory('Beauty');
      expect(viewModel.productCategory, 'Beauty');
    });

    test('updateTargetAudience updates the target audience', () {
      viewModel.updateTargetAudience('Students');
      expect(viewModel.targetAudience, 'Students');
    });

    test('selectPlatform updates the selected platform', () {
      viewModel.selectPlatform(Platform.youTubeShorts);
      expect(viewModel.selectedPlatform, Platform.youTubeShorts);
    });

    test('selectDuration updates the selected duration', () {
      viewModel.selectDuration(DurationOption.s60);
      expect(viewModel.selectedDuration, DurationOption.s60);
    });

    test('selectGoal updates the selected goal', () {
      viewModel.selectGoal(VideoGoal.brandAwareness);
      expect(viewModel.selectedGoal, VideoGoal.brandAwareness);
    });

    test('selectTone updates the selected tone', () {
      viewModel.selectTone(VideoTone.professional);
      expect(viewModel.selectedTone, VideoTone.professional);
    });

    test('validateForm returns error when product name is empty', () {
      final error = viewModel.validateForm();
      expect(error, isNotNull);
      expect(error, 'Le nom du produit est requis');
      expect(viewModel.validationError, 'Le nom du produit est requis');
    });

    test('validateForm returns null when product name is provided', () {
      viewModel.updateProductName('Test Product');
      final error = viewModel.validateForm();
      expect(error, null);
      expect(viewModel.validationError, null);
    });

    test('buildRequest creates correct VideoRequest with minimal data', () {
      viewModel.updateProductName('Test Product');

      final request = viewModel.buildRequest();

      expect(request.productName, 'Test Product');
      expect(request.productCategory, 'Général');
      expect(request.targetAudience, 'Tout le monde');
      expect(request.platform, Platform.tikTok);
      expect(request.duration, DurationOption.s30);
      expect(request.goal, VideoGoal.sellProduct);
      expect(request.tone, VideoTone.trendy);
      expect(request.language, VideoLanguage.french);
      expect(request.price, null);
      expect(request.offer, null);
      expect(request.painPoint, null);
      expect(request.batchSize, 5);
    });

    test('buildRequest creates correct VideoRequest with full data', () {
      viewModel.updateProductName('Super Product');
      viewModel.updateProductCategory('Tech');
      viewModel.updateTargetAudience('Developers');
      viewModel.updateKeyBenefits('Fast, Reliable, Secure');
      viewModel.updatePrice('99.99€');
      viewModel.updateOffer('-20%');
      viewModel.updatePainPoint('Slow performance');
      viewModel.selectPlatform(Platform.instagramReels);
      viewModel.selectDuration(DurationOption.s60);
      viewModel.selectGoal(VideoGoal.viralEngagement);
      viewModel.selectTone(VideoTone.funny);

      final request = viewModel.buildRequest();

      expect(request.productName, 'Super Product');
      expect(request.productCategory, 'Tech');
      expect(request.targetAudience, 'Developers');
      expect(request.keyBenefits, ['Fast', 'Reliable', 'Secure']);
      expect(request.price, '99.99€');
      expect(request.offer, '-20%');
      expect(request.painPoint, 'Slow performance');
      expect(request.platform, Platform.instagramReels);
      expect(request.duration, DurationOption.s60);
      expect(request.goal, VideoGoal.viralEngagement);
      expect(request.tone, VideoTone.funny);
    });

    test('buildRequest parses key benefits correctly', () {
      viewModel.updateProductName('Product');
      viewModel.updateKeyBenefits('Benefit1, Benefit2 , Benefit3');

      final request = viewModel.buildRequest();

      expect(request.keyBenefits, ['Benefit1', 'Benefit2', 'Benefit3']);
    });

    test('buildRequest handles empty key benefits', () {
      viewModel.updateProductName('Product');
      viewModel.updateKeyBenefits('');

      final request = viewModel.buildRequest();

      expect(request.keyBenefits, ['Avantages']);
    });

    test('resetForm resets all fields to initial state', () {
      // Set some values
      viewModel.updateProductName('Product');
      viewModel.updateProductCategory('Category');
      viewModel.selectPlatform(Platform.youTubeLong);
      viewModel.selectTone(VideoTone.luxury);

      // Reset
      viewModel.resetForm();

      // Verify all fields are reset
      expect(viewModel.productName, '');
      expect(viewModel.productCategory, '');
      expect(viewModel.selectedPlatform, Platform.tikTok);
      expect(viewModel.selectedTone, VideoTone.trendy);
      expect(viewModel.canGenerate(), false);
    });

    test('platformLabels returns correct mapping', () {
      final labels = VideoIdeaFormViewModel.platformLabels;
      expect(labels[Platform.tikTok], 'TikTok');
      expect(labels[Platform.instagramReels], 'Reels');
      expect(labels[Platform.youTubeShorts], 'Shorts');
      expect(labels[Platform.youTubeLong], 'YouTube');
    });

    test('durationLabels returns correct mapping', () {
      final labels = VideoIdeaFormViewModel.durationLabels;
      expect(labels[DurationOption.s15], '15s');
      expect(labels[DurationOption.s30], '30s');
      expect(labels[DurationOption.s60], '60s');
      expect(labels[DurationOption.s90], '90s');
    });
  });
}
