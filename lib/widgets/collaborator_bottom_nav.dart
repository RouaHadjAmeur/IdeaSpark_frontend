// collaborator_bottom_nav.dart
// Bottom navigation for Collaborator (Content Creator)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CollaboratorBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int? unreadNotifications;

  const CollaboratorBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Collaborator navigation: My Tasks, Create, Calendar, Notes, Submissions, Profile
    final List<Map<String, dynamic>> tabs = [
      {'icon': Icons.assignment_outlined, 'label': 'My Tasks', 'index': 0},
      {'icon': Icons.add_circle_outline, 'label': 'Create', 'index': 1},
      {'icon': Icons.calendar_month_outlined, 'label': 'Calendar', 'index': 2},
      {'icon': Icons.note_outlined, 'label': 'Notes', 'index': 3},
      {'icon': Icons.cloud_upload_outlined, 'label': 'Submit', 'index': 4},
      {'icon': Icons.person_outline, 'label': 'Profile', 'index': 5},
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
            children: tabs.asMap().entries.map(
              (entry) {
                final tab = entry.value;
                final tabIndex = entry.key;
                final hasNotifications = tabIndex == 3 && (unreadNotifications ?? 0) > 0;

                return _CollaboratorNavItem(
                  icon: tab['icon'] as IconData,
                  label: tab['label'] as String,
                  isSelected: currentIndex == tab['index'],
                  onTap: () => onTap(tab['index'] as int),
                  colorScheme: colorScheme,
                  badge: hasNotifications ? unreadNotifications.toString() : null,
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }
}

class _CollaboratorNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final String? badge;

  const _CollaboratorNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
    this.badge,
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
            Stack(
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
                if (badge != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          color: colorScheme.onError,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
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
