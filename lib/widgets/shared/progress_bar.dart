// progress_bar.dart
// Reusable progress bar component

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String? label;
  final String? percentage;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final bool showLabel;

  const ProgressBar({
    super.key,
    required this.progress,
    this.label,
    this.percentage,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 8,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final fgColor = foregroundColor ?? colorScheme.primary;

    final displayPercentage = percentage ?? '${(progress * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel && label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  displayPercentage,
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: height,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
          ),
        ),
      ],
    );
  }
}

class CircularProgressWithLabel extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? labelStyle;

  const CircularProgressWithLabel({
    super.key,
    required this.progress,
    required this.label,
    this.size = 80,
    this.backgroundColor,
    this.foregroundColor,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final fgColor = foregroundColor ?? colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 4,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation<Color>(fgColor),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: labelStyle ??
                    GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
              ),
              Text(
                label,
                style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MultiSegmentProgressBar extends StatelessWidget {
  final List<ProgressSegment> segments;
  final double height;
  final bool showLabels;

  const MultiSegmentProgressBar({
    super.key,
    required this.segments,
    this.height = 12,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = segments.fold<double>(0, (sum, seg) => sum + seg.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Row(
            children: segments.map((segment) {
              final percentage = total > 0 ? segment.value / total : 0;
              return Expanded(
                flex: (percentage * 100).toInt(),
                child: Container(
                  height: height,
                  color: segment.color,
                ),
              );
            }).toList(),
          ),
        ),
        if (showLabels)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: segments.map((segment) {
                final percentage = total > 0 ? segment.value / total : 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: segment.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${segment.label} (${(percentage * 100).toStringAsFixed(0)}%)',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class ProgressSegment {
  final String label;
  final double value;
  final Color color;

  ProgressSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}
