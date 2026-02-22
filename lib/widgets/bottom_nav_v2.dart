import 'package:flutter/material.dart';
import '../core/app_localizations.dart';
import '../core/app_theme.dart';

class BottomNavV2 extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavV2({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: context.tr('nav_dashboard'),
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.label_important_outline_rounded,
                label: context.tr('nav_brands'),
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.calendar_month_rounded,
                label: context.tr('nav_calendar'),
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.rocket_launch_rounded,
                label: context.tr('nav_projects'),
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
                colorScheme: colorScheme,
              ),
              _NavItem(
                icon: Icons.insights_rounded,
                label: context.tr('nav_insights'),
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              shadows: isSelected
                  ? [
                      Shadow(
                        color: colorScheme.primary.withOpacity(0.5),
                        blurRadius: 6,
                      )
                    ]
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
