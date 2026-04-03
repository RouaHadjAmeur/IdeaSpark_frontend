enum CollabRole { admin, editor, viewer }

enum CollabStatus { pending, accepted, rejected }

enum ContentAction { approved, rejected, commented }

class CollabMember {
  final String id;
  final String email;
  final String name;
  final CollabRole role;
  final CollabStatus status;
  final DateTime invitedAt;

  const CollabMember({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.status,
    required this.invitedAt,
  });

  String get roleLabel {
    switch (role) {
      case CollabRole.admin: return 'Admin';
      case CollabRole.editor: return 'Éditeur';
      case CollabRole.viewer: return 'Lecteur';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.name,
    'status': status.name,
    'invitedAt': invitedAt.toIso8601String(),
  };

  factory CollabMember.fromJson(Map<String, dynamic> j) => CollabMember(
    id: j['id'],
    email: j['email'],
    name: j['name'],
    role: CollabRole.values.firstWhere((r) => r.name == j['role']),
    status: CollabStatus.values.firstWhere((s) => s.name == j['status']),
    invitedAt: DateTime.parse(j['invitedAt']),
  );
}

class PostComment {
  final String id;
  final String postId;
  final String planId;
  final String authorName;
  final String authorEmail;
  final String text;
  final ContentAction? action;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.planId,
    required this.authorName,
    required this.authorEmail,
    required this.text,
    this.action,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'postId': postId,
    'planId': planId,
    'authorName': authorName,
    'authorEmail': authorEmail,
    'text': text,
    'action': action?.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PostComment.fromJson(Map<String, dynamic> j) => PostComment(
    id: j['id'],
    postId: j['postId'],
    planId: j['planId'] ?? '',
    authorName: j['authorName'],
    authorEmail: j['authorEmail'],
    text: j['text'],
    action: j['action'] != null
        ? ContentAction.values.firstWhere((a) => a.name == j['action'])
        : null,
    createdAt: DateTime.parse(j['createdAt']),
  );
}

class HistoryEntry {
  final String id;
  final String planId;
  final String authorName;
  final String action;
  final String description;
  final DateTime createdAt;

  const HistoryEntry({
    required this.id,
    required this.planId,
    required this.authorName,
    required this.action,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'authorName': authorName,
    'action': action,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
    id: j['id'],
    planId: j['planId'],
    authorName: j['authorName'],
    action: j['action'],
    description: j['description'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}
