import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../view_models/auth_view_model.dart';

class SidebarNavigation extends StatefulWidget {
  const SidebarNavigation({super.key});

  @override
  State<SidebarNavigation> createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = MediaQuery.of(context).size.width < 900;
    final location = GoRouterState.of(context).matchedLocation;
    final authVm = context.watch<AuthViewModel>();

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width * 0.8 : 280,
      color: colorScheme.surface,
      child: Column(
        children: [
          _buildProfileHeader(context, colorScheme, authVm),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader(context, 'Menu'),
                _SidebarItem(
                  icon: Icons.rocket_launch_outlined,
                  label: 'Projects',
                  isActive: location.startsWith('/projects') ||
                      location.startsWith('/project-board') ||
                      location.startsWith('/plan-project'),
                  onTap: () => context.go('/projects'),
                ),
                _SidebarItem(
                  icon: Icons.groups_outlined,
                  label: 'Communauté',
                  isActive: location.startsWith('/community'),
                  onTap: () => context.go('/community'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Campaign Manager'),
                _SidebarItem(
                  icon: Icons.smart_toy_outlined,
                  label: 'Campaign Manager',
                  isActive: location.startsWith('/campaign-manager'),
                  onTap: () => context.go('/campaign-manager'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Outils IA'),
                _SidebarItem(
                  icon: Icons.lightbulb_outline,
                  label: 'Hub Générateurs IA',
                  isActive: location == '/generators',
                  onTap: () => context.go('/generators'),
                ),
                _SidebarItem(
                  icon: Icons.image_outlined,
                  label: 'Générateur d\'Images',
                  isActive: location == '/image-generator',
                  onTap: () => context.push('/image-generator'),
                ),
                _SidebarItem(
                  icon: Icons.videocam_outlined,
                  label: 'Générateur Vidéo',
                  isActive: location == '/video-generator',
                  onTap: () => context.push('/video-generator'),
                ),
                _SidebarItem(
                  icon: Icons.auto_awesome,
                  label: 'Générateur de Hooks',
                  isActive: location == '/creative-ai-test',
                  onTap: () => context.push('/creative-ai-test'),
                ),
                _SidebarItem(
                  icon: Icons.photo_library_outlined,
                  label: 'Historique Images',
                  isActive: location == '/image-history',
                  onTap: () => context.push('/image-history'),
                ),
                _SidebarItem(
                  icon: Icons.video_library_outlined,
                  label: 'Historique Vidéos',
                  isActive: location == '/video-history',
                  onTap: () => context.push('/video-history'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Bibliothèque'),
                _SidebarItem(
                  icon: Icons.favorite_outline,
                  label: 'Favoris',
                  isActive: location == '/favorites',
                  onTap: () => context.go('/favorites'),
                ),
                _SidebarItem(
                  icon: Icons.history_outlined,
                  label: 'Historique Général',
                  isActive: location == '/history',
                  onTap: () => context.go('/history'),
                ),
                _SidebarItem(
                  icon: Icons.videocam_outlined,
                  label: 'Camera Coach',
                  isActive: location.startsWith('/camera-coach'),
                  onTap: () => context.go('/camera-coach'),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader(context, 'Compte'),
                _SidebarItem(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  isActive: location == '/profile',
                  onTap: () => context.go('/profile'),
                ),
                _SidebarItem(
                  icon: Icons.star_outline,
                  label: 'Abonnement & Crédits',
                  isActive: location.startsWith('/credits-shop'),
                  onTap: () => context.go('/credits-shop'),
                ),
                _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Paramètres',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ColorScheme colorScheme, AuthViewModel authVm) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final user = authVm.currentUser;
    final displayName = user?.displayName ?? (user != null ? user.email?.split('@').first : null) ?? 'User';
    final email = user?.email ?? '@user';
    final initials = displayName
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();
    final accountType = user?.role?.toString().split('.').last ?? 'Premium';
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, isMobile ? 60 : 30, 20, 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : 'U',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '@$email · $accountType',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isActive ? colorScheme.primary : Colors.transparent,
              width: 3,
            ),
          ),
          color: isActive ? colorScheme.primary.withValues(alpha: 0.08) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17), // 20 - 3 for border
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? colorScheme.primary : colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isActive ? colorScheme.primary : colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}