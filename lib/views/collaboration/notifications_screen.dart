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
                      final notificationId = notification['_id']?.toString() ?? notification['id']?.toString() ?? '';
                      final isHandled = vm.handledNotifications.contains(notificationId);
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
                            vm.markNotificationAsRead(notification['_id'].toString());
                            if (isInvite) {
                              _showInvitationDetails(context, notification, vm);
                            } else if (relatedUser != null) {
                              final userId = (relatedUser['_id'] ?? relatedUser['id'])?.toString();
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
                                if ((isInvite || isFollowRequest) && !isHandled) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          if (isInvite) {
                                            final raw = notification['relatedInvitationId'];
                                            String invitationId = '';
                                            if (raw is Map) {
                                              invitationId = (raw['_id'] ?? raw['id'] ?? '').toString();
                                            } else if (raw != null) {
                                              invitationId = raw.toString();
                                            }
                                            if (invitationId.isNotEmpty) {
                                              vm.declineInvitation(invitationId, notificationId: notificationId);
                                            }
                                          } else {
                                            vm.markNotificationHandled(notificationId);
                                          }
                                        },
                                        style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                                        child: const Text('Refuser'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton(
                                        onPressed: () async {
                                          if (isInvite) {
                                            final raw = notification['relatedInvitationId'];
                                            String invitationId = '';
                                            if (raw is Map) {
                                              invitationId = (raw['_id'] ?? raw['id'] ?? '').toString();
                                            } else if (raw != null) {
                                              invitationId = raw.toString();
                                            }
                                            if (invitationId.isNotEmpty) {
                                              await vm.acceptInvitation(invitationId, notificationId: notificationId);
                                            }
                                          } else if (isFollowRequest && relatedUser != null) {
                                            final followerId = (relatedUser['_id'] ?? relatedUser['id'])?.toString();
                                            if (followerId != null) {
                                              vm.markNotificationHandled(notificationId);
                                              await socialVm.acceptRequest(followerId);
                                              await vm.markNotificationAsRead(notificationId);
                                              await vm.loadNotifications();
                                            }
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

  void _showInvitationDetails(BuildContext context, Map<String, dynamic> notification, CollaborationViewModel vm) {
    final relatedUser = notification['relatedUserId'];
    final relatedUserName = relatedUser != null ? (relatedUser['name'] ?? relatedUser['username'] ?? 'Quelqu\'un') : 'Quelqu\'un';
    final plan = notification['relatedPlanId'];
    final planName = plan != null ? (plan is Map ? (plan['name'] ?? 'Un projet') : 'Un projet') : 'Un projet';
    final notificationId = notification['_id']?.toString() ?? notification['id']?.toString() ?? '';
    
    final raw = notification['relatedInvitationId'];
    String invitationId = '';
    if (raw is Map) {
      invitationId = (raw['_id'] ?? raw['id'] ?? '').toString();
    } else if (raw != null) {
      invitationId = raw.toString();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Détails de l\'invitation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$relatedUserName vous a invité à collaborer.'),
              const SizedBox(height: 12),
              if (planName != 'Un projet')
                Text('Projet : $planName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(notification['message'] ?? 'Rejoignez le projet pour contribuer.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (invitationId.isNotEmpty) {
                  vm.declineInvitation(invitationId, notificationId: notificationId);
                }
              },
              child: const Text('Refuser', style: TextStyle(color: Colors.red)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (invitationId.isNotEmpty) {
                  await vm.acceptInvitation(invitationId, notificationId: notificationId);
                }
              },
              child: const Text('Accepter'),
            ),
          ],
        );
      },
    );
  }
}
