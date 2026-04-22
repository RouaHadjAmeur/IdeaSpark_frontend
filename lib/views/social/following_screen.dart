import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/social_view_model.dart';
import '../../services/auth_service.dart';
import '../../core/utils/image_helper.dart';

class FollowingScreen extends StatefulWidget {
  /// Pass [userId] to view another user's following list; omit for the current user.
  final String? userId;
  const FollowingScreen({super.key, this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SocialViewModel>();
      if (widget.userId != null) {
        vm.fetchSocialLists(widget.userId!);
      } else {
        vm.fetchInitialData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<SocialViewModel>();

    final list = vm.following;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Following'),
        centerTitle: true,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search_outlined, size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text('Not following anyone yet', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _FollowingTile(user: list[index]),
                ),
    );
  }
}

class _FollowingTile extends StatelessWidget {
  final AppUser user;
  const _FollowingTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<SocialViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundImage: ImageHelper.getImageProvider(user.profilePicture),
          child: user.profilePicture == null
              ? Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(user.displayName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.role.name ?? 'Member', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
            if (user.skills != null && user.skills!.isNotEmpty)
              Text(
                user.skills!.take(3).join(' • '),
                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () => vm.toggleFollow(user.id),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size(90, 34),
          ),
          child: const Text('Unfollow'),
        ),
      ),
    );
  }
}
