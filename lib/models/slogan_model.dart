class SloganModel {
  final String id;
  final String slogan;
  final String explanation;
  final double memorabilityScore;
  final String category;
  final bool isFavorite;
  final DateTime createdAt;

  SloganModel({
    required this.id,
    required this.slogan,
    required this.explanation,
    required this.memorabilityScore,
    required this.category,
    this.isFavorite = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SloganModel.fromJson(Map<String, dynamic> json) {
    return SloganModel(
      id: json['id'] ?? json['_id'] ?? '',
      slogan: json['slogan'] ?? '',
      explanation: json['explanation'] ?? '',
      memorabilityScore: (json['memorabilityScore'] ?? 0).toDouble(),
      category: json['category'] ?? 'Général',
      isFavorite: json['isFavorite'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slogan': slogan,
      'explanation': explanation,
      'memorabilityScore': memorabilityScore,
      'category': category,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  SloganModel copyWith({
    String? id,
    String? slogan,
    String? explanation,
    double? memorabilityScore,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return SloganModel(
      id: id ?? this.id,
      slogan: slogan ?? this.slogan,
      explanation: explanation ?? this.explanation,
      memorabilityScore: memorabilityScore ?? this.memorabilityScore,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
