import 'dart:typed_data';

enum ImageFilter {
  none,
  blackAndWhite,
  sepia,
  vintage,
  cool,
  warm,
  bright,
  dark,
}

enum ImageFrame {
  none,
  simple,
  rounded,
  shadow,
  polaroid,
  film,
}

enum ImageEffect {
  none,
  blur,
  shadow,
  glow,
  emboss,
  sharpen,
}

class TextOverlay {
  final String text;
  final double x; // Position X (0-1)
  final double y; // Position Y (0-1)
  final double fontSize;
  final String fontFamily;
  final int color; // Color as int
  final bool bold;
  final bool italic;
  final double rotation; // Rotation en degrés

  TextOverlay({
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 24.0,
    this.fontFamily = 'Arial',
    this.color = 0xFF000000, // Noir par défaut
    this.bold = false,
    this.italic = false,
    this.rotation = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'x': x,
        'y': y,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'color': color,
        'bold': bold,
        'italic': italic,
        'rotation': rotation,
      };

  factory TextOverlay.fromJson(Map<String, dynamic> json) => TextOverlay(
        text: json['text'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24.0,
        fontFamily: json['fontFamily'] as String? ?? 'Arial',
        color: json['color'] as int? ?? 0xFF000000,
        bold: json['bold'] as bool? ?? false,
        italic: json['italic'] as bool? ?? false,
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      );
}

class EditedImage {
  final String id;
  final String originalUrl;
  final String? editedUrl; // URL de l'image éditée sauvegardée
  final Uint8List? editedData; // Données de l'image éditée en mémoire
  final ImageFilter filter;
  final ImageFrame frame;
  final int? frameColor; // Couleur du cadre
  final List<TextOverlay> textOverlays;
  final int? resizedWidth;
  final int? resizedHeight;
  final List<ImageEffect> effects;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EditedImage({
    required this.id,
    required this.originalUrl,
    this.editedUrl,
    this.editedData,
    this.filter = ImageFilter.none,
    this.frame = ImageFrame.none,
    this.frameColor,
    this.textOverlays = const [],
    this.resizedWidth,
    this.resizedHeight,
    this.effects = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalUrl': originalUrl,
        'editedUrl': editedUrl,
        'filter': filter.name,
        'frame': frame.name,
        'frameColor': frameColor,
        'textOverlays': textOverlays.map((e) => e.toJson()).toList(),
        'resizedWidth': resizedWidth,
        'resizedHeight': resizedHeight,
        'effects': effects.map((e) => e.name).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory EditedImage.fromJson(Map<String, dynamic> json) => EditedImage(
        id: json['id'] as String,
        originalUrl: json['originalUrl'] as String,
        editedUrl: json['editedUrl'] as String?,
        filter: ImageFilter.values.firstWhere(
          (e) => e.name == json['filter'],
          orElse: () => ImageFilter.none,
        ),
        frame: ImageFrame.values.firstWhere(
          (e) => e.name == json['frame'],
          orElse: () => ImageFrame.none,
        ),
        frameColor: json['frameColor'] as int?,
        textOverlays: (json['textOverlays'] as List?)
                ?.map((e) => TextOverlay.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        resizedWidth: json['resizedWidth'] as int?,
        resizedHeight: json['resizedHeight'] as int?,
        effects: (json['effects'] as List?)
                ?.map((e) => ImageEffect.values.firstWhere(
                      (effect) => effect.name == e,
                      orElse: () => ImageEffect.none,
                    ))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
      );

  EditedImage copyWith({
    String? id,
    String? originalUrl,
    String? editedUrl,
    Uint8List? editedData,
    ImageFilter? filter,
    ImageFrame? frame,
    int? frameColor,
    List<TextOverlay>? textOverlays,
    int? resizedWidth,
    int? resizedHeight,
    List<ImageEffect>? effects,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      EditedImage(
        id: id ?? this.id,
        originalUrl: originalUrl ?? this.originalUrl,
        editedUrl: editedUrl ?? this.editedUrl,
        editedData: editedData ?? this.editedData,
        filter: filter ?? this.filter,
        frame: frame ?? this.frame,
        frameColor: frameColor ?? this.frameColor,
        textOverlays: textOverlays ?? this.textOverlays,
        resizedWidth: resizedWidth ?? this.resizedWidth,
        resizedHeight: resizedHeight ?? this.resizedHeight,
        effects: effects ?? this.effects,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

// Tailles prédéfinies pour les réseaux sociaux
class SocialMediaSizes {
  static const Map<String, Map<String, int>> sizes = {
    'Instagram': {
      'Post (1:1)': 1080, // 1080x1080
      'Story (9:16)': 1080, // 1080x1920
      'Reel (9:16)': 1080, // 1080x1920
    },
    'TikTok': {
      'Video (9:16)': 1080, // 1080x1920
    },
    'Facebook': {
      'Post (1.91:1)': 1200, // 1200x628
      'Story (9:16)': 1080, // 1080x1920
    },
    'Twitter': {
      'Post (16:9)': 1200, // 1200x675
      'Header (3:1)': 1500, // 1500x500
    },
    'LinkedIn': {
      'Post (1.91:1)': 1200, // 1200x628
      'Article (1.91:1)': 1200, // 1200x628
    },
    'YouTube': {
      'Thumbnail (16:9)': 1280, // 1280x720
      'Banner (16:9)': 2560, // 2560x1440
    },
  };

  static Map<String, int> getSizeForPlatform(String platform, String type) {
    final platformSizes = sizes[platform];
    if (platformSizes == null) return {'width': 1080, 'height': 1080};

    final width = platformSizes[type] ?? 1080;
    
    // Calculer la hauteur basée sur le ratio
    int height;
    if (type.contains('1:1')) {
      height = width;
    } else if (type.contains('9:16')) {
      height = (width * 16 / 9).round();
    } else if (type.contains('16:9')) {
      height = (width * 9 / 16).round();
    } else if (type.contains('1.91:1')) {
      height = (width / 1.91).round();
    } else if (type.contains('3:1')) {
      height = (width / 3).round();
    } else {
      height = width; // Carré par défaut
    }

    return {'width': width, 'height': height};
  }
}