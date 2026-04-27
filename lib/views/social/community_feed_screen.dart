import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/social_view_model.dart';
import '../../models/social_post.dart';
import 'discover_friends_screen.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/image_helper.dart';

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialViewModel>().fetchInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final socialVm = context.watch<SocialViewModel>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscoverFriendsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => socialVm.refreshFeed(),
        child: socialVm.isLoading && socialVm.feed.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : socialVm.feed.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: socialVm.feed.length,
                    itemBuilder: (context, index) {
                      final post = socialVm.feed[index];
                      return _SocialPostCard(post: post);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rss_feed_rounded, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Connect with others to see their ideas!',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscoverFriendsScreen()),
            ),
            icon: const Icon(Icons.search),
            label: const Text('Find Friends'),
          ),
        ],
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  final SocialPost post;

  const _SocialPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = post.user;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                if (user?.id != null) {
                  context.push('/user/${user!.id}');
                }
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: ImageHelper.getImageProvider(user?.profilePicture),
                    child: user?.profilePicture == null
                        ? Text(user?.displayName.substring(0, 1).toUpperCase() ?? '?')
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Unknown User',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.role.name ?? 'Expert',
                          style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    post.publishedAt != null ? DateFormat.MMMd().format(post.publishedAt!) : '',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        post.source == 'video' ? Icons.videocam : Icons.text_fields_rounded,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        post.source == 'video' ? 'VIDEO IDEA' : 'CAMPAIGN SLOGAN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            if (post.hashtags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: post.hashtags.map((tag) => Text(
                  '#${tag.replaceAll('#', '')}',
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
                )).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _ActionButton(icon: Icons.favorite_border, label: 'Like'),
                const SizedBox(width: 16),
                _ActionButton(icon: Icons.chat_bubble_outline, label: 'Comment'),
                const Spacer(),
                _ActionButton(icon: Icons.share_outlined, label: 'Share'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
