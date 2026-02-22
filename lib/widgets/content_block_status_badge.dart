import 'package:flutter/material.dart';
import '../models/content_block.dart';

/// Color-coded status badge for ContentBlock lifecycle states.
class ContentBlockStatusBadge extends StatelessWidget {
  final ContentBlockStatus status;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const ContentBlockStatusBadge({
    super.key,
    required this.status,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  static const _statusConfig = {
    ContentBlockStatus.idea: (
      label:  'Idea',
      color:  Color(0xFF6366F1), // indigo
      icon:   Icons.lightbulb_outline,
    ),
    ContentBlockStatus.approved: (
      label:  'Approved',
      color:  Color(0xFF10B981), // emerald
      icon:   Icons.check_circle_outline,
    ),
    ContentBlockStatus.scheduled: (
      label:  'Scheduled',
      color:  Color(0xFF3B82F6), // blue
      icon:   Icons.schedule_outlined,
    ),
    ContentBlockStatus.inProcess: (
      label:  'In Process',
      color:  Color(0xFFF59E0B), // amber
      icon:   Icons.radio_button_checked,
    ),
    ContentBlockStatus.terminated: (
      label:  'Terminated',
      color:  Color(0xFF6B7280), // gray
      icon:   Icons.block_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg   = _statusConfig[status]!;
    final color = cfg.color;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cfg.icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Text(
            cfg.label,
            style: TextStyle(
              fontSize:   fontSize,
              fontWeight: FontWeight.w600,
              color:      color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
