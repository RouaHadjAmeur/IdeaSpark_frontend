class ProductSection {
  final String nomDuProduit;
  final String probleme;
  final String solution;
  final String cible;
  final String modeleEconomique;
  final String mvp;

  ProductSection({
    required this.nomDuProduit,
    required this.probleme,
    required this.solution,
    required this.cible,
    required this.modeleEconomique,
    required this.mvp,
  });

  factory ProductSection.fromJson(Map<String, dynamic> json) {
    return ProductSection(
      nomDuProduit: json['nomDuProduit'] ?? json['nom_du_produit'] ?? '',
      probleme: json['probleme'] ?? '',
      solution: json['solution'] ?? '',
      cible: json['cible'] ?? '',
      modeleEconomique: json['modeleEconomique'] ?? json['modele_economique'] ?? '',
      mvp: json['mvp'] ?? '',
    );
  }

  ProductSection copyWith({
    String? nomDuProduit,
    String? probleme,
    String? solution,
    String? cible,
    String? modeleEconomique,
    String? mvp,
  }) {
    return ProductSection(
      nomDuProduit: nomDuProduit ?? this.nomDuProduit,
      probleme: probleme ?? this.probleme,
      solution: solution ?? this.solution,
      cible: cible ?? this.cible,
      modeleEconomique: modeleEconomique ?? this.modeleEconomique,
      mvp: mvp ?? this.mvp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomDuProduit': nomDuProduit,
      'probleme': probleme,
      'solution': solution,
      'cible': cible,
      'modeleEconomique': modeleEconomique,
      'mvp': mvp,
    };
  }
}

class ProductIdeaResult {
  final String besoin;
  final ProductSection produit;
  final String rawOutput;
  final double durationSeconds;
  final bool modelLoaded;

  ProductIdeaResult({
    required this.besoin,
    required this.produit,
    required this.rawOutput,
    required this.durationSeconds,
    required this.modelLoaded,
  });

  factory ProductIdeaResult.fromJson(Map<String, dynamic> json) {
    final produitJson = json['produit'] as Map<String, dynamic>? ?? {};
    final durationValue = json['duration_seconds'];

    return ProductIdeaResult(
      besoin: json['besoin']?.toString() ?? '',
      produit: ProductSection.fromJson(produitJson),
      rawOutput: json['raw_output']?.toString() ?? '',
      durationSeconds: durationValue is num ? durationValue.toDouble() : 0.0,
      modelLoaded: json['model_loaded'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'besoin': besoin,
      'produit': produit.toJson(),
      'rawOutput': rawOutput,
      'durationSeconds': durationSeconds,
      'modelLoaded': modelLoaded,
    };
  }
}

class SavedProductIdea {
  final String? id;
  final String besoin;
  final ProductSection produit;
  final String rawOutput;
  final double durationSeconds;
  final bool modelLoaded;
  final bool isFavorite;
  final DateTime? createdAt;

  SavedProductIdea({
    this.id,
    required this.besoin,
    required this.produit,
    required this.rawOutput,
    required this.durationSeconds,
    required this.modelLoaded,
    this.isFavorite = false,
    this.createdAt,
  });

  factory SavedProductIdea.fromJson(Map<String, dynamic> json) {
    final produitJson = json['produit'] as Map<String, dynamic>? ?? {};
    final durationValue = json['durationSeconds'] ?? json['duration_seconds'];
    final createdAtValue = json['createdAt'] ?? json['created_at'];

    return SavedProductIdea(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      besoin: json['besoin']?.toString() ?? '',
      produit: ProductSection.fromJson(produitJson),
      rawOutput: json['rawOutput']?.toString() ?? json['raw_output']?.toString() ?? '',
      durationSeconds: durationValue is num ? durationValue.toDouble() : 0.0,
      modelLoaded: json['modelLoaded'] == true || json['model_loaded'] == true,
      isFavorite: json['isFavorite'] == true || json['is_favorite'] == true,
      createdAt: createdAtValue != null 
          ? DateTime.parse(createdAtValue.toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'besoin': besoin,
      'produit': {
        'nomDuProduit': produit.nomDuProduit,
        'probleme': produit.probleme,
        'solution': produit.solution,
        'cible': produit.cible,
        'modeleEconomique': produit.modeleEconomique,
        'mvp': produit.mvp,
      },
      'rawOutput': rawOutput,
      'durationSeconds': durationSeconds,
      'modelLoaded': modelLoaded,
    };
  }

  SavedProductIdea copyWith({
    String? id,
    String? besoin,
    ProductSection? produit,
    String? rawOutput,
    double? durationSeconds,
    bool? modelLoaded,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return SavedProductIdea(
      id: id ?? this.id,
      besoin: besoin ?? this.besoin,
      produit: produit ?? this.produit,
      rawOutput: rawOutput ?? this.rawOutput,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      modelLoaded: modelLoaded ?? this.modelLoaded,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
