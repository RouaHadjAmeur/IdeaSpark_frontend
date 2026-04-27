import 'package:flutter/material.dart';

/// Generic reusable chip group selector widget
/// Displays a horizontal scrollable list of chips for selecting from a set of options
class ChipGroupSelector<T> extends StatelessWidget {
  final String label;
  final List<T> options;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final String Function(T) labelBuilder;
  final ColorScheme? colorScheme;

  const ChipGroupSelector({
    super.key,
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.labelBuilder,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColorScheme = colorScheme ?? Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: effectiveColorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = option == selectedValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? effectiveColorScheme.primary
                            : effectiveColorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? effectiveColorScheme.primary
                              : effectiveColorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        labelBuilder(option),
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white
                              : effectiveColorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
