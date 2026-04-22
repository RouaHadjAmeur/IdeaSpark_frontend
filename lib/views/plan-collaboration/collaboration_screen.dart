import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/collaboration.dart';
import '../../models/content_block.dart';
import '../../services/collaboration_service.dart';
import '../../services/content_block_service.dart';
import '../../view_models/auth_view_model.dart';

class _PostWithComments {
  final String postId;
  final List<PostComment> comments;
  _PostWithComments({required this.postId, required this.comments});
}

class CollaborationScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const CollaborationScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  State<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends State<CollaborationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _service = CollaborationService();
  List<CollabMember> _members = [];
  List<HistoryEntry> _history = [];
  List<ContentBlock> _blocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final members = await _service.getMembers(widget.planId);
    final history = await _service.getHistory(widget.planId);
    final blocks = await ContentBlockService().list(planId: widget.planId);
    if (mounted) {
      setState(() {
        _members = members;
        _history = history;
        _blocks = blocks;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      child: Icon(Icons.chevron_left_rounded, size: 22, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Collaboration',
                            style: GoogleFonts.syne(
                                fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                        Text(widget.planName,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  // Invite button
                  if (context.watch<AuthViewModel>().isBrandOwner)
                    GestureDetector(
                      onTap: _showInviteDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          Icon(Icons.person_add, size: 16, color: cs.onPrimary),
                          const SizedBox(width: 6),
                          Text('Inviter',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600, color: cs.onPrimary)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: TabBar(
                controller: _tabs,
                tabs: const [
                  Tab(text: '📋 Mes Tâches'),
                  Tab(text: '👥 Membres'),
                  Tab(text: '💬 Commentaires'),
                  Tab(text: '🕒 Activité'),
                ],
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                indicatorWeight: 2,
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _buildActiveTasksTab(cs),
                        _buildMembersTab(cs),
                        _buildCommentsTab(cs),
                        _buildHistoryTab(cs),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Tasks Tab ─────────────────────────────────────────────────────

  Widget _buildActiveTasksTab(ColorScheme cs) {
    final authVm = context.read<AuthViewModel>();
    final myBlocks = _blocks.where((b) => b.assignedTo == authVm.userId).toList();

    if (myBlocks.isEmpty) {
      return _buildEmpty(
        cs,
        Icons.assignment_turned_in_outlined,
        'Aucune tâche active',
        'Les posts qui vous sont assignés apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myBlocks.length,
      itemBuilder: (context, i) {
        final block = myBlocks[i];
        final pending = block.productionChecklist.entries.where((e) => !e.value).length;
        final total = block.productionChecklist.isEmpty ? 4 : block.productionChecklist.length;
        final progress = total == 0 ? 0.0 : (total - pending) / total;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        block.format?.label ?? 'Post',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  block.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  block.phaseLabel ?? '',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: cs.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '$pending tâches restantes',
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Members Tab ───────────────────────────────────────────────────────────

  Widget _buildMembersTab(ColorScheme cs) {
    if (_members.isEmpty) {
      return _buildEmpty(
        cs,
        Icons.group_outlined,
        'Aucun membre',
        'Invitez des collaborateurs pour travailler ensemble',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildMemberCard(_members[i], cs),
    );
  }

  Widget _buildMemberCard(CollabMember member, ColorScheme cs) {
    final roleColor = _roleColor(member.role);
    final statusColor = member.status == CollabStatus.accepted
        ? Colors.green
        : member.status == CollabStatus.pending
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: roleColor.withValues(alpha: 0.1),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: roleColor),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Flexible(
                  child: Text(member.name,
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(member.roleLabel.toUpperCase(),
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(member.email,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              member.status == CollabStatus.accepted ? 'Membre actif'
                  : member.status == CollabStatus.pending ? 'Invitation en attente'
                  : 'Invitation refusée',
              style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600),
            ),
          ]),
        ),
        if (context.read<AuthViewModel>().isBrandOwner)
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.settings_outlined, size: 20, color: cs.onSurfaceVariant),
              onSelected: (value) async {
                if (value == 'admin') {
                  await _service.updateRole(widget.planId, member.id, CollabRole.admin);
                } else if (value == 'editor') {
                  await _service.updateRole(widget.planId, member.id, CollabRole.editor);
                } else if (value == 'viewer') {
                  await _service.updateRole(widget.planId, member.id, CollabRole.viewer);
                } else if (value == 'remove') {
                  await _service.removeMember(widget.planId, member.id);
                }
                await _load();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'admin', child: Row(children: [Icon(Icons.security_rounded, size: 18), SizedBox(width: 12), Text('Passer en Admin')])),
                const PopupMenuItem(value: 'editor', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 12), Text('Passer en Éditeur')])),
                const PopupMenuItem(value: 'viewer', child: Row(children: [Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 12), Text('Passer en Lecteur')])),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(children: [Icon(Icons.person_remove_rounded, size: 18, color: Colors.red), SizedBox(width: 12), Text('Retirer du projet', style: TextStyle(color: Colors.red))]),
                ),
              ],
            ),
          ),
      ]),
    );
  }

  // ── Comments Tab ──────────────────────────────────────────────────────────

  Widget _buildCommentsTab(ColorScheme cs) {
    return FutureBuilder<List<_PostWithComments>>(
      future: _loadAllComments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];
        final allComments = posts.expand((p) => p.comments).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (allComments.isEmpty) {
          return _buildEmpty(
            cs,
            Icons.chat_bubble_outline,
            'Aucun commentaire',
            'Ouvrez un post dans le plan et cliquez sur l\'icône 💬 pour commenter',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: allComments.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final comment = allComments[i];
            Color? actionColor;
            if (comment.action == ContentAction.approved) actionColor = Colors.green;
            if (comment.action == ContentAction.rejected) actionColor = Colors.red;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: actionColor != null
                    ? actionColor.withValues(alpha: 0.05)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: actionColor != null
                      ? actionColor.withValues(alpha: 0.3)
                      : cs.outlineVariant,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Post title
                Text(
                  comment.postId,
                  style: TextStyle(fontSize: 10, color: cs.primary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: cs.primaryContainer,
                    child: Text(
                      comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(comment.authorName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  const Spacer(),
                  if (actionColor != null)
                    Icon(
                      comment.action == ContentAction.approved ? Icons.check_circle : Icons.cancel,
                      size: 14, color: actionColor,
                    ),
                  const SizedBox(width: 4),
                  Text(_formatTime(comment.createdAt),
                      style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                ]),
                const SizedBox(height: 4),
                Text(comment.text,
                    style: TextStyle(fontSize: 12, color: cs.onSurface)),
              ]),
            );
          },
        );
      },
    );
  }

  Future<List<_PostWithComments>> _loadAllComments() async {
    final postIds = await _service.getCommentedPostIds(widget.planId);
    final result = <_PostWithComments>[];
    for (final postId in postIds) {
      final comments = await _service.getComments(postId);
      if (comments.isNotEmpty) {
        result.add(_PostWithComments(postId: postId, comments: comments));
      }
    }
    return result;
  }

  // ── History Tab ───────────────────────────────────────────────────────────

  Widget _buildHistoryTab(ColorScheme cs) {
    if (_history.isEmpty) {
      return _buildEmpty(
        cs,
        Icons.history,
        'Aucun historique',
        'Les modifications apparaîtront ici',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildHistoryCard(_history[i], cs),
    );
  }

  Widget _buildHistoryCard(HistoryEntry entry, ColorScheme cs) {
    final color = _actionColor(entry.action);
    final icon = _actionIcon(entry.action);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Author name — bold, then action label beside it
            Row(
              children: [
                Flexible(
                  child: Text(
                    entry.authorName,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _actionLabel(entry.action),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Description
            Text(
              entry.description,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 4),
            // Timestamp
            Text(
              _formatTime(entry.createdAt),
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmpty(ColorScheme cs, IconData icon, String title, String subtitle) =>
      Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ]),
      );

  // ── Invite Dialog ─────────────────────────────────────────────────────────

  // Note: _sendInvitationEmail removed as it was unused and replaced by backend invitation logic.

  Future<void> _showInviteDialog() async {
    final searchCtrl = TextEditingController();
    CollabRole selectedRole = CollabRole.editor;
    List<Map<String, dynamic>> searchResults = [];
    Map<String, dynamic>? selectedUser;
    bool isSearching = false;
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Inviter un membre'),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  // Search field
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: 'Rechercher par nom ou email',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onChanged: (q) async {
                      if (q.length < 2) {
                        if (ctx.mounted) setS(() { searchResults = []; selectedUser = null; });
                        return;
                      }
                      if (ctx.mounted) setS(() => isSearching = true);
                      final results = await _service.searchUsers(q);
                      if (ctx.mounted) setS(() { searchResults = results; isSearching = false; });
                    },
                  ),
  
                  // Search results — Column inside SingleChildScrollView avoids
                  // the IntrinsicWidth/ShrinkWrappingViewport conflict in AlertDialog
                  if (searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outlineVariant),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < searchResults.length; i++) ...[
                                if (i > 0) Divider(height: 1, color: cs.outlineVariant),
                                Builder(builder: (_) {
                                  final u = searchResults[i];
                                  final name = (u['username'] ?? u['name'] ?? u['email'] ?? '').toString();
                                  final email = (u['email'] ?? '').toString();
                                  final isSelected = selectedUser?['_id'] == u['_id'] || selectedUser?['id'] == u['id'];
                                  return ListTile(
                                    dense: true,
                                    selected: isSelected,
                                    selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: cs.primaryContainer,
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: TextStyle(fontSize: 12, color: cs.primary),
                                      ),
                                    ),
                                    title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    subtitle: Text(email, style: const TextStyle(fontSize: 11)),
                                    onTap: () => setS(() {
                                      selectedUser = u;
                                      searchCtrl.text = name;
                                      searchResults = [];
                                    }),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
  
                  // Selected user banner
                  if (selectedUser != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Icon(Icons.check_circle, size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            (selectedUser!['username'] ?? selectedUser!['email'] ?? '').toString(),
                            style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                  ],
  
                  const SizedBox(height: 12),
                  // Role selector — Column to avoid Row overflow inside dialog
                  Text('Rôle :', style: TextStyle(fontSize: 13, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: CollabRole.values.map((r) => GestureDetector(
                      onTap: () => setS(() => selectedRole = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selectedRole == r
                              ? _roleColor(r)
                              : _roleColor(r).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r == CollabRole.admin ? 'Admin'
                              : r == CollabRole.editor ? 'Éditeur' : 'Lecteur',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selectedRole == r ? Colors.white : _roleColor(r),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: selectedUser == null ? null : () async {
                final user = selectedUser!;
                final userId = (user['_id'] ?? user['id'] ?? '').toString();
                if (userId.isEmpty) return;
                
                // Capture data before context becomes invalid
                final authVm = context.read<AuthViewModel>(); 
                final currentUserName = authVm.displayName ?? 'Propriétaire';
                final invitedUserName = (user['username'] ?? user['name'] ?? user['email']).toString();
                final roleName = selectedRole == CollabRole.admin ? 'Admin'
                    : selectedRole == CollabRole.editor ? 'Éditeur' : 'Lecteur';

                Navigator.pop(ctx);
                try {
                  await _service.inviteByUserId(widget.planId, userId, role: selectedRole.name);
                  
                  // Log this activity in the timeline
                  await _service.addHistory(widget.planId, HistoryEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    planId: widget.planId,
                    authorName: currentUserName,
                    action: 'invitation',
                    description: '$currentUserName a invité $invitedUserName en tant qu\'$roleName',
                    createdAt: DateTime.now(),
                  ));

                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  await _load();
                  _tabs.animateTo(3);
                  
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ Invitation envoyée à $invitedUserName !'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Inviter'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _roleColor(CollabRole role) {
    switch (role) {
      case CollabRole.admin: return const Color(0xFFE53935);
      case CollabRole.editor: return const Color(0xFF4285F4);
      case CollabRole.viewer: return const Color(0xFF34A853);
    }
  }

  Color _actionColor(String action) {
    switch (action) {
      case 'invitation': return const Color(0xFF4285F4);
      case 'approved': return const Color(0xFF34A853);
      case 'rejected': return const Color(0xFFE53935);
      case 'commented': return const Color(0xFFFF9800);
      default: return const Color(0xFF9C27B0);
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'invitation': return 'INVITÉ';
      case 'approved': return 'ACCEPTÉ';
      case 'rejected': return 'REFUSÉ';
      case 'commented': return 'COMMENTÉ';
      default: return 'MODIFIÉ';
    }
  }

  IconData _actionIcon(String action) {
    switch (action) {
      case 'invitation': return Icons.person_add;
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      case 'commented': return Icons.chat_bubble_outline;
      default: return Icons.edit_outlined;
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
