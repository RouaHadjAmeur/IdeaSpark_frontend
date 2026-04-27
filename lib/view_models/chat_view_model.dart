import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/upload_service.dart';
import '../services/call_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final UploadService _uploadService = UploadService();
  final CallService _callService = CallService();
  final String receiverId;
  
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isTyping = false;
  String? _error;
  StreamSubscription? _callSubscription;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  bool get isTyping => _isTyping;
  String? get error => _error;

  ChatViewModel(this.receiverId) {
    _init();
  }

  void _init() {
    _chatService.connect();
    _loadHistory();
    
    // Listen for new messages
    _chatService.onNewMessage.listen((message) {
      if (message.senderId == receiverId || message.receiverId == receiverId) {
        _messages.insert(0, message);
        notifyListeners();
      }
    });

    // Listen for incoming calls to show traces in real-time
    _callSubscription = _callService.onIncomingCall.listen((data) {
      if (data['callerId'] == receiverId) {
        _addCallTraceLocally(
          type: data['type'] == 'video' ? 'call_video' : 'call_audio',
          senderId: receiverId,
          receiverId: _authService.currentUser?.id ?? '',
        );
      }
    });

    // Listen for typing indicator
    _chatService.onUserTyping.listen((senderId) {
      if (senderId == receiverId) {
        _isTyping = true;
        notifyListeners();
        // Clear typing after 3 seconds of inactivity
        Future.delayed(const Duration(seconds: 3), () {
          _isTyping = false;
          notifyListeners();
        });
      }
    });
  }

  void _addCallTraceLocally({required String type, required String senderId, required String receiverId}) {
    final newMessage = Message(
      id: 'call-${DateTime.now().millisecondsSinceEpoch}',
      content: type == 'call_video' ? 'Appel vidéo' : 'Appel vocal',
      senderId: senderId,
      receiverId: receiverId,
      createdAt: DateTime.now(),
      messageType: type,
    );
    _messages.insert(0, newMessage);
    notifyListeners();
  }

  void addOutgoingCallTrace(bool isVideo) {
    _addCallTraceLocally(
      type: isVideo ? 'call_video' : 'call_audio',
      senderId: _authService.currentUser?.id ?? '',
      receiverId: receiverId,
    );
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final history = await _chatService.getConversationHistory(receiverId);
      _messages = history;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    print('📝 ChatViewModel: sendMessage called with: $content');
    
    _chatService.sendMessage(content, receiverId);
    
    // Optimistic UI update
    final newMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderId: _authService.currentUser?.id ?? '',
      receiverId: receiverId,
      createdAt: DateTime.now(),
    );
    
    _messages.insert(0, newMessage);
    notifyListeners();
  }

  Future<void> sendFile(File file) async {
    print('📂 ChatViewModel: Starting upload for file: ${file.path}');
    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      final fileName = p.basename(file.path);
      final messageType = _uploadService.getFileType(fileName);
      print('📂 ChatViewModel: Detected type: $messageType');
      
      final attachmentUrl = await _uploadService.uploadFile(file, fileName);
      print('📂 ChatViewModel: Upload successful, URL: $attachmentUrl');
      
      final content = messageType == 'voice' ? 'Message vocal' : fileName;

      _chatService.sendMessage(
        content, 
        receiverId, 
        type: messageType, 
        attachmentUrl: attachmentUrl
      );

      // Optimistic UI update
      final newMessage = Message(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        senderId: _authService.currentUser?.id ?? '',
        receiverId: receiverId,
        createdAt: DateTime.now(),
        messageType: messageType,
        attachmentUrl: attachmentUrl,
      );

      _messages.insert(0, newMessage);
      _isUploading = false;
      print('📂 ChatViewModel: Message added to list');
      notifyListeners();
    } catch (e) {
      print('❌ ChatViewModel Error sending file: $e');
      _error = 'Erreur d\'envoi: ${e.toString()}';
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> sendVoiceMessage(String filePath) async {
    await sendFile(File(filePath));
  }

  void sendTyping() {
    _chatService.sendTyping(receiverId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    // We don't want to close the shared ChatService here, 
    // but maybe we want to unsubscribe from specific events
    super.dispose();
  }
}
