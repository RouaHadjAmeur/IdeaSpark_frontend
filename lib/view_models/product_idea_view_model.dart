import 'package:flutter/material.dart';
import '../models/product_idea_model.dart';
import '../services/product_idea_service.dart';

class ProductIdeaViewModel extends ChangeNotifier {
  ProductIdeaResult? _idea;
  bool _isLoading = false;
  String? _error;

  ProductIdeaResult? get idea => _idea;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> generateProductIdea({
    required String besoin,
    double? temperature,
    int? maxTokens,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _idea = await ProductIdeaService.generateProductIdea(
        besoin: besoin,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _idea = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _idea = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
