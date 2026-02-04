import 'package:flutter/foundation.dart';

/// ViewModel for Payment screen.
class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({
    required this.packName,
    required this.credits,
    required this.totalPrice,
  });

  final String packName;
  final String credits;
  final String totalPrice;

  int _selectedMethod = 0; // 0: card, 1: apple/google pay, 2: paypal

  int get selectedMethod => _selectedMethod;

  void setPaymentMethod(int index) {
    if (_selectedMethod != index) {
      _selectedMethod = index;
      notifyListeners();
    }
  }

  Future<bool> confirmPayment() async {
    // In real app: call payment API, then return success/failure
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
