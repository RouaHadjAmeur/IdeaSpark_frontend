import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/instagram_insights_service.dart';
import 'dart:math';

class FollowersAnalyticsScreen extends StatefulWidget {
  const FollowersAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<FollowersAnalyticsScreen> createState() => _FollowersAnalyticsScreenState();
}

class _FollowersAnalyticsScreenState extends State<FollowersAnalyticsScreen> {
  final InstagramInsightsService _insightsService = InstagramInsightsService();
  InstagramFollowersDetails? _details;
  bool _isLoading = true;

  // For Active Times toggle
  bool _showHours = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _insightsService.fetchFollowersDetails();
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
          title: const Text('Followers'),
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
                ? const Center(child: Text("Error fetching data", style: TextStyle(color: Colors.white)))
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(textColor),
                        if (_details!.hasDemographics) ...[
                          const SizedBox(height: 24),
                          _buildAgeSection(),
                          const SizedBox(height: 30),
                          Divider(color: Colors.grey[850], thickness: 1),
                          const SizedBox(height: 30),
                          _buildGenderSection(),
                          const SizedBox(height: 30),
                          Divider(color: Colors.grey[850], thickness: 1),
                          const SizedBox(height: 30),
                          _buildActiveTimesSection(),
                          const SizedBox(height: 50),
                        ] else ...[
                          _buildEmptyState(),
                        ],
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
            'Mar 27 - Apr 25', // Hardcoded to match mockup styling
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

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Center(
          child: Text(
            _formatNumber(_details?.totalFollowers ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            (_details?.totalFollowers ?? 0) == 1 ? 'Follower' : 'Followers',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: Colors.grey[850], thickness: 1),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            "You can learn more about who's following you when you have at least 100 followers.",
            textAlign: TextAlign.left,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // For age ranges, we will just show them as linear bars
        ...(_details?.ageRanges ?? []).map((range) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildProgressBarRow(range.label, range.value, const Color(0xFFE91E63)),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildProgressBarRow(String label, double percentage, Color mainColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text('${percentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(3)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(color: mainColor, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSection() {
    double womenPct = 0;
    double menPct = 0;
    for (var item in _details?.genderSplit ?? []) {
      if (item.label.toLowerCase() == 'women') womenPct = item.value;
      if (item.label.toLowerCase() == 'men') menPct = item.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Gender', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${womenPct.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Text('Women', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 4),
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: GenderDonutChartPainter(
                  womenPercent: womenPct,
                  menPercent: menPct,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${menPct.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF5E35B1), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Men', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveTimesSection() {
    // Determine max value for bar scaling
    double maxVal = 1;
    for (var time in _details?.activeTimes ?? []) {
      if (time.value > maxVal) maxVal = time.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Most active times', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildDayCircle('Su'),
              _buildDayCircle('M'),
              _buildDayCircle('Tu'),
              _buildDayCircle('W'),
              _buildDayCircle('Th'),
              _buildDayCircle('F'),
              _buildDayCircle('Sa'),
            ],
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          height: 150,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: (_details?.activeTimes ?? []).map((time) {
                final heightFactor = time.value / maxVal;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 32,
                      height: 120 * heightFactor,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF06292), // Bright pink
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(time.label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCircle(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }
}

class GenderDonutChartPainter extends CustomPainter {
  final double womenPercent;
  final double menPercent;

  GenderDonutChartPainter({required this.womenPercent, required this.menPercent});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = Colors.grey[900]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    final womenAngle = (womenPercent / 100) * 2 * pi;
    final menAngle = (menPercent / 100) * 2 * pi;

    final startAngle = -pi / 2;

    final womenPaint = Paint()
      ..color = const Color(0xFFE91E63) // Pinkish red
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final menPaint = Paint()
      ..color = const Color(0xFF5E35B1) // Deep purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw men
    canvas.drawArc(rect, startAngle + womenAngle, menAngle, false, menPaint);
    
    // Draw women
    canvas.drawArc(rect, startAngle, womenAngle, false, womenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
