import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import '../core/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool get isConnected => _socket?.connected ?? false;

  /// Initialize and connect to the socket server
  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    debugPrint('Connecting to socket at ${ApiConfig.baseUrl}...');
    
    _socket = io.io(ApiConfig.baseUrl, io.OptionBuilder()
      .setTransports(['websocket']) // Use websocket transport
      .setAuth({'token': token})     // Pass JWT token in handshake
      .enableReconnection()         // Auto reconnect
      .build());

    _socket!.onConnect((_) {
      debugPrint('Socket connected successfully');
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    _socket!.onConnectError((data) {
      debugPrint('Socket connect error: $data');
    });

    _socket!.onError((data) {
      debugPrint('Socket error: $data');
    });

    _socket!.connect();
  }

  /// Listen for new notifications
  void onNotification(Function(Map<String, dynamic>) callback) {
    _socket?.on('notification', (data) {
      debugPrint('New notification received via socket: $data');
      if (data is Map<String, dynamic>) {
        callback(data);
      } else {
        try {
          callback(Map<String, dynamic>.from(data));
        } catch (e) {
          debugPrint('Error parsing socket notification: $e');
        }
      }
    });
  }

  /// Listen for plan update events (phases changed, posts assigned, etc.)
  void onPlanUpdated(Function(String planId) callback) {
    _socket?.on('plan_updated', (data) {
      debugPrint('plan_updated socket event: $data');
      try {
        final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
        final planId = (map['planId'] ?? map['id'] ?? '').toString();
        if (planId.isNotEmpty) callback(planId);
      } catch (e) {
        debugPrint('Error parsing plan_updated event: $e');
      }
    });
  }

  /// Disconnect the socket
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    debugPrint('Socket disposed');
  }

  /// Emit an event (if needed in the future)
  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }

  /// Emit an event to a specific room (e.g. 'user:userId')
  void emitToRoom(String room, String event, dynamic data) {
    _socket?.emit('emit_to_room', {'room': room, 'event': event, 'data': data});
    // Also try direct emit with room targeting
    _socket?.emit(event, {'...': data, 'targetRoom': room});
  }
}
