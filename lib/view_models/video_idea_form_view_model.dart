import 'package:flutter/foundation.dart';
import '../models/video_generator_models.dart';
import '../services/video_generator_service.dart';
import '../core/api_config.dart';

/// ViewModel for the Video Ideas Form Screen
/// Manages form state, validation, and data transformation
class VideoIdeaFormViewModel extends ChangeNotifier {
  // Form fields
  String _productName = '';
  String _productCategory = '';
  String _targetAudience = '';
  String _keyBenefits = '';
  String _price = '';
  String _offer = '';
  String _painPoint = '';

  // Enhanced fields
  String? _productImagePath;
  String _ingredients = '';
  String _productFeatures = '';
  String _useCases = '';
  String _ageRange = '';
  String _uniqueSellingPoint = '';
  String _socialProof = '';

  // Enum selections
  Platform _selectedPlatform = Platform.tikTok;
  DurationOption _selectedDuration = DurationOption.s30;
  VideoGoal _selectedGoal = VideoGoal.sellProduct;
  VideoTone _selectedTone = VideoTone.trendy;
  VideoLanguage _selectedLanguage = VideoLanguage.french;

  // Generation mode (AI backend vs local templates)
  bool _useRemoteGeneration = ApiConfig.useRemoteGenerationByDefault;

  // Validation
  String? _validationError;

  // Getters
  String get productName => _productName;
  String get productCategory => _productCategory;
  String get targetAudience => _targetAudience;
  String get keyBenefits => _keyBenefits;
  String get price => _price;
  String get offer => _offer;
  String get painPoint => _painPoint;

  String? get productImagePath => _productImagePath;
  String get ingredients => _ingredients;
  String get productFeatures => _productFeatures;
  String get useCases => _useCases;
  String get ageRange => _ageRange;
  String get uniqueSellingPoint => _uniqueSellingPoint;
  String get socialProof => _socialProof;

  Platform get selectedPlatform => _selectedPlatform;
  DurationOption get selectedDuration => _selectedDuration;
  VideoGoal get selectedGoal => _selectedGoal;
  VideoTone get selectedTone => _selectedTone;
  VideoLanguage get selectedLanguage => _selectedLanguage;

  String? get validationError => _validationError;
  bool get useRemoteGeneration => _useRemoteGeneration;

  // Label mappings for UI
  static const Map<Platform, String> platformLabels = {
    Platform.tikTok: 'TikTok',
    Platform.instagramReels: 'Reels',
    Platform.youTubeShorts: 'Shorts',
    Platform.youTubeLong: 'YouTube',
  };

  static const Map<DurationOption, String> durationLabels = {
    DurationOption.s15: '15s',
    DurationOption.s30: '30s',
    DurationOption.s60: '60s',
    DurationOption.s90: '90s',
  };

  static const Map<VideoTone, String> toneLabels = {
    VideoTone.trendy: 'Tendance',
    VideoTone.professional: 'Pro',
    VideoTone.emotional: 'Émotionnel',
    VideoTone.funny: 'Drôle',
    VideoTone.luxury: 'Luxe',
    VideoTone.directResponse: 'Vente',
  };

  static const Map<VideoGoal, String> goalLabels = {
    VideoGoal.sellProduct: 'Vendre',
    VideoGoal.brandAwareness: 'Notoriété',
    VideoGoal.ugcReview: 'Avis UGC',
    VideoGoal.education: 'Éducatif',
    VideoGoal.viralEngagement: 'Viral',
    VideoGoal.offerPromo: 'Promo',
  };

  final VideoIdeaGeneratorService _service;
  bool _isAnalyzing = false;

  VideoIdeaFormViewModel({
    required VideoIdeaGeneratorService service,
  }) : _service = service;

  bool get isAnalyzing => _isAnalyzing;

  // Update methods
  void updateProductName(String value) {
    _productName = value;
    _clearValidationError();
    notifyListeners();
  }

  void updateProductCategory(String value) {
    _productCategory = value;
    notifyListeners();
  }

  void updateTargetAudience(String value) {
    _targetAudience = value;
    notifyListeners();
  }

  void updateKeyBenefits(String value) {
    _keyBenefits = value;
    notifyListeners();
  }

  void updatePrice(String value) {
    _price = value;
    notifyListeners();
  }

  void updateOffer(String value) {
    _offer = value;
    notifyListeners();
  }

  void updatePainPoint(String value) {
    _painPoint = value;
    notifyListeners();
  }

  void updateProductImagePath(String? path) {
    _productImagePath = path;
    notifyListeners();
    
    if (path != null) {
      analyzeProductImage();
    }
  }

