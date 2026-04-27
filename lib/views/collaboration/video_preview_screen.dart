import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoPath;
  final String challengeTitle;

  const VideoPreviewScreen({
    super.key,
    required this.videoPath,
    required this.challengeTitle,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video
          GestureDetector(
            onTap: _toggleControls,
            child: Center(
              child: _initialized
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // Controls overlay
          AnimatedOpacity(
            opacity: _controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Column(
                children: [
                  // Top bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Preview',
                                  style: GoogleFonts.syne(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  widget.challengeTitle,
                                  style: GoogleFonts.syne(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Bottom controls
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Column(
                      children: [
                        // Scrubber
                        if (_initialized)
                          Row(
                            children: [
                              Text(
                                _formatDuration(_controller.value.position),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.cyanAccent,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.cyanAccent,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    trackHeight: 2,
                                    overlayShape: SliderComponentShape.noOverlay,
                                  ),
                                  child: Slider(
                                    value: _controller.value.position.inMilliseconds.toDouble().clamp(
                                          0,
                                          _controller.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                                        ),
                                    max: _controller.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                                    onChanged: (v) => _controller.seekTo(Duration(milliseconds: v.toInt())),
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(_controller.value.duration),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),

                        // Play/pause row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Rewind 10s
                            IconButton(
                              icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                              onPressed: () {
                                final pos = _controller.value.position - const Duration(seconds: 10);
                                _controller.seekTo(pos < Duration.zero ? Duration.zero : pos);
                              },
                            ),
                            const SizedBox(width: 16),
                            // Play/Pause
                            GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.cyanAccent.withOpacity(0.15),
                                  border: Border.all(color: Colors.cyanAccent, width: 2),
                                ),
                                child: Icon(
                                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.cyanAccent,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Forward 10s
                            IconButton(
                              icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                              onPressed: () {
                                final pos = _controller.value.position + const Duration(seconds: 10);
                                final dur = _controller.value.duration;
                                _controller.seekTo(pos > dur ? dur : pos);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Confirm / re-pick bar
                  SafeArea(
                    top: false,
                    child: Container(
                      color: Colors.black87,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          // Re-pick button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context, false),
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Change'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Confirm submit
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed: () => Navigator.pop(context, true),
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: Text(
                                'Confirm Submission',
                                style: GoogleFonts.syne(fontWeight: FontWeight.w700),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
