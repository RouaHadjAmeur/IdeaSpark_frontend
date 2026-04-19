import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ideaspark/services/call_service.dart';


class CallScreen extends StatefulWidget {
  final String remoteUserId;
  final String remoteUserName;
  final bool isIncoming;
  final bool isVideoButton;

  const CallScreen({
    super.key,
    required this.remoteUserId,
    required this.remoteUserName,
    this.isIncoming = false,
    this.isVideoButton = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _callService = CallService();
  Timer? _timer;
  int _seconds = 0;
  bool _isMuted = false;
  bool _isCameraOff = false;
  CallStatus _currentStatus = CallStatus.idle;
  
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

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
          print('📞 CallScreen: Call ended/rejected, closing screen');
          // Use a flag to avoid double pop if possible, or just check mounted
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            Navigator.of(context).pop();
          }
        }
      }
    });

    _callService.onLocalStream.listen((stream) {
      if (mounted) {
        if (stream == null) {
          _localRenderer.srcObject = null;
        } else if (widget.isVideoButton || _callService.type == CallType.video) {
          _localRenderer.srcObject = stream;
        }
        setState(() {});
      }
    });

    _callService.onRemoteStream.listen((stream) {
      if (mounted) {
        if (stream == null) {
          _remoteRenderer.srcObject = null;
        } else if (widget.isVideoButton || _callService.type == CallType.video) {
          _remoteRenderer.srcObject = stream;
        }
        setState(() {});
      }
    });

    _initAndStart();
  }

  Future<void> _initAndStart() async {
    if (widget.isVideoButton || _callService.type == CallType.video) {
      await _initRenderers();
    }

    if (!widget.isIncoming) {
      await _callService.initiateCall(
        widget.remoteUserId, 
        widget.remoteUserName,
        type: widget.isVideoButton ? CallType.video : CallType.audio,
      );
    }
  }

  Future<void> _initRenderers() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      print('✅ CallScreen: Renderers initialized');
    } catch (e) {
      print('❌ CallScreen: Error initializing renderers: $e');
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
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video views or Profile Info
            _buildMainContent(colorScheme),
            
            // Remote Info (Overlays when active and video)
            if (_currentStatus == CallStatus.active && (widget.isVideoButton || _callService.type == CallType.video))
              Positioned(
                top: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.remoteUserName,
                      style: GoogleFonts.syne(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _formatDuration(_seconds),
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

            // Action Buttons at bottom
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: _buildActionButtons(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme) {
    bool isVideo = widget.isVideoButton || _callService.type == CallType.video;

    if (_currentStatus == CallStatus.active && isVideo) {
      return Stack(
        children: [
          // Remote Video (Full Screen)
          RTCVideoView(
            _remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          // Local Video (Small Overlay)
          Positioned(
            right: 20,
            top: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Default Profile View (Calling, Incoming, or Audio Call)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
        ],
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
              print('📞 CallScreen: Rejecting call...');
              _callService.rejectCall();
              // Status listener will handle the pop, but we can do it here too
              if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
                Navigator.of(context).pop();
              }
            },
          ),
          _CallActionButton(
            icon: Icons.call,
            color: Colors.green,
            onPressed: () async {
              print('📞 CallScreen: Accepting call button pressed (Type: ${ _callService.type})...');
              try {
                // S'assurer que les renderers sont prêts UNIQUEMENT si c'est un appel vidéo
                if (widget.isVideoButton || _callService.type == CallType.video) {
                  print('📞 CallScreen: Video call detected, initializing renderers...');
                  await _initRenderers();
                } else {
                  print('📞 CallScreen: Audio call detected, skipping video renderers init.');
                }
                
                print('📞 CallScreen: Calling CallService.acceptCall()...');
                await _callService.acceptCall(
                  remoteUserId: widget.remoteUserId,
                  remoteUserName: widget.remoteUserName,
                );
                print('✅ CallScreen: CallService.acceptCall() completed successfully.');
              } catch (e, stack) {
                print('❌ CallScreen: Exception in accept button: $e');
                print(stack);
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
            _callService.setMute(_isMuted);
          },
        ),
        if (widget.isVideoButton || _callService.type == CallType.video)
          _CallActionButton(
            icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
            color: Colors.white.withOpacity(0.2),
            onPressed: () {
              setState(() => _isCameraOff = !_isCameraOff);
              _callService.setCamera(!_isCameraOff);
            },
          ),
        _CallActionButton(
          icon: Icons.call_end,
          color: Colors.red,
          onPressed: () {
            print('📞 CallScreen: Ending call...');
            _callService.endCall();
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
              Navigator.of(context).pop();
            }
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
