// Luminosity Indicator Widget
import 'package:flutter/material.dart';

class LuminosityIndicator extends StatelessWidget {
  final double luminosity;

  const LuminosityIndicator({
    super.key,
    required this.luminosity,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor;
    String label;

    if (luminosity < 0.3) {
      barColor = Colors.red;
      label = "Trop sombre";
    } else if (luminosity > 0.7) {
      barColor = Colors.red;
      label = "Trop clair";
    } else {
      barColor = Colors.green;
      label = "Parfait";
    }

    return Positioned(
      left: 20,
      top: MediaQuery.of(context).size.height * 0.25,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  width: 12,
                  height: 200 * luminosity.clamp(0.0, 1.0),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
