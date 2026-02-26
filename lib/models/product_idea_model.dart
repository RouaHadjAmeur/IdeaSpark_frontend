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
      nomDuProduit: json['nom_du_produit']?.toString() ?? '',
      probleme: json['probleme']?.toString() ?? '',
      solution: json['solution']?.toString() ?? '',
      cible: json['cible']?.toString() ?? '',
      modeleEconomique: json['modele_economique']?.toString() ?? '',
      mvp: json['mvp']?.toString() ?? '',
    );
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
}
