import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/challenge_service.dart';
import '../models/challenge.dart';
import '../models/submission.dart';

class ChallengeViewModel extends ChangeNotifier {
  final ChallengeService _service = ChallengeService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<Challenge> _availableChallenges = [];
  List<Challenge> get availableChallenges => _availableChallenges;

  List<Challenge> _brandCampaigns = [];
  List<Challenge> get brandCampaigns => _brandCampaigns;

  List<Submission> _currentSubmissions = [];
  List<Submission> get currentSubmissions => _currentSubmissions;

  List<Submission> _mySubmissions = [];
  List<Submission> get mySubmissions => _mySubmissions;

  Map<String, dynamic>? _challengeStats;
  Map<String, dynamic>? get challengeStats => _challengeStats;

  // ── Creator Actions ──────────────────────────────────────────────────────

  Future<void> loadDiscoverChallenges() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _availableChallenges = await _service.discoverChallenges();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMySubmissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _mySubmissions = await _service.getMySubmissions();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSubmission(String submissionId, File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _service.updateSubmission(submissionId, file);
      final index = _mySubmissions.indexWhere((s) => s.id == submissionId);
      if (index != -1) {
        _mySubmissions[index] = updated;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitVideo(String challengeId, String videoPath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.submitVideo(challengeId, videoPath);
      // Refresh available challenges to update submission count if needed
      await loadDiscoverChallenges();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Brand Owner Actions ──────────────────────────────────────────────────

  Future<void> loadBrandChallenges(String brandId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _brandCampaigns = await _service.getBrandChallenges(brandId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubmissions(String challengeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentSubmissions = await _service.getChallengeSubmissions(challengeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> publishChallenge(String id, String brandId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.publishChallenge(id);
      await loadBrandChallenges(brandId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Challenge> createChallenge(Map<String, dynamic> data, String brandId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['brandId'] = brandId;
      final challenge = await _service.createChallenge(payload);
      await loadBrandChallenges(brandId);
      return challenge;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBrandStats(String brandId) async {
    try {
      _challengeStats = await _service.getBrandStats(brandId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> shortlist(String submissionId, String challengeId, bool shortlisted) async {
    try {
      await _service.shortlistSubmission(submissionId, shortlisted);
      await loadSubmissions(challengeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> declareWinner(String submissionId, String challengeId, String brandId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.declareWinner(submissionId);
      await loadSubmissions(challengeId);
      await loadBrandChallenges(brandId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestRevision(String submissionId, String challengeId, String feedback) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.requestRevision(submissionId, feedback);
      await loadSubmissions(challengeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rateSubmission(String submissionId, String challengeId, int rating) async {
    try {
      await _service.rateSubmission(submissionId, rating);
      await loadSubmissions(challengeId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
