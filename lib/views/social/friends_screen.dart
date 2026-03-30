import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/social_view_model.dart';
import '../../services/auth_service.dart';
import '../../core/utils/image_helper.dart';

/// Shows all mutual follows (friends) of the current user.
/// Each friend card expands to show shared collaboration plans.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialViewModel>().fetchFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<SocialViewModel>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Friends'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => vm.fetchFriends(),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.friends.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handshake_outlined, size: 64, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text('No mutual follows yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Follow people and follow back to see friends here.',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.friends.length,
                  itemBuilder: (context, index) {
                    final entry = vm.friends[index];
                    final user = AppUser.fromJson(entry);
                    final sharedPlans = (entry['sharedPlans'] as List<dynamic>?) ?? [];
                    return _FriendCard(user: user, sharedPlans: sharedPlans);
                  },
                ),
    );
  }
}

class _FriendCard extends StatefulWidget {
  final AppUser user;
  final List<dynamic> sharedPlans;

  const _FriendCard({required this.user, required this.sharedPlans});

  @override
  State<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<_FriendCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final vm = context.watch<SocialViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Friend header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: ImageHelper.getImageProvider(widget.user.profilePicture),
                  child: widget.user.profilePicture == null
                      ? Text(widget.user.displayName.isNotEmpty ? widget.user.displayName[0].toUpperCase() : '?')
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.displayName,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.user.role ?? 'Member',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                      ),
                      if (widget.user.skills != null && widget.user.skills!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.user.skills!.take(3).join(' • '),
                            style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                // Unfollow
                OutlinedButton(
                  onPressed: () => vm.toggleFollow(widget.user.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    minimumSize: const Size(88, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Unfollow'),
                ),
              ],
            ),
          ),

          // ── Shared collaborations toggle ────────────────────────
          if (widget.sharedPlans.isNotEmpty) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.folder_shared_outlined, size: 18, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.sharedPlans.length} shared collaboration${widget.sharedPlans.length > 1 ? 's' : ''}',
                      style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(
                      _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: widget.sharedPlans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final plan = widget.sharedPlans[i] as Map<String, dynamic>;
                  return _SharedPlanTile(plan: plan);
                },
              ),
          ] else ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.folder_outlined, size: 18, color: colorScheme.outlineVariant),
                  const SizedBox(width: 8),
                  Text(
                    'No shared collaborations',
                    style: theme.textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SharedPlanTile extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _SharedPlanTile({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = plan['title'] as String? ?? plan['name'] as String? ?? 'Untitled Plan';
    final status = plan['status'] as String? ?? '';
    final goal = plan['goal'] as String? ?? plan['objective'] as String? ?? '';

    Color statusColor = colorScheme.primary;
    if (status == 'active') statusColor = Colors.green;
    if (status == 'draft') statusColor = colorScheme.secondary;
    if (status == 'completed') statusColor = colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.article_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (goal.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(goal, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          if (status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status, style: theme.textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
