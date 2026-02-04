import 'package:flutter/foundation.dart';

/// Credit pack data for shop.
class CreditPack {
  const CreditPack({
    required this.name,
    required this.credits,
    required this.price,
    required this.description,
    this.popular = false,
  });
  final String name;
  final String credits;
  final String price;
  final String description;
  final bool popular;
}

/// ViewModel for Credits shop and payment.
class CreditsViewModel extends ChangeNotifier {
  int _balance = 1349;

  int get balance => _balance;

  static const List<CreditPack> packs = [
    CreditPack(
      name: 'Pack Pro',
      credits: '500 crédits',
      price: '14,99€',
      description: 'Meilleur rapport qualité-prix',
      popular: true,
    ),
    CreditPack(
      name: 'Pack Débutant',
      credits: '100 crédits',
      price: '4,99€',
      description: 'Idéal pour tester',
    ),
    CreditPack(
      name: 'Pack Expert',
      credits: '1000 crédits',
      price: '24,99€',
      description: 'Pour les créateurs intensifs',
    ),
  ];

  void addCredits(int amount) {
    _balance += amount;
    notifyListeners();
  }
}
