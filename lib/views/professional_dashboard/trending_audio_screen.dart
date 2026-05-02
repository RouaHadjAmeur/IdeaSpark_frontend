import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/instagram_insights_service.dart';

class TrendingAudioScreen extends StatefulWidget {
  const TrendingAudioScreen({super.key});

  @override
  State<TrendingAudioScreen> createState() => _TrendingAudioScreenState();
}

class _TrendingAudioScreenState extends State<TrendingAudioScreen> {
  final InstagramInsightsService _insightsService = InstagramInsightsService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<TrendingAudioItem> _audioItems = [];
  bool _isLoading = true;
  bool _showHeaderBanner = true;
  int? _playingIndex;
  int? _loadingIndex;
  String? _activePreviewUrl;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingIndex = null;
          _loadingIndex = null;
        });
      }
    });
    _loadDetails();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final items = await _insightsService.fetchTrendingAudio();
    if (!mounted) return;
    setState(() {
      _audioItems = items;
      _isLoading = false;
    });
  }

  Future<void> _togglePreview(TrendingAudioItem item, int index) async {
    final previewUrl = item.previewUrl;
    if (previewUrl == null || previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No 30s preview available for this track.')),
      );
      return;
    }

    final isSameTrack = _playingIndex == index && _activePreviewUrl == previewUrl;

    try {
      if (isSameTrack) {
        if (_audioPlayer.playing) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
        if (!mounted) return;
        setState(() {
          _loadingIndex = null;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _loadingIndex = index;
          _playingIndex = index;
        });
      }

      await _audioPlayer.setUrl(previewUrl);
      await _audioPlayer.play();

      if (!mounted) return;
      setState(() {
        _activePreviewUrl = previewUrl;
        _loadingIndex = null;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _loadingIndex = null;
        _playingIndex = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio plugin not loaded yet. Stop app and run again (not hot restart).'),
        ),
      );
    } on PlayerException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingIndex = null;
        _playingIndex = null;
      });
      debugPrint('PlayerException code=${e.code} message=${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preview stream failed to load.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingIndex = null;
        _playingIndex = null;
      });
      debugPrint('Preview playback error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to play this preview right now.')),
      );
    }
  }

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
          title: const Text('Trending audio'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  if (_showHeaderBanner) ...[
                    _buildHeaderBanner(),
                    const SizedBox(height: 16),
                  ],
                  Expanded(
                    child: ListView.builder(
                      itemCount: _audioItems.length,
                      itemBuilder: (context, index) => _buildAudioListItem(_audioItems[index], index),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      color: Colors.grey[900]?.withValues(alpha: 0.5),
      child: Row(
        children: [
          _buildGradientReelsIcon(),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Looking for inspiration for your next reel? Here's what people are talking about today.",
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: () {
              setState(() {
                _showHeaderBanner = false;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientReelsIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFEDA75),
                  Color(0xFFFA7E1E),
                  Color(0xFFD62976),
                  Color(0xFF962FBF),
                  Color(0xFF4F5BD5),
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              shape: BoxShape.circle,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ).createShader(bounds),
            child: const Icon(Icons.slow_motion_video, color: Colors.white, size: 28),
          ),
          Positioned(top: 0, right: 0, child: Icon(Icons.star, color: Colors.yellow[600], size: 12)),
          Positioned(bottom: 0, left: 0, child: Icon(Icons.star, color: Colors.yellow[600], size: 10)),
        ],
      ),
    );
  }

  Widget _buildAudioListItem(TrendingAudioItem item, int index) {
    final isLoadingThisRow = _loadingIndex == index;
    final isPlayingThisRow = _playingIndex == index && _audioPlayer.playing;
    final hasPreview = (item.previewUrl ?? '').isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item.rank}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (item.direction == 'up')
                  const Icon(Icons.keyboard_arrow_up, color: Colors.green, size: 20)
                else if (item.direction == 'down')
                  const Icon(Icons.keyboard_arrow_down, color: Colors.red, size: 20)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A78FF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'New',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _togglePreview(item, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800]),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: hasPreview ? 0.30 : 0.55),
                    ),
                    Center(
                      child: isLoadingThisRow
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              hasPreview
                                  ? (isPlayingThisRow ? Icons.pause : Icons.play_arrow)
                                  : Icons.block,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ],
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
                  item.title,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.call_made, color: Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item.artist}${item.reelsCount.isNotEmpty ? ' · ${item.reelsCount}' : ''}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
