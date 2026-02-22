import 'package:flutter/material.dart';
import '../models/brand.dart';
import '../services/brand_service.dart';

class BrandViewModel extends ChangeNotifier {
  List<Brand> _brands = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  List<Brand> get brands => _brands;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  Future<void> loadBrands() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _brands = await BrandService.getBrands();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Brand?> createBrand(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final brand = await BrandService.createBrand(data);
      _brands.insert(0, brand);
      return brand;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<Brand?> updateBrand(String id, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await BrandService.updateBrand(id, data);
      final idx = _brands.indexWhere((b) => b.id == id);
      if (idx >= 0) _brands[idx] = updated;
      return updated;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBrand(String id) async {
    _error = null;
    try {
      await BrandService.deleteBrand(id);
      _brands.removeWhere((b) => b.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
