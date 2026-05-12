// brand_owner_bottom_nav.dart
// Bottom navigation for Brand Owner (Premium User)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandOwnerBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BrandOwnerBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Brand Owner navigation: Dashboard, Campaigns, Collaborators, Calendar, Submissions, Notifications
    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0},
      {'icon': Icons.campaign_outlined, 'label': 'Campaigns', 'index': 1},
      {'icon': Icons.people_outline, 'label': 'Team', 'index': 2},
      {'icon': Icons.calendar_month_outlined, 'label': 'Calendar', 'index': 3},
      {'icon': Icons.check_circle_outline, 'label': 'Reviews', 'index': 4},
      {'icon': Icons.notifications_outlined, 'label': 'Alerts', 'index': 5},
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tabs.map(
              (tab) => _BrandOwnerNavItem(
                icon: tab['icon'] as IconData,
                label: tab['label'] as String,
                isSelected: currentIndex == tab['index'],
                onTap: () => onTap(tab['index'] as int),
                colorScheme: colorScheme,
              ),
            ).toList(),
          ),
        ),
      ),
    );
  }
}

class _BrandOwnerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _BrandOwnerNavItem({
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.syne(
                fontSize: 10,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
