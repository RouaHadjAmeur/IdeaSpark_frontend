import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

/// ViewModel for Splash screen.
/// Determines next route based on onboarding and auth state.
class SplashViewModel extends ChangeNotifier {
  SplashViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool _isChecking = true;

  bool get isChecking => _isChecking;

  /// Returns the route to navigate to: '/onboarding', '/login', or '/home'.
  Future<String> getNextRoute() async {
    _isChecking = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    final onboardingDone = await _authService.isOnboardingDone();
    final loggedIn = await _authService.isLoggedIn();
    _isChecking = false;
    notifyListeners();
    if (!onboardingDone) {
      return '/onboarding';
    }
    if (!loggedIn) {
      return '/login';
    }
    return '/home';
  }
}
