// assignment_view_model.dart
// ViewModel for managing assignments

import 'package:flutter/foundation.dart';
import '../models/assignment.dart';
import '../services/assignment_service.dart';

class AssignmentViewModel extends ChangeNotifier {
  final _service = AssignmentService();

  List<Assignment> _assignments = [];
  List<Assignment> _myAssignments = [];
  Assignment? _currentAssignment;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Assignment> get assignments => _assignments;
  List<Assignment> get myAssignments => _myAssignments;
  Assignment? get currentAssignment => _currentAssignment;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  List<Assignment> get pendingAssignments =>
      _myAssignments.where((a) => a.status == AssignmentStatus.assigned).toList();

  List<Assignment> get inProgressAssignments =>
      _myAssignments.where((a) => a.status == AssignmentStatus.inProgress).toList();

  List<Assignment> get lateAssignments =>
      _myAssignments.where((a) => a.isLate).toList();

  List<Assignment> get submittedAssignments =>
      _assignments.where((a) => a.status == AssignmentStatus.submitted).toList();

  // ─── Load Assignments ─────────────────────────────────────────────────────

  Future<void> loadAssignmentsByCampaign(String campaignId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _assignments = await _service.getAssignmentsByCampaign(campaignId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyAssignments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get current user ID from auth service
      _myAssignments = await _service.getAssignmentsByCollaborator('current_user');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAssignment(String assignmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentAssignment = await _service.getAssignment(assignmentId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create Assignment ────────────────────────────────────────────────────

  Future<Assignment?> createAssignment(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final assignment = await _service.createAssignment(data);
      _assignments.add(assignment);
      notifyListeners();
      return assignment;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Accept Assignment ────────────────────────────────────────────────────

  Future<bool> acceptAssignment(String assignmentId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.acceptAssignment(assignmentId);
      
      // Update in lists
      final index = _myAssignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        _myAssignments[index] = updated;
      }
      
      final index2 = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index2 != -1) {
        _assignments[index2] = updated;
      }
      
      if (_currentAssignment?.id == assignmentId) {
        _currentAssignment = updated;
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

  // ─── Decline Assignment ───────────────────────────────────────────────────

  Future<bool> declineAssignment(String assignmentId, String reason) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.declineAssignment(assignmentId, reason);
      
      // Update in lists
      final index = _myAssignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        _myAssignments[index] = updated;
      }
      
      final index2 = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index2 != -1) {
        _assignments[index2] = updated;
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

  // ─── Start Assignment ─────────────────────────────────────────────────────

  Future<bool> startAssignment(String assignmentId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.startAssignment(assignmentId);
      
      // Update in lists
      final index = _myAssignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        _myAssignments[index] = updated;
      }
      
      final index2 = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index2 != -1) {
        _assignments[index2] = updated;
      }
      
      if (_currentAssignment?.id == assignmentId) {
        _currentAssignment = updated;
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

  // ─── Update Assignment ────────────────────────────────────────────────────

  Future<bool> updateAssignment(String assignmentId, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateAssignment(assignmentId, data);
      
      // Update in lists
      final index = _assignments.indexWhere((a) => a.id == assignmentId);
      if (index != -1) {
        _assignments[index] = updated;
      }
      
      final index2 = _myAssignments.indexWhere((a) => a.id == assignmentId);
      if (index2 != -1) {
        _myAssignments[index2] = updated;
      }
      
      if (_currentAssignment?.id == assignmentId) {
        _currentAssignment = updated;
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

  // ─── Delete Assignment ────────────────────────────────────────────────────

  Future<bool> deleteAssignment(String assignmentId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteAssignment(assignmentId);
      
      _assignments.removeWhere((a) => a.id == assignmentId);
      _myAssignments.removeWhere((a) => a.id == assignmentId);
      
      if (_currentAssignment?.id == assignmentId) {
        _currentAssignment = null;
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