  Future<void> analyzeProductImage() async {
    if (_productImagePath == null) return;
    
    _isAnalyzing = true;
    notifyListeners();
    
    try {
      final suggestions = await _service.analyzeImage(_productImagePath!);
      
      if (suggestions.containsKey('productName')) {
        _productName = suggestions['productName'];
      }
      if (suggestions.containsKey('productCategory')) {
        _productCategory = suggestions['productCategory'];
      }
      if (suggestions.containsKey('keyBenefits')) {
        _keyBenefits = (suggestions['keyBenefits'] as List).join(', ');
      }
      if (suggestions.containsKey('targetAudience')) {
        _targetAudience = suggestions['targetAudience'];
      }
      if (suggestions.containsKey('painPoint')) {
        _painPoint = suggestions['painPoint'];
      }
      if (suggestions.containsKey('offer')) {
        _offer = suggestions['offer'];
      }
      if (suggestions.containsKey('price')) {
        _price = suggestions['price'];
      }
      
    } catch (e) {
      debugPrint('Error analyzing product image: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void updateIngredients(String value) {
    _ingredients = value;
    notifyListeners();
  }

  void updateProductFeatures(String value) {
    _productFeatures = value;
    notifyListeners();
  }

  void updateUseCases(String value) {
    _useCases = value;
    notifyListeners();
  }

  void updateAgeRange(String value) {
    _ageRange = value;
    notifyListeners();
  }

  void updateUniqueSellingPoint(String value) {
    _uniqueSellingPoint = value;
    notifyListeners();
  }

  void updateSocialProof(String value) {
    _socialProof = value;
    notifyListeners();
  }

  void selectPlatform(Platform platform) {
    _selectedPlatform = platform;
    notifyListeners();
  }

  void selectDuration(DurationOption duration) {
    _selectedDuration = duration;
    notifyListeners();
  }

  void selectGoal(VideoGoal goal) {
    _selectedGoal = goal;
    notifyListeners();
  }

  void selectTone(VideoTone tone) {
    _selectedTone = tone;
    notifyListeners();
  }

  void selectLanguage(VideoLanguage language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void toggleGenerationMode(bool useRemote) {
    _useRemoteGeneration = useRemote;
    notifyListeners();
  }

  // Validation
  bool canGenerate() {
    return _productName.trim().isNotEmpty;
  }

  String? validateForm() {
    if (_productName.trim().isEmpty) {
      _validationError = 'Le nom du produit est requis';
      notifyListeners();
      return _validationError;
    }

    _validationError = null;
    return null;
  }

  void _clearValidationError() {
    if (_validationError != null) {
      _validationError = null;
    }
  }

  // Build VideoRequest from form data
  VideoRequest buildRequest() {
    // Parse key benefits (comma-separated)
    final List<String> benefits = _keyBenefits
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Parse ingredients (comma-separated)
    final List<String>? ingredientsList = _ingredients.trim().isEmpty
        ? null
        : _ingredients
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    // Parse product features (comma-separated)
    final List<String>? featuresList = _productFeatures.trim().isEmpty
        ? null
        : _productFeatures
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return VideoRequest(
      platform: _selectedPlatform,
      duration: _selectedDuration,
      goal: _selectedGoal,
      creatorType: CreatorType.ecommerceBrand, // Default
      tone: _selectedTone,
      language: _selectedLanguage,
      productName: _productName.trim(),
      productCategory: _productCategory.trim().isEmpty
          ? 'Général'
          : _productCategory.trim(),
      keyBenefits: benefits.isEmpty ? ['Avantages'] : benefits,
      targetAudience: _targetAudience.trim().isEmpty
          ? 'Tout le monde'
          : _targetAudience.trim(),
      price: _price.trim().isEmpty ? null : _price.trim(),
      offer: _offer.trim().isEmpty ? null : _offer.trim(),
      painPoint: _painPoint.trim().isEmpty ? null : _painPoint.trim(),
      batchSize: 5,
      productImagePath: _productImagePath,
      ingredients: ingredientsList,
      productFeatures: featuresList,
      useCases: _useCases.trim().isEmpty ? null : _useCases.trim(),
      ageRange: _ageRange.trim().isEmpty ? null : _ageRange.trim(),
      uniqueSellingPoint:
          _uniqueSellingPoint.trim().isEmpty ? null : _uniqueSellingPoint.trim(),
      socialProof: _socialProof.trim().isEmpty ? null : _socialProof.trim(),
    );
  }

  // Reset form to initial state
  void resetForm() {
    _productName = '';
    _productCategory = '';
    _targetAudience = '';
    _keyBenefits = '';
    _price = '';
    _offer = '';
    _painPoint = '';
    _productImagePath = null;
    _ingredients = '';
    _productFeatures = '';
    _useCases = '';
    _ageRange = '';
    _uniqueSellingPoint = '';
    _socialProof = '';
    _selectedPlatform = Platform.tikTok;
    _selectedDuration = DurationOption.s30;
    _selectedGoal = VideoGoal.sellProduct;
    _selectedTone = VideoTone.trendy;
    _selectedLanguage = VideoLanguage.french;
    _validationError = null;
    notifyListeners();
  }

  // Suggestion data for autocomplete
  static const List<String> categorySuggestions = [
    'Beauté & Cosmétiques',
    'Santé & Bien-être',
    'Mode & Vêtements',
    'Tech & Électronique',
    'Maison & Déco',
    'Alimentation & Boissons',
    'Sports & Fitness',
    'Enfants & Bébés',
    'Bijoux & Accessoires',
    'Auto & Moto',
  ];

  static const List<String> ageRangeSuggestions = [
    '13-17 ans (Adolescents)',
    '18-24 ans (Jeunes adultes)',
    '25-34 ans (Adultes)',
    '35-44 ans (Adultes établis)',
    '45-54 ans (Adultes matures)',
    '55+ ans (Seniors)',
  ];

  static const List<String> audienceSuggestions = [
    'Étudiants',
    'Jeunes professionnels',
    'Parents',
    'Mamans',
    'Papas',
    'Entrepreneurs',
    'Sportifs',
    'Fashionistas',
    'Tech-savvy',
    'Éco-conscients',
  ];
}
