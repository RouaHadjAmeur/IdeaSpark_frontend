import '../models/plan.dart';

class CaptionResult {
  final String short;
  final String medium;
  final String long;
  final List<String> hashtags;
  final List<String> emojis;
  final String cta;

  const CaptionResult({
    required this.short,
    required this.medium,
    required this.long,
    required this.hashtags,
    required this.emojis,
    required this.cta,
  });
}

class CaptionGeneratorService {
  CaptionResult generate({
    required String postTitle,
    required String platform,
    required ContentFormat format,
    required String pillar,
    required CtaType ctaType,
    required String brandName,
  }) {
    final emojis = _getEmojis(pillar);
    final hashtags = _getHashtags(brandName, pillar, platform);
    final cta = _getCta(ctaType);

    return CaptionResult(
      short: '${emojis[0]} $postTitle\n\n$cta',
      medium: '${emojis[0]} $postTitle\n\n'
          'Découvrez comment $brandName peut transformer votre quotidien. '
          '$pillar au cœur de notre démarche.\n\n'
          '$cta\n\n'
          '${hashtags.take(5).join(' ')}',
      long: '${emojis[0]} $postTitle\n\n'
          'Chez $brandName, nous croyons que chaque détail compte. '
          'Notre approche centrée sur $pillar nous permet de vous offrir '
          'une expérience unique et mémorable.\n\n'
          '${emojis[1]} Ce que vous allez découvrir :\n'
          '• Une qualité incomparable\n'
          '• Des résultats prouvés\n'
          '• Une communauté engagée\n\n'
          '$cta\n\n'
          '${hashtags.join(' ')}',
      hashtags: hashtags,
      emojis: emojis,
      cta: cta,
    );
  }

  List<String> _getEmojis(String pillar) {
    final p = pillar.toLowerCase();
    if (p.contains('motiv') || p.contains('inspir')) return ['🔥', '💪', '✨', '🚀', '⭐'];
    if (p.contains('educ') || p.contains('learn')) return ['📚', '💡', '🎓', '🧠', '📖'];
    if (p.contains('lifestyle')) return ['✨', '🌟', '💫', '🎯', '🌈'];
    if (p.contains('product') || p.contains('produit')) return ['🛍️', '💎', '⭐', '🎁', '✅'];
    if (p.contains('sport') || p.contains('fitness')) return ['💪', '🏃', '🔥', '⚡', '🏆'];
    return ['✨', '🌟', '💫', '🎯', '🔥'];
  }

  List<String> _getHashtags(String brand, String pillar, String platform) {
    final b = brand.toLowerCase().replaceAll(' ', '');
    final p = pillar.toLowerCase().replaceAll(' ', '');
    final base = ['#$b', '#$p', '#marketing', '#contenu'];
    if (platform == 'Instagram') {
      base.addAll(['#instagood', '#reels', '#explore', '#instadaily']);
    } else if (platform == 'TikTok') {
      base.addAll(['#fyp', '#foryou', '#viral', '#trending']);
    } else if (platform == 'LinkedIn') {
      base.addAll(['#business', '#entrepreneur', '#leadership', '#growth']);
    } else {
      base.addAll(['#facebook', '#community', '#share']);
    }
    return base;
  }

  String _getCta(CtaType ctaType) {
    switch (ctaType) {
      case CtaType.hard:
        return '👉 Achetez maintenant - Lien en bio !';
      case CtaType.soft:
        return '💬 Dites-nous en commentaire ce que vous en pensez !';
      case CtaType.educational:
        return '📌 Sauvegardez ce post pour y revenir plus tard !';
    }
  }
}
