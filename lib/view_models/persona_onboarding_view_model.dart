import 'package:flutter/foundation.dart';
import '../models/persona_model.dart';
import '../services/persona_service.dart';

/// ViewModel for Persona Onboarding flow
/// Manages the 10-question onboarding state and submission
class PersonaOnboardingViewModel extends ChangeNotifier {
  final PersonaService _personaService;
  final String userId;

  PersonaOnboardingViewModel({
    required PersonaService personaService,
    required this.userId,
  }) : _personaService = personaService;

  // Current step (0-9 for 10 questions)
  int _currentStep = 0;

  // User selections
  ProfileType? _selectedProfile;
  ContentGoal? _selectedGoal;
  List<String> _selectedNiches = [];
  String _mainPlatform = '';
  List<String> _selectedPlatforms = [];
  List<ContentStyle> _selectedContentStyles = [];
  ContentTone? _selectedTone;
  List<String> _selectedAudiences = [];
  AudienceAge? _selectedAudienceAge;
  String _language = 'fr';
  List<String> _selectedCTAs = [];

  // State
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _isCompleted = false;

  // Getters
  int get currentStep => _currentStep;
  int get totalSteps => 10;
  double get progress => (_currentStep + 1) / totalSteps;
  bool get isFirstStep => _currentStep == 0;
  bool get isLastStep => _currentStep == totalSteps - 1;

  ProfileType? get selectedProfile => _selectedProfile;
  ContentGoal? get selectedGoal => _selectedGoal;
  List<String> get selectedNiches => _selectedNiches;
  String get mainPlatform => _mainPlatform;
  List<String> get selectedPlatforms => _selectedPlatforms;
  List<ContentStyle> get selectedContentStyles => _selectedContentStyles;
  ContentTone? get selectedTone => _selectedTone;
  List<String> get selectedAudiences => _selectedAudiences;
  AudienceAge? get selectedAudienceAge => _selectedAudienceAge;
  String get language => _language;
  List<String> get selectedCTAs => _selectedCTAs;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isCompleted => _isCompleted;

  // Main Platform options (for Question 3)
  final List<Map<String, String>> mainPlatformOptions = [
    {'value': 'tiktok', 'label': 'TikTok'},
    {'value': 'instagram', 'label': 'Instagram'},
    {'value': 'youtube', 'label': 'YouTube'},
    {'value': 'facebook', 'label': 'Facebook'},
  ];

  // Frequent Platform options (for Question 4)
  final List<Map<String, String>> frequentPlatformOptions = [
    {'value': 'tiktok', 'label': 'TikTok'},
    {'value': 'instagram reels', 'label': 'Instagram Reels'},
    {'value': 'instagram stories', 'label': 'Instagram Stories'},
    {'value': 'youtube shorts', 'label': 'YouTube Shorts'},
    {'value': 'youtube long', 'label': 'YouTube Long'},
    {'value': 'facebook', 'label': 'Facebook'},
  ];

  // Language options
  final List<Map<String, String>> languageOptions = [
    {'value': 'fr', 'label': 'Français'},
    {'value': 'ar', 'label': 'Arabe'},
    {'value': 'en', 'label': 'English'},
    {'value': 'mix', 'label': 'Mixte'},
  ];

