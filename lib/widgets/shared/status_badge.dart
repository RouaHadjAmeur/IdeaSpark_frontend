// status_badge.dart
// Reusable status badge component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context, type);

    return Container(
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors['bg'] as Color,
        border: Border.all(color: colors['border'] as Color, width: 1),
        borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
      ),
      child: Text(
        label,
        style: GoogleFonts.syne(
          fontSize: isCompact ? 10 : 12,
          color: colors['text'] as Color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, Color> _getColors(BuildContext context, StatusType type) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (type) {
      case StatusType.assigned:
        return {
          'bg': const Color(0x1F3B82F6),
          'border': const Color(0xFF3B82F6),
          'text': const Color(0xFF1E40AF),
        };
      case StatusType.inProgress:
        return {
          'bg': const Color(0x1FF59E0B),
          'border': const Color(0xFFF59E0B),
          'text': const Color(0xFFB45309),
        };
      case StatusType.submitted:
        return {
          'bg': const Color(0x1FA855F7),
          'border': const Color(0xFFA855F7),
          'text': const Color(0xFF7C3AED),
        };
      case StatusType.approved:
        return {
          'bg': const Color(0x1F10B981),
          'border': const Color(0xFF10B981),
          'text': const Color(0xFF047857),
        };
      case StatusType.rejected:
        return {
          'bg': const Color(0x1FEF4444),
          'border': const Color(0xFFEF4444),
          'text': const Color(0xFFDC2626),
        };
      case StatusType.late:
        return {
          'bg': const Color(0x1F7F1D1D),
          'border': const Color(0xFF7F1D1D),
          'text': const Color(0xFFDC2626),
        };
      case StatusType.changesRequested:
        return {
          'bg': const Color(0x1FFBBF24),
          'border': const Color(0xFFFBBF24),
          'text': const Color(0xFFB45309),
        };
      case StatusType.pending:
        return {
          'bg': const Color(0x1F6B7280),
          'border': const Color(0xFF6B7280),
          'text': const Color(0xFF374151),
        };
      case StatusType.active:
        return {
          'bg': const Color(0x1F06B6D4),
          'border': const Color(0xFF06B6D4),
          'text': const Color(0xFF0891B2),
        };
      case StatusType.completed:
        return {
          'bg': const Color(0x1F10B981),
          'border': const Color(0xFF10B981),
          'text': const Color(0xFF047857),
        };
    }
  }
}

enum StatusType {
  assigned,
  inProgress,
  submitted,
  approved,
  rejected,
  late,
  changesRequested,
  pending,
  active,
  completed,
}

extension StatusTypeExt on StatusType {
  String get label {
    switch (this) {
      case StatusType.assigned:
        return 'Assigned';
      case StatusType.inProgress:
        return 'In Progress';
      case StatusType.submitted:
        return 'Submitted';
      case StatusType.approved:
        return 'Approved';
      case StatusType.rejected:
        return 'Rejected';
      case StatusType.late:
        return 'Late';
      case StatusType.changesRequested:
        return 'Changes Requested';
      case StatusType.pending:
        return 'Pending';
      case StatusType.active:
        return 'Active';
      case StatusType.completed:
        return 'Completed';
    }
  }

  Color getColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (this) {
      case StatusType.assigned:
        return const Color(0xFF3B82F6);
      case StatusType.inProgress:
        return const Color(0xFFF59E0B);
      case StatusType.submitted:
        return const Color(0xFFA855F7);
      case StatusType.approved:
        return const Color(0xFF10B981);
      case StatusType.rejected:
        return const Color(0xFFEF4444);
      case StatusType.late:
        return const Color(0xFF7F1D1D);
      case StatusType.changesRequested:
        return const Color(0xFFFBBF24);
      case StatusType.pending:
        return const Color(0xFF6B7280);
      case StatusType.active:
        return const Color(0xFF06B6D4);
      case StatusType.completed:
        return const Color(0xFF10B981);
    }
  }
}
