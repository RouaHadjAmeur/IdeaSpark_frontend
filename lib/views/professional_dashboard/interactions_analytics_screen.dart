import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/instagram_insights_service.dart';
import 'package:intl/intl.dart';

class InteractionsAnalyticsScreen extends StatefulWidget {
  const InteractionsAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<InteractionsAnalyticsScreen> createState() => _InteractionsAnalyticsScreenState();
}

class _InteractionsAnalyticsScreenState extends State<InteractionsAnalyticsScreen> {
  final InstagramInsightsService _insightsService = InstagramInsightsService();
  InstagramInteractionsDetails? _details;
  bool _isLoading = true;

  // Toggle for 'By interaction' and 'Top content' sections
  bool _showPosts = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _insightsService.fetchInteractionsDetails();
    if (mounted) {
      setState(() {
        _details = details;
        _isLoading = false;
      });
    }
  }

  String _formatNumber(int number) {
    if (number == 0) return '0';
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF121212);
    final textColor = Colors.white;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Interactions'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _details == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Not available now',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(textColor),
                        const SizedBox(height: 24),
                        _buildOverviewSection(),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey[850], thickness: 1),
                        const SizedBox(height: 24),
                        _buildByContentType(),
                        const SizedBox(height: 30),
                        Divider(color: Colors.grey[850], thickness: 1),
                        const SizedBox(height: 20),
                        _buildByInteractionToggle(),
                        const SizedBox(height: 24),
                        _buildInteractionsList(),
                        const SizedBox(height: 30),
                        _buildTopContent(),
                        const SizedBox(height: 30),
                        Divider(color: Colors.grey[850], thickness: 1),
                        const SizedBox(height: 20),
                        _buildAudienceSection(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Text(
                  'Last 30 days',
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
              ],
            ),
          ),
          Text(
            'Mar 27 - Apr 25',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final details = _details!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Interactions', details.totalInteractions),
          _buildMetricRow('Likes', details.likes),
          _buildMetricRow('Comments', details.comments),
          _buildMetricRow('Saves', details.saves),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, int? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(
            value == null ? 'Not available' : _formatNumber(value),
            style: TextStyle(
              color: value == null ? Colors.grey[400] : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildByContentType() {
    final details = _details!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('By content type', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildFilterChip('All', isSelected: true),
              const SizedBox(width: 8),
              _buildFilterChip('Followers', isSelected: false),
              const SizedBox(width: 8),
              _buildFilterChip('Non-followers', isSelected: false),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildProgressBarRow('Posts', details.postsPercentage, const Color(0xFFE91E63)),
        const SizedBox(height: 16),
        _buildProgressBarRow('Reels', details.reelsPercentage, const Color(0xFFE91E63)),
      ],
    );
  }

  Widget _buildFilterChip(String label, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey[800] : Colors.transparent,
        border: Border.all(color: Colors.grey[800]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontSize: 13),
      ),
    );
  }

  Widget _buildProgressBarRow(String label, double percentage, Color mainColor) {
    final visualFollowerSplit = percentage * 0.692;
    final visualNonFollowerSplit = percentage * 0.308;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(3)),
                  child: Row(
                    children: [
                      if (visualFollowerSplit > 0)
                        Expanded(
                          flex: (visualFollowerSplit * 10).toInt(),
                          child: Container(color: mainColor),
                        ),
                      if (visualNonFollowerSplit > 0)
                        Expanded(
                          flex: (visualNonFollowerSplit * 10).toInt(),
                          child: Container(color: const Color(0xFF5E35B1)),
                        ),
                      if (percentage < 100 && percentage > 0)
                        Expanded(
                          flex: ((100 - percentage) * 10).toInt(),
                          child: const SizedBox(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildByInteractionToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('By interaction', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showPosts = true),
                child: _buildFilterChip('Posts', isSelected: _showPosts),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _showPosts = false),
                child: _buildFilterChip('Reels', isSelected: !_showPosts),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionsList() {
    final details = _details!;
    int likes = _showPosts ? details.postsLikes : details.reelsLikes;
    int comments = _showPosts ? details.postsComments : details.reelsComments;
    int saves = _showPosts ? details.postsSaves : details.reelsSaves;

    return Column(
      children: [
        _buildInteractionRow('Likes', likes),
        const SizedBox(height: 24),
        _buildInteractionRow('Comments', comments),
        const SizedBox(height: 24),
        _buildInteractionRow('Saves', saves),
      ],
    );
  }

  Widget _buildInteractionRow(String title, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Text(_formatNumber(value), style: const TextStyle(color: Colors.white, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildTopContent() {
    final details = _details!;
    final list = _showPosts ? details.topPosts : details.topReels;
    final title = _showPosts ? 'Top posts' : 'Top reels';

    if (list.isEmpty) {
      return _buildUnavailableSection('Top content not available now');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Based on likes', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
              const Text('See all', style: TextStyle(color: Color(0xFF5A78FF), fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.thumbnailUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800]),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              right: 8,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatNumber(item.interactions),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(item.timestamp),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d').format(date);
    } catch (_) {
      return '';
    }
  }

  Widget _buildAudienceSection() {
    return _buildUnavailableSection('Audience analytics not available now');
  }

  Widget _buildUnavailableSection(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[300], fontSize: 14),
        ),
      ),
    );
  }
}
