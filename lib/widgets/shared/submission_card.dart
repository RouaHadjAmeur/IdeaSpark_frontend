// submission_card.dart
// Reusable submission card component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/submission.dart';
import 'status_badge.dart';

class SubmissionCard extends StatelessWidget {
  final Submission submission;
  final String? collaboratorName;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onRequestChanges;
  final bool showActions;

  const SubmissionCard({
    super.key,
    required this.submission,
    this.collaboratorName,
    required this.onTap,
    this.onApprove,
    this.onReject,
    this.onRequestChanges,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
              // Header: Collaborator + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (collaboratorName != null)
                          Text(
                            collaboratorName!,
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        Text(
                          'Submission',
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
                    label: submission.status.label,
                    type: _statusToType(submission.status),
                    isCompact: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Media preview
              if (submission.media.isNotEmpty)
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (submission.media.first.thumbnail != null)
                        Image.network(
                          submission.media.first.thumbnail!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      else
                        Icon(
                          _getMediaIcon(submission.media.first.type),
                          size: 32,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      if (submission.media.length > 1)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${submission.media.length - 1}',
                              style: GoogleFonts.syne(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),

              // Caption preview
              if (submission.caption.isNotEmpty)
                Text(
                  submission.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

              // Feedback (if rejected or changes requested)
              if (submission.feedback != null && submission.feedback!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFCD34D),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      submission.feedback!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ),

              // Action buttons (if showActions and pending)
              if (showActions && submission.status == SubmissionStatus.submitted)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: BorderSide(color: colorScheme.error),
                          ),
                          child: Text(
                            'Reject',
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRequestChanges,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: Color(0xFFFBBF24)),
                          ),
                          child: Text(
                            'Changes',
                            style: GoogleFonts.syne(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFBBF24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: onApprove,
                          child: Text(
                            'Approve',
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

  StatusType _statusToType(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.submitted:
        return StatusType.submitted;
      case SubmissionStatus.approved:
        return StatusType.approved;
      case SubmissionStatus.rejected:
        return StatusType.rejected;
      case SubmissionStatus.changesRequested:
        return StatusType.changesRequested;
      case SubmissionStatus.published:
        return StatusType.completed;
      case SubmissionStatus.shortlisted:
        return StatusType.pending;
      case SubmissionStatus.winner:
        return StatusType.approved;
      case SubmissionStatus.revisionRequested:
        return StatusType.changesRequested;
    }
  }

  IconData _getMediaIcon(MediaType type) {
    switch (type) {
      case MediaType.video:
        return Icons.videocam_outlined;
      case MediaType.image:
        return Icons.image_outlined;
      case MediaType.carousel:
        return Icons.collections_outlined;
      case MediaType.document:
        return Icons.description_outlined;
    }
  }
}
