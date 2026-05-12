// note_card.dart
// Reusable note card component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/note.dart';
import 'status_badge.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final String? authorName;
  final VoidCallback onTap;
  final VoidCallback? onMarkSeen;
  final VoidCallback? onDelete;

  const NoteCard({
    super.key,
    required this.note,
    this.authorName,
    required this.onTap,
    this.onMarkSeen,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: note.isUnread
              ? colorScheme.primary.withOpacity(0.05)
              : colorScheme.surface,
          border: Border.all(
            color: note.isUnread
                ? colorScheme.primary.withOpacity(0.3)
                : colorScheme.outlineVariant,
            width: 1,
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
              // Header: Author + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (authorName != null)
                          Text(
                            authorName!,
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        Text(
                          note.target.label,
                          style: GoogleFonts.syne(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: note.status.label,
                    type: note.isUnread ? StatusType.pending : StatusType.active,
                    isCompact: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                note.message,
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              // Footer: Date + Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(note.createdAt),
                    style: GoogleFonts.syne(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    children: [
                      if (note.isUnread && onMarkSeen != null)
                        TextButton(
                          onPressed: onMarkSeen,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            'Mark as seen',
                            style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return date.toString().split(' ')[0];
    }
  }
}
