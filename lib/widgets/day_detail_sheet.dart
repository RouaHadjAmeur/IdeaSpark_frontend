import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../models/brand.dart';

// ─── Public helper ────────────────────────────────────────────────────────────

void showDayDetailSheet(
  BuildContext context, {
  required DateTime date,
  required List<CalendarEntry> entries,
  required List<Plan> plans,
  required List<Brand> brands,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DayDetailSheet(
      date: date,
      entries: entries,
      plans: plans,
      brands: brands,
    ),
  );
}

// ─── DayDetailSheet ───────────────────────────────────────────────────────────

class DayDetailSheet extends StatelessWidget {
  final DateTime date;
  final List<CalendarEntry> entries;
  final List<Plan> plans;
  final List<Brand> brands;

  const DayDetailSheet({
    super.key,
    required this.date,
    required this.entries,
    required this.plans,
    required this.brands,
  });

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _formatColors = {
    ContentFormat.reel:     Color(0xFFFF6B6B),
    ContentFormat.carousel: Color(0xFF4D96FF),
    ContentFormat.story:    Color(0xFFC77DFF),
    ContentFormat.post:     Color(0xFF6BCB77),
  };

  static const _pillarPalette = [
    Color(0xFFFF9F43),
    Color(0xFF4D96FF),
    Color(0xFF6BCB77),
    Color(0xFFC77DFF),
    Color(0xFFFF6B6B),
  ];

  Color _colorForEntry(CalendarEntry e) {
    if (e.format != null) {
      return _formatColors[e.format!] ?? const Color(0xFF9E9E9E);
    }
    if (e.pillar != null) {
      final hash = e.pillar!.codeUnits.fold(0, (a, b) => a + b);
      return _pillarPalette[hash % _pillarPalette.length];
    }
    return const Color(0xFF9E9E9E);
  }

  Plan? _planFor(String planId) =>
      plans.cast<Plan?>().firstWhere((p) => p?.id == planId, orElse: () => null);

  Phase? _phaseFor(Plan plan, String contentBlockId) {
    for (final phase in plan.phases) {
      if (phase.contentBlocks.any((b) => b.id == contentBlockId)) return phase;
    }
    return null;
  }

  String? _brandName(String brandId) => brands
      .cast<Brand?>()
      .firstWhere(
        (b) => b?.id == brandId || b?.name == brandId,
        orElse: () => null,
      )
      ?.name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateLabel = '${_monthNames[date.month - 1]} ${date.day}';
    final postCount = entries.length;

    // Group by planId preserving insertion order
    final grouped = <String, List<CalendarEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(e.planId, () => []).add(e);
    }

    return DraggableScrollableSheet(
      initialChildSize: postCount == 0 ? 0.5 : 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag handle ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Date header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 14),
              child: Row(
                children: [
                  const Text('🗓', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontFamily: 'Syne',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          postCount == 0
                              ? 'Nothing planned — add something!'
                              : '$postCount ${postCount == 1 ? 'post' : 'posts'} planned',
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  if (postCount == 0) ...[
                    _buildEmptyState(context),
                    const SizedBox(height: 24),
                  ] else ...[
                    for (final planId in grouped.keys) ...[
                      _buildPlanGroup(context, planId, grouped[planId]!),
                      const SizedBox(height: 20),
                    ],
                  ],
                  _buildAddSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Free day — perfect for planning!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plan group ──────────────────────────────────────────────────────────────

  Widget _buildPlanGroup(
    BuildContext context,
    String planId,
    List<CalendarEntry> groupEntries,
  ) {
    final cs = Theme.of(context).colorScheme;
    final plan = _planFor(planId);
    final planName = plan?.name ?? 'Unknown Plan';
    final brandName = plan != null ? _brandName(plan.brandId) : null;

    // Progress: published / total for this plan on this day
    final published = groupEntries
        .where((e) => e.status == CalendarEntryStatus.published)
        .length;
    final progress = groupEntries.isNotEmpty
        ? (published / groupEntries.length * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plan header row
        Row(
          children: [
            if (plan != null)
              Text(plan.objective.emoji,
                  style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (brandName != null)
                    Text(
                      brandName,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            // Progress pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$progress% done',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Entry cards
        ...groupEntries.map((e) {
          final phase =
              plan != null ? _phaseFor(plan, e.contentBlockId) : null;
          return _EntryCard(
            entry: e,
            phaseLabel: phase?.name,
            accentColor: _colorForEntry(e),
          );
        }),
      ],
    );
  }

  // ── Add section ─────────────────────────────────────────────────────────────

  Widget _buildAddSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: cs.outlineVariant, height: 24),
        Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Add Content to This Day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                label: const Text('Generate Idea',
                    style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Manual Post',
                    style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Entry Card ───────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final CalendarEntry entry;
  final String? phaseLabel;
  final Color accentColor;

  const _EntryCard({
    required this.entry,
    this.phaseLabel,
    required this.accentColor,
  });

  (String, Color, String) _statusInfo(
      CalendarEntryStatus status, ColorScheme cs) {
    switch (status) {
      case CalendarEntryStatus.published:
        return ('🟢', Colors.green, 'Done');
      case CalendarEntryStatus.cancelled:
        return ('⚫', cs.onSurfaceVariant, 'Cancelled');
      case CalendarEntryStatus.scheduled:
        return ('🔵', cs.primary, 'Scheduled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (statusIcon, statusColor, statusLabel) =
        _statusInfo(entry.status, cs);

    final metaParts = [
      if (entry.format != null) entry.format!.label,
      if (entry.pillar != null && entry.pillar!.isNotEmpty) entry.pillar!,
      if (entry.platform.isNotEmpty) entry.platform,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14)),
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phase label + time + status badge
                    Row(
                      children: [
                        if (phaseLabel != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              phaseLabel!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (entry.scheduledTime != null) ...[
                          Icon(Icons.schedule_rounded,
                              size: 10,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.7)),
                          const SizedBox(width: 2),
                          Text(
                            entry.scheduledTime!,
                            style: TextStyle(
                              fontSize: 10,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                        const Spacer(),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(statusIcon,
                                  style: const TextStyle(fontSize: 9)),
                              const SizedBox(width: 3),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      entry.title ?? 'Untitled Post',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        metaParts.join(' · '),
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Quick action buttons
                    Row(
                      children: [
                        _ActionBtn(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 6),
                        _ActionBtn(
                          icon: Icons.play_circle_outline_rounded,
                          label: 'Start',
                          color: Colors.green,
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 6),
                        _ActionBtn(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Replace',
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 6),
                        _ActionBtn(
                          icon: Icons.event_rounded,
                          label: 'Schedule',
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Compact action button ────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          border: Border.all(color: c.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: c,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
