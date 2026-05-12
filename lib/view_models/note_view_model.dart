// note_view_model.dart
// ViewModel for managing notes

import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../services/note_service.dart';

class NoteViewModel extends ChangeNotifier {
  final _service = NoteService();

  List<Note> _notes = [];
  List<Note> _myNotes = [];
  Note? _currentNote;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<Note> get notes => _notes;
  List<Note> get myNotes => _myNotes;
  Note? get currentNote => _currentNote;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  List<Note> get unreadNotes => _myNotes.where((n) => n.isUnread).toList();
  int get unreadCount => unreadNotes.length;

  // ─── Load Notes ───────────────────────────────────────────────────────────

  Future<void> loadNotesByCampaign(String campaignId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notes = await _service.getNotesByCampaign(campaignId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMyNotes(String collaboratorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myNotes = await _service.getNotesByCollaborator(collaboratorId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadNotes(String collaboratorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myNotes = await _service.getUnreadNotes(collaboratorId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNote(String noteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentNote = await _service.getNote(noteId);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Create Note ──────────────────────────────────────────────────────────

  Future<Note?> createNote(Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final note = await _service.createNote(data);
      _notes.add(note);
      notifyListeners();
      return note;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    } finally {
      _isSaving = false;
    }
  }

  // ─── Mark Note as Seen ────────────────────────────────────────────────────

  Future<bool> markNoteSeen(String noteId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.markNoteSeen(noteId);
      
      // Update in lists
      final index = _myNotes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        _myNotes[index] = updated;
      }
      
      final index2 = _notes.indexWhere((n) => n.id == noteId);
      if (index2 != -1) {
        _notes[index2] = updated;
      }
      
      if (_currentNote?.id == noteId) {
        _currentNote = updated;
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

  // ─── Update Note ──────────────────────────────────────────────────────────

  Future<bool> updateNote(String noteId, Map<String, dynamic> data) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateNote(noteId, data);
      
      // Update in lists
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        _notes[index] = updated;
      }
      
      final index2 = _myNotes.indexWhere((n) => n.id == noteId);
      if (index2 != -1) {
        _myNotes[index2] = updated;
      }
      
      if (_currentNote?.id == noteId) {
        _currentNote = updated;
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

  // ─── Delete Note ──────────────────────────────────────────────────────────

  Future<bool> deleteNote(String noteId) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteNote(noteId);
      
      _notes.removeWhere((n) => n.id == noteId);
      _myNotes.removeWhere((n) => n.id == noteId);
      
      if (_currentNote?.id == noteId) {
        _currentNote = null;
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
