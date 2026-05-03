import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/api_config.dart';

class SocialVideoTrendsScreen extends StatefulWidget {
  const SocialVideoTrendsScreen({super.key});

  @override
  State<SocialVideoTrendsScreen> createState() => _SocialVideoTrendsScreenState();
}

class _SocialVideoTrendsScreenState extends State<SocialVideoTrendsScreen> {
  static const _tabs = ['En Tendance', 'Recent', 'Populaire'];
  int _activeTab = 0;
  final _searchController = TextEditingController();
  List<_VideoTrendCardData> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _sortForTab {
    switch (_activeTab) {
      case 1:
        return 'recent';
      case 2:
        return 'popular';
      default:
        return 'trending';
    }
  }

  Future<void> _loadTrends() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final params = <String, String>{
        'sort': _sortForTab,
        'limit': '50',
      };
      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        params['search'] = search;
      }
      final query = params.entries
          .map(
            (e) =>
                '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
          )
          .join('&');
      final url = '${ApiConfig.youtubeTrendsBase}?$query';

      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      final rawItems = decoded is Map<String, dynamic>
          ? (decoded['items'] as List<dynamic>? ?? const [])
          : (decoded as List<dynamic>? ?? const []);

      final items = rawItems
          .whereType<Map<String, dynamic>>()
          .map(_VideoTrendCardData.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _items = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Video & Reseaux Sociaux',
                      style: GoogleFonts.syne(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    'shorts',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _loadTrends(),
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _loadTrends,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final active = index == _activeTab;
                    return Padding(
                      padding:
                          EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 8),
                      child: ChoiceChip(
                        label: Text(_tabs[index]),
                        selected: active,
                        onSelected: (_) {
                          setState(() => _activeTab = index);
                          _loadTrends();
                        },
                        selectedColor: cs.primary,
                        labelStyle: TextStyle(
                          color: active ? cs.onPrimary : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: cs.surfaceContainerHighest,
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              'Could not load videos\n$_error',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : _items.isEmpty
                            ? const Center(child: Text('No videos found'))
                            : RefreshIndicator(
                                onRefresh: _loadTrends,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: _items.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) =>
                                      _SocialTrendCard(item: _items[index]),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialTrendCard extends StatelessWidget {
  const _SocialTrendCard({required this.item});

  final _VideoTrendCardData item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isYoutube = item.platform.toLowerCase() == 'youtube';

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isYoutube
                          ? Icons.play_circle_fill_rounded
                          : Icons.music_note_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.platform,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (item.isRising)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B3D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 10)),
                      SizedBox(width: 3),
                      Text(
                        'Rising',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(item.thumbnail, fit: BoxFit.cover),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _Metric(text: item.viewsText),
                        const SizedBox(width: 10),
                        _Metric(text: item.likesText),
                        const SizedBox(width: 10),
                        _Metric(text: item.commentsText),
                        const Spacer(),
                        Text(
                          item.durationText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(item.creatorAvatar),
                onBackgroundImageError:
                    (Object exception, StackTrace? stackTrace) {},
                radius: 12,
              ),
              const SizedBox(width: 8),
              Text(
                item.creatorHandle,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              const BoxDecoration(color: Color(0xFF36CFC9), shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

class _VideoTrendCardData {
  final String platform;
  final bool isRising;
  final String thumbnail;
  final String title;
  final String viewsText;
  final String likesText;
  final String commentsText;
  final String durationText;
  final String creatorHandle;
  final String creatorAvatar;

  const _VideoTrendCardData({
    required this.platform,
    required this.isRising,
    required this.thumbnail,
    required this.title,
    required this.viewsText,
    required this.likesText,
    required this.commentsText,
    required this.durationText,
    required this.creatorHandle,
    required this.creatorAvatar,
  });

  factory _VideoTrendCardData.fromJson(Map<String, dynamic> json) {
    final channel = (json['channel'] ?? '').toString();
    final thumbnailPreview = (json['thumbnail_preview'] ?? '').toString();
    final thumbnail = (json['thumbnail'] ?? '').toString();
    final views = _toNum(json['views']);
    final likes = _toNum(json['likes']);
    final comments = _toNum(json['comments']);
    final durationSeconds = _toNum(json['duration_seconds']).round();
    final virality = _toNum(json['virality_score']);

    return _VideoTrendCardData(
      platform: (json['platform'] ?? 'YouTube').toString(),
      isRising: virality >= 24,
      thumbnail: thumbnailPreview.isNotEmpty ? thumbnailPreview : thumbnail,
      title: (json['title'] ?? '').toString(),
      viewsText: '${_compact(views)} vues',
      likesText: '${_compact(likes)} J\'aime',
      commentsText: _compact(comments),
      durationText: _mmss(durationSeconds),
      creatorHandle: '@$channel',
      creatorAvatar:
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(channel.isEmpty ? 'YT' : channel)}&background=0D8ABC&color=fff',
    );
  }

  static num _toNum(dynamic v) {
    if (v is num) return v;
    return num.tryParse('$v') ?? 0;
  }

  static String _compact(num value) {
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }

  static String _mmss(int total) {
    final m = total ~/ 60;
    final s = total % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

