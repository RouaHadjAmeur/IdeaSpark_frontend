import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/plan.dart';

class PlanStatsScreen extends StatelessWidget {
  final Plan plan;

  const PlanStatsScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalPosts = plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);

    // Count by format
    final formatCounts = <String, int>{};
    final ctaCounts = <String, int>{};
    final pillarCounts = <String, int>{};

    for (final phase in plan.phases) {
      for (final block in phase.contentBlocks) {
        formatCounts[block.format.label] = (formatCounts[block.format.label] ?? 0) + 1;
        ctaCounts[block.ctaType.name] = (ctaCounts[block.ctaType.name] ?? 0) + 1;
        pillarCounts[block.pillar] = (pillarCounts[block.pillar] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Statistiques du Plan',
                      style: GoogleFonts.syne(
                          fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                children: [
                  // Plan overview
                  _buildOverviewCard(cs, totalPosts),
                  const SizedBox(height: 16),

                  // Format distribution
                  _buildSectionTitle('Distribution par Format', cs),
                  const SizedBox(height: 10),
                  _buildBarChart(formatCounts, totalPosts, cs, _formatColor),
                  const SizedBox(height: 16),

                  // CTA distribution
                  _buildSectionTitle('Distribution par CTA', cs),
                  const SizedBox(height: 10),
                  _buildBarChart(ctaCounts, totalPosts, cs, _ctaColor),
                  const SizedBox(height: 16),

                  // Top pillars
                  _buildSectionTitle('Top Piliers de Contenu', cs),
                  const SizedBox(height: 10),
                  _buildPillarList(pillarCounts, totalPosts, cs),
                  const SizedBox(height: 16),

                  // Phase breakdown
                  _buildSectionTitle('Répartition par Phase', cs),
                  const SizedBox(height: 10),
                  ...plan.phases.asMap().entries.map((e) =>
                      _buildPhaseBar(e.key, e.value, totalPosts, cs)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(ColorScheme cs, int totalPosts) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.name,
                style: GoogleFonts.syne(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${plan.objective.emoji} ${plan.objective.label}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('$totalPosts', 'Posts', Colors.white),
                _statItem('${plan.phases.length}', 'Phases', Colors.white),
                _statItem('${plan.durationWeeks}w', 'Durée', Colors.white),
                _statItem('${plan.postingFrequency}/wk', 'Fréq.', Colors.white),
              ],
            ),
          ],
        ),
      );

  Widget _statItem(String value, String label, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color.withValues(alpha: 0.8))),
        ],
      );

  Widget _buildSectionTitle(String title, ColorScheme cs) => Text(
        title,
        style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 0.5),
      );

  Widget _buildBarChart(
    Map<String, int> data,
    int total,
    ColorScheme cs,
    Color Function(String) colorFn,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: data.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            final color = colorFn(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(e.key,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const Spacer(),
                    Text('${e.value} (${(pct * 100).round()}%)',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );

  Widget _buildPillarList(Map<String, int> data, int total, ColorScheme cs) {
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: sorted.take(5).map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(e.key,
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text('${e.value} posts',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              Text('${(pct * 100).round()}%',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhaseBar(int idx, Phase phase, int total, ColorScheme cs) {
    final count = phase.contentBlocks.length;
    final pct = total > 0 ? count / total : 0.0;
    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFF6B35),
      const Color(0xFF9C27B0),
    ];
    final color = colors[idx % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('W${phase.weekNumber}',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700, color: color)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(phase.name,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text('$count posts',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _formatColor(String format) {
    switch (format.toLowerCase()) {
      case 'reel': return const Color(0xFFE91E63);
      case 'carousel': return const Color(0xFF2196F3);
      case 'story': return const Color(0xFFFF9800);
      default: return const Color(0xFF4CAF50);
    }
  }

  Color _ctaColor(String cta) {
    switch (cta.toLowerCase()) {
      case 'hard': return const Color(0xFFE91E63);
      case 'soft': return const Color(0xFF2196F3);
      default: return const Color(0xFF00BCD4);
    }
  }
}