  // Navigation methods
  void nextStep() {
    if (_currentStep < totalSteps - 1 && _canProceedFromCurrentStep()) {
      _currentStep++;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalSteps) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // Selection methods
  void selectProfile(ProfileType profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  void selectGoal(ContentGoal goal) {
    _selectedGoal = goal;
    notifyListeners();
  }

  void toggleNiche(String value) {
    if (_selectedNiches.contains(value)) {
      _selectedNiches.remove(value);
    } else {
      _selectedNiches.add(value);
    }
    notifyListeners();
  }

  void selectMainPlatform(String platform) {
    _mainPlatform = platform;
    // Auto-add to platforms list if not already there
    if (!_selectedPlatforms.contains(platform)) {
      _selectedPlatforms.add(platform);
    }
    notifyListeners();
  }

  void togglePlatform(String platform) {
    if (_selectedPlatforms.contains(platform)) {
      _selectedPlatforms.remove(platform);
      // If main platform was removed, clear it
      if (_mainPlatform == platform) {
        _mainPlatform = '';
      }
    } else {
      _selectedPlatforms.add(platform);
    }
    notifyListeners();
  }

  void toggleContentStyle(ContentStyle style) {
    if (_selectedContentStyles.contains(style)) {
      _selectedContentStyles.remove(style);
    } else {
      _selectedContentStyles.add(style);
    }
    notifyListeners();
  }

  void selectTone(ContentTone tone) {
    _selectedTone = tone;
    notifyListeners();
  }

  void toggleAudience(String value) {
    if (_selectedAudiences.contains(value)) {
      _selectedAudiences.remove(value);
    } else {
      _selectedAudiences.add(value);
    }
    notifyListeners();
  }

  void selectAudienceAge(AudienceAge age) {
    _selectedAudienceAge = age;
    notifyListeners();
  }

  void selectLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleCta(String value) {
    if (_selectedCTAs.contains(value)) {
      _selectedCTAs.remove(value);
    } else {
      _selectedCTAs.add(value);
    }
    notifyListeners();
  }

  // Validation
  bool _canProceedFromCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedProfile != null;
      case 1:
        return _selectedGoal != null;
      case 2:
        return _selectedNiches.isNotEmpty;
      case 3:
        return _mainPlatform.isNotEmpty;
      case 4:
        return _selectedPlatforms.isNotEmpty;
      case 5:
        return _selectedContentStyles.isNotEmpty;
      case 6:
        return _selectedTone != null;
      case 7:
        return _selectedAudiences.isNotEmpty;
      case 8:
        return _selectedAudienceAge != null;
      case 9:
        return _language.isNotEmpty && _selectedCTAs.isNotEmpty;
      default:
        return false;
    }
  }

  bool canProceed() {
    return _canProceedFromCurrentStep();
  }

  // Submit persona
  Future<bool> submitPersona() async {
    if (!_canCompleteOnboarding()) {
      _errorMessage = 'Veuillez compléter toutes les étapes';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final persona = PersonaModel(
        userId: userId,
        profile: _selectedProfile!,
        goal: _selectedGoal!,
        niches: _selectedNiches,
        mainPlatform: _mainPlatform,
        platforms: _selectedPlatforms,
        contentStyles: _selectedContentStyles,
        tone: _selectedTone!,
        audiences: _selectedAudiences,
        audienceAge: _selectedAudienceAge!,
        language: _language,
        ctas: _selectedCTAs,
      );

      await _personaService.savePersona(persona);

      _isCompleted = true;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'enregistrement: ${e.toString()}';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  bool _canCompleteOnboarding() {
    return _selectedProfile != null &&
        _selectedGoal != null &&
        _selectedNiches.isNotEmpty &&
        _mainPlatform.isNotEmpty &&
        _selectedPlatforms.isNotEmpty &&
        _selectedContentStyles.isNotEmpty &&
        _selectedTone != null &&
        _selectedAudiences.isNotEmpty &&
        _selectedAudienceAge != null &&
        _language.isNotEmpty &&
        _selectedCTAs.isNotEmpty;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _currentStep = 0;
    _selectedProfile = null;
    _selectedGoal = null;
    _selectedNiches = [];
    _mainPlatform = '';
    _selectedPlatforms = [];
    _selectedContentStyles = [];
    _selectedTone = null;
    _selectedAudiences = [];
    _selectedAudienceAge = null;
    _language = 'fr';
    _selectedCTAs = [];
    _isSubmitting = false;
    _errorMessage = null;
    _isCompleted = false;
    notifyListeners();
  }

}
