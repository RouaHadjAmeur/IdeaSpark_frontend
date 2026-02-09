import 'package:flutter/foundation.dart';

/// ViewModel for Criteria / Parameters screen.
class CriteriaViewModel extends ChangeNotifier {
  CriteriaViewModel({String? initialType}) : _type = initialType ?? 'Video Ideas';

  String _type;
  String _niche = '';
  String _audience = 'Étudiants';
  String _platform = 'TikTok';
  String _tone = 'Viral';
  double _creativity = 0.6;

  String get type => _type;
  String get niche => _niche;
  String get audience => _audience;
  String get platform => _platform;
  String get tone => _tone;
  double get creativity => _creativity;

  static const List<String> audienceOptions = ['Étudiants', 'Mamans', 'Entrepreneurs', 'Freelancers'];
  static const List<String> platformOptions = ['TikTok', 'Reels', 'YouTube', 'Shorts'];
  static const List<String> toneOptions = ['Viral', 'Premium', 'Fun', 'Sérieux'];

  void setType(String value) {
    if (_type != value) {
      _type = value;
      notifyListeners();
    }
  }

  void setNiche(String value) {
    if (_niche != value) {
      _niche = value;
      notifyListeners();
    }
  }

  void setAudience(String value) {
    if (_audience != value) {
      _audience = value;
      notifyListeners();
    }
  }

  void setPlatform(String value) {
    if (_platform != value) {
      _platform = value;
      notifyListeners();
    }
  }

  void setTone(String value) {
    if (_tone != value) {
      _tone = value;
      notifyListeners();
    }
  }

  void setCreativity(double value) {
    if (_creativity != value) {
      _creativity = value;
      notifyListeners();
    }
  }

  /// Build type label from typeId (e.g. from home).
  void setTypeFromId(String? typeId) {
    if (typeId == null) return;
    final type = switch (typeId) {
      'business' => 'Business Ideas',
      'video' => 'Video Ideas',
      'product' => 'Product Ideas',
      'slogans' => 'Slogans & Names',
      _ => 'Video Ideas',
    };
    setType(type);
  }
}
