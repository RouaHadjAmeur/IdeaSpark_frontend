import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/challenge.dart';
import '../../models/submission.dart';
import '../../view_models/challenge_view_model.dart';
import '../../view_models/auth_view_model.dart';
import '../../view_models/collaboration_view_model.dart';
import 'video_preview_screen.dart';

// ── Picker option tile ──────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1A1D29),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8B95B0) : const Color(0xFF5A6578),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Challenge? _selectedChallenge;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2) {
        context.read<ChallengeViewModel>().loadMySubmissions();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final challengeVm = context.read<ChallengeViewModel>();
      challengeVm.loadDiscoverChallenges();
      challengeVm.loadMySubmissions();
      context.read<CollaborationViewModel>().loadPendingBrandInvitations();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, colorScheme, isDark),
            _buildTabBar(context, colorScheme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDiscoverTab(context, colorScheme, isDark),
                  _buildChallengeDetailTab(context, colorScheme, isDark),
                  _buildMySubmissionsTab(context, colorScheme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Consumer<AuthViewModel>(
        builder: (context, authVm, child) {
          final user = authVm.currentUser;
          final initials = user?.displayName.split(' ').map((e) => e[0]).take(2).join('').toUpperCase() ?? '??';
          return Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.role.value.toUpperCase() ?? 'USER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        user?.displayName ?? 'Anonymous',
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        labelStyle: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'DISCOVER'),
          Tab(text: 'CHALLENGE'),
          Tab(text: 'MY WORK'),
        ],
      ),
    );
  }

  Widget _buildDiscoverTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Consumer2<ChallengeViewModel, CollaborationViewModel>(
      builder: (context, viewModel, collabVm, child) {
        if (viewModel.isLoading && viewModel.availableChallenges.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await viewModel.loadDiscoverChallenges();
            await collabVm.loadPendingBrandInvitations();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending brand invitations banner
                if (collabVm.pendingBrandInvitations.isNotEmpty)
                  _buildPendingInvitationsBanner(context, colorScheme, isDark, collabVm),
                Text(
                  'Open Challenges',
                  style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Find briefs that match your style · submit · win rewards',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _buildFilterButton(context, colorScheme),
                const SizedBox(height: 24),
                if (viewModel.availableChallenges.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        'No open challenges yet.\nCheck back later!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else ...[
                  Text(
                    'Featured This Week',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...viewModel.availableChallenges.map((challenge) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildChallengeCard(
                      context,
                      colorScheme,
                      isDark,
                      challenge: challenge,
                    ),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPickerSheet(BuildContext context, ChallengeViewModel viewModel, String challengeId, {String challengeTitle = 'Challenge'}) async {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? videoPath = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF151B2D) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select Video Source',
              style: GoogleFonts.syne(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'MP4 or MOV · Max 200MB · Vertical preferred',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            // Photo Library option
            _PickerOption(
              icon: Icons.photo_library_outlined,
              label: 'Photo Library',
              subtitle: 'Pick a video from your camera roll',
              color: colorScheme.primary,
              isDark: isDark,
              onTap: () async {
                final XFile? file = await ImagePicker().pickVideo(source: ImageSource.gallery);
                if (ctx.mounted) Navigator.pop(ctx, file?.path);
              },
            ),
            const SizedBox(height: 12),
            // Files option
            _PickerOption(
              icon: Icons.folder_outlined,
              label: 'Files',
              subtitle: 'Browse your device storage',
              color: colorScheme.secondary,
              isDark: isDark,
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.media,
                  allowMultiple: false,
                );
                if (ctx.mounted) Navigator.pop(ctx, result?.files.single.path);
              },
            ),
          ],
        ),
      ),
    );

    if (videoPath == null || !context.mounted) return;

    // Show preview — user must confirm before submitting
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoPreviewScreen(
          videoPath: videoPath,
          challengeTitle: challengeTitle,
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await viewModel.submitVideo(challengeId, videoPath);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video submitted successfully!')),
        );
        _tabController.animateTo(2);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    }
  }

  Widget _buildPendingInvitationsBanner(
      BuildContext context, ColorScheme colorScheme, bool isDark, CollaborationViewModel collabVm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...collabVm.pendingBrandInvitations.map((invite) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                : colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(Icons.group_add_outlined, color: colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brand Invitation',
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Join "${invite.brandName ?? 'a brand'}" as collaborator',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () async {
                      await collabVm.declineBrandInvitation(invite.id);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text('Decline', style: TextStyle(fontSize: 12)),
                  ),
                  FilledButton(
                    onPressed: collabVm.isLoading
                        ? null
                        : () async {
                            try {
                              await collabVm.acceptBrandInvitation(invite.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('You joined "${invite.brandName}"! Refreshing challenges…')),
                                );
                                await context.read<ChallengeViewModel>().loadDiscoverChallenges();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        )),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context, ColorScheme colorScheme) {
    return OutlinedButton.icon(
      onPressed: () {
        // Show filter options
      },
      icon: Icon(Icons.filter_list, size: 18, color: colorScheme.onSurface),
      label: Text(
        'Filter',
        style: TextStyle(color: colorScheme.onSurface),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required Challenge challenge,
  }) {
    final deadlineStr = DateFormat('MMM d').format(challenge.deadline);
    final isNew = DateTime.now().difference(challenge.createdAt).inDays < 3;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChallenge = challenge;
        });
        _tabController.animateTo(1);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      challenge.title.substring(0, 2).toUpperCase(),
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
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
                        challenge.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (isNew)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              challenge.title,
              style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTag(challenge.videoType, colorScheme, isDark),
                _buildTag('${challenge.minDuration}–${challenge.maxDuration}s', colorScheme, isDark),
                if (challenge.language.isNotEmpty)
                  _buildTag(challenge.language, colorScheme, isDark),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deadline $deadlineStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${challenge.submissionsCount} submissions',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '🏆 ${challenge.reward}',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View Brief →',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainerHigh 
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildChallengeDetailTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    if (_selectedChallenge == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎬', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Select a challenge to view the brief',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Go to Discover'),
            ),
          ],
        ),
      );
    }

    final challenge = _selectedChallenge!;
    final deadlineStr = DateFormat('MMM d, yyyy').format(challenge.deadline);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Challenge Brief',
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Read the full brief · submit your entry',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _buildBrandHeader(context, colorScheme, isDark, challenge),
          const SizedBox(height: 24),
          Text(
            challenge.title,
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            challenge.description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildRewardCard(
                  context,
                  colorScheme,
                  isDark,
                  'Winner',
                  challenge.reward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRewardCard(
                  context,
                  colorScheme,
                  isDark,
                  'Runner-up',
                  challenge.runnerUpReward.isNotEmpty ? challenge.runnerUpReward : 'N/A',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRewardCard(
                  context,
                  colorScheme,
                  isDark,
                  'Entries',
                  challenge.maxParticipants > 0
                      ? '${challenge.submissionsCount}/${challenge.maxParticipants}'
                      : '${challenge.submissionsCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoGrid(context, colorScheme, isDark, challenge, deadlineStr),
          const SizedBox(height: 24),
          _buildEvaluationCriteria(context, colorScheme, isDark),
          const SizedBox(height: 24),
          _buildSubmitSection(context, colorScheme, isDark, challenge),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context, ColorScheme colorScheme, bool isDark, Challenge challenge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                challenge.title.substring(0, 1).toUpperCase(),
                style: GoogleFonts.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenge Brand',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.title,
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: challenge.status == 'live' ? colorScheme.primary : Colors.grey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              challenge.status.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    String label,
    String amount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.syne(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(BuildContext context, ColorScheme colorScheme, bool isDark, Challenge challenge, String deadlineStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(colorScheme, 'Video Type', challenge.videoType),
          const SizedBox(height: 16),
          _buildInfoRow(colorScheme, 'Duration', '${challenge.minDuration} – ${challenge.maxDuration}s'),
          const SizedBox(height: 16),
          _buildInfoRow(colorScheme, 'Deadline', deadlineStr),
          const SizedBox(height: 16),
          if (challenge.language.isNotEmpty)
            ...[_buildInfoRow(colorScheme, 'Language', challenge.language), const SizedBox(height: 16)],
          if (challenge.targetAudience.isNotEmpty)
            ...[_buildInfoRow(colorScheme, 'Audience', challenge.targetAudience), const SizedBox(height: 16)],
          _buildInfoRow(colorScheme, 'Entries', '${challenge.submissionsCount} / ${challenge.maxParticipants}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ColorScheme colorScheme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluationCriteria(BuildContext context, ColorScheme colorScheme, bool isDark) {
    final challenge = _selectedChallenge!;
    if (challenge.criteria.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checklist_rounded, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Evaluation Criteria',
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...challenge.criteria.map((criterion) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCriteriaItem(colorScheme, criterion),
          )),
        ],
      ),
    );
  }

  Widget _buildCriteriaItem(ColorScheme colorScheme, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitSection(BuildContext context, ColorScheme colorScheme, bool isDark, Challenge challenge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Consumer<ChallengeViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              Row(
                children: [
                  const Text('🎬', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    'Submit Your Video',
                    style: GoogleFonts.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'MP4 or MOV · Max 200MB · Vertical format preferred',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (viewModel.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    viewModel.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => _showPickerSheet(context, viewModel, challenge.id, challengeTitle: challenge.title),
                  icon: viewModel.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(viewModel.isLoading ? 'UPLOADING...' : 'PICK & SUBMIT VIDEO'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMySubmissionsTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Consumer<ChallengeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.mySubmissions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final all = viewModel.mySubmissions;
        final active = all.where((s) => s.status != 'winner' && s.status != 'rejected').toList();
        final wins = all.where((s) => s.status == 'winner').toList();

        return RefreshIndicator(
          onRefresh: () => viewModel.loadMySubmissions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Work',
                  style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track status · respond to feedback · claim rewards',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                // Stats row
                Row(
                  children: [
                    _buildMiniStat(colorScheme, isDark, '${all.length}', 'Total'),
                    const SizedBox(width: 10),
                    _buildMiniStat(colorScheme, isDark, '${wins.length}', 'Won'),
                    const SizedBox(width: 10),
                    _buildMiniStat(colorScheme, isDark,
                      '${active.where((s) => s.status == 'revision_requested').length}',
                      'Revisions'),
                  ],
                ),
                const SizedBox(height: 28),
                if (active.isNotEmpty) ...[
                  Text('Active Submissions',
                    style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
                  const SizedBox(height: 14),
                  ...active.map((sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildSubmissionCard(context, colorScheme, isDark, submission: sub),
                  )),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text(
                      all.isEmpty
                          ? 'No submissions yet.\nBrowse challenges and submit your first video!'
                          : 'No active submissions right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant, height: 1.5),
                    )),
                  ),
                if (wins.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Past Wins 🏆',
                    style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
                  const SizedBox(height: 14),
                  ...wins.map((sub) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildSubmissionCard(context, colorScheme, isDark, submission: sub),
                  )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(ColorScheme colorScheme, bool isDark, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.syne(
              fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required Submission submission,
  }) {
    Color statusColor = Colors.blue;
    IconData statusIcon = Icons.hourglass_empty;
    String statusText = submission.status.toUpperCase();

    switch (submission.status) {
      case 'shortlisted':
        statusColor = Colors.amber;
        statusIcon = Icons.star;
        break;
      case 'winner':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.emoji_events;
        statusText = submission.challengeReward.isNotEmpty
            ? '🏆 WINNER — ${submission.challengeReward}'
            : '🏆 WINNER';
        break;
      case 'revision_requested':
        statusColor = Colors.orange;
        statusIcon = Icons.refresh;
        statusText = 'REVISION NEEDED';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.close;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  image: submission.thumbnailUrl != null 
                    ? DecorationImage(image: NetworkImage(submission.thumbnailUrl!), fit: BoxFit.cover)
                    : null,
                ),
                child: submission.thumbnailUrl == null ? Icon(
                  Icons.play_circle_outline,
                  size: 32,
                  color: colorScheme.onSurfaceVariant,
                ) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.challengeTitle.isNotEmpty
                          ? submission.challengeTitle
                          : 'Challenge #${submission.challengeId.substring(0, 8)}',
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submitted ${DateFormat('MMM d').format(submission.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark 
                    ? colorScheme.surfaceContainerHigh 
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brand Feedback',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${submission.feedback}"',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (submission.status == 'revision_requested') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final colorScheme = Theme.of(context).colorScheme;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  String? path = await showModalBottomSheet<String>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF151B2D) : Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 36, height: 4,
                            decoration: BoxDecoration(color: colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 20),
                          Text('Upload Revised Video', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
                          const SizedBox(height: 24),
                          _PickerOption(
                            icon: Icons.photo_library_outlined,
                            label: 'Photo Library',
                            subtitle: 'Pick a video from your camera roll',
                            color: colorScheme.primary,
                            isDark: isDark,
                            onTap: () async {
                              final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
                              if (ctx.mounted) Navigator.pop(ctx, file?.path);
                            },
                          ),
                          const SizedBox(height: 12),
                          _PickerOption(
                            icon: Icons.folder_outlined,
                            label: 'Files',
                            subtitle: 'Browse your device storage',
                            color: colorScheme.secondary,
                            isDark: isDark,
                            onTap: () async {
                              final result = await FilePicker.platform.pickFiles(type: FileType.media, allowMultiple: false);
                              if (ctx.mounted) Navigator.pop(ctx, result?.files.single.path);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                  if (path != null && context.mounted) {
                    final confirmed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => VideoPreviewScreen(
                          videoPath: path,
                          challengeTitle: 'Revised Submission',
                        ),
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      await context.read<ChallengeViewModel>().updateSubmission(submission.id, File(path));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Revision uploaded successfully!')),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Revised Version'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
