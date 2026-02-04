class IdeaModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final double score;
  final bool isFavorite;

  IdeaModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.score,
    this.isFavorite = false,
  });

  IdeaModel copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    double? score,
    bool? isFavorite,
  }) {
    return IdeaModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      score: score ?? this.score,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
