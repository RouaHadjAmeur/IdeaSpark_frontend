/// User persona model for personalized content generation
/// Stores user preferences collected during onboarding
class PersonaModel {
  final String? id;
  final String userId;
  final ProfileType profile;
  final ContentGoal goal;
  final List<String> niches;
  final String mainPlatform;
  final List<String> platforms;
  final List<ContentStyle> contentStyles;
  final ContentTone tone;
  final List<String> audiences;
  final AudienceAge audienceAge;
  final String language;
  final List<String> ctas;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PersonaModel({
    this.id,
    required this.userId,
    required this.profile,
    required this.goal,
    required this.niches,
    required this.mainPlatform,
    required this.platforms,
    required this.contentStyles,
    required this.tone,
    required this.audiences,
    required this.audienceAge,
    required this.language,
    required this.ctas,
    this.createdAt,
    this.updatedAt,
  });

  /// Helper to remove emojis and extra spaces from strings
  static String _cleanString(String input) {
    // Remove all emojis and Unicode symbols, then trim
    return input
        .replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '') // Emoji ranges
        .replaceAll(RegExp(r'[\u{2600}-\u{26FF}]', unicode: true), '') // Misc symbols
        .replaceAll(RegExp(r'[\u{2700}-\u{27BF}]', unicode: true), '') // Dingbats
        .replaceAll(RegExp(r'[\u{FE00}-\u{FE0F}]', unicode: true), '') // Variation selectors
        .trim();
  }

  /// Map frontend values to backend format
  Map<String, dynamic> toJson() {
    return {
      // Backend expects these field names (NOT profile, goal, tone, etc.)
      'userType': _cleanString(profile.label),
      'mainGoal': _cleanString(goal.label),
      'niches': niches.map((n) => _cleanString(n)).toList(),
      'mainPlatform': _mapMainPlatformToBackend(mainPlatform),
      'frequentPlatforms': platforms.map((p) => _mapFrequentPlatformToBackend(p)).toList(),
      'contentStyles': contentStyles.map((s) => _cleanString(s.label)).toList(),
      'preferredTone': _cleanString(tone.label),
      'audiences': audiences.map((a) => _cleanString(a)).toList(),
      'audienceAge': _mapAudienceAge(audienceAge.value),
      'language': _mapLanguageToBackend(language),
      'preferredCTAs': ctas.map((c) => _cleanString(c)).toList(),
      // Backend gets userId from JWT, don't send it
    };
  }

  /// Map main platform to backend MainPlatform enum format
  static String _mapMainPlatformToBackend(String platform) {
    final Map<String, String> platformMap = {
      'tiktok': 'TikTok',
      'instagram': 'Instagram',
      'youtube': 'YouTube',
      'facebook': 'Facebook',
    };
    return platformMap[platform.toLowerCase()] ?? 'TikTok';
  }

  /// Map frequent platforms to backend FrequentPlatform enum format
  static String _mapFrequentPlatformToBackend(String platform) {
    final Map<String, String> platformMap = {
      'tiktok': 'TikTok',
      'instagram reels': 'Instagram Reels',
      'instagram stories': 'Instagram Stories',
      'youtube shorts': 'YouTube Shorts',
      'youtube long': 'YouTube Long',
      'facebook': 'Facebook',
    };
    return platformMap[platform.toLowerCase()] ?? 'TikTok';
  }

  /// Map audience age to backend format
  static String _mapAudienceAge(String age) {
    final Map<String, String> ageMap = {
      '-17': '-17',
      '18-44': '18-44',
      '+45': '+45',
      'mixte': 'Mixte',
    };
    return ageMap[age.toLowerCase()] ?? '18-44';
  }

  /// Map language to backend format
  static String _mapLanguageToBackend(String lang) {
    final Map<String, String> langMap = {
      'fr': 'Français',
      'ar': 'Arabe',
      'en': 'English',
      'mix': 'Mixte',
      'mixte': 'Mixte',
    };
    return langMap[lang.toLowerCase()] ?? 'Français';
  }

  /// Map backend language value back to frontend code
  static String _mapLanguageFromBackend(String lang) {
    final Map<String, String> langMap = {
      'français': 'fr',
      'arabe': 'ar',
      'english': 'en',
      'mixte': 'mix',
    };
    return langMap[lang.toLowerCase()] ?? lang;
  }

  /// Map backend mainPlatform value back to frontend code
  static String _mapMainPlatformFromBackend(String platform) {
    return platform.toLowerCase();
  }

  /// Map backend frequentPlatform value back to frontend code
  static String _mapFrequentPlatformFromBackend(String platform) {
    return platform.toLowerCase();
  }

  PersonaModel copyWith({
    String? id,
    String? userId,
    ProfileType? profile,
    ContentGoal? goal,
    List<String>? niches,
    String? mainPlatform,
    List<String>? platforms,
    List<ContentStyle>? contentStyles,
    ContentTone? tone,
    List<String>? audiences,
    AudienceAge? audienceAge,
    String? language,
    List<String>? ctas,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PersonaModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
      goal: goal ?? this.goal,
      niches: niches ?? this.niches,
      mainPlatform: mainPlatform ?? this.mainPlatform,
      platforms: platforms ?? this.platforms,
      contentStyles: contentStyles ?? this.contentStyles,
      tone: tone ?? this.tone,
      audiences: audiences ?? this.audiences,
      audienceAge: audienceAge ?? this.audienceAge,
      language: language ?? this.language,
      ctas: ctas ?? this.ctas,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory PersonaModel.fromJson(Map<String, dynamic> json) {
    // Backend uses _id (MongoDB), userType, mainGoal, preferredTone, etc.
    final userTypeStr = (json['userType'] ?? '') as String;
    final mainGoalStr = (json['mainGoal'] ?? '') as String;
    final toneStr = (json['preferredTone'] ?? '') as String;
    final ageStr = (json['audienceAge'] ?? '') as String;

    return PersonaModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      userId: json['userId']?.toString() ?? '',
      profile: ProfileType.values.firstWhere(
        (e) => e.label == userTypeStr || e.value == userTypeStr,
        orElse: () => ProfileType.student,
      ),
      goal: ContentGoal.values.firstWhere(
        (e) => e.label == mainGoalStr || e.value == mainGoalStr,
        orElse: () => ContentGoal.views,
      ),
      niches: List<String>.from(json['niches'] ?? []),
      mainPlatform: _mapMainPlatformFromBackend(json['mainPlatform'] ?? ''),
      platforms: (json['frequentPlatforms'] as List<dynamic>?)
          ?.map((p) => _mapFrequentPlatformFromBackend(p.toString()))
          .toList() ?? [],
      contentStyles: (json['contentStyles'] as List<dynamic>?)
          ?.map((style) => ContentStyle.values.firstWhere(
                (e) => e.label == style.toString() || e.value == style.toString(),
                orElse: () => ContentStyle.facecam,
              ))
          .toList() ?? [],
      tone: ContentTone.values.firstWhere(
        (e) => e.label == toneStr || e.value == toneStr,
        orElse: () => ContentTone.fun,
      ),
      audiences: List<String>.from(json['audiences'] ?? []),
      audienceAge: AudienceAge.values.firstWhere(
        (e) => e.value == ageStr || e.label == ageStr,
        orElse: () => AudienceAge.adult,
      ),
      language: _mapLanguageFromBackend(json['language'] ?? 'Français'),
      ctas: List<String>.from(json['preferredCTAs'] ?? []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

enum ProfileType {
  student('student', 'Étudiant(e)', 'Je crée du contenu pour mon audience', 'Student', 'I create content for my audience'),
  ecommerce('ecommerce', 'E-commerce', 'Je représente une marque ou entreprise', 'E-commerce', 'I represent a brand or company'),
  influencer('influencer', 'Influenceur', 'Je crée du contenu pour influencer', 'Influencer', 'I create content to influence'),
  entrepreneur('entrepreneur', 'Entrepreneur', 'Je développe mon business', 'Entrepreneur', 'I develop my business'),
  other('other', 'Autre', 'Autre profil', 'Other', 'Other profile');

  final String value;
  final String label;
  final String description;
  final String labelEn;
  final String descriptionEn;
  const ProfileType(this.value, this.label, this.description, this.labelEn, this.descriptionEn);

  String localizedLabel(String locale) => locale == 'en' ? labelEn : label;
  String localizedDescription(String locale) => locale == 'en' ? descriptionEn : description;
}

enum ContentGoal {
  views('views', 'Vues', 'Gagner plus de vues', 'Views', 'Get more views'),
  community('community', 'Communauté', 'Développer ma communauté', 'Community', 'Grow my community'),
  sell('sell', 'Vendre', 'Générer des ventes', 'Sell', 'Generate sales'),
  leads('leads', 'Leads', 'Obtenir des leads', 'Leads', 'Get leads'),
  educate('educate', 'Éduquer', 'Partager des connaissances', 'Educate', 'Share knowledge');

  final String value;
  final String label;
  final String description;
  final String labelEn;
  final String descriptionEn;
  const ContentGoal(this.value, this.label, this.description, this.labelEn, this.descriptionEn);

  String localizedLabel(String locale) => locale == 'en' ? labelEn : label;
  String localizedDescription(String locale) => locale == 'en' ? descriptionEn : description;
}

enum ContentStyle {
  facecam('facecam', 'Facecam', 'Apparition à la caméra', 'Facecam', 'On-camera appearance'),
  voiceOver('voiceover', 'Voice-over', 'Narration voix-off', 'Voice-over', 'Off-screen narration'),
  textScreen('textscreen', 'Texte écran', 'Texte à l\'écran', 'Text on screen', 'On-screen text'),
  demo('demo', 'Démo', 'Démonstration produit', 'Demo', 'Product demonstration'),
  storytime('storytime', 'Storytime', 'Histoires, narratives', 'Storytime', 'Stories, narratives'),
  other('other', 'Autre', 'Autre style', 'Other', 'Other style');

  final String value;
  final String label;
  final String description;
  final String labelEn;
  final String descriptionEn;
  const ContentStyle(this.value, this.label, this.description, this.labelEn, this.descriptionEn);

  String localizedLabel(String locale) => locale == 'en' ? labelEn : label;
  String localizedDescription(String locale) => locale == 'en' ? descriptionEn : description;
}

enum ContentTone {
  fun('fun', 'Fun', 'Amusant, léger', 'Fun', 'Funny, light'),
  expert('expert', 'Expert', 'Professionnel, expert', 'Expert', 'Professional, expert'),
  reassuring('reassuring', 'Rassurant', 'Rassurant, confiant', 'Reassuring', 'Reassuring, confident'),
  motivation('motivation', 'Motivation', 'Motivant, uplifting', 'Motivation', 'Motivating, uplifting'),
  direct('direct', 'Direct', 'Direct, sans détour', 'Direct', 'Straight to the point'),
  mixed('mixed', 'Mixte', 'Mélange de tons', 'Mixed', 'Mix of tones');

  final String value;
  final String label;
  final String description;
  final String labelEn;
  final String descriptionEn;
  const ContentTone(this.value, this.label, this.description, this.labelEn, this.descriptionEn);

  String localizedLabel(String locale) => locale == 'en' ? labelEn : label;
  String localizedDescription(String locale) => locale == 'en' ? descriptionEn : description;
}

enum AudienceAge {
  teen('-17', '-17', 'Moins de 17 ans', '-17', 'Under 17'),
  adult('18-44', '18-44', 'Adultes', '18-44', 'Adults'),
  senior('+45', '+45', 'Plus de 45 ans', '+45', 'Over 45'),
  mixed('mixte', 'Mixte', 'Toutes les tranches d\'âge', 'Mixed', 'All age ranges');

  final String value;
  final String label;
  final String description;
  final String labelEn;
  final String descriptionEn;
  const AudienceAge(this.value, this.label, this.description, this.labelEn, this.descriptionEn);

  String localizedLabel(String locale) => locale == 'en' ? labelEn : label;
  String localizedDescription(String locale) => locale == 'en' ? descriptionEn : description;
}
