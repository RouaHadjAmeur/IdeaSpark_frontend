import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    
    // 5 main tabs: Home, Brands, Calendar, Projects, Contacts
    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.home_outlined, 'label': 'Accueil', 'index': 0},
      {'icon': Icons.bookmark_outline, 'label': 'Marques', 'index': 1},
      {'icon': Icons.insights_outlined, 'label': 'Stratégies', 'index': 2},
      {'icon': Icons.rocket_launch_outlined, 'label': 'Projects', 'index': 3},
      {'icon': Icons.contacts_outlined, 'label': 'Contacts', 'index': 6},
    ];

    final activeColor = colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tabs.map(
              (tab) => _NavItem(
                icon: tab['icon'] as IconData,
                label: tab['label'] as String,
                isSelected: currentIndex == tab['index'],
                onTap: () => onTap(tab['index'] as int),
                colorScheme: colorScheme,
                activeColor: activeColor,
              ),
            ).toList(),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.syne(
                fontSize: 10,
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
