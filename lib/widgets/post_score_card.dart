import 'package:flutter/material.dart';
import '../models/post_analysis.dart';

class PostScoreCard extends StatelessWidget {
  final PostAnalysis analysis;

  const PostScoreCard({
    super.key,
    required this.analysis,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score global
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score du Post',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: analysis.scoreColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${analysis.overallScore}/100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              analysis.scoreLabel,
              style: TextStyle(
                fontSize: 16,
                color: analysis.scoreColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Divider(height: 24),

            // Détails des scores
            ...analysis.scores.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          analysis.getScoreLabel(entry.key),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${entry.value.score}/100',
                          style: TextStyle(
                            color: analysis.getScoreColor(entry.value.score),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: entry.value.score / 100,
                      backgroundColor: Colors.grey[200],
                      color: analysis.getScoreColor(entry.value.score),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.value.feedback,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 24),

            // Suggestions
            Text(
              '💡 Suggestions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...analysis.suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(fontSize: 16),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 24),

            // Engagement prédit
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: analysis.engagementColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    analysis.engagementIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Engagement prédit: ${analysis.engagementLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
