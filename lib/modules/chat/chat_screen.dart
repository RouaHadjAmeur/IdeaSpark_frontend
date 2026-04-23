import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/message.dart';
import '../../view_models/chat_view_model.dart';
import '../../services/auth_service.dart';
import '../../services/call_service.dart';
import '../../services/voice_recorder_service.dart';
import '../../widgets/voice_message_player.dart';
import 'call_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final VoiceRecorderService _recorderService = VoiceRecorderService();

  Future<void> _pickFile(BuildContext context) async {
    debugPrint('📂 ChatScreen: Opening file picker...');
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any, // Permet de choisir n'importe quel fichier
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        debugPrint('📂 ChatScreen: File picked: $path');
        
        if (!mounted) return;
        final file = File(path);
        
        // Appel au ViewModel
        await context.read<ChatViewModel>().sendFile(file);
      } else {
        debugPrint('📂 ChatScreen: No file selected or path is null');
      }
    } catch (e) {
      debugPrint('❌ ChatScreen: Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection du fichier: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    await _recorderService.startRecording();
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
  }

  Future<void> _stopRecording(BuildContext context) async {
    _recordingTimer?.cancel();
    final filePath = await _recorderService.stopRecording();
    setState(() {
      _isRecording = false;
    });
    if (filePath != null) {
      if (!mounted) return;
      context.read<ChatViewModel>().sendVoiceMessage(filePath);
    }
  }

  String _formatRecordingDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatViewModel(widget.receiverId),
      child: Builder(
        builder: (context) {
          // Listen for errors to show SnackBars
          final vm = context.watch<ChatViewModel>();
          if (vm.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(vm.error!), backgroundColor: Colors.red),
                );
                vm.clearError();
              }
            });
          }

          return Scaffold(
            appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.receiverName),
              Consumer<ChatViewModel>(
                builder: (context, vm, _) {
                  if (vm.isTyping) {
                    return const Text(
                      'En train d\'écrire...',
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          actions: [
            IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              context.read<ChatViewModel>().addOutgoingCallTrace(true);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    remoteUserId: widget.receiverId,
                    remoteUserName: widget.receiverName,
                    isIncoming: false,
                    isVideoButton: true,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              context.read<ChatViewModel>().addOutgoingCallTrace(false);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    remoteUserId: widget.receiverId,
                    remoteUserName: widget.receiverName,
                    isIncoming: false,
                  ),
                ),
              );
            },
          ),
          ],
        ),
            body: Column(
              children: [
                Expanded(
                  child: Consumer<ChatViewModel>(
                    builder: (context, vm, _) {
                      if (vm.isLoading && vm.messages.isEmpty) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (vm.error != null && vm.messages.isEmpty) {
                        return Center(child: Text('Erreur: ${vm.error}'));
                      }

                      if (vm.messages.isEmpty) {
                        return const Center(child: Text('Aucun message. Commencez la discussion !'));
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: vm.messages.length,
                        itemBuilder: (context, index) {
                          final message = vm.messages[index];
                          final isMe = message.senderId == AuthService().currentUser?.id;
                          return _buildMessageBubble(message, isMe);
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMessageContent(message, isMe),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: (isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant).withOpacity(0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isMe) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isMe ? colorScheme.onPrimary : colorScheme.onSurface;

    switch (message.messageType) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                if (message.attachmentUrl != null) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
                      body: Center(child: Image.network(message.attachmentUrl!)),
                    ),
                  ));
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: message.attachmentUrl != null
                    ? Image.network(
                        message.attachmentUrl!,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      )
                    : const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            if (message.content.isNotEmpty && message.content != message.attachmentUrl)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(message.content, style: TextStyle(color: textColor, fontSize: 15)),
              ),
          ],
        );
      case 'voice':
        return message.attachmentUrl != null
            ? VoiceMessagePlayer(audioUrl: message.attachmentUrl!)
            : const Text('Message vocal indisponible');
      case 'call_audio':
      case 'call_video':
        final isVideo = message.messageType == 'call_video';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam_outlined : Icons.call_outlined,
              color: textColor.withOpacity(0.7),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isVideo ? 'Appel vidéo' : 'Appel vocal',
              style: TextStyle(color: textColor, fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        );
      case 'file':
        final fileName = message.attachmentUrl?.split('/').last ?? 'Fichier';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: textColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(color: textColor, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(Icons.download, color: textColor),
              onPressed: () async {
                if (message.attachmentUrl != null) {
                  final url = Uri.parse(message.attachmentUrl!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                }
              },
            ),
          ],
        );
      case 'text':
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            height: 1.3,
          ),
        );
    }
  }

  Widget _buildMessageInput(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<ChatViewModel>(
              builder: (context, vm, _) {
                if (vm.isUploading) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: LinearProgressIndicator(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Row(
              children: [
                if (_messageController.text.isEmpty && !_isRecording) ...[
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => _pickFile(context),
                  ),
                  GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(context),
                    child: const IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: null, // Long press only
                    ),
                  ),
                ],
                if (_isRecording) ...[
                  const Icon(Icons.fiber_manual_record, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(_formatRecordingDuration(_recordingSeconds)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    onPressed: () => _stopRecording(context),
                  ),
                ] else
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: (val) {
                        setState(() {}); // For showing/hiding icons
                        context.read<ChatViewModel>().sendTyping();
                      },
                      decoration: InputDecoration(
                        hintText: 'Écrivez un message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                const SizedBox(width: 8),
                if (_messageController.text.isNotEmpty)
                  CircleAvatar(
                    backgroundColor: colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final text = _messageController.text;
                        if (text.trim().isNotEmpty) {
                          context.read<ChatViewModel>().sendMessage(text);
                          _messageController.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
