import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:ideaspark/core/api_config.dart';
import 'package:ideaspark/core/app_theme.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class TrendModel {
  final String topic;
  final String summary;
  final String volume;
  final String geo;
  final String niche;

  TrendModel({
    required this.topic,
    required this.summary,
    required this.volume,
    required this.geo,
    required this.niche,
  });

  factory TrendModel.fromJson(Map<String, dynamic> j) => TrendModel(
        topic: j['topic'] ?? '',
        summary: j['summary'] ?? '',
        volume: j['volume'] ?? 'N/A',
        geo: j['geo'] ?? 'GLOBAL',
        niche: j['niche'] ?? 'general',
      );
}

// ─── Niche chip config ────────────────────────────────────────────────────────

class _Niche {
  final String label;
  final String value; // null value = "All"
  final String emoji;
  const _Niche(this.label, this.value, this.emoji);
}

const _niches = [
  _Niche('All', '', '✨'),
  _Niche('Tech', 'tech', '💻'),
  _Niche('Business', 'business', '💼'),
  _Niche('Politics', 'politics', '🏛️'),
  _Niche('Sports', 'sports', '⚽'),
  _Niche('Health', 'health', '❤️'),
  _Niche('Entertainment', 'entertainment', '🎬'),
  _Niche('Science', 'science', '🔬'),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class TrendsAnalysisScreen extends StatefulWidget {
  const TrendsAnalysisScreen({super.key});

  @override
  State<TrendsAnalysisScreen> createState() => _TrendsAnalysisScreenState();
}

class _TrendsAnalysisScreenState extends State<TrendsAnalysisScreen>
    with SingleTickerProviderStateMixin {
  // Region tabs
  static const _regions = [
    ('Tunisia 🇹🇳', 'TN'),
    ('Global 🌍', 'GLOBAL'),
  ];
  int _regionIndex = 0;

  // Niche filter
  int _nicheIndex = 0; // 0 = All

  List<TrendModel> _trends = [];
  bool _loading = true;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _loadTrends();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTrends() async {
    setState(() { _loading = true; _error = null; });
    _fadeCtrl.reset();
    try {
      final geo = _regions[_regionIndex].$2;
      final niche = _niches[_nicheIndex].value;
      var url = '${ApiConfig.trendsBase}?geo=$geo';
      if (niche.isNotEmpty) url += '&niche=$niche';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _trends = data.map((e) => TrendModel.fromJson(e)).toList();
          _loading = false;
        });
        _fadeCtrl.forward();
      } else {
        setState(() { _error = 'Server error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Sections: first 4 = Rising, next 4 = Popular, rest = Evergreen
  List<TrendModel> get _rising => _trends.take(4).toList();
  List<TrendModel> get _popular => _trends.skip(4).take(4).toList();
  List<TrendModel> get _evergreen => _trends.skip(8).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Current Trends',
                      style: GoogleFonts.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadTrends,
                    icon: const Icon(Icons.refresh_rounded),
                    color: cs.onSurface,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceContainerHighest,
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                ],
              ),
            ),

            // ── Match Banner ─────────────────────────────────────────────────
            if (!_loading && _trends.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.successColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        '${_trends.length} trends match your profile!',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 14),

            // ── Region Tabs ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_regions.length, (i) {
                  final active = _regionIndex == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 0 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () {
                          if (_regionIndex == i) return;
                          setState(() => _regionIndex = i);
                          _loadTrends();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: active
                                ? cs.primary.withValues(alpha: 0.15)
                                : cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active ? cs.primary : cs.outlineVariant,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _regions[i].$1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                                color: active ? cs.primary : cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // ── Niche Filter Chips ────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _niches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = _nicheIndex == i;
                  return GestureDetector(
                    onTap: () {
                      if (_nicheIndex == i) return;
                      setState(() => _nicheIndex = i);
                      _loadTrends();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: active ? cs.primary : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? cs.primary : cs.outlineVariant,
                        ),
                      ),
                      child: Text(
                        '${_niches[i].emoji} ${_niches[i].label}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          color: active ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _loadTrends, cs: cs)
                      : _trends.isEmpty
                          ? _EmptyView(cs: cs)
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: _TrendsList(
                                rising: _rising,
                                popular: _popular,
                                evergreen: _evergreen,
                                cs: cs,
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trends List ─────────────────────────────────────────────────────────────

class _TrendsList extends StatelessWidget {
  final List<TrendModel> rising;
  final List<TrendModel> popular;
  final List<TrendModel> evergreen;
  final ColorScheme cs;

  const _TrendsList({
    required this.rising,
    required this.popular,
    required this.evergreen,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (rising.isNotEmpty) ...[
          _header('🔥 Rising Trends', cs),
          const SizedBox(height: 10),
          ...rising.asMap().entries.map((e) => _TrendCard(
                trend: e.value,
                rank: e.key + 1,
                accent: const Color(0xFF00C896),
                badge: '↗ Rising',
                cs: cs,
              )),
          const SizedBox(height: 20),
        ],
        if (popular.isNotEmpty) ...[
          _header('⭐ Popular Now', cs),
          const SizedBox(height: 10),
          ...popular.asMap().entries.map((e) => _TrendCard(
                trend: e.value,
                rank: e.key + 1,
                accent: const Color(0xFF6C63FF),
                badge: 'Top ${e.key + 1}',
                cs: cs,
              )),
          const SizedBox(height: 20),
        ],
        if (evergreen.isNotEmpty) ...[
          _header('🌿 Evergreen', cs),
          const SizedBox(height: 10),
          ...evergreen.map((t) => _TrendCard(
                trend: t,
                rank: 0,
                accent: const Color(0xFF0EA5E9),
                badge: 'Stable',
                cs: cs,
              )),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  Widget _header(String text, ColorScheme cs) => Text(
        text,
        style: GoogleFonts.syne(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
      );
}

// ─── Trend Card ──────────────────────────────────────────────────────────────

const _nicheEmoji = {
  'tech': '💻',
  'business': '💼',
  'politics': '🏛️',
  'sports': '⚽',
  'health': '❤️',
  'entertainment': '🎬',
  'science': '🔬',
  'mena': '🌍',
  'general': '📰',
};

class _TrendCard extends StatelessWidget {
  final TrendModel trend;
  final int rank;
  final Color accent;
  final String badge;
  final ColorScheme cs;

  const _TrendCard({
    required this.trend,
    required this.rank,
    required this.accent,
    required this.badge,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = _nicheEmoji[trend.niche] ?? '📰';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trend.topic,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.syne(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                    height: 1.3,
                  ),
                ),
                if (trend.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trend.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: accent,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                // Niche chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trend.niche,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── States ───────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ColorScheme cs;
  const _ErrorView({required this.message, required this.onRetry, required this.cs});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text('Could not load trends',
                  style: GoogleFonts.syne(
                      fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(message,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  final ColorScheme cs;
  const _EmptyView({required this.cs});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📭', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No trends yet',
                style: GoogleFonts.syne(
                    fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('Run the n8n workflow to fetch trends',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      );
}
