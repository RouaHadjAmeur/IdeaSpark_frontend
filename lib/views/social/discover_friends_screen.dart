import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/social_view_model.dart';
import '../../services/auth_service.dart';
import '../../core/utils/image_helper.dart';

class DiscoverFriendsScreen extends StatefulWidget {
  const DiscoverFriendsScreen({super.key});

  @override
  State<DiscoverFriendsScreen> createState() => _DiscoverFriendsScreenState();
}

class _DiscoverFriendsScreenState extends State<DiscoverFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late SocialViewModel _socialVm;

  @override
  void initState() {
    super.initState();
    _socialVm = context.read<SocialViewModel>();
    _socialVm.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _socialVm.removeListener(_onViewModelChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onViewModelChange() {
    if (!mounted) return;
    final vm = context.read<SocialViewModel>();
    if (vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () => vm.clearError(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final socialVm = context.watch<SocialViewModel>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Discover Friends'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, skills, or interests...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          socialVm.searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              onChanged: (value) => socialVm.searchUsers(value),
            ),
          ),
        ),
      ),
      body: socialVm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_searchController.text.isEmpty) ...[
                  Text(
                    'Suggested for You',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...socialVm.suggestions.map((user) => _UserListItem(user: user)),
                  if (socialVm.suggestions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No suggestions yet. Complete your profile!')),
                    ),
                ] else ...[
                  Text(
                    'Search Results',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...socialVm.searchResults.map((user) => _UserListItem(user: user)),
                  if (socialVm.searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No users found.')),
                    ),
                ],
              ],
            ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final AppUser user;

  const _UserListItem({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final socialVm = context.watch<SocialViewModel>();
    final isFollowing = socialVm.isFollowing(user.id);
    final isRequested = socialVm.isRequested(user.id);
    final isFollower = socialVm.isFollower(user.id);

    String buttonText = 'Follow';
    if (isFollowing) {
      buttonText = 'Followed';
    } else if (isRequested) {
      buttonText = 'Sent';
    } else if (isFollower) {
      buttonText = 'Follow back';
    }

    Color bgColor = colorScheme.primary;
    Color fgColor = colorScheme.onPrimary;
    BorderSide? side;

    if (isFollowing) {
      bgColor = Colors.transparent;
      fgColor = colorScheme.primary;
      side = BorderSide(color: colorScheme.primary);
    } else if (isRequested) {
      bgColor = colorScheme.secondary.withValues(alpha: 0.2);
      fgColor = colorScheme.secondary;
      side = BorderSide(color: colorScheme.secondary);
    } else if (isFollower) {
      bgColor = colorScheme.tertiary;
      fgColor = colorScheme.onTertiary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: ImageHelper.getImageProvider(user.profilePicture),
              child: user.profilePicture == null
                  ? Text(user.displayName.substring(0, 1).toUpperCase())
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.role.name ?? 'Expert',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                  ),
                  if (user.skills != null && user.skills!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.skills!.take(3).join(' • '),
                      style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => socialVm.toggleFollow(user.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                foregroundColor: fgColor,
                elevation: 0,
                side: side,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(110, 36),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
