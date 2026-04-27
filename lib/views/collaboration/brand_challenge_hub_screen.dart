import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/brand.dart';
import '../../models/challenge.dart';
import '../../models/submission.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/challenge_view_model.dart';
import 'brand_team_sheet.dart';
import 'submission_review_screen.dart';

class BrandChallengeHubScreen extends StatefulWidget {
  const BrandChallengeHubScreen({super.key});

  @override
  State<BrandChallengeHubScreen> createState() => _BrandChallengeHubScreenState();
}

class _BrandChallengeHubScreenState extends State<BrandChallengeHubScreen> {
  String? _selectedBrandId;
  Challenge? _reviewingChallenge;
  int _reviewTab = 0; // 0 = All, 1 = Shortlisted

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final brandVm = context.read<BrandViewModel>();
      brandVm.loadBrands().then((_) {
        if (mounted && brandVm.brands.isNotEmpty) {
          final firstId = brandVm.brands.first.id;
          if (firstId != null) {
            setState(() => _selectedBrandId = firstId);
            context.read<ChallengeViewModel>().loadBrandChallenges(firstId);
          }
        }
      });
    });
  }

  void _selectBrand(String brandId) {
    setState(() {
      _selectedBrandId = brandId;
      _reviewingChallenge = null;
    });
    context.read<ChallengeViewModel>().loadBrandChallenges(brandId);
  }

  void _reviewChallenge(Challenge challenge) {
    setState(() {
      _reviewingChallenge = challenge;
      _reviewTab = 0;
    });
    context.read<ChallengeViewModel>().loadSubmissions(challenge.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF5F6FA),
      body: SafeArea(
        child: _reviewingChallenge != null
            ? _buildReviewPanel(context, isDark)
            : _buildHubView(context, isDark),
      ),
    );
  }

  // ── HUB VIEW ──────────────────────────────────────────────────────────────

  Widget _buildHubView(BuildContext context, bool isDark) {
    return Consumer2<BrandViewModel, ChallengeViewModel>(
      builder: (context, brandVm, challengeVm, _) {
        final challenges = challengeVm.brandCampaigns;
        final activeChallenges = challenges.where((c) => c.status == 'live').length;
        final totalEntries = challenges.fold<int>(0, (sum, c) => sum + c.submissionsCount);
        final totalShortlisted = challenges.fold<int>(0, (sum, c) => sum + c.shortlistedCount);

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (_selectedBrandId != null) {
              await challengeVm.loadBrandChallenges(_selectedBrandId!);
            }
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context, isDark, brandVm)),
              SliverToBoxAdapter(
                child: _buildStatsRow(context, isDark, activeChallenges, totalEntries, totalShortlisted),
              ),
              SliverToBoxAdapter(
                child: _buildManageTeamButton(context, isDark),
              ),
              if (challengeVm.isLoading && challenges.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (challenges.isEmpty)
                SliverFillRemaining(child: _buildEmptyChallenges(context, isDark))
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        if (i < challenges.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildChallengeCard(context, isDark, challenges[i]),
                          );
                        }
                        return _buildNewChallengeButton(context, isDark);
                      },
                      childCount: challenges.length + 1,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, BrandViewModel brandVm) {
    final authVm = context.read<AuthViewModel>();
    final user = authVm.currentUser;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient top bar
        Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'BRAND OWNER',
                        style: GoogleFonts.spaceMono(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.displayName ?? 'Brand Owner',
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29),
                      ),
                    ),
                  ],
                ),
              ),
              // Brand selector
              if (brandVm.brands.isNotEmpty)
                _buildBrandSelector(context, isDark, brandVm.brands),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBrandSelector(BuildContext context, bool isDark, List<Brand> brands) {
    if (brands.length == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          brands.first.name,
          style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.primary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBrandId,
          isDense: true,
          style: GoogleFonts.spaceMono(fontSize: 11, color: AppColors.primary),
          dropdownColor: isDark ? AppColors.bgCard : Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary, size: 16),
          items: brands.map((b) => DropdownMenuItem(
            value: b.id,
            child: Text(b.name),
          )).toList(),
          onChanged: (id) {
            if (id != null) _selectBrand(id);
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isDark, int active, int entries, int shortlisted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          _buildStatCard(isDark, '$active', 'ACTIVE', AppColors.primary),
          const SizedBox(width: 10),
          _buildStatCard(isDark, '$entries', 'ENTRIES', AppColors.secondary),
          const SizedBox(width: 10),
          _buildStatCard(isDark, '$shortlisted', 'SHORTLISTED', AppColors.accent),
        ],
      ),
    );
  }

  Widget _buildStatCard(bool isDark, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManageTeamButton(BuildContext context, bool isDark) {
    if (_selectedBrandId == null) return const SizedBox.shrink();
    final brandVm = context.read<BrandViewModel>();
    final brand = brandVm.brands.firstWhere(
      (b) => b.id == _selectedBrandId,
      orElse: () => brandVm.brands.first,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () => BrandTeamSheet.show(context, _selectedBrandId!, brand.name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 15, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                'MANAGE TEAM',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '· Invite collaborators to join challenges',
                  style: TextStyle(fontSize: 11, color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, bool isDark, Challenge challenge) {
    final isLive = challenge.status == 'live';
    final isReview = challenge.status == 'review';
    final isClosed = challenge.status == 'closed';

    Color statusColor = isLive
        ? AppColors.success
        : isReview
            ? AppColors.accent
            : AppColors.secondary;

    String statusText = challenge.status.toUpperCase();
    if (isReview) statusText = 'IN REVIEW';

    final progress = challenge.maxParticipants > 0
        ? (challenge.submissionsCount / challenge.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    final deadlineStr = DateFormat('MMM d, yyyy').format(challenge.deadline);
    final daysLeft = challenge.deadline.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? AppColors.primary.withValues(alpha: 0.25)
              : isReview
                  ? AppColors.accent.withValues(alpha: 0.25)
                  : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color banner strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLive
                    ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.3)]
                    : isReview
                        ? [AppColors.accent, AppColors.accent.withValues(alpha: 0.3)]
                        : [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.3)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(statusText, statusColor),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${challenge.submissionsCount} submissions',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                          ),
                        ),
                        Text(
                          challenge.maxParticipants > 0
                              ? '/ ${challenge.maxParticipants} max'
                              : 'no cap',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark ? AppColors.bgElevated : const Color(0xFFE8EAED),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLive ? AppColors.primary : AppColors.accent,
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Meta row
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13,
                        color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0)),
                    const SizedBox(width: 4),
                    Text(
                      daysLeft > 0 ? '$deadlineStr · $daysLeft days left' : deadlineStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '🏆 ${challenge.reward}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29),
                      ),
                    ),
                  ],
                ),
                if (challenge.shortlistedCount > 0) ...[
                  const SizedBox(height: 10),
                  _buildCreatorStack(isDark, challenge.shortlistedCount),
                ],
                if (!isClosed) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _reviewChallenge(challenge),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLive ? AppColors.primary : AppColors.accent,
                        foregroundColor: isLive ? AppColors.bgDark : AppColors.bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'REVIEW SUBMISSIONS',
                        style: GoogleFonts.spaceMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceMono(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCreatorStack(bool isDark, int count) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.success,
    ];
    final displayCount = count.clamp(0, 4);
    return Row(
      children: [
        SizedBox(
          height: 24,
          width: (displayCount * 16 + 8).toDouble(),
          child: Stack(
            children: List.generate(displayCount, (i) {
              return Positioned(
                left: i * 16.0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length].withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.bgDark : Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count shortlisted',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
          ),
        ),
      ],
    );
  }

  Widget _buildNewChallengeButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: GestureDetector(
        onTap: () => context.push('/brands-list'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'LAUNCH NEW CHALLENGE',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChallenges(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎯', style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No challenges yet',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Launch your first challenge to start collecting creator content.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/brands-list'),
              icon: const Icon(Icons.rocket_launch_outlined),
              label: const Text('Launch Challenge'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bgDark,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── REVIEW PANEL ──────────────────────────────────────────────────────────

  Widget _buildReviewPanel(BuildContext context, bool isDark) {
    final challenge = _reviewingChallenge!;

    return Consumer<ChallengeViewModel>(
      builder: (context, vm, _) {
        final submissions = vm.currentSubmissions;
        final winner = submissions.where((s) => s.status == 'winner').firstOrNull;
        final shortlisted = submissions.where((s) => s.status == 'shortlisted').toList();
        final pending = submissions.where((s) => s.status == 'pending' || s.status == 'revision_requested').toList();
        final reviewing = _reviewTab == 0 ? [...pending, ...shortlisted] : shortlisted;

        return Column(
          children: [
            // Review header
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _reviewingChallenge = null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.bgCard : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(Icons.arrow_back, size: 18,
                          color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: GoogleFonts.syne(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${submissions.length} submissions · ${shortlisted.length} shortlisted',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusPill(challenge.status.toUpperCase(), AppColors.primary),
                ],
              ),
            ),
            // Sub-tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _buildReviewTab(0, 'All (${pending.length + shortlisted.length})', isDark),
                  const SizedBox(width: 8),
                  _buildReviewTab(1, 'Shortlisted (${shortlisted.length})', isDark),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Content
            Expanded(
              child: vm.isLoading && submissions.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : vm.error != null && submissions.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.secondary, size: 36),
                                const SizedBox(height: 12),
                                Text(
                                  vm.error!.replaceAll('Exception: ', ''),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.secondary),
                                ),
                                const SizedBox(height: 16),
                                TextButton(
                                  onPressed: () => vm.loadSubmissions(challenge.id),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => vm.loadSubmissions(challenge.id),
                      child: CustomScrollView(
                        slivers: [
                          if (winner != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                                child: _buildWinnerCard(context, isDark, winner, challenge),
                              ),
                            ),
                          if (_reviewTab == 1 && shortlisted.isNotEmpty)
                            SliverToBoxAdapter(
                              child: _buildShortlistGrid(context, isDark, shortlisted, challenge),
                            ),
                          if (reviewing.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _reviewTab == 0
                                          ? 'No submissions yet.\nShare the challenge to get entries!'
                                          : 'No shortlisted submissions yet.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Challenge ID: ${challenge.id}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _buildSubmissionCard(context, isDark, reviewing[i], challenge),
                                  ),
                                  childCount: reviewing.length,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewTab(int index, String label, bool isDark) {
    final selected = _reviewTab == index;
    return GestureDetector(
      onTap: () => setState(() => _reviewTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : isDark ? AppColors.bgCard : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? AppColors.primary : (isDark ? AppColors.textSecondary : const Color(0xFF5A6578)),
          ),
        ),
      ),
    );
  }

  Widget _buildWinnerCard(BuildContext context, bool isDark, Submission winner, Challenge challenge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.accent.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFFF59E0B)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'WINNER',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.bgDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                challenge.reward,
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVideoThumbnail(isDark, winner.thumbnailUrl, size: 80),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator #${winner.creatorId.substring(0, 8)}',
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted ${DateFormat('MMM d').format(winner.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                      ),
                    ),
                    if (winner.rating != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < (winner.rating ?? 0) ? Icons.star : Icons.star_border,
                          size: 14,
                          color: AppColors.accent,
                        )),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortlistGrid(BuildContext context, bool isDark, List<Submission> shortlisted, Challenge challenge) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SHORTLISTED',
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.8,
            ),
            itemCount: shortlisted.length,
            itemBuilder: (context, i) {
              final sub = shortlisted[i];
              return _buildShortlistTile(isDark, sub, challenge);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShortlistTile(bool isDark, Submission sub, Challenge challenge) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: _buildVideoThumbnail(isDark, sub.thumbnailUrl, size: double.infinity),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Column(
              children: [
                Text(
                  '#${sub.creatorId.substring(0, 6)}',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9,
                    color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Consumer<ChallengeViewModel>(
                  builder: (context, vm, _) => GestureDetector(
                    onTap: () => _confirmDeclareWinner(context, sub, challenge),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '👑 WINNER',
                        style: GoogleFonts.spaceMono(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(BuildContext context, bool isDark, Submission sub, Challenge challenge) {
    final isShortlisted = sub.status == 'shortlisted';
    final isRevision = sub.status == 'revision_requested';

    Color statusColor = AppColors.primary;
    String statusLabel = 'UNDER REVIEW';
    if (isShortlisted) { statusColor = AppColors.accent; statusLabel = 'SHORTLISTED'; }
    if (isRevision) { statusColor = AppColors.secondary; statusLabel = 'REVISION NEEDED'; }

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => SubmissionReviewScreen(submission: sub, challenge: challenge),
          ),
        );
        if (changed == true && context.mounted) {
          context.read<ChallengeViewModel>().loadSubmissions(challenge.id);
        }
      },
      child: Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildVideoThumbnail(isDark, sub.thumbnailUrl, size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusPill(statusLabel, statusColor),
                      const SizedBox(height: 6),
                      Text(
                        'Creator #${sub.creatorId.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textPrimary : const Color(0xFF1A1D29),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d').format(sub.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.feedback_outlined, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '"${sub.feedback}"',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondary : const Color(0xFF5A6578),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Action buttons
            Consumer<ChallengeViewModel>(
              builder: (context, vm, _) => Row(
                children: [
                  // Shortlist toggle
                  Expanded(
                    child: _ActionButton(
                      label: isShortlisted ? 'UNLIST' : 'SHORTLIST',
                      icon: isShortlisted ? Icons.star : Icons.star_border,
                      color: AppColors.accent,
                      onTap: vm.isLoading ? null : () => vm.shortlist(sub.id, challenge.id, !isShortlisted),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Revision
                  Expanded(
                    child: _ActionButton(
                      label: 'REVISE',
                      icon: Icons.refresh,
                      color: AppColors.secondary,
                      onTap: vm.isLoading || isRevision
                          ? null
                          : () => _showRevisionDialog(context, vm, sub, challenge),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Winner
                  Expanded(
                    child: _ActionButton(
                      label: 'WINNER',
                      icon: Icons.emoji_events,
                      color: AppColors.success,
                      onTap: vm.isLoading
                          ? null
                          : () => _confirmDeclareWinner(context, sub, challenge),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildVideoThumbnail(bool isDark, String? url, {required double size}) {
    return Container(
      width: size == double.infinity ? null : size,
      height: size == double.infinity ? null : size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgElevated : const Color(0xFFE8EAED),
        borderRadius: BorderRadius.circular(10),
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? Icon(Icons.play_circle_outline, size: size == double.infinity ? 24 : size * 0.4,
              color: isDark ? AppColors.textTertiary : const Color(0xFF8B95B0))
          : null,
    );
  }

  Future<void> _showRevisionDialog(
      BuildContext context, ChallengeViewModel vm, Submission sub, Challenge challenge) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Revision'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Describe what needs to be changed...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != null && confirmed.isNotEmpty && context.mounted) {
      await vm.requestRevision(sub.id, challenge.id, confirmed);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Revision requested successfully')),
        );
      }
    }
  }

  Future<void> _confirmDeclareWinner(BuildContext context, Submission sub, Challenge challenge) async {
    final vm = context.read<ChallengeViewModel>();
    final brandId = _selectedBrandId ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Declare Winner'),
        content: Text(
          'Declare this submission as the winner of "${challenge.title}"?\n\nThis will close the challenge and notify all participants.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: AppColors.bgDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Declare Winner'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await vm.declareWinner(sub.id, challenge.id, brandId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🏆 Winner declared! Challenge closed.')),
        );
        setState(() => _reviewingChallenge = null);
        if (brandId.isNotEmpty) vm.loadBrandChallenges(brandId);
      }
    }
  }
}

// ── Reusable action button ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: disabled ? Colors.transparent : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled ? AppColors.border : color.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: disabled ? AppColors.textTertiary : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: disabled ? AppColors.textTertiary : color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
