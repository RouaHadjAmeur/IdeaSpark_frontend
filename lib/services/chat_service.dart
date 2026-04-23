import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/api_config.dart';
import '../models/message.dart';
import 'auth_service.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  ChatService._();
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;

  final _authService = AuthService();
  io.Socket? _socket;
  
  // Streams for real-time updates
  final _messageController = StreamController<Message>.broadcast();
  Stream<Message> get onNewMessage => _messageController.stream;

  final _typingController = StreamController<String>.broadcast();
  Stream<String> get onUserTyping => _typingController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (_socket != null && _socket!.connected) return;

    final userId = _authService.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      debugPrint('❌ ChatService: Cannot connect, userId is null or empty');
      return;
    }

    debugPrint('🔌 ChatService: Connecting for userId: $userId');

    // The backend uses namespace '/chat'
    final socketUrl = '${ApiConfig.baseUrl}/chat';
    
    _socket = io.io(
      socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': userId})
          .enableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✅ Connected to Chat WebSocket');
    });

    _socket!.onConnectError((data) {
      debugPrint('❌ Chat WebSocket Connect Error: $data');
    });

    _socket!.onError((data) {
      debugPrint('❌ Chat WebSocket Error: $data');
    });

    _socket!.onDisconnect((_) {
      debugPrint('ℹ️ Disconnected from Chat WebSocket');
    });

    _socket!.on('newMessage', (data) {
      final message = Message.fromJson(data);
      _messageController.add(message);
    });

    _socket!.on('userTyping', (data) {
      if (data is Map && data.containsKey('senderId')) {
        _typingController.add(data['senderId']);
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void sendMessage(String content, String receiverId, {String type = 'text', String? attachmentUrl}) {
    debugPrint('📤 Attempting to send message: $content to $receiverId');
    
    if (_socket == null || !_socket!.connected) {
      debugPrint('⚠️ Socket not connected, connecting now...');
      connect();
      
      // Wait for connection then send
      _socket!.once('connect', (_) {
        debugPrint('✅ Connected late, sending message now');
        _emitMessage(content, receiverId, type, attachmentUrl);
      });
      return;
    }

    _emitMessage(content, receiverId, type, attachmentUrl);
  }

  void _emitMessage(String content, String receiverId, String type, String? attachmentUrl) {
    final payload = {
      'content': content,
      'receiver': receiverId,
      'messageType': type,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    };

    debugPrint('🚀 Emitting sendMessage event with payload: $payload');
    _socket!.emit('sendMessage', payload);
  }

  void sendTyping(String receiverId) {
    _socket?.emit('typing', {
      'receiverId': receiverId,
      'senderId': _authService.currentUser?.id,
    });
  }

  Future<List<Message>> getConversationHistory(String receiverId, {int page = 1, int limit = 20}) async {
    final token = _authService.accessToken;
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/messages/conversation/$receiverId?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> messagesJson = data['messages'];
      return messagesJson.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load conversation history');
    }
  }

  void dispose() {
    _messageController.close();
    _typingController.close();
    disconnect();
  }
}
