import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/instagram_insights_service.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionalDashboardScreen> createState() => _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState extends State<ProfessionalDashboardScreen> {
  final InstagramInsightsService _insightsService = InstagramInsightsService();
  InstagramInsights? _insights;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final insights = await _insightsService.fetchInsights();
    if (mounted) {
      setState(() {
        _insights = insights;
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

  String _formatMetricValue(int? value) {
    if (value == null) return 'Not available';
    return _formatNumber(value);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000000) : const Color(0xFF121212);
    final textColor = Colors.white;
    final textSecondary = Colors.grey[400]!;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          title: const Text('Professional dashboard'),
          actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {})],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Insights', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Last 30 Days', style: TextStyle(color: textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInsightRow('Views', _insights?.views, onTap: () => context.push('/professional-dashboard/views')),
                    _buildInsightRow('Interactions', _insights?.interactions, onTap: () => context.push('/professional-dashboard/interactions')),
                    _buildInsightRow('New followers', _insights?.newFollowers, onTap: () => context.push('/professional-dashboard/followers')),
                    _buildInsightRow('Content you shared', _insights?.contentShared),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[850], thickness: 1, height: 1),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your tools', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                          const Text('See all', style: TextStyle(color: Color(0xFF5A78FF), fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildToolRow(icon: Icons.history, title: 'Monthly recap'),
                    _buildToolRow(icon: Icons.school_outlined, title: 'Best practices'),
                    _buildToolRow(icon: Icons.lightbulb_outline, title: 'Inspiration', isNew: true),
                    _buildToolRow(icon: Icons.trending_up, title: 'Ad tools'),
                    _buildToolRow(icon: Icons.badge_outlined, title: 'Branded content'),
                    _buildToolRow(icon: Icons.send_outlined, title: 'Saved replies', subtitle: 'Save replies to common questions'),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[850], thickness: 1, height: 1),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Tips and resources', style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => context.push('/professional-dashboard/trending-audio'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        child: Row(
                          children: [
                            const Icon(Icons.show_chart, color: Colors.white, size: 26),
                            const SizedBox(width: 16),
                            const Expanded(child: Text('Trending audio', style: TextStyle(color: Colors.white, fontSize: 16))),
                            Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        child: Row(
                          children: [
                            const Icon(Icons.help_outline, color: Colors.white, size: 26),
                            const SizedBox(width: 16),
                            const Expanded(child: Text('Other helpful resources', style: TextStyle(color: Colors.white, fontSize: 16))),
                            Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInsightRow(String title, int? value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            Row(
              children: [
                Text(
                  _formatMetricValue(value),
                  style: TextStyle(color: value == null ? Colors.grey[400] : Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolRow({required IconData icon, required String title, String? subtitle, bool isNew = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ],
              ),
            ),
            if (isNew) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF5A78FF), borderRadius: BorderRadius.circular(12)),
                child: const Text('New', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
            ],
            Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }
}
