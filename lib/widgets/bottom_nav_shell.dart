import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ideaspark/core/app_localizations.dart';

class BottomNavShell extends StatefulWidget {
  final String location;
  final Widget child;

  const BottomNavShell({super.key, required this.location, required this.child});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _currentIndex(String location) {
    switch (location) {
      case '/home':
        return 0;
      case '/favorites':
        return 1;
      case '/history':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }

  void _onTap(int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/favorites');
        break;
      case 2:
        context.go('/history');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(widget.location);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
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
                _NavItem(icon: Icons.home_rounded, label: context.tr('nav_home'), isSelected: index == 0, onTap: () => _onTap(0), colorScheme: colorScheme),
                _NavItem(icon: Icons.favorite_rounded, label: context.tr('nav_favorites'), isSelected: index == 1, onTap: () => _onTap(1), colorScheme: colorScheme),
                _NavItem(icon: Icons.history_rounded, label: context.tr('nav_history'), isSelected: index == 2, onTap: () => _onTap(2), colorScheme: colorScheme),
                _NavItem(icon: Icons.person_rounded, label: context.tr('nav_profile'), isSelected: index == 3, onTap: () => _onTap(3), colorScheme: colorScheme),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
