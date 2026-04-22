import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../view_models/plan_view_model.dart';
import '../../view_models/collaboration_view_model.dart';

import '../../models/plan.dart' as pl;
import '../../models/content_block.dart';
import '../../models/collaboration.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/content_block_service.dart';
import '../../services/collaboration_service.dart';
import '../../services/in_app_notification_service.dart';

class ProjectBoardScreen extends StatefulWidget {
  final pl.Plan plan;

  const ProjectBoardScreen({super.key, required this.plan});

  @override
  State<ProjectBoardScreen> createState() => _ProjectBoardScreenState();
}

class _ProjectBoardScreenState extends State<ProjectBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ContentBlock> _blocks = [];
  bool _isLoading = false;
  String? _error;
  final _service = ContentBlockService();

  static const _tabs = ['Board', 'Timeline', 'Calendar', 'Notes'];

  // Kanban column definitions: (status, label, color)
  static const _columns = [
    (ContentBlockStatus.idea, 'Planned', Color(0xFF757575)),
    (ContentBlockStatus.approved, 'Approved', Color(0xFF2196F3)),
    (ContentBlockStatus.scheduled, 'Scheduled', Color(0xFFFF9800)),
    (ContentBlockStatus.inProcess, 'In Progress', Color(0xFF4CAF50)),
    (ContentBlockStatus.terminated, 'Terminated', Color(0xFFE91E63)),
  ];

  late TextEditingController _notesCtrl;
  List<CollabMember> _mentionSuggestions = [];
  bool _showMentions = false;
  bool _isMonthlyView = true;
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 3 && widget.plan.notesSeen == false) {
        // Notes tab selected
        final authVm = context.read<AuthViewModel>();
        if (!authVm.isBrandOwner) {
           context.read<PlanViewModel>().markNoteAsSeen(widget.plan.id!);
        }
      }
    });

    _notesCtrl = TextEditingController(text: widget.plan.notes);
    _notesCtrl.addListener(_onNotesChanged);
    _loadBlocks();
    // Defer to post-frame so CollaborationViewModel.notifyListeners()
    // is not triggered during the initial build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCollaborators();
    });
  }

  void _loadCollaborators() {
    context.read<CollaborationViewModel>().loadMembers(widget.plan.id!);
  }

  void _onNotesChanged() {
    final text = _notesCtrl.text;
    final selection = _notesCtrl.selection;
    if (selection.baseOffset <= 0) {
      if (_showMentions) setState(() => _showMentions = false);
      return;
    }

    final lastChar = text.substring(selection.baseOffset - 1, selection.baseOffset);
    if (lastChar == '@') {
      setState(() {
        _showMentions = true;
        _mentionSuggestions = context.read<CollaborationViewModel>().members;
      });
    } else if (_showMentions) {
      // Find current word
      final beforeCursor = text.substring(0, selection.baseOffset);
      final atIndex = beforeCursor.lastIndexOf('@');
      if (atIndex != -1) {
        final query = beforeCursor.substring(atIndex + 1).toLowerCase();
        setState(() {
          _mentionSuggestions = context.read<CollaborationViewModel>().members
              .where((m) => m.name.toLowerCase().contains(query) || m.email.toLowerCase().contains(query))
              .toList();
          if (_mentionSuggestions.isEmpty && query.isNotEmpty) _showMentions = false;
        });
      } else {
        setState(() => _showMentions = false);
      }
    }
  }

  void _insertMention(CollabMember member) {
    final text = _notesCtrl.text;
    final selection = _notesCtrl.selection;
    final beforeCursor = text.substring(0, selection.baseOffset);
    final atIndex = beforeCursor.lastIndexOf('@');
    
    if (atIndex != -1) {
      final newText = text.replaceRange(atIndex, selection.baseOffset, '@${member.name} ');
      _notesCtrl.text = newText;
      _notesCtrl.selection = TextSelection.collapsed(offset: atIndex + member.name.length + 2);
    }
    setState(() => _showMentions = false);
  }

  // ─── Monthly Calendar Helpers ─────────────────────────────────────────────

  String get _monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_currentMonth.month - 1]} ${_currentMonth.year}';
  }

  void _prevMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });

  Map<int, List<ContentBlock>> _monthEntries() {
    final result = <int, List<ContentBlock>>{};
    for (final b in _blocks) {
      if (b.scheduledAt != null &&
          b.scheduledAt!.year == _currentMonth.year &&
          b.scheduledAt!.month == _currentMonth.month) {
        result.putIfAbsent(b.scheduledAt!.day, () => []).add(b);
      }
    }
    return result;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBlocks() async {
    if (widget.plan.id == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _blocks = await _service.list(planId: widget.plan.id!);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, ContentBlockStatus newStatus) async {
    try {
      final updated = await _service.updateStatus(id, newStatus);
      setState(() {
        final idx = _blocks.indexWhere((b) => b.id == id);
        if (idx >= 0) _blocks[idx] = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Update failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _scheduleBlock(String id, DateTime dt) async {
    try {
      final updated = await _service.schedule(id, dt);
      setState(() {
        final idx = _blocks.indexWhere((b) => b.id == id);
        if (idx >= 0) _blocks[idx] = updated;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Schedule failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _updateAssignment(String id, String? userId, String? userName) async {
    try {
      final updated = await _service.updateAssignment(id, userId: userId, userName: userName);
      setState(() {
        final idx = _blocks.indexWhere((b) => b.id == id);
        if (idx >= 0) _blocks[idx] = updated;
      });

      // Notify the collaborator
      if (userId != null && userId.isNotEmpty) {
        InAppNotificationService().add(AppNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          title: 'Nouvelle tâche assignée ! 📋',
          body: 'On vous a assigné la tâche "${updated.title}"',
          time: DateTime.now(),
          type: 'assignment',
        ));
        
        // Add to history
        await CollaborationService().addHistory(
          widget.plan.id!,
          HistoryEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            planId: widget.plan.id!,
            authorName: context.read<AuthViewModel>().displayName ?? 'Admin',
            action: 'ASSIGNMENT',
            description: 'A assigné "${updated.title}" à $userName',
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Assignment failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(cs),
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                    bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                indicatorWeight: 2,
              ),
            ),
            // Tab views
            Expanded(
              child: _isLoading && _blocks.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBoardTab(cs),
                        _buildTimelineTab(cs),
                        _buildCalendarTab(cs),
                        _buildNotesTab(cs),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail Sheet ─────────────────────────────────────────────────────────────

  void _showItemDetail(ContentBlock block) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ContentItemDetailSheet(
        block: block,
        onStatusChange: (s) => _updateStatus(block.id, s),
        onSchedule: (dt) => _scheduleBlock(block.id, dt),
        onAssign: (userId, userName) => _updateAssignment(block.id, userId, userName),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.name,
                  style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_blocks.length} content item${_blocks.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cs.primary),
              ),
            ),
          GestureDetector(
            onTap: _loadBlocks,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.refresh_rounded,
                  size: 18, color: cs.onSurface),
            ),
          ),
        ]),
      );

  // ── Board Tab (Kanban) ──────────────────────────────────────────────────────

  Widget _buildBoardTab(ColorScheme cs) {
    if (_error != null && _blocks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurface)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadBlocks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ]),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _columns.map((col) {
          final (status, label, color) = col;
          final colBlocks =
              _blocks.where((b) => b.status == status).toList();
          return _KanbanColumn(
            label: label,
            color: color,
            blocks: colBlocks,
            onCardTap: (block) => _showItemDetail(block),
          );
        }).toList(),
      ),
    );
  }

  // ── Timeline Tab ────────────────────────────────────────────────────────────

  Widget _buildTimelineTab(ColorScheme cs) {
    final phases = widget.plan.phases;
    if (phases.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.layers_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('No phases defined',
              style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Phases are created automatically when a plan is generated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: phases.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _PhaseCard(phase: phases[i], cs: cs),
    );
  }

  Widget _buildCalendarTab(ColorScheme cs) {
    return Column(
      children: [
        // Header with view toggle and month navigation
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              if (_isMonthlyView) ...[
                GestureDetector(onTap: _prevMonth, child: Icon(Icons.chevron_left_rounded, size: 20, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Text(_monthLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(width: 8),
                GestureDetector(onTap: _nextMonth, child: Icon(Icons.chevron_right_rounded, size: 20, color: cs.onSurfaceVariant)),
              ] else
                Text('SCHEDULED POSTS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant, letterSpacing: 0.5)),
              const Spacer(),
              _viewToggle(cs),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _isMonthlyView ? _buildMonthlyGrid(cs) : _buildScheduledList(cs),
        ),
      ],
    );
  }

  Widget _viewToggle(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleItem('MO', _isMonthlyView, () => setState(() => _isMonthlyView = true), cs),
          _toggleItem('LI', !_isMonthlyView, () => setState(() => _isMonthlyView = false), cs),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, bool active, VoidCallback onTap, ColorScheme cs) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? cs.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? cs.primary : cs.onSurfaceVariant)),
      ),
    );
  }

  Widget _buildMonthlyGrid(ColorScheme cs) {
    final byDay = _monthEntries();
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();
    final isCurrentMonth = today.year == _currentMonth.year && today.month == _currentMonth.month;

    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: dayLabels.map((l) => Expanded(child: Center(child: Text(l, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant))))).toList()),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.85),
            itemCount: rows * 7,
            itemBuilder: (context, index) {
              final dayNum = index - leadingBlanks + 1;
              if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
              final isToday = isCurrentMonth && dayNum == today.day;
              final dayBlocks = byDay[dayNum] ?? [];
              final hasDots = dayBlocks.isNotEmpty;

              return GestureDetector(
                onTap: () {
                   if (dayBlocks.isNotEmpty) {
                     // Show detail for first block or a list? 
                     // For now, list is simpler if multiple, but user said "dots"
                     _showItemDetail(dayBlocks.first);
                   }
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? cs.primary.withValues(alpha: 0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isToday ? cs.primary.withValues(alpha: 0.3) : Colors.transparent),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum', style: TextStyle(fontSize: 11, color: isToday ? cs.primary : cs.onSurface, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
                      if (hasDots) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayBlocks.take(3).map((b) => Container(
                            width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(color: Color(0xFFFF9800), shape: BoxShape.circle),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledList(ColorScheme cs) {
    final scheduled = _blocks.where((b) => b.scheduledAt != null).toList()..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));
    if (scheduled.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.calendar_today_outlined,
              size: 48,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('Nothing scheduled',
              style: TextStyle(
                  color: cs.onSurface, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Open the Board tab and schedule content items.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: cs.onSurfaceVariant)),
        ]),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: scheduled.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _ScheduledTile(block: scheduled[i], cs: cs, onTap: () => _showItemDetail(scheduled[i])),
    );
  }

  // ── Notes Tab ───────────────────────────────────────────────────────────────

  Widget _buildNotesTab(ColorScheme cs) {
    final vm = context.read<PlanViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionLabel('CAMPAIGN NOTEBOOK', cs),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 8,
                    minLines: 4,
                    style: TextStyle(fontSize: 14, color: cs.onSurface, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Jot down ideas, reminders, or @mention collaborators...',
                      hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                      border: InputBorder.none,
                    ),
                  ),
                  if (_showMentions && _mentionSuggestions.isNotEmpty)
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _mentionSuggestions.length,
                          itemBuilder: (context, i) {
                            final m = _mentionSuggestions[i];
                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              title: Text(m.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(m.email, style: const TextStyle(fontSize: 11)),
                              onTap: () => _insertMention(m),
                            );
                          },
                        ),
                      ),
                    ),
                  if (widget.plan.lastNoteAuthorId != null && widget.plan.lastNoteAuthorId!.isNotEmpty)
                    Positioned(
                      top: 4, right: 8,
                      child: Text(
                        'Last edit by brand owner',
                        style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Reaction/Confirm button (Seen ✅)
                  if (!context.read<AuthViewModel>().isBrandOwner)
                    TextButton.icon(
                      onPressed: widget.plan.notesSeen
                          ? null
                          : () => context.read<PlanViewModel>().markNoteAsSeen(widget.plan.id!),
                      icon: Icon(
                        widget.plan.notesSeen ? Icons.check_circle_rounded : Icons.remove_red_eye_outlined,
                        size: 16,
                        color: widget.plan.notesSeen ? Colors.green : cs.primary,
                      ),
                      label: Text(
                        widget.plan.notesSeen ? 'Seen' : 'Mark as Seen',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.plan.notesSeen ? Colors.green : cs.primary,
                        ),
                      ),
                    )
                  else
                    // Admin view of "seen" status
                    Row(
                      children: [
                        Icon(
                          widget.plan.notesSeen ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 16,
                          color: widget.plan.notesSeen ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.plan.notesSeen ? 'Seen by collaborator' : 'Not seen yet',
                          style: TextStyle(fontSize: 11, color: widget.plan.notesSeen ? Colors.blue : Colors.grey),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (vm.isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: vm.isSaving
                        ? null
                        : () async {
                            final authVm = context.read<AuthViewModel>();
                            final text = _notesCtrl.text.trim();
                            // Pass current user ID as authorId to track who made the note
                            final ok = await vm.updatePlanNotes(
                              widget.plan.id!, 
                              text, 
                              authorId: authVm.userId
                            );
                            if (ok && mounted) {
                              // Notify collaborators if author is brand owner
                              if (authVm.isBrandOwner) {
                                InAppNotificationService().add(AppNotification(
                                  id: DateTime.now().millisecondsSinceEpoch,
                                  title: 'Note de l\'admin 📝',
                                  body: 'L\'admin a ajouté une note sur votre plan "${widget.plan.name}"',
                                  time: DateTime.now(),
                                  type: 'note',
                                ));
                              }

                              // Trigger mention notifications locally (Simulating Backend)
                              final collabVm = context.read<CollaborationViewModel>();
                              final mentions = collabVm.members.where((m) => text.contains('@${m.name}')).toList();
                              for (final _ in mentions) {
                                InAppNotificationService().add(AppNotification(
                                  id: DateTime.now().millisecondsSinceEpoch,
                                  title: 'You were mentioned! 💬',
                                  body: 'You were mentioned in the notes for "${widget.plan.name}"',
                                  time: DateTime.now(),
                                  type: 'mention',
                                ));
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(mentions.isNotEmpty ? 'Notes saved & collaborators notified' : 'Notes saved successfully'),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ));
                            } else if (!ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Failed to save notes: ${vm.error ?? "Unknown error"}'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                              ));
                            }
                          },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Notes'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _SectionLabel('PLAN OVERVIEW', cs),
        const SizedBox(height: 12),
        _InfoCard(cs: cs, children: [
          _InfoRow('Objective',
              '${widget.plan.objective.emoji} ${widget.plan.objective.label}',
              cs),
          _InfoRow('Duration',
              '${widget.plan.durationWeeks} weeks', cs),
          _InfoRow('Frequency',
              '${widget.plan.postingFrequency}x / week', cs),
          _InfoRow(
              'Intensity', widget.plan.promotionIntensity, cs),
          if (widget.plan.platforms.isNotEmpty)
            _InfoRow(
                'Platforms', widget.plan.platforms.join(', '), cs),
        ]),
        const SizedBox(height: 20),
        _SectionLabel('CONTENT MIX', cs),
        const SizedBox(height: 12),
        _InfoCard(
          cs: cs,
          children: widget.plan.contentMixPreference.entries
              .where((e) => !e.key.toLowerCase().contains('id'))
              .map((e) => _InfoRow(e.key.toUpperCase(), '${e.value}%', cs))
              .toList(),
        ),
        if (widget.plan.phases
            .any((p) => p.description != null)) ...[
          const SizedBox(height: 20),
          _SectionLabel('PHASE NOTES', cs),
          const SizedBox(height: 12),
          ...widget.plan.phases
              .where((p) => p.description != null)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: cs.outlineVariant),
                    ),
                    child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week ${p.weekNumber} · ${p.name}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.description!,
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                                height: 1.4),
                          ),
                        ]),
                  ),
                ),
              ),
        ],
      ]),
    );
  }

}

