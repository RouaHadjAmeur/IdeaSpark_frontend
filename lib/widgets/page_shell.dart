import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'sidebar_navigation.dart';

/// A layout wrapper that adds the sidebar to non-shell routes.
/// On desktop the sidebar is always visible on the left.
/// On mobile it is accessible via a drawer opened by a hamburger button.
/// A back button is shown whenever the page can be popped.
class PageShell extends StatelessWidget {
  const PageShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final colorScheme = Theme.of(context).colorScheme;

    // Remove top system-inset from the child so that inner SafeArea / AppBar
    // widgets don't double-count the status-bar height that PageShell already
    // handles inside _TopBar.
    final body = MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: child,
    );

    if (isMobile) {
      return Scaffold(
        drawer: const SidebarNavigation(),
        body: Builder(
          builder: (ctx) => Column(
            children: [
              const _TopBar(),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          const SidebarNavigation(),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final colorScheme = Theme.of(context).colorScheme;
    final canPop = context.canPop();

    // On desktop, only render the bar when there is somewhere to go back to.
    if (!isMobile && !canPop) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: [
            if (isMobile)
              IconButton(
                icon: Icon(Icons.menu_rounded, color: colorScheme.onSurface),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            if (canPop)
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onSurface),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
