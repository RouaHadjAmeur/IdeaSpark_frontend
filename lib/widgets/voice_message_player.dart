import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;

  const VoiceMessagePlayer({super.key, required this.audioUrl});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final duration = await _player.setUrl(widget.audioUrl);
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }

      _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
    } catch (e) {
      print('❌ Error loading audio: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () {
            if (_isPlaying) {
              _player.pause();
            } else {
              _player.play();
            }
          },
        ),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds / _duration.inMilliseconds
                : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatDuration(_position),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
