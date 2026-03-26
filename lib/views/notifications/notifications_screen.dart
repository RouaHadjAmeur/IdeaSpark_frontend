import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/in_app_notification_service.dart';

export '../../services/in_app_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = InAppNotificationService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_refresh);
  }

  @override
  void dispose() {
    _service.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notifications = _service.notifications;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
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
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => _service.markAllRead(),
                      child: Text('Tout lire',
                          style: TextStyle(fontSize: 12, color: cs.primary)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? _buildEmpty(cs)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _buildCard(notifications[i], cs),
                    ),
            ),
          ],
        ),
      ),
    );
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
          Text('Activez les rappels dans vos plans\npour recevoir des alertes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ]),
      );

  Widget _buildCard(AppNotification item, ColorScheme cs) {
    final color = _color(item.type);
    return GestureDetector(
      onTap: () => _service.markRead(item.id),
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
            child: Icon(_icon(item.type), size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
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
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
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

  Color _color(String type) {
    switch (type) {
      case 'post': return const Color(0xFFFF6B35);
      case 'sync': return const Color(0xFF34A853);
      case 'plan': return const Color(0xFF4285F4);
      default: return const Color(0xFF9C27B0);
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'post': return Icons.notifications_active_rounded;
      case 'sync': return Icons.sync_rounded;
      case 'plan': return Icons.rocket_launch_rounded;
      default: return Icons.waving_hand_rounded;
    }
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${t.day}/${t.month}/${t.year}';
  }
}