// ── Kanban Column ─────────────────────────────────────────────────────────────

class _KanbanColumn extends StatelessWidget {
  final String label;
  final Color color;
  final List<ContentBlock> blocks;
  final void Function(ContentBlock) onCardTap;

  const _KanbanColumn({
    required this.label,
    required this.color,
    required this.blocks,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${blocks.length}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),
          ),
          const SizedBox(height: 10),

          // Cards (or empty state)
          if (blocks.isEmpty)
            Container(
              margin: const EdgeInsets.only(right: 12),
              height: 60,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: cs.outlineVariant
                        .withValues(alpha: 0.5)),
              ),
              child: Center(
                child: Text('Empty',
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant)),
              ),
            )
          else
            ...blocks.map((b) => Padding(
                  padding:
                      const EdgeInsets.only(right: 12, bottom: 8),
                  child: _KanbanCard(
                    block: b,
                    accentColor: color,
                    onTap: () => onCardTap(b),
                  ),
                )),
        ],
      ),
    );
  }
}

// ── Kanban Card ───────────────────────────────────────────────────────────────

class _KanbanCard extends StatelessWidget {
  final ContentBlock block;
  final Color accentColor;
  final VoidCallback onTap;

  const _KanbanCard({
    required this.block,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type chip + platform icon
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _typeShort(block.contentType),
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor),
                  ),
                ),
                const Spacer(),
                Icon(_platformIcon(block.platform),
                    size: 13, color: cs.onSurfaceVariant),
              ]),
              const SizedBox(height: 8),

              // Title
              Text(
                block.title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (block.format != null) ...[
                const SizedBox(height: 5),
                Text(
                  block.format!.name.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.5),
                ),
              ],

              if (block.scheduledAt != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.schedule_rounded,
                      size: 10, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDate(block.scheduledAt!),
                    style: TextStyle(
                        fontSize: 10,
                        color: cs.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ],

              // CTA chip
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${block.ctaType.name} CTA',
                  style: TextStyle(
                      fontSize: 9, color: cs.onSurfaceVariant),
                ),
              ),
            ]),
      ),
    );
  }

  String _typeShort(ContentType t) {
    switch (t) {
      case ContentType.educational:
        return 'EDU';
      case ContentType.promo:
        return 'PROMO';
      case ContentType.teaser:
        return 'TEASER';
      case ContentType.launch:
        return 'LAUNCH';
      case ContentType.socialProof:
        return 'PROOF';
      case ContentType.objection:
        return 'OBJ';
      case ContentType.behindScenes:
        return 'BTS';
      case ContentType.authority:
        return 'AUTH';
    }
  }

  IconData _platformIcon(ContentPlatform p) {
    switch (p) {
      case ContentPlatform.tiktok:
        return Icons.music_note_rounded;
      case ContentPlatform.instagram:
        return Icons.photo_camera_rounded;
      case ContentPlatform.youtube:
        return Icons.play_circle_rounded;
      case ContentPlatform.facebook:
        return Icons.facebook;
      case ContentPlatform.linkedin:
        return Icons.work_rounded;
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ── Phase Card (Timeline tab) ─────────────────────────────────────────────────

class _PhaseCard extends StatefulWidget {
  final pl.Phase phase;
  final ColorScheme cs;

  const _PhaseCard({required this.phase, required this.cs});

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(
            color: _expanded
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _expanded ? cs.primary : cs.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('W${widget.phase.weekNumber}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _expanded
                              ? cs.onPrimary
                              : cs.primary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.phase.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface)),
                      if (widget.phase.description != null)
                        Text(widget.phase.description!,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ]),
              ),
              Text(
                '${widget.phase.contentBlocks.length} posts',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ]),
          ),
        ),
        if (_expanded && widget.phase.contentBlocks.isNotEmpty) ...[
          Divider(height: 1, color: cs.outlineVariant),
          ...widget.phase.contentBlocks.map((b) => Padding(
                padding:
                    const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(b.format.name.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: cs.primary)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(b.title,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
              )),
        ],
      ]),
    );
  }
}

