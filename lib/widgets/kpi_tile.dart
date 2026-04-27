import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String delta;
  final List<Color> colors;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.delta,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            delta,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
