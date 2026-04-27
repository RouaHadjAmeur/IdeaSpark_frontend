import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// ViewModel for Onboarding flow.
class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  int _currentPage = 0;
  static const int totalPages = 3;

  int get currentPage => _currentPage;
  int get total => totalPages;

  void setPage(int index) {
    if (_currentPage != index && index >= 0 && index < totalPages) {
      _currentPage = index;
      notifyListeners();
    }
  }

  void nextPage() {
    if (_currentPage < totalPages - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  bool get isLastPage => _currentPage == totalPages - 1;

  Future<void> completeOnboarding() async {
    await _authService.setOnboardingDone();
  }
}
