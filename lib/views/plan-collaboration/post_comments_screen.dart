import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/collaboration.dart';
import '../../services/collaboration_service.dart';

class PostCommentsScreen extends StatefulWidget {
  final String postId;
  final String postTitle;
  final String planId;
  final String currentUserName;

  const PostCommentsScreen({
    super.key,
    required this.postId,
    required this.postTitle,
    required this.planId,
    required this.currentUserName,
  });

  @override
  State<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends State<PostCommentsScreen> {
  final _service = CollaborationService();
  final _ctrl = TextEditingController();
  List<PostComment> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final comments = await _service.getComments(widget.postId);
    if (mounted) setState(() { _comments = comments; _loading = false; });
  }

  Future<void> _addComment({ContentAction? action}) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && action == null) return;

    final comment = PostComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.postId,
      planId: widget.planId,
      authorName: widget.currentUserName,
      authorEmail: '',
      text: text.isNotEmpty ? text : (action == ContentAction.approved ? '✅ Approuvé' : '❌ Rejeté'),
      action: action,
      createdAt: DateTime.now(),
    );

    await _service.addComment(comment);

    // Add to history
    if (action != null) {
      await _service.addHistory(widget.planId, HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        planId: widget.planId,
        authorName: widget.currentUserName,
        action: action.name,
        description: '${action == ContentAction.approved ? "Approuvé" : "Rejeté"} : ${widget.postTitle}',
        createdAt: DateTime.now(),
      ));
    }

    _ctrl.clear();
    await _load();
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
                        Text('Commentaires',
                            style: GoogleFonts.syne(
                                fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface)),
                        Text(widget.postTitle,
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Approve/Reject buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _addComment(action: ContentAction.approved),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                          SizedBox(width: 6),
                          Text('Approuver',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _addComment(action: ContentAction.rejected),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 6),
                          Text('Rejeter',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // Comments list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48,
                                color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
                            const SizedBox(height: 12),
                            Text('Aucun commentaire',
                                style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600)),
                          ]),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildComment(_comments[i], cs),
                        ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    maxLines: 2,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _addComment(),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.send_rounded, size: 20, color: cs.onPrimary),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(PostComment comment, ColorScheme cs) {
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
        Row(children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: cs.primaryContainer,
            child: Text(
              comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ),
          const SizedBox(width: 8),
          Text(comment.authorName,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const Spacer(),
          if (actionColor != null)
            Icon(
              comment.action == ContentAction.approved
                  ? Icons.check_circle
                  : Icons.cancel,
              size: 16,
              color: actionColor,
            ),
          const SizedBox(width: 4),
          Text(_formatTime(comment.createdAt),
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ]),
        const SizedBox(height: 6),
        Text(comment.text,
            style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.4)),
      ]),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${t.day}/${t.month}/${t.year}';
  }
}
