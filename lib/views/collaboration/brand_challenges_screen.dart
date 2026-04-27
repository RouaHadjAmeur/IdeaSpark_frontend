import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/challenge.dart';
import '../../models/submission.dart';
import '../../view_models/challenge_view_model.dart';
import '../../view_models/brand_view_model.dart';
import '../../view_models/auth_view_model.dart';

class BrandChallengesScreen extends StatefulWidget {
  const BrandChallengesScreen({super.key});

  @override
  State<BrandChallengesScreen> createState() => _BrandChallengesScreenState();
}

class _BrandChallengesScreenState extends State<BrandChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedChallengeId;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _criteriaController = TextEditingController();
  String? _selectedBrandId;
  String _selectedVideoType = 'UGC';
  DateTime? _selectedDeadline;
  final List<String> _selectedCriteria = [];
  final Map<String, List<String>> _criteriaByCategory = {
    'Video Quality': ['Good Lighting', 'Clean Background', 'Vertical Format', 'HD Resolution', 'Stable Footage'],
    'Content': ['Hook in 3s', 'Product Mentioned', 'Natural Tone', 'Authentic Reaction', 'Clear Storyline'],
    'Audio': ['Trending Audio', 'Clear Speech', 'No Background Noise', 'Original Voice'],
    'Engagement': ['Strong CTA', 'Emotional Appeal', 'Humor', 'Educational Value'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final brandVm = context.read<BrandViewModel>();
    await brandVm.loadBrands();
    if (brandVm.brands.isNotEmpty && mounted) {
      setState(() {
        _selectedBrandId = brandVm.brands.first.id;
      });
      context.read<ChallengeViewModel>().loadBrandChallenges(_selectedBrandId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _maxParticipantsController.dispose();
    _criteriaController.dispose();
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
                  _buildManageChallengesTab(context, colorScheme, isDark),
                  _buildLaunchChallengeTab(context, colorScheme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Consumer<AuthViewModel>(
      builder: (context, authVm, _) {
        final user = authVm.currentUser;
        final name = user?.displayName ?? user?.email ?? 'Brand Owner';
        final initials = name.trim().split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join().toUpperCase();
        return Container(
          padding: const EdgeInsets.all(20),
          child: Row(
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
                    initials.isEmpty ? 'BO' : initials,
                    style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BRAND OWNER',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                        color: colorScheme.primary, letterSpacing: 1.2),
                    ),
                    Text(
                      name,
                      style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          Tab(text: 'MANAGE CHALLENGES'),
          Tab(text: 'LAUNCH CHALLENGE'),
        ],
      ),
    );
  }

  Widget _buildManageChallengesTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Consumer2<ChallengeViewModel, BrandViewModel>(
      builder: (context, challengeVm, brandVm, child) {
        if (challengeVm.isLoading && challengeVm.brandCampaigns.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final campaigns = challengeVm.brandCampaigns;

        return RefreshIndicator(
          onRefresh: () => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brand Challenges',
                  style: GoogleFonts.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Launch campaigns · collect creator content · pick your winner',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatsRow(context, colorScheme, isDark, campaigns),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Campaigns',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (campaigns.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No campaigns yet. Click below to start!',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...campaigns.map((challenge) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCampaignCard(
                      context,
                      colorScheme,
                      isDark,
                      challenge: challenge,
                    ),
                  )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Launch New Challenge'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_selectedChallengeId != null) ...[
                  const SizedBox(height: 32),
                  _buildSubmissionFeed(context, colorScheme, isDark),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(BuildContext context, ColorScheme colorScheme, bool isDark, List<Challenge> campaigns) {
    int active = campaigns.where((c) => c.status == 'live').length;
    int submissions = campaigns.fold(0, (sum, c) => sum + c.submissionsCount);
    int shortlisted = campaigns.fold(0, (sum, c) => sum + c.shortlistedCreators.length);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            colorScheme,
            isDark,
            label: 'Active',
            value: active.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            colorScheme,
            isDark,
            label: 'Entries',
            value: submissions.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            colorScheme,
            isDark,
            label: 'Shortlisted',
            value: shortlisted.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.syne(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required Challenge challenge,
  }) {
    final progress = challenge.submissionsCount / challenge.maxParticipants;
    final id = challenge.id;
    final deadlineStr = DateFormat('MMM d').format(challenge.deadline);
    final statusColor = challenge.status == 'live' ? colorScheme.primary : Colors.orange;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChallengeId = id;
        });
        context.read<ChallengeViewModel>().loadSubmissions(id);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _selectedChallengeId == id 
                ? colorScheme.primary 
                : colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: _selectedChallengeId == id ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: GoogleFonts.syne(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    challenge.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Submissions',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${challenge.submissionsCount} / ${challenge.maxParticipants}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(colorScheme, 'Deadline $deadlineStr'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(colorScheme, 'Reward ${challenge.reward}'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(colorScheme, 'UGC Video'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (challenge.shortlistedCreators.isEmpty)
                      Text(
                        'No shortlist yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else ...[
                      ...challenge.shortlistedCreators.take(4).map((id) => Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, size: 16, color: Colors.blue),
                        ),
                      )),
                      if (challenge.shortlistedCreators.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            '+${challenge.shortlistedCreators.length - 4}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedChallengeId = id;
                    });
                    context.read<ChallengeViewModel>().loadSubmissions(id);
                  },
                  child: Text(
                    'Review →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ColorScheme colorScheme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSubmissionFeed(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Consumer<ChallengeViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.currentSubmissions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = viewModel.currentSubmissions;
        final selectedChallenge = viewModel.brandCampaigns.firstWhere(
          (c) => c.id == _selectedChallengeId,
          orElse: () => viewModel.brandCampaigns.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedChallenge.title} — Submission Feed',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${submissions.length} entries · ${selectedChallenge.shortlistedCreators.length} shortlisted · deadline ${DateFormat('MMM d').format(selectedChallenge.deadline)}',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (submissions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No submissions yet.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...submissions.map((submission) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSubmissionCard(
                  context,
                  colorScheme,
                  isDark,
                  submission: submission,
                  challenge: selectedChallenge,
                ),
              )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildSubmissionCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required Submission submission,
    required Challenge challenge,
  }) {
    final isTopPick = submission.status == 'shortlisted' || submission.status == 'winner';
    final brandVm = context.read<BrandViewModel>();
    final challengeVm = context.read<ChallengeViewModel>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopPick 
              ? Colors.amber.withValues(alpha: 0.5) 
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isTopPick ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTopPick)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    submission.status == 'winner' ? '🏆 FINAL WINNER' : 'SHORTLISTED — TOP PICK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  image: submission.thumbnailUrl != null 
                    ? DecorationImage(image: NetworkImage(submission.thumbnailUrl!), fit: BoxFit.cover)
                    : null,
                ),
                child: submission.thumbnailUrl == null ? Icon(
                  Icons.play_circle_outline,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                ) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creator ${submission.creatorId.substring(0, 4)}',
                      style: GoogleFonts.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
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
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          Icons.star,
                          size: 16,
                          color: (submission.rating ?? 0) > index ? Colors.amber.shade600 : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTagChip(colorScheme, submission.status.toUpperCase()),
              if (submission.revisions.isNotEmpty)
                _buildTagChip(colorScheme, '${submission.revisions.length} Revisions'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (challenge.status == 'live' || challenge.status == 'review') ...[
                if (submission.status != 'winner')
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final brandId = brandVm.brands.first.id!;
                      challengeVm.declareWinner(submission.id, challenge.id, brandId);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('🏆 Declare Winner', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => challengeVm.shortlist(submission.id, challenge.id, submission.status != 'shortlisted'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: colorScheme.outlineVariant),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      submission.status == 'shortlisted' ? '✓ Shortlisted' : '+ Shortlist',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.remove_red_eye_outlined, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(ColorScheme colorScheme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildLaunchChallengeTab(BuildContext context, ColorScheme colorScheme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Launch New Challenge',
            style: GoogleFonts.syne(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a brief for creators to submit content',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildFormSection(
            context,
            colorScheme,
            isDark,
            title: 'Challenge Details',
            children: [
              _buildTextField(
                colorScheme,
                label: 'Challenge Title',
                hint: 'e.g., Unboxing Challenge — Build Your Fort',
                controller: _titleController,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                colorScheme,
                label: 'Description',
                hint: 'Describe what you want creators to showcase...',
                maxLines: 4,
                controller: _descriptionController,
              ),
              const SizedBox(height: 16),
              Consumer<BrandViewModel>(
                builder: (context, brandVm, child) {
                  if (brandVm.isLoading && brandVm.brands.isEmpty) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ));
                  }
                  return _buildDropdown(
                    colorScheme,
                    label: 'Brand',
                    hint: 'Select brand',
                    items: brandVm.brands.map((b) => b.name).toList(),
                    value: _selectedBrandId != null && brandVm.brands.any((b) => b.id == _selectedBrandId)
                      ? brandVm.brands.firstWhere((b) => b.id == _selectedBrandId).name 
                      : null,
                    onChanged: (val) {
                      setState(() {
                        final brand = brandVm.brands.firstWhere((b) => b.name == val);
                        _selectedBrandId = brand.id;
                      });
                      context.read<ChallengeViewModel>().loadBrandChallenges(_selectedBrandId!);
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormSection(
            context,
            colorScheme,
            isDark,
            title: 'Content Requirements',
            children: [
              _buildDropdown(
                colorScheme,
                label: 'Video Type',
                hint: 'Select type',
                items: const ['UGC', 'Testimonial', 'Product Demo', 'Unboxing', 'Other'],
                value: _selectedVideoType,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedVideoType = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      colorScheme,
                      label: 'Min Duration (seconds)',
                      hint: '30',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      colorScheme,
                      label: 'Max Duration (seconds)',
                      hint: '60',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                colorScheme,
                label: 'Language',
                hint: 'Select language',
                items: ['Tunisian Darija', 'French', 'English', 'Arabic'],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                colorScheme,
                label: 'Target Audience',
                hint: 'e.g., Parents 25-45',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFormSection(
            context,
            colorScheme,
            isDark,
            title: 'Evaluation Criteria',
            children: [
              Text(
                'Select presets or add your own — these are shown to creators',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ..._criteriaByCategory.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                      color: colorScheme.primary, letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.value.map((criterion) {
                      final isSelected = _selectedCriteria.contains(criterion);
                      return FilterChip(
                        label: Text(criterion, style: const TextStyle(fontSize: 11)),
                        selected: isSelected,
                        selectedColor: colorScheme.primaryContainer,
                        checkmarkColor: colorScheme.primary,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCriteria.add(criterion);
                            } else {
                              _selectedCriteria.remove(criterion);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                ],
              )),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      colorScheme,
                      label: 'Add Custom Criterion',
                      hint: 'e.g. "Mention discount code"',
                      controller: _criteriaController,
                      onSubmitted: (val) {
                        if (val.isNotEmpty && !_selectedCriteria.contains(val)) {
                          setState(() {
                            _selectedCriteria.add(val);
                            _criteriaController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: IconButton.filled(
                      onPressed: () {
                        final val = _criteriaController.text.trim();
                        if (val.isNotEmpty && !_selectedCriteria.contains(val)) {
                          setState(() {
                            _selectedCriteria.add(val);
                            _criteriaController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              if (_selectedCriteria.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selected (${_selectedCriteria.length})',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: colorScheme.primary)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCriteria.map((c) => Chip(
                          label: Text(c, style: const TextStyle(fontSize: 11)),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          backgroundColor: colorScheme.primaryContainer,
                          onDeleted: () => setState(() => _selectedCriteria.remove(c)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _buildFormSection(
            context,
            colorScheme,
            isDark,
            title: 'Campaign Settings',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      colorScheme,
                      label: 'Winner Reward (TND)',
                      hint: '500',
                      keyboardType: TextInputType.number,
                      controller: _rewardController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      colorScheme,
                      label: 'Runner-up Reward (TND)',
                      hint: '150',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      colorScheme,
                      label: 'Max Submissions',
                      hint: '30',
                      keyboardType: TextInputType.number,
                      controller: _maxParticipantsController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDeadlinePicker(context, colorScheme),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Consumer<ChallengeViewModel>(
                  builder: (context, viewModel, child) {
                    return FilledButton(
                      onPressed: viewModel.isLoading ? null : () async {
                        if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in title and description')),
                          );
                          return;
                        }

                        final brandVm = context.read<BrandViewModel>();
                        if (_selectedBrandId == null && brandVm.brands.isEmpty) return;

                        final brandId = _selectedBrandId ?? brandVm.brands.first.id!;

                        try {
                          final challenge = await viewModel.createChallenge({
                            'title': _titleController.text,
                            'description': _descriptionController.text,
                            'winnerReward': double.tryParse(_rewardController.text) ?? 0,
                            'submissionCap': int.tryParse(_maxParticipantsController.text) ?? 30,
                            'deadline': _selectedDeadline?.toIso8601String() ?? DateTime.now().add(const Duration(days: 7)).toIso8601String(),
                            'criteria': _selectedCriteria,
                            'videoType': _selectedVideoType,
                          }, brandId);

                          // For now, let's automatically publish it to make it live
                          await viewModel.publishChallenge(challenge.id, brandId);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Challenge launched successfully!')),
                            );
                            _titleController.clear();
                            _descriptionController.clear();
                            _rewardController.clear();
                            _maxParticipantsController.clear();
                            setState(() {
                              _selectedCriteria.clear();
                              _selectedDeadline = null;
                              _selectedVideoType = 'UGC';
                            });
                            _tabController.animateTo(0);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Launch failed: $e')),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Launch Challenge'),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFormSection(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required String title,
    required List<Widget> children,
  }) {
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
          Text(
            title,
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDeadlinePicker(BuildContext context, ColorScheme colorScheme) {
    final hasDate = _selectedDeadline != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deadline',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: child!,
                ),
              );
              if (date != null) setState(() => _selectedDeadline = date);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasDate ? colorScheme.primary : colorScheme.outlineVariant,
                  width: hasDate ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                    size: 18,
                    color: hasDate ? colorScheme.primary : colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasDate
                          ? DateFormat('MMM d, yyyy').format(_selectedDeadline!)
                          : 'Select date',
                      style: TextStyle(
                        fontSize: 14,
                        color: hasDate ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  if (hasDate)
                    GestureDetector(
                      onTap: () => setState(() => _selectedDeadline = null),
                      child: Icon(Icons.close, size: 16, color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    ColorScheme colorScheme, {
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? suffixIcon,
    TextEditingController? controller,
    Function(String)? onSubmitted,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    ColorScheme colorScheme, {
    required String label,
    required String hint,
    required List<String> items,
    String? value,
    Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
