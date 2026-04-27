import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampaignStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;
  final Function(int) onStepTapped;

  const CampaignStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Background line
          Positioned(
            top: 14,
            left: 24,
            right: 24,
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: const Color(0xFF6D4ED3).withValues(alpha: 0.12),
              ),
            ),
          ),
          // Progress line
          Positioned(
            top: 14,
            left: 24,
            right: 24,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 1.5,
                    width: totalSteps > 1 ? constraints.maxWidth * (currentStep / (totalSteps - 1)) : 0,
                    color: const Color(0xFF6D4ED3),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isDone = index < currentStep;
              
              return GestureDetector(
                onTap: () => onStepTapped(index),
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (isActive || isDone) ? const Color(0xFF6D4ED3) : const Color(0xFFF0EEFF),
                        shape: BoxShape.circle,
                        boxShadow: isActive ? [
                          BoxShadow(
                            color: const Color(0xFF6D4ED3).withValues(alpha: 0.22),
                            spreadRadius: 4,
                          )
                        ] : null,
                        border: (!isActive && !isDone) ? Border.all(color: const Color(0xFF6D4ED3).withValues(alpha: 0.12), width: 1.5) : null,
                      ),
                      child: Center(
                        child: isDone 
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: (isActive || isDone) ? Colors.white : const Color(0xFFA89EC0),
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      width: 52,
                      child: Text(
                        stepTitles[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive ? const Color(0xFF6D4ED3) : const Color(0xFFA89EC0),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
