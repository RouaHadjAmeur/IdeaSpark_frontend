import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_theme.dart';
import '../../models/challenge.dart';
import '../../models/submission.dart';
import '../../view_models/challenge_view_model.dart';

class SubmissionReviewScreen extends StatefulWidget {
  final Submission submission;
  final Challenge challenge;

  const SubmissionReviewScreen({
    super.key,
    required this.submission,
    required this.challenge,
  });

  @override
  State<SubmissionReviewScreen> createState() => _SubmissionReviewScreenState();
}

class _SubmissionReviewScreenState extends State<SubmissionReviewScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _controlsVisible = true;
  int _hoverStar = 0;
  late int _currentRating;
  late String _currentStatus;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.submission.rating ?? 0;
    _currentStatus = widget.submission.status;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.submission.videoUrl))
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _rate(int stars) async {
    setState(() { _actionBusy = true; _currentRating = stars; });
    final vm = context.read<ChallengeViewModel>();
    await vm.rateSubmission(widget.submission.id, widget.challenge.id, stars);
    if (mounted) setState(() => _actionBusy = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rated $stars star${stars > 1 ? 's' : ''} — creator notified'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  Future<void> _shortlist() async {
    final vm = context.read<ChallengeViewModel>();
    final isShortlisted = _currentStatus == 'shortlisted';
    setState(() => _actionBusy = true);
    await vm.shortlist(widget.submission.id, widget.challenge.id, !isShortlisted);
    if (mounted) {
      setState(() {
        _currentStatus = isShortlisted ? 'pending' : 'shortlisted';
        _actionBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isShortlisted ? 'Removed from shortlist' : 'Shortlisted — creator notified'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _requestRevision() async {
    final ctrl = TextEditingController();
    final feedback = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Request Revision', style: GoogleFonts.syne(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Describe what needs to be changed...',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1A2139),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text('Send', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
    if (feedback == null || feedback.isEmpty || !mounted) return;
    setState(() => _actionBusy = true);
    final vm = context.read<ChallengeViewModel>();
    await vm.requestRevision(widget.submission.id, widget.challenge.id, feedback);
    if (mounted) {
      setState(() { _currentStatus = 'revision_requested'; _actionBusy = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revision requested — creator notified'), backgroundColor: AppColors.secondary),
      );
    }
  }

  Future<void> _declareWinner() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151B2D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Declare Winner', style: GoogleFonts.syne(color: AppColors.accent, fontWeight: FontWeight.bold)),
        content: Text(
          'Declare this submission as the winner of "${widget.challenge.title}"?\n\nThis closes the challenge and notifies all participants.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('🏆 Declare Winner', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actionBusy = true);
    final vm = context.read<ChallengeViewModel>();
    await vm.declareWinner(widget.submission.id, widget.challenge.id, '');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🏆 Winner declared! Creator notified.'), backgroundColor: AppColors.accent),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isShortlisted = _currentStatus == 'shortlisted';
    final isRevision = _currentStatus == 'revision_requested';
    final isWinner = _currentStatus == 'winner';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ── VIDEO ──────────────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _controlsVisible = !_controlsVisible),
                  child: Center(
                    child: _initialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : const CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                // Controls overlay
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.challenge.title,
                                        style: GoogleFonts.syne(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Submitted ${DateFormat('MMM d, yyyy').format(widget.submission.createdAt)}',
                                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildStatusBadge(_currentStatus),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Playback controls
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Column(
                            children: [
                              if (_initialized)
                                Row(
                                  children: [
                                    Text(_formatDuration(_controller.value.position),
                                        style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: AppColors.primary,
                                          inactiveTrackColor: Colors.white24,
                                          thumbColor: AppColors.primary,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                          trackHeight: 2,
                                          overlayShape: SliderComponentShape.noOverlay,
                                        ),
                                        child: Slider(
                                          value: _controller.value.position.inMilliseconds.toDouble().clamp(
                                              0, _controller.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity)),
                                          max: _controller.value.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                                          onChanged: (v) => _controller.seekTo(Duration(milliseconds: v.toInt())),
                                        ),
                                      ),
                                    ),
                                    Text(_formatDuration(_controller.value.duration),
                                        style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                  ],
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.replay_10, color: Colors.white, size: 26),
                                    onPressed: () {
                                      final p = _controller.value.position - const Duration(seconds: 10);
                                      _controller.seekTo(p < Duration.zero ? Duration.zero : p);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _controller.value.isPlaying ? _controller.pause() : _controller.play(),
                                    child: Container(
                                      width: 52, height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        border: Border.all(color: AppColors.primary, width: 2),
                                      ),
                                      child: Icon(
                                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: AppColors.primary, size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.forward_10, color: Colors.white, size: 26),
                                    onPressed: () {
                                      final p = _controller.value.position + const Duration(seconds: 10);
                                      final d = _controller.value.duration;
                                      _controller.seekTo(p > d ? d : p);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── REVIEW PANEL ───────────────────────────────────────────────────
          Container(
            color: const Color(0xFF0A0E1A),
            child: Column(
              children: [
                // Gradient divider
                Container(
                  height: 2,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Creator info row
                        Row(
                          children: [
                            Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [AppColors.primary, AppColors.secondary],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  widget.submission.creatorId.substring(0, 2).toUpperCase(),
                                  style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Creator #${widget.submission.creatorId.substring(0, 8)}',
                                    style: GoogleFonts.syne(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy · HH:mm').format(widget.submission.createdAt),
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.submission.challengeReward.isNotEmpty)
                              Text(
                                '🏆 ${widget.submission.challengeReward}',
                                style: GoogleFonts.spaceMono(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Star rating
                        Row(
                          children: [
                            Text('RATE', style: GoogleFonts.spaceMono(
                              fontSize: 10, fontWeight: FontWeight.bold,
                              color: Colors.white38, letterSpacing: 1.2,
                            )),
                            const SizedBox(width: 12),
                            ...List.generate(5, (i) {
                              final star = i + 1;
                              final filled = star <= (_hoverStar > 0 ? _hoverStar : _currentRating);
                              return GestureDetector(
                                onTap: _actionBusy ? null : () => _rate(star),
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => _hoverStar = star),
                                  onExit: (_) => setState(() => _hoverStar = 0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Icon(
                                      filled ? Icons.star : Icons.star_border,
                                      color: filled ? AppColors.accent : Colors.white24,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (_currentRating > 0) ...[
                              const SizedBox(width: 8),
                              Text('$_currentRating/5', style: GoogleFonts.spaceMono(
                                fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.bold,
                              )),
                            ],
                          ],
                        ),

                        if (widget.submission.feedback != null && widget.submission.feedback!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.feedback_outlined, size: 13, color: AppColors.secondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '"${widget.submission.feedback}"',
                                    style: const TextStyle(color: Colors.white60, fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Action buttons
                        if (isWinner)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('🏆', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text('Winner — Challenge Closed', style: GoogleFonts.syne(
                                  color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold,
                                )),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: _ReviewAction(
                                  label: isShortlisted ? 'UNLISTED' : 'SHORTLIST',
                                  icon: isShortlisted ? Icons.star : Icons.star_border,
                                  color: AppColors.success,
                                  busy: _actionBusy,
                                  active: isShortlisted,
                                  onTap: _shortlist,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ReviewAction(
                                  label: isRevision ? 'REQUESTED' : 'REVISION',
                                  icon: Icons.refresh,
                                  color: AppColors.secondary,
                                  busy: _actionBusy || isRevision,
                                  active: isRevision,
                                  onTap: isRevision ? () {} : _requestRevision,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ReviewAction(
                                  label: 'WINNER',
                                  icon: Icons.emoji_events,
                                  color: AppColors.accent,
                                  busy: _actionBusy,
                                  active: false,
                                  onTap: _declareWinner,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'shortlisted': color = AppColors.success; label = 'SHORTLISTED'; break;
      case 'winner': color = AppColors.accent; label = 'WINNER'; break;
      case 'revision_requested': color = AppColors.secondary; label = 'REVISION'; break;
      default: color = AppColors.primary; label = 'UNDER REVIEW';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: GoogleFonts.spaceMono(fontSize: 8, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.8)),
    );
  }
}

class _ReviewAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool busy;
  final bool active;
  final VoidCallback onTap;

  const _ReviewAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.busy,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = busy;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active || disabled ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: disabled ? Colors.white12 : color.withValues(alpha: active ? 0.6 : 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: disabled ? Colors.white24 : color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.spaceMono(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: disabled ? Colors.white24 : color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
