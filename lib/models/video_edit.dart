enum VideoTransition {
  none,
  fade,
  slide,
  zoom,
  dissolve,
  wipe,
}

class VideoTextOverlay {
  final String text;
  final Duration startTime;
  final Duration endTime;
  final double x; // Position X (0-1)
  final double y; // Position Y (0-1)
  final double fontSize;
  final String fontFamily;
  final int color; // Color as int
  final bool bold;
  final bool italic;
  final double rotation; // Rotation en degrés
  final int? backgroundColor; // Couleur de fond optionnelle

  VideoTextOverlay({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.x,
    required this.y,
    this.fontSize = 24.0,
    this.fontFamily = 'Arial',
    this.color = 0xFFFFFFFF, // Blanc par défaut
    this.bold = false,
    this.italic = false,
    this.rotation = 0.0,
    this.backgroundColor,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'startTime': startTime.inMilliseconds,
        'endTime': endTime.inMilliseconds,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'color': color,
        'bold': bold,
        'italic': italic,
        'rotation': rotation,
        'backgroundColor': backgroundColor,
      };

  factory VideoTextOverlay.fromJson(Map<String, dynamic> json) => VideoTextOverlay(
        text: json['text'] as String,
        startTime: Duration(milliseconds: json['startTime'] as int),
        endTime: Duration(milliseconds: json['endTime'] as int),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
        fontFamily: json['fontFamily'] as String? ?? 'Arial',
        color: json['color'] as int? ?? 0xFFFFFFFF,
        bold: json['bold'] as bool? ?? false,
        italic: json['italic'] as bool? ?? false,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        backgroundColor: json['backgroundColor'] as int?,
      );
}

class VideoSubtitle {
  final String text;
  final Duration startTime;
  final Duration endTime;
  final double fontSize;
  final int color;
  final int? backgroundColor;
  final String position; // 'bottom', 'top', 'center'

  VideoSubtitle({
    required this.text,
    required this.startTime,
    required this.endTime,
    this.fontSize = 18.0,
    this.color = 0xFFFFFFFF, // Blanc par défaut
    this.backgroundColor = 0x80000000, // Noir semi-transparent
    this.position = 'bottom',
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'startTime': startTime.inMilliseconds,
        'endTime': endTime.inMilliseconds,
        'fontSize': fontSize,
        'color': color,
        'backgroundColor': backgroundColor,
        'position': position,
      };

  factory VideoSubtitle.fromJson(Map<String, dynamic> json) => VideoSubtitle(
        text: json['text'] as String,
        startTime: Duration(milliseconds: json['startTime'] as int),
        endTime: Duration(milliseconds: json['endTime'] as int),
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
        color: json['color'] as int? ?? 0xFFFFFFFF,
        backgroundColor: json['backgroundColor'] as int?,
        position: json['position'] as String? ?? 'bottom',
      );
}

class VideoTransitionEffect {
  final VideoTransition type;
  final Duration duration;
  final Duration position; // Position dans la vidéo où appliquer la transition

  VideoTransitionEffect({
    required this.type,
    required this.duration,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'duration': duration.inMilliseconds,
        'position': position.inMilliseconds,
      };

  factory VideoTransitionEffect.fromJson(Map<String, dynamic> json) => VideoTransitionEffect(
        type: VideoTransition.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => VideoTransition.none,
        ),
        duration: Duration(milliseconds: json['duration'] as int),
        position: Duration(milliseconds: json['position'] as int),
      );
}

class VideoMusic {
  final String name;
  final String path; // Chemin local ou URL
  final Duration startTime; // Quand commencer la musique dans la vidéo
  final Duration? fadeInDuration; // Durée du fade in
  final Duration? fadeOutDuration; // Durée du fade out
  final double volume; // Volume (0.0 - 1.0)

