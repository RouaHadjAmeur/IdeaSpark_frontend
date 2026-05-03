import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/instagram_insights_service.dart';

class ViewsAnalyticsScreen extends StatefulWidget {
  const ViewsAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<ViewsAnalyticsScreen> createState() => _ViewsAnalyticsScreenState();
}

class _ViewsAnalyticsScreenState extends State<ViewsAnalyticsScreen> {
  final InstagramInsightsService _insightsService = InstagramInsightsService();
  InstagramViewsDetails? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _insightsService.fetchViewsDetails();
    if (!mounted) return;
    setState(() {
      _details = details;
      _isLoading = false;
    });
  }

  String _formatNumber(int number) => NumberFormat.decimalPattern().format(number);

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF121212);

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
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
          title: const Text('Views'),
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
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildOverviewSection(),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey[850], thickness: 1),
                        const SizedBox(height: 24),
                        _buildByContentType(),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey[850], thickness: 1),
                        const SizedBox(height: 24),
                        _buildTopContent(),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey[850], thickness: 1),
                        const SizedBox(height: 24),
                        _buildAudienceSection(),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey[850], thickness: 1),
                        const SizedBox(height: 24),
                        _buildProfileActivity(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
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
            child: const Row(
              children: [
                Text(
                  'Last 30 days',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white),
              ],
            ),
          ),
          const Text(
            'Mar 27 - Apr 25',
            style: TextStyle(
              color: Colors.white,
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
          _buildMetricRow('Views', details.totalViews),
          _buildMetricRow('Accounts reached', details.accountsReached),
          _buildMetricRow('Profile visits', details.profileVisits),
          _buildMetricRow('External link taps', details.externalLinkTaps),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(
            _formatNumber(value),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
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
          child: Text(
            'By content type',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
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
        _buildProgressBarRow('Reels', details.reelsPercentage, const Color(0xFF5E35B1)),
        const SizedBox(height: 16),
        _buildProgressBarRow('Posts', details.postsPercentage, const Color(0xFFD32F2F)),
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

  Widget _buildProgressBarRow(String label, double percentage, Color color) {
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
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                    ),
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

  Widget _buildTopContent() {
    final details = _details!;
    if (details.topContent.isEmpty) {
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
              const Text(
                'By top content',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text(
                'See all',
                style: TextStyle(color: Color(0xFF5A78FF), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: details.topContent.length,
            itemBuilder: (context, index) {
              final item = details.topContent[index];
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
                                    _formatNumber(item.views),
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
      return DateFormat('MMM d').format(DateTime.parse(isoString));
    } catch (_) {
      return '';
    }
  }

  Widget _buildAudienceSection() {
    return _buildUnavailableSection('Audience analytics not available now');
  }

  Widget _buildProfileActivity() {
    final details = _details!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile activity',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatNumber(details.profileVisits),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile visits', style: TextStyle(color: Colors.white, fontSize: 15)),
              Text(_formatNumber(details.profileVisits), style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('External link taps', style: TextStyle(color: Colors.white, fontSize: 15)),
              Text(_formatNumber(details.externalLinkTaps), style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailableSection(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(message, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
      ),
    );
  }
}
