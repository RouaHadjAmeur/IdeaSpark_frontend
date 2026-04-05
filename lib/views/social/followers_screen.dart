import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/social_view_model.dart';
import '../../services/auth_service.dart';
import '../../core/utils/image_helper.dart';

class FollowersScreen extends StatefulWidget {
  /// Pass [userId] to view another user's followers; omit (or pass null) for the current user.
  final String? userId;
  const FollowersScreen({super.key, this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
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

    final list = widget.userId != null ? vm.followers : vm.followers;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Followers'),
        centerTitle: true,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text('No followers yet', style: theme.textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) => _UserTile(user: list[index]),
                ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<SocialViewModel>();
    final isFollowing = vm.isFollowing(user.id);
    final isRequested = vm.isRequested(user.id);

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
        subtitle: Text(user.role ?? 'Member', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
        trailing: TextButton(
          onPressed: () => vm.toggleFollow(user.id),
          style: TextButton.styleFrom(
            foregroundColor: isFollowing ? colorScheme.outline : colorScheme.primary,
            side: BorderSide(color: isFollowing ? colorScheme.outline : colorScheme.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size(90, 34),
          ),
          child: Text(isFollowing ? 'Following' : isRequested ? 'Sent' : 'Follow back'),
        ),
      ),
    );
  }
}
