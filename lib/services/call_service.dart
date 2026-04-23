import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/api_config.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

enum CallStatus { idle, calling, incoming, active }

enum CallType { audio, video }

class CallService {
  CallService._();
  static final CallService _instance = CallService._();
  factory CallService() => _instance;

  final _authService = AuthService();
  io.Socket? _socket;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Call state
  String? _remoteUserId;
  String? _remoteUserName;
  CallStatus _status = CallStatus.idle;
  CallType _type = CallType.audio;
  Map<String, dynamic>? _pendingOffer;
  Completer<void>? _offerCompleter;
  final List<RTCIceCandidate> _pendingIceCandidates = [];
  
  // Controllers
  final _statusController = StreamController<CallStatus>.broadcast();
  Stream<CallStatus> get onStatusChanged => _statusController.stream;

  final _incomingCallController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onIncomingCall => _incomingCallController.stream;

  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get onRemoteStream => _remoteStreamController.stream;

  final _localStreamController = StreamController<MediaStream?>.broadcast();
  Stream<MediaStream?> get onLocalStream => _localStreamController.stream;

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _peerConnection?.getRemoteStreams().isNotEmpty ?? false 
      ? _peerConnection!.getRemoteStreams()[0] : null;

  CallStatus get status => _status;
  CallType get type => _type;
  String? get remoteUserName => _remoteUserName;

  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('ℹ️ CallService: Already connected');
      return;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      debugPrint('❌ CallService: Cannot connect, userId is null or empty. Retrying in 2s...');
      Future.delayed(const Duration(seconds: 2), () => connect());
      return;
    }

    debugPrint('🔌 CallService: Connecting for userId: $userId to ${ApiConfig.baseUrl}/call');

    _socket = io.io(
      '${ApiConfig.baseUrl}/call',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId})
          .enableAutoConnect()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✅ CallService: Connected to Call WebSocket');
    });

    _socket!.onConnectError((data) {
      debugPrint('❌ CallService: Connection Error: $data');
    });

    _socket!.on('incomingCall', (data) {
      debugPrint('📞 CallService: RECEIVED incomingCall event from server: $data');
      _remoteUserId = data['callerId'];
      _remoteUserName = data['callerName'];
      _type = data['type'] == 'video' ? CallType.video : CallType.audio;
      _status = CallStatus.incoming;
      _statusController.add(_status);
      _incomingCallController.add({
        'callerId': _remoteUserId!, 
        'callerName': _remoteUserName!,
        'type': data['type'] ?? 'audio'
      });
      
      // Initialize completer for the offer that should follow
      _offerCompleter = Completer<void>();
      
      // Jouer la sonnerie
      _playRingtone();
    });

    _socket!.on('offer', (data) async {
      debugPrint('📞 CallService: Received WebRTC OFFER from server');
      _pendingOffer = data['sdp'];
      _remoteUserId = data['callerId'];
      
      // Complete the completer if it exists
      if (_offerCompleter != null && !_offerCompleter!.isCompleted) {
        debugPrint('✅ CallService: Offer received, notifying waiter...');
        _offerCompleter!.complete();
      }
    });

    _socket!.on('answer', (data) async {
      debugPrint('📞 CallService: Received WebRTC ANSWER from $_remoteUserId');
      final sdp = data['sdp'];
      await _handleAnswer(sdp);
    });

    _socket!.on('ice-candidate', (data) async {
      final candidateMap = data['candidate'];
      debugPrint('📞 CallService: Received ICE CANDIDATE from $_remoteUserId');
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );

      if (_peerConnection != null) {
        await _peerConnection!.addCandidate(candidate);
      } else {
        _pendingIceCandidates.add(candidate);
      }
    });

    _socket!.on('callEnded', (_) {
      _stopRingtone();
      _cleanUp();
    });

    _socket!.on('callRejected', (_) {
      _stopRingtone();
      _cleanUp();
    });
  }

  Future<void> initiateCall(String receiverId, String receiverName, {CallType type = CallType.audio}) async {
    debugPrint('📞 CallService: initiateCall to $receiverName ($receiverId) type: $type');
    
    try {
      _type = type;
      // Check permissions
      if (_type == CallType.video) {
        final camStatus = await Permission.camera.request();
        if (camStatus != PermissionStatus.granted) {
          debugPrint('❌ CallService: Camera permission denied');
          return;
        }
      }
      
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        debugPrint('❌ CallService: Microphone permission denied');
        return;
      }

      _remoteUserId = receiverId;
      _remoteUserName = receiverName;
      _status = CallStatus.calling;
      _statusController.add(_status);

      // Notify signaling server
      _socket!.emit('initCall', {
        'callerId': _authService.currentUser?.id,
        'callerName': _authService.currentUser?.displayName,
        'receiverId': receiverId,
        'type': _type == CallType.video ? 'video' : 'audio',
      });

      // Create PeerConnection and Local Stream
      await _createPeerConnection();

      // Create Offer
      debugPrint('📞 CallService: Creating WebRTC offer...');
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Send Offer
      debugPrint('🚀 CallService: Emitting offer to $receiverId');
      _socket!.emit('offer', {
        'sdp': offer.toMap(),
        'receiverId': receiverId,
      });
    } catch (e, stack) {
      debugPrint('❌ CallService: Error in initiateCall: $e');
      debugPrint(stack.toString());
      _cleanUp();
    }
  }

  Future<void> acceptCall({String? remoteUserId, String? remoteUserName}) async {
    debugPrint('📞 CallService: acceptCall() START');
    debugPrint('📞 CallService: Current state - _remoteUserId: $_remoteUserId, status: $_status');
    _stopRingtone();
    
    try {
      // Use provided ID if internal state is missing (fallback)
      if (_remoteUserId == null && remoteUserId != null) {
        debugPrint('⚠️ CallService: _remoteUserId was null, using provided fallback: $remoteUserId');
        _remoteUserId = remoteUserId;
        _remoteUserName = remoteUserName;
      }

      if (_remoteUserId == null) {
        throw Exception('Impossible d\'accepter l\'appel : remoteUserId manquant');
      }

      // If offer hasn't arrived yet, wait for it (max 5 seconds)
      if (_pendingOffer == null) {
        debugPrint('⏳ CallService: Offer not yet arrived, waiting up to 5s...');
        if (_offerCompleter != null) {
          await _offerCompleter!.future.timeout(const Duration(seconds: 5));
        }
      }

      if (_pendingOffer == null) {
        throw Exception('Délai d\'attente de l\'offre expiré (Signalisation trop lente)');
      }

      // 1. Ensure permissions
      debugPrint('📞 CallService: Checking permissions for type: $_type');
      if (_type == CallType.video) {
        final camStatus = await Permission.camera.request();
        if (camStatus != PermissionStatus.granted) {
          throw Exception('Permission Caméra refusée');
        }
      }

      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        throw Exception('Permission Microphone refusée');
      }

      debugPrint('📞 CallService: Permissions OK, updating status to ACTIVE');
      _status = CallStatus.active;
      _statusController.add(_status);

      // 2. Create PeerConnection and Local Stream
      debugPrint('📞 CallService: Creating PeerConnection...');
      await _createPeerConnection();

      // Ensure local stream is shared with UI
      if (_localStream != null) {
        debugPrint('📞 CallService: Local stream available, sending to UI');
        _localStreamController.add(_localStream!);
      }

      // 3. Set Remote Description (the offer)
      debugPrint('📞 CallService: Setting remote description (OFFER)...');
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(_pendingOffer!['sdp'], _pendingOffer!['type']),
      );

      // 4. Add any ICE candidates that arrived early
      if (_pendingIceCandidates.isNotEmpty) {
        debugPrint('📞 CallService: Adding ${ _pendingIceCandidates.length} pending ICE candidates');
        for (var candidate in _pendingIceCandidates) {
          await _peerConnection!.addCandidate(candidate);
        }
        _pendingIceCandidates.clear();
      }

      // 5. Create and set Local Description (the answer)
      debugPrint('📞 CallService: Creating WebRTC ANSWER...');
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      // 6. Send answer to the caller via signaling server
      debugPrint('🚀 CallService: Emitting ANSWER to server for caller: $_remoteUserId');
      _socket!.emit('answer', {
        'sdp': answer.toMap(),
        'callerId': _remoteUserId,
      });
      
      _pendingOffer = null;
      debugPrint('✅ CallService: acceptCall() COMPLETED successfully');
    } catch (e, stack) {
      debugPrint('❌ CallService: CRITICAL Error in acceptCall: $e');
      debugPrint(stack.toString());
      _cleanUp();
      rethrow;
    }
  }

  void rejectCall() {
    _stopRingtone();
    if (_remoteUserId != null) {
      _socket!.emit('rejectCall', {'callerId': _remoteUserId});
    }
    _cleanUp();
  }

  void endCall() {
    if (_remoteUserId != null) {
      _socket!.emit('endCall', {'receiverId': _remoteUserId});
    }
    _cleanUp();
  }

  void setMute(bool mute) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !mute;
    });
  }

  void setCamera(bool enabled) {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = enabled;
    });
  }

  Future<void> _createPeerConnection() async {
    if (_peerConnection != null) return;
    
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        _socket!.emit('ice-candidate', {
          'candidate': candidate.toMap(),
          'receiverId': _remoteUserId,
        });
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        debugPrint('📞 CallService: Received remote stream');
        _remoteStreamController.add(event.streams[0]);
      }
    };

    debugPrint('📞 CallService: Accessing media (Audio: true, Video: ${ _type == CallType.video})...');
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': _type == CallType.video,
      };
      
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      debugPrint('✅ CallService: Media access granted. Tracks: ${ _localStream!.getTracks().length}');
      _localStreamController.add(_localStream!);
    } catch (e) {
      debugPrint('❌ CallService: Failed to get user media: $e');
      // If video fails, try audio only as fallback?
      if (_type == CallType.video) {
        debugPrint('⚠️ CallService: Trying audio-only fallback...');
        _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
        _localStreamController.add(_localStream!);
      } else {
        rethrow;
      }
    }

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
    debugPrint('📞 CallService: Local tracks added to PeerConnection');
  }

  Future<void> _handleAnswer(Map<String, dynamic> sdp) async {
    if (_peerConnection != null) {
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp['sdp'], sdp['type']),
      );
      _status = CallStatus.active;
      _statusController.add(_status);
    }
  }

  void _playRingtone() {
    try {
      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.play(AssetSource('soundCall.mp3'));
      debugPrint('🎵 CallService: Ringtone started');
    } catch (e) {
      debugPrint('❌ CallService: Error playing ringtone: $e');
    }
  }

  void _stopRingtone() {
    try {
      _audioPlayer.stop();
      debugPrint('🎵 CallService: Ringtone stopped');
    } catch (e) {
      debugPrint('❌ CallService: Error stopping ringtone: $e');
    }
  }

  void _cleanUp() {
    debugPrint('🧹 CallService: Cleaning up resources...');
    _localStream?.getTracks().forEach((track) {
      track.stop();
      debugPrint('🧹 CallService: Stopped track: ${track.kind}');
    });
    _localStream?.dispose();
    _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _remoteUserId = null;
    _remoteUserName = null;
    _status = CallStatus.idle;
    _type = CallType.audio; // Reset type to default
    _statusController.add(_status);
    _pendingOffer = null;
    _offerCompleter = null;
    _pendingIceCandidates.clear();
    
    // Clear streams
    _localStreamController.add(null); 
    _remoteStreamController.add(null);
  }
}
