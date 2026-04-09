
class Message {
  final String id;
  final String content;
  final String senderId;
  final String receiverId;
  final DateTime createdAt;
  final bool isRead;
  final String messageType;
  final String? attachmentUrl;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
    this.isRead = false,
    this.messageType = 'text',
    this.attachmentUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // The backend might return sender/receiver as full objects or just IDs
    String extractId(dynamic field) {
      if (field is Map) return field['_id'] ?? field['id'] ?? '';
      return field.toString();
    }

    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      content: json['content'] ?? '',
      senderId: extractId(json['sender']),
      receiverId: extractId(json['receiver']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      messageType: json['messageType'] ?? 'text',
      attachmentUrl: json['attachmentUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'receiver': receiverId,
      'messageType': messageType,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
    };
  }
}
