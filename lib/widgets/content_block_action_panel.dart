import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/content_block.dart';
import '../view_models/content_block_view_model.dart';
import 'content_block_status_badge.dart';

/// Bottom panel shown after AI generates a video idea.
/// Lets user select Brand/Plan/Phase and take actions.
class ContentBlockActionPanel extends StatelessWidget {
  final ContentBlockGenerationResult result;

  const ContentBlockActionPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContentBlockViewModel(),
      child: _ContentBlockActionPanelBody(result: result),
    );
  }
}

class _ContentBlockActionPanelBody extends StatefulWidget {
  final ContentBlockGenerationResult result;
  const _ContentBlockActionPanelBody({required this.result});

  @override
  State<_ContentBlockActionPanelBody> createState() =>
      _ContentBlockActionPanelBodyState();
}

class _ContentBlockActionPanelBodyState
    extends State<_ContentBlockActionPanelBody> {
  // Minimal demo — in production, load brands/plans from their respective VMs
  final _brandIdCtrl   = TextEditingController();
  final _planIdCtrl    = TextEditingController();
  final _phaseCtrl     = TextEditingController();
  final _targetIdCtrl  = TextEditingController();

  @override
  void dispose() {
    _brandIdCtrl.dispose();
    _planIdCtrl.dispose();
    _phaseCtrl.dispose();
    _targetIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<ContentBlockViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final block  = vm.currentBlock;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Save This Idea',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (block != null)
                ContentBlockStatusBadge(status: block.status),
            ],
          ),

          // Title preview
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.result.title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const Divider(color: Colors.white12),
          const SizedBox(height: 8),

          // Context selectors
          _SectionLabel('Context (optional)'),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _CompactField(
                  controller: _brandIdCtrl,
                  label: 'Brand ID *',
                  icon: Icons.storefront_outlined,
                  onChanged: (v) => vm.selectBrand(v, v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CompactField(
                  controller: _planIdCtrl,
                  label: 'Plan ID',
                  icon: Icons.map_outlined,
                  onChanged: (v) => vm.selectPlan(v, v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _CompactField(
            controller: _phaseCtrl,
            label: 'Phase / Week label',
            icon: Icons.calendar_view_week_outlined,
            onChanged: (v) => vm.selectPhase(v, v),
          ),

          const SizedBox(height: 16),

          // Error
          if (vm.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          if (vm.isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          else ...[
            // Primary row
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Save as Idea',
                    icon: Icons.bookmark_add_outlined,
                    color: const Color(0xFF6366F1),
                    onTap: () async {
                      // Set generationResult then save
                      vm.generationResult = widget.result;
                      final saved = await vm.saveAsIdea();
                      if (saved != null && context.mounted) {
                        _showSnack(context, 'Saved as Idea ✓', const Color(0xFF6366F1));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Approve',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    enabled: block?.status == ContentBlockStatus.idea,
                    onTap: () async {
                      final approved = await vm.approve();
                      if (approved != null && context.mounted) {
                        _showSnack(context, 'Approved ✓', const Color(0xFF10B981));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Secondary row
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Add to Plan',
                    icon: Icons.science_outlined,
                    color: const Color(0xFF8B5CF6),
                    enabled: block != null &&
                        vm.selectedPlanId != null &&
                        block.status != ContentBlockStatus.terminated,
                    onTap: () async {
                      final updated = await vm.addToPlan();
                      if (updated != null && context.mounted) {
                        _showSnack(context, 'Added to plan ✓', const Color(0xFF8B5CF6));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    label: 'Add to Calendar',
                    icon: Icons.calendar_month_outlined,
                    color: const Color(0xFF3B82F6),
                    enabled: block?.status == ContentBlockStatus.approved ||
                        block?.status == ContentBlockStatus.scheduled,
                    onTap: () => _pickDateAndSchedule(context, vm),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Replace row
            Row(
              children: [
                Expanded(
                  child: _CompactField(
                    controller: _targetIdCtrl,
                    label: 'Target Block ID to replace',
                    icon: Icons.swap_horiz_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  label: 'Replace',
                  icon: Icons.swap_horiz,
                  color: const Color(0xFFF59E0B),
                  enabled: block != null && _targetIdCtrl.text.isNotEmpty,
                  onTap: () async {
                    if (_targetIdCtrl.text.trim().isEmpty) return;
                    final updated = await vm.replacePost(_targetIdCtrl.text.trim());
                    if (updated != null && context.mounted) {
                      _showSnack(context, 'Post replaced ✓', const Color(0xFFF59E0B));
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDateAndSchedule(
    BuildContext context,
    ContentBlockViewModel vm,
  ) async {
    final now  = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) return;

    final scheduled = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    vm.setScheduledAt(scheduled);

    final updated = await vm.addToCalendar();
    if (updated != null && context.mounted) {
      _showSnack(context, 'Scheduled for ${_fmt(scheduled)} ✓', const Color(0xFF3B82F6));
    }
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}

class _CompactField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  const _CompactField({
    required this.controller,
    required this.label,
    required this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        prefixIcon: Icon(icon, color: Colors.white38, size: 16),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.white24;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [color.withOpacity(0.85), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveColor.withOpacity(0.4)),
          boxShadow: enabled
              ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: enabled ? Colors.white : Colors.white38),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color:      enabled ? Colors.white : Colors.white38,
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