// ── Scheduled Tile (Calendar tab) ─────────────────────────────────────────────

class _ScheduledTile extends StatelessWidget {
  final ContentBlock block;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _ScheduledTile(
      {required this.block, required this.cs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(children: [
          // Date box
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${block.scheduledAt!.day}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.primary)),
              Text(_monthAbbr(block.scheduledAt!.month),
                  style:
                      TextStyle(fontSize: 10, color: cs.primary)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(block.title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(_platformIcon(block.platform),
                        size: 11, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${block.platform.name} · ${block.format?.name ?? ''}',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant),
                    ),
                  ]),
                ]),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(block.status)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(block.status.label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(block.status))),
          ),
        ]),
      ),
    );
  }

  IconData _platformIcon(ContentPlatform p) {
    switch (p) {
      case ContentPlatform.tiktok:
        return Icons.music_note_rounded;
      case ContentPlatform.instagram:
        return Icons.photo_camera_rounded;
      case ContentPlatform.youtube:
        return Icons.play_circle_rounded;
      case ContentPlatform.facebook:
        return Icons.facebook;
      case ContentPlatform.linkedin:
        return Icons.work_rounded;
    }
  }

  Color _statusColor(ContentBlockStatus s) {
    switch (s) {
      case ContentBlockStatus.idea:
        return const Color(0xFF757575);
      case ContentBlockStatus.approved:
        return const Color(0xFF2196F3);
      case ContentBlockStatus.scheduled:
        return const Color(0xFFFF9800);
      case ContentBlockStatus.inProcess:
        return const Color(0xFF4CAF50);
      case ContentBlockStatus.terminated:
        return const Color(0xFFE91E63);
    }
  }

  String _monthAbbr(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];
}

