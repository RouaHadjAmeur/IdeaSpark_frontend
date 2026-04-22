import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_localizations.dart';
import '../view_models/auth_view_model.dart';

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
    final authVm = context.watch<AuthViewModel>();
    
    // Change label and icon for non-premium users
    final brandsLabel = authVm.isPremium ? context.tr('nav_brands') : 'Challenges';
    final brandsIcon = authVm.isPremium ? Icons.label_important_outline_rounded : Icons.lightbulb_outline_rounded;
    
    // Unified tabs for all users
    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.home_rounded, 'label': context.tr('nav_dashboard'), 'index': 0},
      {'icon': brandsIcon, 'label': brandsLabel, 'index': 1},
      {'icon': Icons.calendar_month_rounded, 'label': context.tr('nav_calendar'), 'index': 2},
      {'icon': Icons.rocket_launch_rounded, 'label': 'Projects', 'index': 3},
      {'icon': Icons.analytics_outlined, 'label': context.tr('nav_insights'), 'index': 4},
    ];

    final activeColor = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: tabs.map((tab) {
              final int branchIndex = tab['index'];
              return Expanded(
                child: _NavItem(
                  icon: tab['icon'],
                  label: tab['label'],
                  isSelected: currentIndex == branchIndex,
                  onTap: () => onTap(branchIndex),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
              );
            }).toList(),
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
  final Color activeColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    required this.activeColor,
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
              color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
              shadows: isSelected
                  ? [
                      Shadow(
                        color: activeColor.withOpacity(0.5),
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
              style: GoogleFonts.syne(
                fontSize: 8,
                color: isSelected ? activeColor : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
