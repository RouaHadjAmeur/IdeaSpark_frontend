import 'package:flutter/foundation.dart';

/// Generator type for home grid.
class GeneratorItem {
  const GeneratorItem({
    required this.icon,
    required this.title,
    required this.typeId,
  });
  final String icon;
  final String title;
  final String typeId;
}

/// ViewModel for Home screen.
class HomeViewModel extends ChangeNotifier {
  static final List<GeneratorItem> generators = const [
    GeneratorItem(icon: '💼', title: 'Business Ideas', typeId: 'business'),
    GeneratorItem(icon: '🎥', title: 'Video Ideas', typeId: 'video'),
    GeneratorItem(icon: '🛍️', title: 'Product Ideas', typeId: 'product'),
    GeneratorItem(icon: '✨', title: 'Slogans & Names', typeId: 'slogans'),

  ];

  static final List<String> trending = const [
    'Fitness femmes 25–35',
    'E-commerce Tunisia',
    'YouTube productivity',
    'Tech startups',
  ];

  List<GeneratorItem> get generatorList => generators;
  List<String> get trendingList => trending;
}
