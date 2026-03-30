import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../view_models/collaboration_view_model.dart';
import '../../view_models/social_view_model.dart';
import '../../core/utils/image_helper.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollaborationViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<CollaborationViewModel>();
    final socialVm = context.watch<SocialViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: vm.isLoading && vm.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : vm.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification pour le moment',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => vm.loadNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = vm.notifications[index];
                      final type = notification['type'] as String;
                      final isInvite = type == 'invite_received';
                      final isFollowRequest = type == 'follow_request';
                      final isFollowAccepted = type == 'follow_accepted';
                      
                      final isRead = notification['read'] ?? false;
                      final dateStr = notification['createdAt'] as String;
                      final date = DateTime.parse(dateStr).toLocal();
                      
                      final relatedUser = notification['relatedUserId'];
                      final relatedUserName = relatedUser != null ? (relatedUser['name'] ?? relatedUser['username'] ?? 'Quelqu\'un') : 'Quelqu\'un';
                      final relatedUserProfileImg = relatedUser != null ? relatedUser['profile_img'] : null;

                      return Card(
                        elevation: 0,
                        color: isRead ? colorScheme.surface : colorScheme.primaryContainer.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isRead ? colorScheme.outlineVariant : colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            vm.markNotificationAsRead(notification['_id']);
                            if (relatedUser != null) {
                              final userId = relatedUser['_id'] ?? relatedUser['id'];
                              if (userId != null) {
                                context.push('/user/$userId');
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isFollowRequest || isFollowAccepted || (relatedUserProfileImg != null))
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundImage: ImageHelper.getImageProvider(relatedUserProfileImg),
                                        child: relatedUserProfileImg == null ? const Icon(Icons.person, size: 18) : null,
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isInvite ? colorScheme.primary.withValues(alpha: 0.1) : colorScheme.secondary.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isInvite ? Icons.mail_outline : Icons.notifications_none,
                                          color: isInvite ? colorScheme.primary : colorScheme.secondary,
                                          size: 20,
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontSize: 14,
                                                fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: relatedUserName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                                TextSpan(text: ' ${notification['message'] ?? ''}'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('dd MMM yyyy, HH:mm').format(date),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                if ((isInvite || isFollowRequest) && !isRead) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          if (isInvite) {
                                            vm.declineInvitation(notification['_id']);
                                          } else {
                                            // Handle decline follow request if needed
                                          }
                                        },
                                        style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                                        child: const Text('Refuser'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: () async {
                                          if (isInvite) {
                                            await vm.acceptInvitation(notification['_id']);
                                          } else if (isFollowRequest && relatedUser != null) {
                                            final followerId = relatedUser['_id'] ?? relatedUser['id'];
                                            await socialVm.acceptRequest(followerId);
                                            await vm.markNotificationAsRead(notification['_id']);
                                            await vm.loadNotifications();
                                          }
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        child: const Text('Accepter'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
