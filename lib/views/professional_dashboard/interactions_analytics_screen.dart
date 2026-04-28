import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/instagram_insights_service.dart';
import 'package:intl/intl.dart';
import 'dart:math';

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
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(textColor),
                    const SizedBox(height: 30),
                    _buildCircularChart(),
                    const SizedBox(height: 30),
                    _buildAudienceSplit(),
                    const SizedBox(height: 20),
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
            'Mar 27 - Apr 25', // Hardcoded to match mockup
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

  Widget _buildCircularChart() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: InteractionsDonutChartPainter(
                followersPercent: 69.2, // Mocked split
                nonFollowersPercent: 30.8,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                'Interactions',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                _formatNumber(_details?.totalInteractions ?? 0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceSplit() {
    // We use mocked demographic split (69.2 vs 30.8) as Meta doesn't easily provide demographic interaction split natively
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Followers', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              const Text('69.2%', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF5E35B1), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Text('Non-followers', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              ),
              const Text('30.8%', style: TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildByContentType() {
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
        _buildProgressBarRow('Posts', _details?.postsPercentage ?? 0, const Color(0xFFE91E63)),
        const SizedBox(height: 16),
        _buildProgressBarRow('Reels', _details?.reelsPercentage ?? 0, const Color(0xFFE91E63)),
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
    // For interactions, screenshots show a purple chunk (non-follower) at the end of the bar.
    // We will hardcode a visual split to match the screenshot style.
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
    int likes = _showPosts ? (_details?.postsLikes ?? 0) : (_details?.reelsLikes ?? 0);
    int comments = _showPosts ? (_details?.postsComments ?? 0) : (_details?.reelsComments ?? 0);
    int saves = _showPosts ? (_details?.postsSaves ?? 0) : (_details?.reelsSaves ?? 0);

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
    final list = _showPosts ? (_details?.topPosts ?? []) : (_details?.topReels ?? []);
    final title = _showPosts ? 'Top posts' : 'Top reels';

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
              Text('See all', style: TextStyle(color: const Color(0xFF5A78FF), fontSize: 14, fontWeight: FontWeight.bold)),
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
                                    color: Colors.black.withOpacity(0.7),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Audience', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Icon(Icons.info_outline, color: Colors.grey[400], size: 16),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[800]!)),
                child: const Icon(Icons.people_outline, color: Colors.white),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Audience demographics are not available because fewer than 100 accounts interacted with your content during the selected time period.',
                  style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InteractionsDonutChartPainter extends CustomPainter {
  final double followersPercent;
  final double nonFollowersPercent;

  InteractionsDonutChartPainter({required this.followersPercent, required this.nonFollowersPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 14.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final followerAngle = (followersPercent / 100) * 2 * pi;
    final nonFollowerAngle = (nonFollowersPercent / 100) * 2 * pi;

    final startAngle = -pi / 2;

    final followerPaint = Paint()
      ..color = const Color(0xFFE91E63) // Pinkish red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final nonFollowerPaint = Paint()
      ..color = const Color(0xFF5E35B1) // Deep purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw non-followers
    canvas.drawArc(rect, startAngle + followerAngle, nonFollowerAngle, false, nonFollowerPaint);
    
    // Draw followers
    canvas.drawArc(rect, startAngle, followerAngle, false, followerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
