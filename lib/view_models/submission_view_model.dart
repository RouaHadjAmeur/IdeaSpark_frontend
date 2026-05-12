// submission_view_model.dart
// ViewModel for managing submissions

import 'package:flutter/foundation.dart';
import '../models/submission.dart';
import '../services/submission_service.dart';

class SubmissionViewModel extends ChangeNotifier {
  final _service = SubmissionService();

  List<Submission> _submissions = [];
  List<Submission> _pendingSubmissions = [];
  Submission? _currentSubmission;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Submission> get submissions => _submissions;
  List<Submission> get pendingSubmissions => _pendingSubmissions;
  Submission? get currentSubmission => _currentSubmission;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  List<Submission> get approvedSubmissions =>
      _submissions.where((s) => s.status == SubmissionStatus.approved).toList();

  List<Submission> get rejectedSubmissions =>
      _submissions.where((s) => s.status == SubmissionStatus.rejected).toList();

  List<Submission> get publishedSubmissions =>
      _submissions.where((s) => s.status == SubmissionStatus.published).toList();

  // ─── Load Submissions ─────────────────────────────────────────────────────

  Future<void> loadSubmissionsByCampaign(String campaignId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _submissions = await _service.getSubmissionsByCampaign(campaignId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingSubmissions(String campaignId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingSubmissions = await _service.getPendingSubmissions(campaignId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSubmission(String submissionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentSubmission = await _service.getSubmission(submissionId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create Submission ────────────────────────────────────────────────────

  Future<Submission?> createSubmission(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final submission = await _service.createSubmission(data);
      _submissions.add(submission);
      notifyListeners();
      return submission;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Approve Submission ───────────────────────────────────────────────────

  Future<bool> approveSubmission(String submissionId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.approveSubmission(submissionId);
      
      // Update in lists
      final index = _submissions.indexWhere((s) => s.id == submissionId);
      if (index != -1) {
        _submissions[index] = updated;
      }
      
      final index2 = _pendingSubmissions.indexWhere((s) => s.id == submissionId);
      if (index2 != -1) {
        _pendingSubmissions.removeAt(index2);
      }
      
      if (_currentSubmission?.id == submissionId) {
        _currentSubmission = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Reject Submission ────────────────────────────────────────────────────

  Future<bool> rejectSubmission(String submissionId, String feedback) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.rejectSubmission(submissionId, feedback);
      
      // Update in lists
      final index = _submissions.indexWhere((s) => s.id == submissionId);
      if (index != -1) {
        _submissions[index] = updated;
      }
      
      final index2 = _pendingSubmissions.indexWhere((s) => s.id == submissionId);
      if (index2 != -1) {
        _pendingSubmissions.removeAt(index2);
      }
      
      if (_currentSubmission?.id == submissionId) {
        _currentSubmission = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Request Changes ──────────────────────────────────────────────────────

  Future<bool> requestChanges(String submissionId, String feedback) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.requestChanges(submissionId, feedback);
      
      // Update in lists
      final index = _submissions.indexWhere((s) => s.id == submissionId);
      if (index != -1) {
        _submissions[index] = updated;
      }
      
      final index2 = _pendingSubmissions.indexWhere((s) => s.id == submissionId);
      if (index2 != -1) {
        _pendingSubmissions[index2] = updated;
      }
      
      if (_currentSubmission?.id == submissionId) {
        _currentSubmission = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Update Submission ────────────────────────────────────────────────────

  Future<bool> updateSubmission(String submissionId, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateSubmission(submissionId, data);
      
      // Update in lists
      final index = _submissions.indexWhere((s) => s.id == submissionId);
      if (index != -1) {
        _submissions[index] = updated;
      }
      
      if (_currentSubmission?.id == submissionId) {
        _currentSubmission = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Delete Submission ────────────────────────────────────────────────────

  Future<bool> deleteSubmission(String submissionId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteSubmission(submissionId);
      
      _submissions.removeWhere((s) => s.id == submissionId);
      _pendingSubmissions.removeWhere((s) => s.id == submissionId);
      
      if (_currentSubmission?.id == submissionId) {
        _currentSubmission = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Clear Error ──────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
