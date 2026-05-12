// task_card.dart
// Reusable task/assignment card component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/assignment.dart';
import 'status_badge.dart';
import 'priority_indicator.dart';

class TaskCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool showActions;

  const TaskCard({
    super.key,
    required this.assignment,
    required this.onTap,
    this.onAccept,
    this.onDecline,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLate = assignment.isLate;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(
            color: isLate ? const Color(0xFFEF4444) : colorScheme.outlineVariant,
            width: isLate ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      assignment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: assignment.status.label,
                    type: _statusToType(assignment.status),
                    isCompact: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Priority + Deadline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriorityIndicator(
                    priority: _priorityToLevel(assignment.priority),
                    isCompact: true,
                  ),
                  Text(
                    _formatDeadline(assignment.deadline),
                    style: GoogleFonts.syne(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isLate
                          ? const Color(0xFFDC2626)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Instructions preview
              if (assignment.instructions.isNotEmpty)
                Text(
                  assignment.instructions,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

              // Action buttons (if showActions)
              if (showActions && assignment.status == AssignmentStatus.assigned)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: Text(
                            'Decline',
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: onAccept,
                          child: Text(
                            'Accept',
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  StatusType _statusToType(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.assigned:
        return StatusType.assigned;
      case AssignmentStatus.accepted:
        return StatusType.pending;
      case AssignmentStatus.declined:
        return StatusType.rejected;
      case AssignmentStatus.inProgress:
        return StatusType.inProgress;
      case AssignmentStatus.submitted:
        return StatusType.submitted;
      case AssignmentStatus.approved:
        return StatusType.approved;
      case AssignmentStatus.rejected:
        return StatusType.rejected;
      case AssignmentStatus.changesRequested:
        return StatusType.changesRequested;
    }
  }

  PriorityLevel _priorityToLevel(AssignmentPriority priority) {
    switch (priority) {
      case AssignmentPriority.low:
        return PriorityLevel.low;
      case AssignmentPriority.medium:
        return PriorityLevel.medium;
      case AssignmentPriority.high:
        return PriorityLevel.high;
      case AssignmentPriority.urgent:
        return PriorityLevel.urgent;
    }
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    } else {
      return deadline.toString().split(' ')[0];
    }
  }
}
