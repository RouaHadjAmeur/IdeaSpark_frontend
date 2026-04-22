import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/in_app_notification_service.dart';
import '../../view_models/collaboration_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/collaboration_service.dart';
import '../../models/collaboration.dart';
import '../../services/plan_service.dart';

import '../strategic_content_manager/campaign_workspace_screen.dart';
import '../execution_hub/project_board_screen.dart';
import '../social/user_profile_screen.dart';

export '../../services/in_app_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _localService = InAppNotificationService();

  @override
  void initState() {
    super.initState();
    _localService.addListener(_refresh);
    // Refresh from backend every time this screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CollaborationViewModel>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _localService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _accept(Map<String, dynamic> notif, CollaborationViewModel vm) async {
    final raw = notif['relatedInvitationId'];
    String invitationId = '';
    if (raw is Map) {
      invitationId = (raw['_id'] ?? raw['id'] ?? '').toString();
    } else if (raw != null) {
      invitationId = raw.toString();
    }
    debugPrint('[_accept] raw=$raw  invitationId=$invitationId');
    if (invitationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Invitation ID manquant'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Capture context-dependent refs BEFORE any async gap
    final authVm = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final userName = authVm.displayName ?? 'Collaborateur';

    try {
      await vm.acceptInvitation(invitationId, notificationId: notif['_id']?.toString() ?? notif['id']?.toString());
      await vm.markNotificationAsRead(notif['_id']?.toString() ?? notif['id']?.toString() ?? '');
      
      // Extract context for descriptive log
      final planRaw = notif['relatedPlanId'];
      final roleRaw = notif['role']?.toString() ?? 'editor';
      final roleName = roleRaw == 'admin' ? 'Admin'
          : roleRaw == 'editor' ? 'Éditeur'
          : 'Lecteur';

      // Log to timeline
      if (planRaw is Map) {
        final planId = (planRaw['_id'] ?? planRaw['id'])?.toString();
        final planName = (planRaw['name'] ?? 'ce projet').toString();
        if (planId != null) {
          await CollaborationService().addHistory(planId, HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            planId: planId,
            authorName: userName,
            action: 'invitation',
            description: '$userName a rejoint "$planName" en tant qu\'$roleName',
            createdAt: DateTime.now(),
          ));
        }
      }

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('✅ Invitation acceptée ! Bienvenue dans le projet.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        _handleNavigation(notif);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('❌ $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _decline(Map<String, dynamic> notif, CollaborationViewModel vm) async {
    final raw = notif['relatedInvitationId'];
    String invitationId = '';
    if (raw is Map) {
      invitationId = (raw['_id'] ?? raw['id'] ?? '').toString();
    } else if (raw != null) {
      invitationId = raw.toString();
    }
    debugPrint('[_decline] raw=$raw  invitationId=$invitationId');
    if (invitationId.isEmpty) return;

    // Capture context-dependent refs BEFORE any async gap
    final authVm = context.read<AuthViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final userName = authVm.displayName ?? 'Collaborateur';

    try {
      await vm.declineInvitation(invitationId, notificationId: notif['_id']?.toString() ?? notif['id']?.toString());
      await vm.markNotificationAsRead(notif['_id']?.toString() ?? notif['id']?.toString() ?? '');
      
      // Extract context for descriptive log
      final planRaw = notif['relatedPlanId'];
      if (planRaw is Map) {
        final planId = (planRaw['_id'] ?? planRaw['id'])?.toString();
        final planName = (planRaw['name'] ?? 'ce projet').toString();
        if (planId != null) {
          await CollaborationService().addHistory(planId, HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            planId: planId,
            authorName: userName,
            action: 'rejected',
            description: '$userName a décliné l\'invitation à "$planName"',
            createdAt: DateTime.now(),
          ));
        }
      }

      messenger.showSnackBar(const SnackBar(
        content: Text('Invitation refusée.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('❌ $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final localNotifs = _localService.notifications;

    return Consumer<CollaborationViewModel>(
      builder: (context, vm, _) {
        final backendNotifs = vm.notifications;
        final hasAny = backendNotifs.isNotEmpty || localNotifs.isNotEmpty;

        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            border: Border.all(color: cs.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.chevron_left_rounded,
                              size: 22, color: cs.onSurface),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Notifications',
                          style: GoogleFonts.syne(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      const Spacer(),
                      if (localNotifs.isNotEmpty)
                        TextButton(
                          onPressed: () => _localService.markAllRead(),
                          child: Text('Tout lire',
                              style: TextStyle(fontSize: 12, color: cs.primary)),
                        ),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: vm.loadNotifications,
                    child: !hasAny
                        ? _buildEmpty(cs)
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                            children: [
                              // Backend collaboration notifications
                              if (backendNotifs.isNotEmpty) ...[
                                _sectionLabel('Collaboration', cs),
                                const SizedBox(height: 8),
                                ...backendNotifs.map(
                                    (n) => _buildBackendCard(n, vm, cs)),
                                const SizedBox(height: 20),
                              ],

                              // Local plan/post reminder notifications
                              if (localNotifs.isNotEmpty) ...[
                                _sectionLabel('Rappels', cs),
                                const SizedBox(height: 8),
                                ...localNotifs.map((n) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: _buildLocalCard(n, cs),
                                    )),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String label, ColorScheme cs) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: cs.primary,
          ),
        ),
      );

  Widget _buildBackendCard(
      Map<String, dynamic> notif, CollaborationViewModel vm, ColorScheme cs) {
    final type = notif['type']?.toString() ?? '';
    final isRead = notif['read'] == true;
    final message = notif['message']?.toString() ?? '';
    final inviter = notif['relatedUserId'];
    final plan = notif['relatedPlanId'];
    final inviterName = inviter is Map
        ? (inviter['username'] ?? inviter['name'] ?? 'Someone').toString()
        : 'Someone';
    final planName = plan is Map ? (plan['name'] ?? '').toString() : '';
    final color = _backendColor(type);
    final createdAt = notif['createdAt'] != null
        ? DateTime.tryParse(notif['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
      onTap: () async {
        if (!isRead) await vm.markNotificationAsRead(notif['_id'].toString());
        if (type == 'invite_received') {
          _showInvitationDetails(context, notif, vm, inviterName, planName);
        } else {
          if (mounted) _handleNavigation(notif);
        }
      },
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead
                ? cs.surfaceContainerHighest
                : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isRead
                  ? cs.outlineVariant
                  : color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_backendIcon(type), size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    type == 'invite_received'
                        ? '$inviterName t\'a invité à collaborer'
                        : message,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isRead ? FontWeight.w500 : FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  if (planName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text('📋 $planName',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 2),
                  Text(_formatTime(createdAt),
                      style: TextStyle(
                          fontSize: 10, color: cs.onSurfaceVariant)),
                ]),
              ),
              if (!isRead)
                Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
            ]),

            // Accept / Decline for pending invitations
            if (type == 'invite_received' && !vm.handledNotifications.contains(notif['_id']?.toString() ?? notif['id']?.toString() ?? '')) ...[
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decline(notif, vm),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.error,
                      side: BorderSide(color: cs.error),
                      minimumSize: const Size.fromHeight(36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Refuser',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _accept(notif, vm),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size.fromHeight(36),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accepter',
                        style: TextStyle(fontSize: 13)),
                  ),
                ),
              ]),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildLocalCard(AppNotification item, ColorScheme cs) {
    final color = _localColor(item.type);
    return GestureDetector(
      onTap: () => _localService.markRead(item.id),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.isRead
              ? cs.surfaceContainerHighest
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isRead
                ? cs.outlineVariant
                : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_localIcon(item.type), size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text(item.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: item.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          color: cs.onSurface)),
                ),
                if (!item.isRead)
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
              ]),
              const SizedBox(height: 4),
              Text(item.body,
                  style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Text(_formatTime(item.time),
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _handleNavigation(Map<String, dynamic> notif) async {
    final ctx = context;
    if (!ctx.mounted) return;

    final type = notif['type']?.toString() ?? '';
    final planRaw = notif['relatedPlanId'];
    final userRaw = notif['relatedUserId'];

    // 1. User/Profile navigation
    if (type.contains('follow') || type == 'mention') {
      String? userId;
      if (userRaw is Map) {
        userId = (userRaw['_id'] ?? userRaw['id'])?.toString();
      } else if (userRaw is String) {
        userId = userRaw;
      }

      if (userId != null) {
        Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId!)),
        );
      }
      return;
    }

    // 2. Project/Collaboration navigation
    if (planRaw != null) {
      String? planId;
      if (planRaw is Map) {
        planId = (planRaw['_id'] ?? planRaw['id'])?.toString();
      } else if (planRaw is String) {
        planId = planRaw;
      }

      if (planId != null) {
        try {
          final plan = await PlanService.getPlanById(planId);
          if (!mounted) return;

          // Re-read navigator after mounted check
          final nav = Navigator.of(context);
          if (type == 'task_assigned') {
            nav.push(MaterialPageRoute(builder: (_) => ProjectBoardScreen(plan: plan)));
          } else {
            nav.push(MaterialPageRoute(builder: (_) => CampaignWorkspaceScreen(plan: plan)));
          }
        } catch (e) {
          debugPrint('Failed to navigate to plan: $e');
        }
      }
    }
  }

  Widget _buildEmpty(ColorScheme cs) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.notifications_none_rounded,
              size: 64,
              color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Aucune notification',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface)),
          const SizedBox(height: 8),
          Text('Les invitations de collaboration\napparaîtront ici',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ]),
      );

  Color _backendColor(String type) {
    switch (type) {
      case 'invite_received':       return const Color(0xFF9C27B0);
      case 'invite_accepted':       return const Color(0xFF34A853);
      case 'invite_declined':       return const Color(0xFFE53935);
      case 'task_assigned':         return const Color(0xFF4285F4);
      case 'deliverable_submitted': return const Color(0xFFFF9800);
      case 'collaborator_removed':  return const Color(0xFFE53935);
      default:                      return const Color(0xFF9C27B0);
    }
  }

  IconData _backendIcon(String type) {
    switch (type) {
      case 'invite_received':       return Icons.group_add_rounded;
      case 'invite_accepted':       return Icons.check_circle_outline_rounded;
      case 'invite_declined':       return Icons.cancel_outlined;
      case 'task_assigned':         return Icons.assignment_rounded;
      case 'deliverable_submitted': return Icons.upload_file_rounded;
      case 'collaborator_removed':  return Icons.person_remove_outlined;
      default:                      return Icons.notifications_rounded;
    }
  }

  Color _localColor(String type) {
    switch (type) {
      case 'post':  return const Color(0xFFFF6B35);
      case 'sync':  return const Color(0xFF34A853);
      case 'plan':  return const Color(0xFF4285F4);
      default:      return const Color(0xFF9C27B0);
    }
  }

  IconData _localIcon(String type) {
    switch (type) {
      case 'post':  return Icons.notifications_active_rounded;
      case 'sync':  return Icons.sync_rounded;
      case 'plan':  return Icons.rocket_launch_rounded;
      default:      return Icons.waving_hand_rounded;
    }
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${t.day}/${t.month}/${t.year}';
  }

  void _showInvitationDetails(BuildContext context, Map<String, dynamic> notif, CollaborationViewModel vm, String inviterName, String planName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Détails de l\'invitation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$inviterName vous a invité à collaborer.'),
              const SizedBox(height: 12),
              if (planName.isNotEmpty)
                Text('Projet : $planName', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(notif['message']?.toString() ?? 'Rejoignez le projet pour contribuer.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _decline(notif, vm);
              },
              child: const Text('Refuser', style: TextStyle(color: Colors.red)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _accept(notif, vm);
              },
              child: const Text('Accepter'),
            ),
          ],
        );
      },
    );
  }
}
