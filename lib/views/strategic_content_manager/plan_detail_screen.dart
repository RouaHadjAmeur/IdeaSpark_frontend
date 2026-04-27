import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_localizations.dart';
import '../../models/plan.dart';
import '../../models/brand.dart';
import '../../services/plan_service.dart';
import '../../view_models/plan_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../services/google_calendar_storage_service.dart';
import '../../models/google_calendar_tokens.dart';
import '../../services/deep_link_service.dart';
import '../../views/settings/google_calendar_token_screen.dart';
import '../../services/notification_service.dart';
import '../../services/in_app_notification_service.dart';
import '../notifications/notifications_screen.dart';
import '../content/post_preview_screen.dart';
import '../content/caption_generator_screen.dart';
import '../templates/plan_templates_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../analytics/plan_stats_screen.dart';
import '../../services/pdf_export_service.dart';
import '../plan-collaboration/collaboration_screen.dart';
import '../plan-collaboration/post_comments_screen.dart';
import '../../view_models/auth_view_model.dart';
import '../../services/image_generator_service.dart';
import '../../services/image_download_service.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late Plan _plan;
  bool _isLoadingDetail = false;
  final Set<int> _expandedPhases = {};
  bool _isGoogleCalendarConnected = false;
  GoogleCalendarTokens? _googleTokens;
  bool _isSyncingToGoogle = false;
  bool _remindersActive = false;

  static const _palette = [
    Color(0xFFFF6B6B),
    Color(0xFF6BCB77),
    Color(0xFF4D96FF),
    Color(0xFFFFD93D),
    Color(0xFFC77DFF),
    Color(0xFFFF9F43),
    Color(0xFF00CFDD),
  ];

  Color _brandColor(String id) =>
      _palette[id.codeUnits.fold(0, (a, b) => a + b) % _palette.length];

  @override
  void initState() {
    super.initState();
    _plan = widget.plan;
    _checkGoogleCalendarConnection();
    // Listen for deep link OAuth callback - tokens saved automatically
    DeepLinkService().onGoogleCalendarConnected = (tokens) {
      if (mounted) {
        setState(() {
          _googleTokens = tokens;
          _isGoogleCalendarConnected = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Google Calendar connecté automatiquement !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };
    if (_plan.phases.isEmpty && _plan.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDetail());
    } else {
      if (_plan.phases.isNotEmpty) _expandedPhases.add(0);
    }
  }

  @override
  void dispose() {
    DeepLinkService().onGoogleCalendarConnected = null;
    super.dispose();
  }

  Future<void> _checkGoogleCalendarConnection() async {
    final tokens = await GoogleCalendarStorageService.getTokens();
    if (mounted) {
      setState(() {
        _googleTokens = tokens;
        _isGoogleCalendarConnected = tokens != null && !tokens.isExpired;
      });
      
      // Si connecté, envoyer une notification de rappel automatique
      if (_isGoogleCalendarConnected && _plan.phases.isNotEmpty) {
        final totalPosts = _plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
        await NotificationService.schedulePublicationReminder(
          id: _plan.id.hashCode,
          title: '📅 ${_plan.name}',
          body: '$totalPosts publications planifiées - Vérifiez votre Google Calendar !',
          scheduledTime: DateTime.now(),
        );
      }
    }
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoadingDetail = true);
    try {
      final detail = await PlanService.getPlanById(_plan.id!);
      if (mounted) {
        setState(() {
          _plan = detail;
          if (detail.phases.isNotEmpty) _expandedPhases.add(0);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingDetail = false);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer2<PlanViewModel, BrandViewModel>(
      builder: (context, vm, brandVm, _) {
        final brand = brandVm.brands
            .cast<Brand?>()
            .firstWhere((b) => b?.id == _plan.brandId,
                orElse: () => null);
        final totalBlocks =
            _plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
        final brandColor = _brandColor(_plan.brandId);

        return Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(cs, vm),
                Expanded(
                  child: _isLoadingDetail
                      ? const Center(child: CircularProgressIndicator())
                      : ListView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          children: [
                            const SizedBox(height: 8),
                            _buildInfoBanner(cs, brand, brandColor),
                            const SizedBox(height: 16),
                            _buildStats(cs, totalBlocks),
                            const SizedBox(height: 20),
                            _buildActions(cs, vm),
                            if (_plan.phases.isNotEmpty) ...[
                              const SizedBox(height: 28),
                              _sectionLabel(context.tr('detail_phases_label'), cs),
                              const SizedBox(height: 10),
                              ..._plan.phases
                                  .asMap()
                                  .entries
                                  .map((e) => _buildPhaseCard(
                                      cs, e.key, e.value)),
                            ] else if (!_isLoadingDetail) ...[
                              const SizedBox(height: 24),
                              _buildNoPhasesHint(cs),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(ColorScheme cs, PlanViewModel vm) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
          children: [
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
              child: Text(
                _plan.name,
                style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _statusBadge(_plan.status, cs),
            const SizedBox(width: 8),
            // Notifications button
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(children: [
                  Center(
                    child: Icon(Icons.notifications_outlined,
                        size: 18, color: cs.onSurfaceVariant),
                  ),
                  if (InAppNotificationService().unreadCount > 0)
                    Positioned(
                      top: 4, right: 4,
                      child: Container(
                        width: 10, height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Edit name button
            GestureDetector(
              onTap: () => _showEditNameDialog(vm),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_outlined,
                    size: 17, color: cs.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );

  // ─── Info Banner ──────────────────────────────────────────────────────────

  Widget _buildInfoBanner(
      ColorScheme cs, Brand? brand, Color brandColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brandColor.withValues(alpha: 0.06),
        border: Border.all(color: brandColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: brandColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                brand?.name ?? context.tr('detail_unknown_brand'),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface),
              ),
              const SizedBox(width: 8),
              Text('·', style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(width: 8),
              Text(
                '${_plan.objective.emoji} ${_plan.objective.label}',
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 13, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _formatDate(_plan.startDate),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded,
                  size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _formatDate(_plan.endDate),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Widget _buildStats(ColorScheme cs, int totalBlocks) {
    return Row(
      children: [
        _statItem('${_plan.phases.length}',
            context.tr('detail_phases_label'),
            Icons.layers_outlined, cs),
        const SizedBox(width: 8),
        _statItem('$totalBlocks', 'Posts',
            Icons.article_outlined, cs),
        const SizedBox(width: 8),
        _statItem('${_plan.durationWeeks}w', context.tr('detail_duration_stat'),
            Icons.hourglass_top_rounded, cs),
        const SizedBox(width: 8),
        _statItem('${_plan.postingFrequency}/wk', context.tr('detail_frequency_stat'),
            Icons.repeat_rounded, cs),
      ],
    );
  }

  Widget _statItem(
      String value, String label, IconData icon, ColorScheme cs) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: cs.primary),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: cs.primary)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Widget _buildActions(ColorScheme cs, PlanViewModel vm) {
    final isDraft = _plan.status == PlanStatus.draft;
    final isActive = _plan.status == PlanStatus.active;
    final hasPhases = _plan.phases.isNotEmpty;

    return Column(
      children: [
        // Activate (draft + has phases)
        if (isDraft && hasPhases)
          Consumer<AuthViewModel>(
            builder: (context, authVm, _) {
              final canActivate = authVm.isBrandOwner || authVm.userId == _plan.userId;
              return _actionButton(
                label: context.tr('detail_activate_btn'),
                color: canActivate ? Colors.green : Colors.grey,
                onPressed: (vm.isSaving || !canActivate) ? null : () => _activatePlan(vm, authVm),
              );
            }
          ),

        // Google Calendar button (active only)
        if (isActive) ...[
          const SizedBox(height: 8),
          _actionButton(
            label: '📅 Ouvrir Google Calendar',
            color: const Color(0xFF4285F4),
            onPressed: _openGoogleCalendar,
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: _remindersActive
                ? '🔕 Désactiver les rappels'
                : '🔔 Activer les rappels de publications',
            color: _remindersActive
                ? Colors.grey
                : const Color(0xFFFF6B35),
            outlined: true,
            onPressed: _toggleReminders,
          ),
        ],

        // Regenerate (has id + any status) - restricted to Brand Owner for now
        if (_plan.id != null) ...[
          if (isDraft || isActive) const SizedBox(height: 8),
          Consumer<AuthViewModel>(
            builder: (context, authVm, _) {
              final canRegen = authVm.isBrandOwner;
              return _actionButton(
                label: context.tr('detail_regen_btn'),
                color: canRegen ? cs.secondary : Colors.grey,
                outlined: true,
                onPressed: (vm.isGenerating || !canRegen) ? null : () => _regenerate(vm),
              );
            }
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: '🔖 Sauvegarder comme template',
            color: const Color(0xFF9C27B0),
            outlined: true,
            onPressed: _saveAsTemplate,
          ),
          const SizedBox(height: 8),
/* ... (sharing, stats, pdf export) ... */
          const SizedBox(height: 8),
          _actionButton(
            label: '📤 Partager ce plan',
            color: const Color(0xFF00BCD4),
            outlined: true,
            onPressed: _sharePlan,
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: '📊 Voir les statistiques',
            color: const Color(0xFF4285F4),
            outlined: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlanStatsScreen(plan: _plan)),
            ),
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: '📄 Exporter en PDF',
            color: const Color(0xFFE53935),
            outlined: true,
            onPressed: () => PdfExportService.exportPlan(_plan),
          ),
          const SizedBox(height: 8),
          _actionButton(
            label: '👥 Collaboration',
            color: const Color(0xFF9C27B0),
            outlined: true,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollaborationScreen(
                  planId: _plan.id ?? '',
                  planName: _plan.name,
                ),
              ),
            ),
            trailing: _plan.notesSeen == false 
                ? Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  )
                : null,
          ),
        ],

        const SizedBox(height: 8),
        // Delete - restricted to Brand Owner
        Consumer<AuthViewModel>(
          builder: (context, authVm, _) {
            final canDelete = authVm.isBrandOwner;
            return _actionButton(
              label: context.tr('detail_delete_btn'),
              color: canDelete ? cs.error : Colors.grey,
              outlined: true,
              onPressed: (vm.isSaving || !canDelete) ? null : () => _confirmDelete(vm),
            );
          }
        ),

        // Loading indicator
        if (vm.isSaving || vm.isGenerating || _isSyncingToGoogle) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cs.primary)),
              const SizedBox(width: 10),
              Text(
                vm.isGenerating
                    ? context.tr('detail_regen_gemini')
                    : context.tr('detail_processing'),
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],

        // Error
        if (vm.error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 14, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vm.error!,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.onErrorContainer),
                  ),
                ),
                GestureDetector(
                  onTap: vm.clearError,
                  child: Icon(Icons.close_rounded,
                      size: 14,
                      color: cs.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool outlined = false,
    Widget? trailing,
  }) {
    final style = outlined
        ? OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          )
        : FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: style,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (trailing != null) trailing,
                ],
              ),
            )
          : FilledButton(
              onPressed: onPressed,
              style: style,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (trailing != null) trailing,
                ],
              ),
            ),
    );
  }

  // ─── Phases ───────────────────────────────────────────────────────────────

  Widget _buildPhaseCard(ColorScheme cs, int idx, Phase phase) {
    final isExpanded = _expandedPhases.contains(idx);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(
            color: isExpanded
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Phase header
          GestureDetector(
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedPhases.remove(idx);
              } else {
                _expandedPhases.add(idx);
              }
            }),
            child: Container(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? cs.primary
                          : cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        'W${phase.weekNumber}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isExpanded
                              ? cs.onPrimary
                              : cs.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phase.name,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface),
                        ),
                        if (phase.description != null)
                          Text(
                            phase.description!,
                            style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant),
                            maxLines: isExpanded ? 3 : 1,
                            overflow: isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${phase.contentBlocks.length} posts',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Content blocks
          if (isExpanded && phase.contentBlocks.isNotEmpty) ...[
            Divider(height: 1, color: cs.outlineVariant),
            ...phase.contentBlocks.map((block) =>
                _buildContentBlock(cs, block)),
          ],
        ],
      ),
    );
  }

  Widget _buildContentBlock(ColorScheme cs, ContentBlock block) {
    final formatColor = _formatColor(block.format, cs);
    final ctaColor = _ctaColor(block.ctaType, cs);
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image thumbnail (if exists)
          if (block.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                block.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.broken_image, size: 20, color: cs.onSurfaceVariant),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
          ],
          // Format badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: formatColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              block.format.label,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: formatColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 8,
                  children: [
                    Text(block.pillar,
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: ctaColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${block.ctaType.name} CTA',
                        style: TextStyle(
                            fontSize: 9,
                            color: ctaColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (block.recommendedDayOffset < 7)
                      Text(
                        '${weekdays[block.recommendedDayOffset]} ${block.recommendedTime ?? ''}',
                        style: TextStyle(
                            fontSize: 10, color: cs.onSurfaceVariant),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Preview button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostPreviewScreen(
                  block: block,
                  brandName: _plan.name,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.visibility_outlined,
                  size: 16, color: cs.primary),
            ),
          ),
          const SizedBox(width: 6),
          // Caption generator button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CaptionGeneratorScreen(
                  block: block,
                  brandName: _plan.name,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.auto_awesome,
                  size: 16, color: Colors.purple),
            ),
          ),
          const SizedBox(width: 6),
          // Image generator button
          GestureDetector(
            onTap: () => _showImageGeneratorDialog(block),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: block.imageUrl != null 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                block.imageUrl != null ? Icons.image : Icons.image_outlined,
                size: 16, 
                color: block.imageUrl != null ? Colors.green : Colors.blue,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Comments button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostCommentsScreen(
                  postId: block.id ?? block.title,
                  postTitle: block.title,
                  planId: _plan.id ?? '',
                  currentUserName: 'Vous',
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 16, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPhasesHint(ColorScheme cs) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_rounded,
                color: cs.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('detail_no_phases'),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  Text(
                      context.tr('detail_no_phases_desc'),
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      );

  // ─── Action handlers ──────────────────────────────────────────────────────

  Future<void> _toggleReminders() async {
    if (_remindersActive) {
      // Désactiver
      await NotificationService.cancelAll();
      InAppNotificationService().clear();
      setState(() => _remindersActive = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔕 Rappels désactivés'),
            backgroundColor: Colors.grey,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // Activer
      await _schedulePostReminders();
      setState(() => _remindersActive = true);
    }
  }

  Future<void> _schedulePostReminders() async {
    final phases = _plan.phases;
    if (phases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune phase trouvée dans ce plan'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int count = 0;
    for (final phase in phases) {
      for (final block in phase.contentBlocks) {
        count++;
        // Add to in-app notifications
        InAppNotificationService().add(AppNotification(
          id: count,
          title: '📢 Post à publier - ${_plan.name}',
          body: '${block.title}\n${block.format.label} • ${block.pillar}',
          time: DateTime.now(),
          type: 'post',
        ));
        // Also send system notification
        await NotificationService.schedulePublicationReminder(
          id: count,
          title: '📢 ${_plan.name} - Post à publier !',
          body: '${block.title} • ${block.format.label}',
          scheduledTime: DateTime.now(),
        );
      }
    }

    // Add plan summary notification
    InAppNotificationService().add(AppNotification(
      id: 0,
      title: '✅ Rappels activés - ${_plan.name}',
      body: '$count publications planifiées. Consultez vos rappels pour ne rien manquer !',
      time: DateTime.now(),
      type: 'plan',
    ));

    if (mounted) {
      final ctx = context;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text('✅ $count rappels activés pour ${_plan.name} !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Voir',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _sharePlan() async {
    final totalPosts = _plan.phases.fold<int>(0, (s, p) => s + p.contentBlocks.length);
    final phases = _plan.phases.map((p) =>
        '📌 ${p.name} (${p.contentBlocks.length} posts)').join('\n');

    final text = '''
🚀 Plan Marketing : ${_plan.name}
${_plan.objective.emoji} ${_plan.objective.label}

📅 ${_formatDate(_plan.startDate)} → ${_formatDate(_plan.endDate)}
📊 ${_plan.phases.length} phases • $totalPosts publications • ${_plan.durationWeeks} semaines

$phases

Créé avec IdeaSpark ✨
''';

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      text, 
      subject: 'Plan Marketing - ${_plan.name}',
      sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  Future<void> _saveAsTemplate() async {
    final template = PlanTemplate.fromPlan(_plan);
    await PlanTemplatesService.save(template);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔖 "${_plan.name}" sauvegardé comme template !'),
        backgroundColor: const Color(0xFF9C27B0),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Voir',
          textColor: Colors.white,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PlanTemplatesScreen(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openGoogleCalendar() async {
    final uri = Uri.parse('https://calendar.google.com');
    try {
      // Try externalApplication first, fallback to inAppWebView
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        // Fallback: try platformDefault
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // Last fallback: inAppWebView
      try {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ouvrez calendar.google.com dans votre navigateur'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  Future<void> _configureGoogleCalendar() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const GoogleCalendarTokenScreen(),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _checkGoogleCalendarConnection();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Google Calendar connecté !'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _syncToGoogleCalendar() async {
    if (_googleTokens == null) return;
    setState(() => _isSyncingToGoogle = true);
    try {
      // TODO: call sync-plan endpoint with _googleTokens
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plan synchronisé avec Google Calendar !'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingToGoogle = false);
    }
  }

  Future<void> _activatePlan(PlanViewModel vm, AuthViewModel authVm) async {
    final activated = await vm.activatePlan(
      _plan.id!, 
      currentUserId: authVm.userId, 
      isBrandOwner: authVm.isBrandOwner
    );
    if (activated != null && mounted) {
      setState(() => _plan = activated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.tr('detail_plan_activated')),
            behavior: SnackBarBehavior.floating),
      );
    } else if (activated == null && mounted && vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(vm.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _regenerate(PlanViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('detail_regen_dialog_title')),
        content: Text(ctx.tr('detail_regen_dialog_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.tr('detail_regen_confirm'))),
        ],
      ),
    );
    if (ok != true) return;
    final plan = await vm.regeneratePlan(_plan.id!);
    if (plan != null && mounted) {
      setState(() {
        _plan = plan;
        _expandedPhases.clear();
        if (plan.phases.isNotEmpty) _expandedPhases.add(0);
      });
    }
  }

  Future<void> _confirmDelete(PlanViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('plans_delete_title')),
        content: Text('${ctx.tr('delete')} "${_plan.name}"? ${ctx.tr('plans_cannot_undone')}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text(ctx.tr('delete')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await vm.deletePlan(_plan.id!);
      if (vm.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Delete failed: ${vm.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating),
        );
      } else if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _showEditNameDialog(PlanViewModel vm) async {
    final ctrl = TextEditingController(text: _plan.name);
    final cs = Theme.of(context).colorScheme;
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('detail_edit_name')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ctx.tr('detail_plan_name_label'),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: cs.primary, width: 1.5),
            ),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.tr('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Text(ctx.tr('save'))),
        ],
      ),
    );
    // Do NOT dispose ctrl here — the dialog's exit animation still references
    // it. The controller will be garbage-collected once it goes out of scope.
    if (newName != null && newName.isNotEmpty && newName != _plan.name) {
      try {
        final updated =
            await PlanService.updatePlan(_plan.id!, {'name': newName});
        if (mounted) setState(() => _plan = updated);
        // Also update in VM list
        if (mounted) vm.setCurrentPlan(updated);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update name: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text, ColorScheme cs) => Text(
        text,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: 1.2),
      );

  Widget _statusBadge(PlanStatus status, ColorScheme cs) {
    const colors = {
      PlanStatus.draft: Color(0xFF9E9E9E),
      PlanStatus.active: Colors.green,
      PlanStatus.completed: Color(0xFF9C27B0),
    };
    final labels = {
      PlanStatus.draft: context.tr('plan_status_draft'),
      PlanStatus.active: context.tr('plan_status_active'),
      PlanStatus.completed: context.tr('plan_status_completed'),
    };
    final color = colors[status] ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? '',
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }

  Color _formatColor(ContentFormat f, ColorScheme cs) {
    switch (f) {
      case ContentFormat.reel:
        return const Color(0xFFE91E63);
      case ContentFormat.carousel:
        return const Color(0xFF2196F3);
      case ContentFormat.story:
        return const Color(0xFFFF9800);
      case ContentFormat.post:
        return cs.primary;
    }
  }

  Color _ctaColor(CtaType cta, ColorScheme cs) {
    switch (cta) {
      case CtaType.hard:
        return cs.error;
      case CtaType.soft:
        return cs.secondary;
      case CtaType.educational:
        return const Color(0xFF00BCD4);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ─── Image Generator Dialog ──────────────────────────────────────────────

  void _showImageGeneratorDialog(ContentBlock block) {
    final cs = Theme.of(context).colorScheme;
    
    // Get brand info from context
    final brandVm = context.read<BrandViewModel>();
    final brand = brandVm.brands.cast<Brand?>().firstWhere(
      (b) => b?.id == _plan.brandId,
      orElse: () => null,
    );
    
    // Auto-detect category from brand description
    String? autoCategory;
    if (brand?.description != null) {
      final desc = brand!.description!.toLowerCase();
      if (desc.contains('cosmetic') || desc.contains('makeup') || desc.contains('beauty') || desc.contains('skincare')) {
        autoCategory = 'cosmetics';
      } else if (desc.contains('sport') || desc.contains('fitness') || desc.contains('athletic')) {
        autoCategory = 'sports';
      } else if (desc.contains('fashion') || desc.contains('clothing') || desc.contains('apparel')) {
        autoCategory = 'fashion';
      } else if (desc.contains('food') || desc.contains('restaurant') || desc.contains('cuisine')) {
        autoCategory = 'food';
      } else if (desc.contains('tech') || desc.contains('software') || desc.contains('digital')) {
        autoCategory = 'technology';
      }
    }
    
    final promptController = TextEditingController(
      text: '${brand?.name ?? _plan.name} - ${block.title}',
    );
    final objectController = TextEditingController(); // NOUVEAU : champ objet spécifique
    String selectedStyle = 'professional';
    String? selectedCategory = autoCategory;
    bool isGenerating = false;
    String? generatedImageUrl;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.image, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Générer une Image'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (block.imageUrl != null) ...[
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(block.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '✅ Image déjà générée',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Image pour ${brand?.name ?? _plan.name}',
                            style: TextStyle(fontSize: 10, color: cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: promptController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ex: ${brand?.name ?? "Nike"} - Chaussures...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  
                  // NOUVEAU : Champ objet spécifique
                  Text(
                    'Objet spécifique (optionnel)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: objectController,
                    decoration: InputDecoration(
                      hintText: 'Ex: rouge à lèvres, parfum, espadrille, pantalon...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Catégorie ${autoCategory != null ? "(auto)" : ""}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      hintText: 'Sélectionnez',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 12),
                    items: [
                      DropdownMenuItem(value: null, child: Text('Aucune', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'cosmetics', child: Text('💄 Cosmétiques', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'beauty', child: Text('✨ Beauté', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'sports', child: Text('⚽ Sports', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'fashion', child: Text('👗 Mode', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'food', child: Text('🍔 Food', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'technology', child: Text('💻 Tech', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: 'lifestyle', child: Text('🏠 Lifestyle', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedCategory = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Style',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'professional',
                      'minimal',
                      'colorful',
                      'dark',
                      'nature',
                    ].map((style) {
                      final isSelected = selectedStyle == style;
                      return ChoiceChip(
                        label: Text(style, style: TextStyle(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (_) {
                          setDialogState(() => selectedStyle = style);
                        },
                        selectedColor: cs.primary,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected ? cs.onPrimary : cs.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  if (isGenerating) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: cs.primary, strokeWidth: 2.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Génération...',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (generatedImageUrl != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '✅ Image générée',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        generatedImageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 120,
                            color: cs.surfaceContainerHighest,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 32, color: cs.onSurfaceVariant),
                                const SizedBox(height: 4),
                                Text(
                                  'Erreur',
                                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bouton Partager seulement (pas de bouton Utiliser, sauvegarde automatique)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: generatedImageUrl == null ? null : () async {
                          // Show share dialog with image and caption
                          await ImageDownloadService.showShareDialog(
                            context: context,
                            imageUrl: generatedImageUrl!,
                            caption: '${brand?.name ?? _plan.name} - ${block.title}\n\n${block.pillar}',
                          );
                        },
                        icon: Icon(Icons.share, size: 14),
                        label: Text('Partager', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.primary,
                          side: BorderSide(color: cs.primary),
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(fontSize: 10, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isGenerating ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton.icon(
              onPressed: isGenerating
                  ? null
                  : () async {
                      setDialogState(() {
                        isGenerating = true;
                        errorMessage = null;
                        generatedImageUrl = null;
                      });

                      try {
                        // Convert style string to ImageStyle enum
                        ImageStyle style;
                        switch (selectedStyle) {
                          case 'minimal':
                            style = ImageStyle.minimalist;
                            break;
                          case 'colorful':
                            style = ImageStyle.colorful;
                            break;
                          case 'professional':
                            style = ImageStyle.professional;
                            break;
                          case 'dark':
                          case 'nature':
                          default:
                            style = ImageStyle.professional;
                        }

                        // Construire la description avec l'objet spécifique si fourni
                        String finalDescription = promptController.text.trim();
                        if (objectController.text.trim().isNotEmpty) {
                          finalDescription = '${objectController.text.trim()} - $finalDescription';
                        }

                        final result = await ImageGeneratorService.generateImage(
                          description: finalDescription,
                          style: style,
                          brandName: _plan.name,
                          category: selectedCategory,
                        );

                        setDialogState(() {
                          generatedImageUrl = result.url;
                          isGenerating = false;
                        });

                        // Sauvegarder automatiquement l'image dans le post
                        if (block.id != null) {
                          try {
                            await ImageGeneratorService.saveImageToPost(
                              contentBlockId: block.id!,
                              imageUrl: result.url,
                            );
                            
                            // Reload plan from backend to get updated data
                            await _fetchDetail();
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Image générée et sauvegardée !'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            print('❌ Erreur sauvegarde: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Image générée (sauvegarde échouée)'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Image générée avec succès !'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          errorMessage = e.toString();
                          isGenerating = false;
                        });
                      }
                    },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Générer'),
            ),
          ],
        ),
      ),
    );
  }
}

