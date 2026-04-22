import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/brand_collaborator.dart';
import '../../view_models/collaboration_view_model.dart';

/// Bottom sheet for managing brand collaborators.
/// Shows current team, search to invite, remove members.
class BrandTeamSheet extends StatefulWidget {
  final String brandId;
  final String brandName;

  const BrandTeamSheet({
    super.key,
    required this.brandId,
    required this.brandName,
  });

  static Future<void> show(BuildContext context, String brandId, String brandName) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrandTeamSheet(brandId: brandId, brandName: brandName),
    );
  }

  @override
  State<BrandTeamSheet> createState() => _BrandTeamSheetState();
}

class _BrandTeamSheetState extends State<BrandTeamSheet> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollaborationViewModel>().loadBrandCollaborators(widget.brandId);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bgCard : Colors.white;
    final textColor = isDark ? AppColors.textPrimary : const Color(0xFF1A1D29);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brand Team',
                          style: GoogleFonts.syne(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          widget.brandName,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<CollaborationViewModel>(
                builder: (context, vm, _) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Invite section
                      _buildInviteSection(context, vm, isDark, textColor),
                      const SizedBox(height: 24),
                      // Current team
                      _buildTeamSection(context, vm, isDark, textColor),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteSection(BuildContext context, CollaborationViewModel vm, bool isDark, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INVITE COLLABORATOR',
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name or email…',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search, size: 18,
                      color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0)),
                  filled: true,
                  fillColor: isDark ? AppColors.bgElevated : const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (val) {
                  if (val.trim().length >= 2) {
                    vm.searchUsers(val.trim());
                  }
                },
              ),
            ),
          ],
        ),
        // Search results
        if (vm.searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgElevated : const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.searchResults.length.clamp(0, 5),
              separatorBuilder: (context, _) => Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, i) {
                final user = vm.searchResults[i];
                final alreadyMember = vm.brandCollaborators.any((c) => c.userId == user.id);
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    user.displayName,
                    style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    user.email,
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0)),
                  ),
                  trailing: alreadyMember
                      ? Text('Already invited',
                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0)))
                      : TextButton(
                          onPressed: vm.isLoading
                              ? null
                              : () => _invite(context, vm, user.id, user.displayName),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: Text('INVITE',
                              style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTeamSection(BuildContext context, CollaborationViewModel vm, bool isDark, Color textColor) {
    final collaborators = vm.brandCollaborators;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CURRENT TEAM',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${collaborators.length}',
                style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (vm.isLoading && collaborators.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: AppColors.primary),
          ))
        else if (collaborators.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgElevated : const Color(0xFFF5F6FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'No collaborators yet.\nInvite someone to join your brand team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0),
                  height: 1.5,
                ),
              ),
            ),
          )
        else
          ...collaborators.map((c) => _buildMemberTile(context, vm, c, isDark, textColor)),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, CollaborationViewModel vm, BrandCollaborator collab, bool isDark, Color textColor) {
    final name = collab.userName ?? 'Unknown User';
    final email = collab.userEmail ?? '';
    final isPending = collab.isPending;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgElevated : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPending ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: (isPending ? AppColors.accent : AppColors.primary).withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isPending ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                if (email.isNotEmpty)
                  Text(email, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isPending ? AppColors.accent : AppColors.success).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (isPending ? AppColors.accent : AppColors.success).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              isPending ? 'PENDING' : 'ACTIVE',
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isPending ? AppColors.accent : AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 16, color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0)),
            color: isDark ? AppColors.bgCard : Colors.white,
            onSelected: (v) {
              if (v == 'remove') _removeCollaborator(context, vm, collab);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'remove', child: Text('Remove')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _invite(BuildContext context, CollaborationViewModel vm, String userId, String userName) async {
    _searchCtrl.clear();
    try {
      await vm.inviteToBrand(widget.brandId, userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invitation sent to $userName')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _removeCollaborator(BuildContext context, CollaborationViewModel vm, BrandCollaborator collab) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Collaborator'),
        content: Text('Remove ${collab.userName ?? 'this user'} from the brand team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await vm.removeBrandCollaborator(widget.brandId, collab.userId);
    }
  }
}
