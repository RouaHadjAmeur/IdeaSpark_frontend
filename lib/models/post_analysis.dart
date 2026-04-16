import 'package:flutter/material.dart';

class PostAnalysis {
  final int overallScore;
  final Map<String, ScoreDetail> scores;
  final List<String> suggestions;
  final String predictedEngagement;

  PostAnalysis({
    required this.overallScore,
    required this.scores,
    required this.suggestions,
    required this.predictedEngagement,
  });

  factory PostAnalysis.fromJson(Map<String, dynamic> json) {
    return PostAnalysis(
      overallScore: json['overallScore'] ?? 0,
      scores: (json['scores'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, ScoreDetail.fromJson(value)),
          ) ??
          {},
      suggestions: List<String>.from(json['suggestions'] ?? []),
      predictedEngagement: json['predictedEngagement'] ?? 'medium',
    );
  }

  Color get scoreColor {
    if (overallScore >= 90) return Colors.green;
    if (overallScore >= 75) return Colors.lightGreen;
    if (overallScore >= 60) return Colors.orange;
    return Colors.red;
  }

  String get scoreLabel {
    if (overallScore >= 90) return 'Excellent';
    if (overallScore >= 75) return 'Très bon';
    if (overallScore >= 60) return 'Bon';
    if (overallScore >= 40) return 'Moyen';
    return 'Faible';
  }

  String getScoreLabel(String key) {
    const labels = {
      'caption': 'Caption',
      'hashtags': 'Hashtags',
      'timing': 'Timing',
      'structure': 'Structure',
    };
    return labels[key] ?? key;
  }

  Color getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color get engagementColor {
    if (predictedEngagement == 'high') return Colors.green;
    if (predictedEngagement == 'medium') return Colors.orange;
    return Colors.red;
  }

  IconData get engagementIcon {
    if (predictedEngagement == 'high') return Icons.trending_up;
    if (predictedEngagement == 'medium') return Icons.trending_flat;
    return Icons.trending_down;
  }

  String get engagementLabel {
    const labels = {
      'high': 'ÉLEVÉ',
      'medium': 'MOYEN',
      'low': 'FAIBLE',
    };
    return labels[predictedEngagement] ?? predictedEngagement.toUpperCase();
  }
}

class ScoreDetail {
  final int score;
  final String feedback;

  ScoreDetail({
    required this.score,
    required this.feedback,
  });

  factory ScoreDetail.fromJson(Map<String, dynamic> json) {
    return ScoreDetail(
      score: json['score'] ?? 0,
      feedback: json['feedback'] ?? '',
    );
  }
}
