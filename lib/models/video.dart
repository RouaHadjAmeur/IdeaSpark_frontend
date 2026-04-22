class Video {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final int duration; // en secondes
  final int width;
  final int height;
  final String user;
  final String userUrl;
  final String source; // 'pexels'
  final DateTime createdAt;

  Video({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.width,
    required this.height,
    required this.user,
    required this.userUrl,
    required this.source,
    required this.createdAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    // Helper function to convert to int (handles both String and int)
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Video(
      id: json['id']?.toString() ?? '',
      videoUrl: json['videoUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      duration: toInt(json['duration']),
      width: toInt(json['width']),
      height: toInt(json['height']),
      user: json['user'] ?? '',
      userUrl: json['userUrl'] ?? '',
      source: json['source'] ?? 'pexels',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'width': width,
      'height': height,
      'user': user,
      'userUrl': userUrl,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get durationFormatted {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  String get resolution {
    return '${width}x${height}';
  }
}
