import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/services/call_service.dart';


class CallScreen extends StatefulWidget {
  final String remoteUserId;
  final String remoteUserName;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.remoteUserId,
    required this.remoteUserName,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _callService = CallService();
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  CallStatus _currentStatus = CallStatus.idle;

  @override
  void initState() {
    super.initState();
    _currentStatus = _callService.status;
    
    _callService.onStatusChanged.listen((status) {
      if (mounted) {
        setState(() => _currentStatus = status);
        if (status == CallStatus.active) {
          _startTimer();
        } else if (status == CallStatus.idle) {
          Navigator.of(context).pop();
        }
      }
    });

    if (!widget.isIncoming) {
      _callService.initiateCall(widget.remoteUserId, widget.remoteUserName);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Profile Picture Placeholder
            CircleAvatar(
              radius: 60,
              backgroundColor: colorScheme.primary.withOpacity(0.2),
              child: Text(
                widget.remoteUserName[0].toUpperCase(),
                style: GoogleFonts.syne(fontSize: 48, color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.remoteUserName,
              style: GoogleFonts.syne(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _getStatusText(),
              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.6)),
            ),
            if (_currentStatus == CallStatus.active) ...[
              const SizedBox(height: 16),
              Text(
                _formatDuration(_seconds),
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
            const Spacer(),
            // Action Buttons
            _buildActionButtons(colorScheme),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case CallStatus.calling:
        return 'Appel en cours...';
      case CallStatus.incoming:
        return 'Appel entrant...';
      case CallStatus.active:
        return 'En ligne';
      case CallStatus.idle:
        return 'Appel terminé';
    }
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    if (widget.isIncoming && _currentStatus == CallStatus.incoming) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CallActionButton(
            icon: Icons.call_end,
            color: Colors.red,
            onPressed: () {
              _callService.rejectCall();
              Navigator.of(context).pop();
            },
          ),
          _CallActionButton(
            icon: Icons.call,
            color: Colors.green,
            onPressed: () async {
              try {
                await _callService.acceptCall();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de l\'acceptation : $e')),
                  );
                }
              }
            },
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CallActionButton(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          color: Colors.white.withOpacity(0.2),
          onPressed: () {
            setState(() => _isMuted = !_isMuted);
            // TODO: Implement actual mute logic in CallService
          },
        ),
        _CallActionButton(
          icon: Icons.call_end,
          color: Colors.red,
          onPressed: () {
            _callService.endCall();
            Navigator.of(context).pop();
          },
        ),
        _CallActionButton(
          icon: Icons.volume_up,
          color: Colors.white.withOpacity(0.2),
          onPressed: () {
            // TODO: Implement speaker logic
          },
        ),
      ],
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CallActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
