// priority_indicator.dart
// Priority indicator component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriorityIndicator extends StatelessWidget {
  final PriorityLevel priority;
  final bool isCompact;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(priority);

    return Container(
      padding: isCompact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors['bg'] as Color,
        border: Border.all(color: colors['border'] as Color, width: 1),
        borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: colors['dot'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            priority.label,
            style: GoogleFonts.syne(
              fontSize: isCompact ? 10 : 12,
              color: colors['text'] as Color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return {
          'bg': const Color(0x1F93C5FD),
          'border': const Color(0xFF93C5FD),
          'text': const Color(0xFF1E40AF),
          'dot': const Color(0xFF3B82F6),
        };
      case PriorityLevel.medium:
        return {
          'bg': const Color(0x1FFCD34D),
          'border': const Color(0xFFFCD34D),
          'text': const Color(0xFFB45309),
          'dot': const Color(0xFFF59E0B),
        };
      case PriorityLevel.high:
        return {
          'bg': const Color(0x1FFECACA),
          'border': const Color(0xFFFECACA),
          'text': const Color(0xFFDC2626),
          'dot': const Color(0xFFF87171),
        };
      case PriorityLevel.urgent:
        return {
          'bg': const Color(0x1FDC2626),
          'border': const Color(0xFFDC2626),
          'text': const Color(0xFFFFFFFF),
          'dot': const Color(0xFFFFFFFF),
        };
    }
  }
}

enum PriorityLevel {
  low,
  medium,
  high,
  urgent,
}

extension PriorityLevelExt on PriorityLevel {
  String get label {
    switch (this) {
      case PriorityLevel.low:
        return 'Low';
      case PriorityLevel.medium:
        return 'Medium';
      case PriorityLevel.high:
        return 'High';
      case PriorityLevel.urgent:
        return 'Urgent';
    }
  }

  int get value {
    switch (this) {
      case PriorityLevel.low:
        return 1;
      case PriorityLevel.medium:
        return 2;
      case PriorityLevel.high:
        return 3;
      case PriorityLevel.urgent:
        return 4;
    }
  }

  static PriorityLevel fromValue(int value) {
    switch (value) {
      case 1:
        return PriorityLevel.low;
      case 2:
        return PriorityLevel.medium;
      case 3:
        return PriorityLevel.high;
      case 4:
        return PriorityLevel.urgent;
      default:
        return PriorityLevel.medium;
    }
  }
}