  VideoMusic({
    required this.name,
    required this.path,
    this.startTime = Duration.zero,
    this.fadeInDuration,
    this.fadeOutDuration,
    this.volume = 0.5,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'path': path,
        'startTime': startTime.inMilliseconds,
        'fadeInDuration': fadeInDuration?.inMilliseconds,
        'fadeOutDuration': fadeOutDuration?.inMilliseconds,
        'volume': volume,
      };

  factory VideoMusic.fromJson(Map<String, dynamic> json) => VideoMusic(
        name: json['name'] as String,
        path: json['path'] as String,
        startTime: Duration(milliseconds: json['startTime'] as int? ?? 0),
        fadeInDuration: json['fadeInDuration'] != null
            ? Duration(milliseconds: json['fadeInDuration'] as int)
            : null,
        fadeOutDuration: json['fadeOutDuration'] != null
            ? Duration(milliseconds: json['fadeOutDuration'] as int)
            : null,
        volume: (json['volume'] as num?)?.toDouble() ?? 0.5,
      );
}

class VideoEdit {
  final String id;
  final String originalVideoPath;
  final String? editedVideoPath; // Chemin de la vidéo éditée
  final List<VideoTextOverlay> textOverlays;
  final Duration? trimStart;
  final Duration? trimEnd;
  final List<VideoSubtitle> subtitles;
  final List<VideoTransitionEffect> transitions;
  final VideoMusic? music;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VideoEdit({
    required this.id,
    required this.originalVideoPath,
    this.editedVideoPath,
    this.textOverlays = const [],
    this.trimStart,
    this.trimEnd,
    this.subtitles = const [],
    this.transitions = const [],
    this.music,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalVideoPath': originalVideoPath,
        'editedVideoPath': editedVideoPath,
        'textOverlays': textOverlays.map((e) => e.toJson()).toList(),
        'trimStart': trimStart?.inMilliseconds,
        'trimEnd': trimEnd?.inMilliseconds,
        'subtitles': subtitles.map((e) => e.toJson()).toList(),
        'transitions': transitions.map((e) => e.toJson()).toList(),
        'music': music?.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory VideoEdit.fromJson(Map<String, dynamic> json) => VideoEdit(
        id: json['id'] as String,
        originalVideoPath: json['originalVideoPath'] as String,
        editedVideoPath: json['editedVideoPath'] as String?,
        textOverlays: (json['textOverlays'] as List?)
                ?.map((e) => VideoTextOverlay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        trimStart: json['trimStart'] != null
            ? Duration(milliseconds: json['trimStart'] as int)
            : null,
        trimEnd: json['trimEnd'] != null
            ? Duration(milliseconds: json['trimEnd'] as int)
            : null,
        subtitles: (json['subtitles'] as List?)
                ?.map((e) => VideoSubtitle.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        transitions: (json['transitions'] as List?)
                ?.map((e) => VideoTransitionEffect.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        music: json['music'] != null
            ? VideoMusic.fromJson(json['music'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  VideoEdit copyWith({
    String? id,
    String? originalVideoPath,
    String? editedVideoPath,
    List<VideoTextOverlay>? textOverlays,
    Duration? trimStart,
    Duration? trimEnd,
    List<VideoSubtitle>? subtitles,
    List<VideoTransitionEffect>? transitions,
    VideoMusic? music,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      VideoEdit(
        id: id ?? this.id,
        originalVideoPath: originalVideoPath ?? this.originalVideoPath,
        editedVideoPath: editedVideoPath ?? this.editedVideoPath,
        textOverlays: textOverlays ?? this.textOverlays,
        trimStart: trimStart ?? this.trimStart,
        trimEnd: trimEnd ?? this.trimEnd,
        subtitles: subtitles ?? this.subtitles,
        transitions: transitions ?? this.transitions,
        music: music ?? this.music,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

// Musiques prédéfinies disponibles
class PredefinedMusic {
  static const List<Map<String, String>> tracks = [
    {
      'name': 'Upbeat Corporate',
      'path': 'assets/music/upbeat_corporate.mp3',
      'duration': '2:30',
      'genre': 'Corporate',
    },
    {
      'name': 'Chill Vibes',
      'path': 'assets/music/chill_vibes.mp3',
      'duration': '3:15',
      'genre': 'Chill',
    },
    {
      'name': 'Energetic Pop',
      'path': 'assets/music/energetic_pop.mp3',
      'duration': '2:45',
      'genre': 'Pop',
    },
    {
      'name': 'Acoustic Guitar',
      'path': 'assets/music/acoustic_guitar.mp3',
      'duration': '3:00',
      'genre': 'Acoustic',
    },
    {
      'name': 'Electronic Beat',
      'path': 'assets/music/electronic_beat.mp3',
      'duration': '2:20',
      'genre': 'Electronic',
    },
  ];
}