// ── Content Item Detail Sheet ─────────────────────────────────────────────────

class _ContentItemDetailSheet extends StatefulWidget {
  final ContentBlock block;
  final void Function(ContentBlockStatus) onStatusChange;
  final void Function(DateTime) onSchedule;
  final void Function(String?, String?) onAssign;

  const _ContentItemDetailSheet({
    required this.block,
    required this.onStatusChange,
    required this.onSchedule,
    required this.onAssign,
  });

  @override
  State<_ContentItemDetailSheet> createState() =>
      _ContentItemDetailSheetState();
}

class _ContentItemDetailSheetState
    extends State<_ContentItemDetailSheet> {
  late ContentBlockStatus _selectedStatus;
  late Map<String, bool> _checklist;
  final _service = ContentBlockService();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.block.status;
    _checklist = Map<String, bool>.from(widget.block.productionChecklist.isEmpty
        ? {
            'Script': false,
            'Shoot / Record': false,
            'Edit': false,
            'Upload': false,
          }
        : widget.block.productionChecklist);
  }

  static Color _statusColor(ContentBlockStatus s) {
    switch (s) {
      case ContentBlockStatus.idea:
        return const Color(0xFF757575);
      case ContentBlockStatus.approved:
        return const Color(0xFF2196F3);
      case ContentBlockStatus.scheduled:
        return const Color(0xFFFF9800);
      case ContentBlockStatus.inProcess:
        return const Color(0xFF4CAF50);
      case ContentBlockStatus.terminated:
        return const Color(0xFFE91E63);
    }
  }

  static String _typeLabel(ContentType t) {
    switch (t) {
      case ContentType.educational:
        return 'Educational';
      case ContentType.promo:
        return 'Promotional';
      case ContentType.teaser:
        return 'Teaser';
      case ContentType.launch:
        return 'Launch';
      case ContentType.socialProof:
        return 'Social Proof';
      case ContentType.objection:
        return 'Objection';
      case ContentType.behindScenes:
        return 'Behind Scenes';
      case ContentType.authority:
        return 'Authority';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding:
                  const EdgeInsets.fromLTRB(20, 4, 20, 40),
              children: [
                // Title
                Text(widget.block.title,
                    style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
                const SizedBox(height: 8),

                // Metadata chips
                Wrap(spacing: 8, runSpacing: 6, children: [
                  _Chip(
                      _typeLabel(widget.block.contentType),
                      cs.primary,
                      cs),
                  _Chip(widget.block.platform.name,
                      const Color(0xFF2196F3), cs),
                  if (widget.block.format != null)
                    _Chip(widget.block.format!.name,
                        const Color(0xFFFF9800), cs),
                  _Chip(
                      '${widget.block.ctaType.name} CTA',
                      cs.secondary,
                      cs),
                ]),
                const SizedBox(height: 16),

                // Assignment Section
                _SectionLabel('ASSIGNED TO', cs),
                const SizedBox(height: 8),
                Consumer<CollaborationViewModel>(
                  builder: (context, collabVm, _) {
                    final members = collabVm.members;
                    final assignedTo = widget.block.assignedTo;
                    final assignedName = widget.block.assignedToName ?? 'Unassigned';

                    return GestureDetector(
                      onTap: () async {
                        final selected = await showDialog<CollabMember>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: cs.surface,
                            title: const Text('Assign to...', style: TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.bold)),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: members.length + 1,
                                itemBuilder: (ctx, i) {
                                  if (i == 0) {
                                    return ListTile(
                                      title: const Text('Unassigned', style: TextStyle(color: Colors.red)),
                                      onTap: () => Navigator.pop(ctx, null),
                                    );
                                  }
                                  final m = members[i - 1];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      radius: 14,
                                      backgroundColor: cs.primaryContainer,
                                      child: Text(m.name[0].toUpperCase(), style: TextStyle(fontSize: 10, color: cs.primary)),
                                    ),
                                    title: Text(m.name, style: const TextStyle(fontSize: 13)),
                                    onTap: () => Navigator.pop(ctx, m),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                        if (context.mounted) {
                           // Always trigger if unassigning or assigning 
                           widget.onAssign(selected?.id, selected?.name);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: assignedTo != null ? cs.primaryContainer : cs.outlineVariant.withValues(alpha: 0.2),
                              child: Text(
                                assignedName.isNotEmpty ? assignedName[0].toUpperCase() : '?',
                                style: TextStyle(fontSize: 10, color: assignedTo != null ? cs.primary : cs.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(assignedName, style: TextStyle(fontSize: 13, fontWeight: assignedTo != null ? FontWeight.w600 : FontWeight.normal)),
                            const Spacer(),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: cs.onSurfaceVariant),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Description
                if (widget.block.description != null) ...[
                  _SectionLabel('DESCRIPTION', cs),
                  const SizedBox(height: 6),
                  Text(widget.block.description!,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface,
                          height: 1.5)),
                  const SizedBox(height: 16),
                ],

                // Hooks
                if (widget.block.hooks.isNotEmpty) ...[
                  _SectionLabel('HOOKS', cs),
                  const SizedBox(height: 8),
                  ...widget.block.hooks.asMap().entries.map(
                        (e) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 6),
                          child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: cs.primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${e.key + 1}',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: cs.primary)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(e.value,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: cs.onSurface,
                                          height: 1.4)),
                                ),
                              ]),
                        ),
                      ),
                  const SizedBox(height: 16),
                ],

                // Script outline
                if (widget.block.scriptOutline != null) ...[
                  _SectionLabel('SCRIPT OUTLINE', cs),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: cs.outlineVariant),
                    ),
                    child: SelectableText(
                      widget.block.scriptOutline!,
                      style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface,
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: widget.block.scriptOutline!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Script copied'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.content_copy_rounded,
                        size: 14),
                    label: const Text('Copy Script'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tags
                if (widget.block.tags.isNotEmpty) ...[
                  _SectionLabel('TAGS', cs),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.block.tags
                        .map((t) => Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    cs.surfaceContainerHighest,
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: cs.outlineVariant),
                              ),
                              child: Text('#$t',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          cs.onSurfaceVariant)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Status selector
                _SectionLabel('STATUS', cs),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ContentBlockStatus.values.map((s) {
                      final color = _statusColor(s);
                      final isSelected = _selectedStatus == s;
                      return Padding(
                        padding:
                            const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(
                                () => _selectedStatus = s);
                            widget.onStatusChange(s);
                            HapticFeedback.lightImpact();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 160),
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : color
                                      .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(10),
                              border: Border.all(
                                  color: isSelected
                                      ? color
                                      : color.withValues(
                                          alpha: 0.3)),
                            ),
                            child: Text(s.label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : color)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Schedule
                _SectionLabel('SCHEDULE', cs),
                const SizedBox(height: 8),
                if (widget.block.scheduledAt != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      Icon(Icons.schedule_rounded,
                          size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(
                        _fmtDateTime(widget.block.scheduledAt!),
                        style: TextStyle(
                            fontSize: 13,
                            color: cs.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: widget.block.scheduledAt ??
                          DateTime.now(),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 30)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                          widget.block.scheduledAt ??
                              DateTime.now()),
                    );
                    if (time == null || !context.mounted) return;
                    final dt = DateTime(date.year, date.month,
                        date.day, time.hour, time.minute);
                    widget.onSchedule(dt);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.calendar_today_rounded,
                      size: 15),
                  label: Text(widget.block.scheduledAt != null
                      ? 'Change Schedule'
                      : 'Set Schedule'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                // Production checklist
                _SectionLabel('PRODUCTION CHECKLIST', cs),
                const SizedBox(height: 8),
                ..._checklist.entries.map(
                  (e) => CheckboxListTile(
                    value: e.value,
                    title: Text(e.key,
                        style: const TextStyle(fontSize: 13)),
                    controlAffinity:
                        ListTileControlAffinity.leading,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) async {
                        final newValue = v ?? false;
                        final oldValue = _checklist[e.key] ?? false;
                        setState(() => _checklist[e.key] = newValue);
                        
                        final authVm = context.read<AuthViewModel>();
                        final userName = authVm.currentUser?.name ?? 'User';
                        final planId = widget.block.planId ?? '';

                        try {
                          await _service.updateChecklist(
                            widget.block.id, 
                            _checklist, 
                            userId: authVm.currentUser?.id
                          );
                          
                          // Log activity locally for "Activities" feed
                          if (planId.isNotEmpty) {
                            await CollaborationService().addHistory(
                              planId,
                              HistoryEntry(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                planId: planId,
                                authorName: userName,
                                action: 'CHECKLIST_UPDATE',
                                description: '$userName ${newValue ? "completed" : "reverted"} "${e.key}" for "${widget.block.title}"',
                                createdAt: DateTime.now(),
                              ),
                            );
                            // Refresh activity log if board is listening
                            if (mounted) {
                              context.read<CollaborationViewModel>().loadActivityLog(planId);
                            }
                          }
                        } catch (err) {
                          if (mounted) {
                            setState(() => _checklist[e.key] = oldValue);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Failed to save: $err'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                    },
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  String _fmtDateTime(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${m[d.month - 1]} ${d.day}, ${d.year} at $h:$min';
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _SectionLabel(this.text, this.cs);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 1.2));
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final ColorScheme cs;

  const _Chip(this.label, this.color, this.cs);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

class _InfoCard extends StatelessWidget {
  final ColorScheme cs;
  final List<Widget> children;

  const _InfoCard({required this.cs, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: children
              .map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: c))
              .toList(),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final ColorScheme cs;

  const _InfoRow(this.label, this.value, this.cs);

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: cs.onSurfaceVariant)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ]);
}
