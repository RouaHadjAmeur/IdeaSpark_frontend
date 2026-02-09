import 'package:flutter/foundation.dart';
import '../models/idea_model.dart';

/// ViewModel for Results list screen.
class ResultsViewModel extends ChangeNotifier {
  final List<IdeaModel> _ideas = List.from(_sampleIdeas);
  String _selectedFilter = 'Tous';

  List<IdeaModel> get ideas => _ideas;
  String get selectedFilter => _selectedFilter;

  static const List<String> filterOptions = ['Tous', 'Viral', 'Réaliste', 'Courtes'];

  int get resultsCount => _ideas.length;

  void setFilter(String filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      notifyListeners();
    }
  }

  void refresh() {
    // In real app would re-fetch from API
    notifyListeners();
  }

  IdeaModel? getIdeaById(String id) {
    try {
      return _ideas.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static final List<IdeaModel> _sampleIdeas = [
    IdeaModel(
      id: '1',
      type: 'Video',
      title: 'Morning Routine Transformation',
      description: 'Montre une routine matinale chaotique vs organisée avec des transitions rapides et une musique motivante.',
      score: 8.7,
    ),
    IdeaModel(
      id: '2',
      type: 'Video',
      title: '5 Productivity Hacks Students',
      description: 'Liste rapide de 5 astuces de productivité pour étudiants avec démonstration visuelle et timer.',
      score: 9.2,
    ),
    IdeaModel(
      id: '3',
      type: 'Video',
      title: 'Study With Me POV',
      description: 'Session d\'étude en temps réel avec ambiance cozy, musique lofi et motivation.',
      score: 7.9,
    ),
  ];
}
