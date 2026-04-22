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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: context.tr('nav_dashboard'),
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
                _NavItem(
                  icon: Icons.label_important_outline_rounded,
                  label: context.tr('nav_brands'),
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: context.tr('nav_calendar'),
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
                _NavItem(
                  icon: Icons.dashboard_customize_rounded,
                  label: 'Execution',
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
                _NavItem(
                  icon: Icons.insights_rounded,
                  label: context.tr('nav_insights'),
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
                _NavItem(
                  icon: Icons.contacts_rounded,
                  label: context.tr('nav_contacts'),
                  isSelected: currentIndex == 5,
                  onTap: () => onTap(5),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: context.tr('nav_profile'),
                  isSelected: currentIndex == 6,
                  onTap: () => onTap(6),
                  colorScheme: colorScheme,
                  activeColor: activeColor,
                ),
              ],
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
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
