import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/video_generator_models.dart';
import '../../../models/content_block.dart';
import '../../../models/brand.dart';
import '../../../models/plan.dart' as pl;
import '../../../services/brand_service.dart';
import '../../../services/plan_service.dart';
import '../../../view_models/content_block_view_model.dart';

// ─── Main Card ────────────────────────────────────────────────────────────────

class VideoResultCard extends StatefulWidget {
  final VideoIdea idea;
  final VideoRequest? request;
  final VoidCallback? onRegenerate;
  /// When provided, shows a heart toggle icon in the card header.
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const VideoResultCard({
    super.key,
    required this.idea,
    this.request,
    this.onRegenerate,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  State<VideoResultCard> createState() => _VideoResultCardState();
}

class _VideoResultCardState extends State<VideoResultCard> {
  late final ContentBlockViewModel _cbVm;

  @override
  void initState() {
    super.initState();
    _cbVm = ContentBlockViewModel();
    _cbVm.generationResult = _buildGenerationResult();
  }

  @override
  void dispose() {
    _cbVm.dispose();
    super.dispose();
  }

  // ─── Mapping helpers ───────────────────────────────────────────────────────

  ContentBlockGenerationResult _buildGenerationResult() {
    final idea = widget.idea;
    final req = widget.request;
    return ContentBlockGenerationResult(
      title: idea.title,
      hooks: [idea.hook],
      scriptOutline: idea.script,
      contentType: _goalToType(req?.goal),
      ctaType: _goalToCta(req?.goal),
      platform: _toPlatform(req?.platform),
      format: _toFormat(req?.platform),
      description: idea.caption,
      tags: idea.hashtags,
    );
  }

  static ContentPlatform _toPlatform(Platform? p) {
    switch (p) {
      case Platform.tikTok:
        return ContentPlatform.tiktok;
      case Platform.instagramReels:
        return ContentPlatform.instagram;
      case Platform.youTubeShorts:
      case Platform.youTubeLong:
        return ContentPlatform.youtube;
      default:
        return ContentPlatform.instagram;
    }
  }

  static ContentType _goalToType(VideoGoal? g) {
    switch (g) {
      case VideoGoal.sellProduct:
      case VideoGoal.offerPromo:
        return ContentType.promo;
      case VideoGoal.brandAwareness:
        return ContentType.authority;
      case VideoGoal.ugcReview:
        return ContentType.socialProof;
      default:
        return ContentType.educational;
    }
  }

  static ContentCtaType _goalToCta(VideoGoal? g) {
    if (g == VideoGoal.sellProduct || g == VideoGoal.offerPromo) {
      return ContentCtaType.hard;
    }
    return ContentCtaType.soft;
  }

  static ContentFormat _toFormat(Platform? p) {
    if (p == Platform.tikTok) return ContentFormat.short;
    if (p == Platform.youTubeLong) return ContentFormat.post;
    return ContentFormat.reel;
  }

  // ─── Label helpers ─────────────────────────────────────────────────────────

  static String _platformLabel(ContentPlatform p) {
    const m = {
      ContentPlatform.tiktok: 'TikTok',
      ContentPlatform.instagram: 'Instagram',
      ContentPlatform.youtube: 'YouTube',
      ContentPlatform.facebook: 'Facebook',
      ContentPlatform.linkedin: 'LinkedIn',
    };
    return m[p] ?? p.name;
  }

  static String _typeLabel(ContentType t) {
    const m = {
      ContentType.educational: 'Educational',
      ContentType.promo: 'Promo',
      ContentType.teaser: 'Teaser',
      ContentType.launch: 'Launch',
      ContentType.socialProof: 'Social Proof',
      ContentType.objection: 'Objection',
      ContentType.behindScenes: 'Behind Scenes',
      ContentType.authority: 'Authority',
    };
    return m[t] ?? t.name;
  }

  static String _ctaLabel(ContentCtaType c) {
    const m = {
      ContentCtaType.soft: 'Soft CTA',
      ContentCtaType.hard: 'Hard CTA',
      ContentCtaType.educational: 'Edu CTA',
    };
    return m[c] ?? c.name;
  }

  static String _formatLabel(ContentFormat f) {
    const m = {
      ContentFormat.reel: 'Reel',
      ContentFormat.short: 'Short',
      ContentFormat.post: 'Post',
      ContentFormat.carousel: 'Carousel',
      ContentFormat.story: 'Story',
      ContentFormat.live: 'Live',
    };
    return m[f] ?? f.name;
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: _cbVm,
      builder: (context, _) {
        final result = _cbVm.generationResult!;
        final block = _cbVm.currentBlock;

        return Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, cs, result, block),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetaChips(cs, result),
                    const SizedBox(height: 16),
                    _buildHooks(cs, result.hooks),
                    const SizedBox(height: 14),
                    Text(
                      widget.idea.caption,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Divider(color: cs.outlineVariant),
                    const SizedBox(height: 10),
                    _buildScenes(cs),
                    const SizedBox(height: 14),
                    _buildHashtags(cs),
                    const SizedBox(height: 20),
                    if (_cbVm.errorMessage != null) _buildError(cs),
                    if (_cbVm.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      _buildActions(context, cs, block),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    ColorScheme cs,
    ContentBlockGenerationResult result,
    ContentBlock? block,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _badge('🎬 Video Idea', cs.primary.withValues(alpha: 0.12), cs.primary),
              const Spacer(),
              if (block != null) ...[
                _StatusBadge(status: block.status),
                const SizedBox(width: 8),
              ],
              if (widget.onFavoriteToggle != null) ...[
                GestureDetector(
                  onTap: widget.onFavoriteToggle,
                  child: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: widget.isFavorite ? Colors.red : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: widget.idea.script));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Script copied!')),
                  );
                },
                child: Icon(Icons.copy_outlined, size: 18, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.idea.title,
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Metadata chips ────────────────────────────────────────────────────────

  Widget _buildMetaChips(ColorScheme cs, ContentBlockGenerationResult r) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _chip(_typeLabel(r.contentType), const Color(0xFF6366F1)),
        _chip(_formatLabel(r.format), const Color(0xFF8B5CF6)),
        _chip(_platformLabel(r.platform), const Color(0xFF3B82F6)),
        _chip(_ctaLabel(r.ctaType), const Color(0xFF10B981)),
        _chip(
          r.productSuggestion != null ? '📦 ${r.productSuggestion}' : 'No Product',
          Colors.grey,
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      );

  Widget _badge(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );

  // ─── Hooks ─────────────────────────────────────────────────────────────────

  Widget _buildHooks(ColorScheme cs, List<String> hooks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hooks:',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ...hooks.map(
          (h) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: cs.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    '"$h"',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Scenes ────────────────────────────────────────────────────────────────

  Widget _buildScenes(ColorScheme cs) {
    final scenes = widget.idea.scenes.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Structure:', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...scenes.map(
          (scene) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${scene.startSec}-${scene.endSec}s',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scene.description,
                    style: TextStyle(fontSize: 13, color: cs.onSurface, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.idea.scenes.length > 3)
          Text(
            '... (${widget.idea.scenes.length - 3} more)',
            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
      ],
    );
  }

  // ─── Hashtags ──────────────────────────────────────────────────────────────

  Widget _buildHashtags(ColorScheme cs) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.idea.hashtags.take(5).map(
            (h) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(h, style: TextStyle(fontSize: 12, color: cs.primary)),
            ),
          ).toList(),
    );
  }

  // ─── Error ─────────────────────────────────────────────────────────────────

  Widget _buildError(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _cbVm.errorMessage!,
          style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
        ),
      ),
    );
  }

  // ─── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, ColorScheme cs, ContentBlock? block) {
    final hasSavedBlock = block != null;
    final canApprove = block?.status == ContentBlockStatus.idea;
    final canAddToPlan =
        block != null && block.status != ContentBlockStatus.terminated;
    final canSchedule = block?.status == ContentBlockStatus.approved ||
        block?.status == ContentBlockStatus.scheduled;

    return Column(
      children: [
        // Row 1: Save | Approve
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: hasSavedBlock ? 'Saved ✓' : 'Save as Idea',
                icon: hasSavedBlock
                    ? Icons.bookmark
                    : Icons.bookmark_add_outlined,
                color: const Color(0xFF6366F1),
                enabled: !hasSavedBlock,
                onTap: () => _onSave(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: block?.status == ContentBlockStatus.approved
                    ? 'Approved ✓'
                    : 'Approve',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
                enabled: canApprove,
                onTap: () => _onApprove(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 2: Add to Plan | Add to Calendar
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                label: 'Add to Plan',
                icon: Icons.map_outlined,
                color: const Color(0xFF8B5CF6),
                enabled: canAddToPlan,
                onTap: () => _onAddToPlan(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionBtn(
                label: 'Add to Calendar',
                icon: Icons.calendar_month_outlined,
                color: const Color(0xFF3B82F6),
                enabled: canSchedule,
                onTap: () => _onSchedule(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Row 3: Regenerate
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onRegenerate,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Regenerate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              side: BorderSide(color: cs.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Action handlers ───────────────────────────────────────────────────────

  void _onSave(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaveSheet(
        cbVm: _cbVm,
        onSuccess: (msg) => _snack(context, msg, const Color(0xFF6366F1)),
      ),
    );
  }

  void _onApprove(BuildContext context) async {
    final result = await _cbVm.approve();
    if (result != null && context.mounted) {
      _snack(context, 'Idea approved ✓', const Color(0xFF10B981));
    }
  }

  void _onAddToPlan(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToPlanSheet(
        cbVm: _cbVm,
        onSuccess: (msg) => _snack(context, msg, const Color(0xFF8B5CF6)),
      ),
    );
  }

  void _onSchedule(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScheduleSheet(
        cbVm: _cbVm,
        onSuccess: (msg) => _snack(context, msg, const Color(0xFF3B82F6)),
      ),
    );
  }

  void _snack(BuildContext context, String msg, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final ContentBlockStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ContentBlockStatus.idea => ('Idea', const Color(0xFF6366F1), Icons.lightbulb_outline),
      ContentBlockStatus.approved => ('Approved', const Color(0xFF10B981), Icons.check_circle_outline),
      ContentBlockStatus.scheduled => ('Scheduled', const Color(0xFF3B82F6), Icons.schedule),
      ContentBlockStatus.inProcess => ('In Process', const Color(0xFFF59E0B), Icons.autorenew),
      ContentBlockStatus.terminated => ('Terminated', Colors.grey, Icons.block),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : Colors.grey;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  colors: [color.withValues(alpha: 0.85), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: enabled ? null : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: effectiveColor.withValues(alpha: 0.35)),
          boxShadow: enabled
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: enabled ? Colors.white : Colors.grey),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey,
                  fontSize: 12,
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

// ─── Sheet base ───────────────────────────────────────────────────────────────

class _SheetBase extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetBase({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.white12),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Save as Idea Sheet ───────────────────────────────────────────────────────

class _SaveSheet extends StatefulWidget {
  final ContentBlockViewModel cbVm;
  final void Function(String msg) onSuccess;

  const _SaveSheet({required this.cbVm, required this.onSuccess});

  @override
  State<_SaveSheet> createState() => _SaveSheetState();
}

class _SaveSheetState extends State<_SaveSheet> {
  List<Brand> _brands = [];
  bool _loading = true;
  Brand? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await BrandService.getBrands();
      if (mounted) setState(() { _brands = brands; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedBrand == null) return;
    widget.cbVm.selectBrand(_selectedBrand!.id!, _selectedBrand!.name);
    final block = await widget.cbVm.saveAsIdea();
    if (block != null && mounted) {
      widget.onSuccess('Saved as Idea: "${block.title}"');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBase(
      title: '💾 Save as Idea',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select a brand to save this idea under:',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_brands.isEmpty)
            const Text('No brands found. Create a brand first.',
                style: TextStyle(color: Colors.white54))
          else ...[
            ..._brands.map(
              (b) => GestureDetector(
                onTap: () => setState(() => _selectedBrand = b),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _selectedBrand?.id == b.id
                        ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedBrand?.id == b.id
                          ? const Color(0xFF6366F1)
                          : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            b.name.isNotEmpty ? b.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w600)),
                            if (b.description != null)
                              Text(b.description!,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (_selectedBrand?.id == b.id)
                        const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: widget.cbVm,
              builder: (_, _) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedBrand != null && !widget.cbVm.isLoading
                      ? _save
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: widget.cbVm.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save as Idea', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Add to Plan Sheet ────────────────────────────────────────────────────────

class _AddToPlanSheet extends StatefulWidget {
  final ContentBlockViewModel cbVm;
  final void Function(String msg) onSuccess;

  const _AddToPlanSheet({required this.cbVm, required this.onSuccess});

  @override
  State<_AddToPlanSheet> createState() => _AddToPlanSheetState();
}

class _AddToPlanSheetState extends State<_AddToPlanSheet> {
  List<Brand> _brands = [];
  List<pl.Plan> _plans = [];
  Brand? _brand;
  pl.Plan? _plan;
  pl.Phase? _phase;
  bool _loading = true;
  bool _loadingPlans = false;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    try {
      final brands = await BrandService.getBrands();
      if (mounted) setState(() { _brands = brands; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onBrandSelected(Brand b) async {
    setState(() { _brand = b; _plans = []; _plan = null; _phase = null; _loadingPlans = true; });
    try {
      final plans = await PlanService.getPlans(brandId: b.id!);
      if (mounted) setState(() { _plans = plans; _loadingPlans = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  Future<void> _confirm() async {
    if (_plan == null) return;
    widget.cbVm.selectBrand(_brand!.id!, _brand!.name);
    widget.cbVm.selectPlan(_plan!.id!, _plan!.name);
    if (_phase != null) {
      widget.cbVm.selectPhase(_phase!.id ?? '', _phase!.name);
    }
    final updated = await widget.cbVm.addToPlan();
    if (updated != null && mounted) {
      final phasePart = _phase != null ? ' — ${_phase!.name}' : '';
      widget.onSuccess('Added to "${_plan!.name}"$phasePart ✓');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetBase(
      title: '📋 Add to Plan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2))
          else ...[
            // Step 1: Brand
            _sectionLabel('1. Select Brand'),
            const SizedBox(height: 10),
            ..._brands.map(
              (b) => _selectionTile(
                label: b.name,
                selected: _brand?.id == b.id,
                onTap: () => _onBrandSelected(b),
              ),
            ),
            if (_brand != null) ...[
              const SizedBox(height: 16),
              // Step 2: Plan
              _sectionLabel('2. Select Plan'),
              const SizedBox(height: 10),
              if (_loadingPlans)
                const Center(child: CircularProgressIndicator(strokeWidth: 2))
              else if (_plans.isEmpty)
                const Text('No plans found for this brand.',
                    style: TextStyle(color: Colors.white54))
              else
                ..._plans.map(
                  (p) => _selectionTile(
                    label: p.name,
                    subtitle: '${p.objective.label} • ${p.status.name}',
                    selected: _plan?.id == p.id,
                    onTap: () => setState(() { _plan = p; _phase = null; }),
                  ),
                ),
            ],
            if (_plan != null && _plan!.phases.isNotEmpty) ...[
              const SizedBox(height: 16),
              // Step 3: Phase (optional)
              _sectionLabel('3. Select Phase (optional)'),
              const SizedBox(height: 10),
              ..._plan!.phases.map(
                (ph) => _selectionTile(
                  label: ph.name,
                  subtitle: 'Week ${ph.weekNumber}',
                  selected: _phase?.id == ph.id,
                  onTap: () => setState(() => _phase = ph),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: widget.cbVm,
              builder: (_, _) => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _plan != null && !widget.cbVm.isLoading ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: widget.cbVm.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add to Plan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  Widget _selectionTile({
    required String label,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF8B5CF6).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF8B5CF6) : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF8B5CF6), size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule Sheet ───────────────────────────────────────────────────────────

class _ScheduleSheet extends StatefulWidget {
  final ContentBlockViewModel cbVm;
  final void Function(String msg) onSuccess;

  const _ScheduleSheet({required this.cbVm, required this.onSuccess});

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  DateTime? _date;
  TimeOfDay? _time;
  ContentPlatform _platform = ContentPlatform.instagram;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _confirm() async {
    if (_date == null || _time == null) return;
    final scheduled = DateTime(
      _date!.year,
      _date!.month,
      _date!.day,
      _time!.hour,
      _time!.minute,
    );
    widget.cbVm.setScheduledAt(scheduled);
    final updated = await widget.cbVm.addToCalendar();
    if (updated != null && mounted) {
      final fmt = _formatDt(scheduled);
      widget.onSuccess('Scheduled for $fmt ✓');
      Navigator.pop(context);
    }
  }

  String _formatDt(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day} at $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final ready = _date != null && _time != null;

    return _SheetBase(
      title: '📅 Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Platform
          const Text('Platform', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _PlatformSelector(
            selected: _platform,
            onChanged: (p) => setState(() => _platform = p),
          ),
          const SizedBox(height: 20),

          // Date
          const Text('Date', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _PickerButton(
            icon: Icons.calendar_today_outlined,
            label: _date == null
                ? 'Select date'
                : '${_date!.day}/${_date!.month}/${_date!.year}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          // Time
          const Text('Time', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _PickerButton(
            icon: Icons.access_time_outlined,
            label: _time == null ? 'Select time' : _time!.format(context),
            onTap: _pickTime,
          ),
          const SizedBox(height: 24),

          // Summary
          if (ready)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Will be scheduled for ${_formatDt(DateTime(_date!.year, _date!.month, _date!.day, _time!.hour, _time!.minute))} on ${_platformLabel(_platform)}',
                      style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          ListenableBuilder(
            listenable: widget.cbVm,
            builder: (_, _) => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: ready && !widget.cbVm.isLoading ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: widget.cbVm.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Schedule', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _platformLabel(ContentPlatform p) {
    const m = {
      ContentPlatform.tiktok: 'TikTok',
      ContentPlatform.instagram: 'Instagram',
      ContentPlatform.youtube: 'YouTube',
      ContentPlatform.facebook: 'Facebook',
      ContentPlatform.linkedin: 'LinkedIn',
    };
    return m[p] ?? p.name;
  }
}

// ─── Platform Selector ────────────────────────────────────────────────────────

class _PlatformSelector extends StatelessWidget {
  final ContentPlatform selected;
  final ValueChanged<ContentPlatform> onChanged;

  const _PlatformSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const platforms = [
      (ContentPlatform.instagram, 'Instagram', '📸'),
      (ContentPlatform.tiktok, 'TikTok', '🎵'),
      (ContentPlatform.youtube, 'YouTube', '▶️'),
      (ContentPlatform.facebook, 'Facebook', '👥'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: platforms.map(
        (entry) {
          final (p, label, emoji) = entry;
          final isSelected = selected == p;
          return GestureDetector(
            onTap: () => onChanged(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white12,
                ),
              ),
              child: Text(
                '$emoji $label',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white54,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}

// ─── Picker Button ────────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white38, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
