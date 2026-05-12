import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/plan.dart';

class StatusWorkflowNode extends StatelessWidget {
  final ContentBlockStatus status;
  final bool isActive;
  final bool isCompleted;

  const StatusWorkflowNode({
    super.key,
    required this.status,
    this.isActive = false,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(status.color);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? color : Colors.transparent,
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.3),
              width: isActive ? 3 : 2,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: isCompleted 
            ? const Icon(Icons.check, size: 14, color: Colors.white)
            : isActive 
              ? Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)))
              : null,
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: Text(
            status.label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? color : color.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: Text(
            status.description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 8,
              color: Colors.grey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class StatusWorkflowBar extends StatelessWidget {
  final ContentBlockStatus currentStatus;

  const StatusWorkflowBar({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ContentBlockStatus.empty,
      ContentBlockStatus.draft,
      ContentBlockStatus.submitted,
      ContentBlockStatus.approved,
      ContentBlockStatus.published,
    ];

    int currentIndex = statuses.indexOf(currentStatus);
    if (currentStatus == ContentBlockStatus.scheduled) currentIndex = statuses.indexOf(ContentBlockStatus.approved);
    if (currentStatus == ContentBlockStatus.revisionRequested) currentIndex = statuses.indexOf(ContentBlockStatus.submitted);

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final stepWidth = totalWidth / statuses.length;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Stack(
            children: [
              // Background Line (Grey)
              Positioned(
                top: 11, // Match circle center
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Container(
                  height: 2,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              // Active Line (Primary Color)
              if (currentIndex > 0)
                Positioned(
                  top: 11,
                  left: stepWidth / 2,
                  width: stepWidth * currentIndex,
                  child: Container(
                    height: 2,
                    color: Color(statuses[currentIndex].color).withValues(alpha: 0.5),
                  ),
                ),
              // Nodes
              Row(
                children: List.generate(statuses.length, (index) {
                  final s = statuses[index];
                  bool isPast = index < currentIndex;
                  bool isCurrent = s == currentStatus || 
                                 (currentStatus == ContentBlockStatus.scheduled && s == ContentBlockStatus.approved) ||
                                 (currentStatus == ContentBlockStatus.revisionRequested && s == ContentBlockStatus.submitted);

                  return Expanded(
                    child: StatusWorkflowNode(
                      status: s,
                      isActive: isCurrent,
                      isCompleted: isPast,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
