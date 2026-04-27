import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../view_models/collaboration_view_model.dart';

class ProjectActivityBoard extends StatefulWidget {
  final String planId;
  const ProjectActivityBoard({super.key, required this.planId});

  @override
  State<ProjectActivityBoard> createState() => _ProjectActivityBoardState();
}

class _ProjectActivityBoardState extends State<ProjectActivityBoard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollaborationViewModel>().loadActivityLog(widget.planId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<CollaborationViewModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Text(
            'Activité du projet',
            style: GoogleFonts.syne(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: vm.isLoading && vm.activityLog.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => vm.loadActivityLog(widget.planId),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: vm.activityLog.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final activity = vm.activityLog[index];
                      final dateStr = activity['createdAt'] as String;
                      final date = DateTime.parse(dateStr).toLocal();
                      final formattedDate = DateFormat('dd/MM HH:mm').format(date);
                      
                      return _ActivityItem(
                        userName: activity['userName'] ?? 'Utilisateur',
                        action: activity['actionType'] ?? 'modifié',
                        field: activity['fieldChanged'],
                        oldValue: activity['oldValue'],
                        newValue: activity['newValue'],
                        timestamp: formattedDate,
                        colorScheme: colorScheme,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String userName;
  final String action;
  final String? field;
  final String? oldValue;
  final String? newValue;
  final String timestamp;
  final ColorScheme colorScheme;

  const _ActivityItem({
    required this.userName,
    required this.action,
    this.field,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    String message = '';
    IconData icon;
    Color iconColor;

    switch (action) {
      case 'create':
        message = 'a créé le projet';
        icon = Icons.add_circle_outline;
        iconColor = Colors.green;
        break;
      case 'invite':
        message = 'a invité un nouveau collaborateur';
        icon = Icons.person_add_outlined;
        iconColor = Colors.blue;
        break;
      case 'accept':
        message = 'a rejoint le projet';
        icon = Icons.person_outline_rounded;
        iconColor = Colors.purple;
        break;
      case 'delete':
        message = 'a supprimé un élément: $field';
        icon = Icons.delete_outline_rounded;
        iconColor = Colors.red;
        break;
      default:
        message = 'a modifié $field';
        icon = Icons.edit_note_rounded;
        iconColor = Colors.orange;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                  children: [
                    TextSpan(
                      text: userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' $message '),
                  ],
                ),
              ),
              if (oldValue != null || newValue != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (oldValue != null) ...[
                        Expanded(child: Text(oldValue!, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12, decoration: TextDecoration.lineThrough))),
                        const Icon(Icons.arrow_forward, size: 12),
                      ],
                      if (newValue != null)
                        Expanded(child: Text(newValue!, style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                timestamp,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
