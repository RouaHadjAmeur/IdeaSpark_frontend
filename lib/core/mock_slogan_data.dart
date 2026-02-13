import '../models/slogan_model.dart';

class MockSloganData {
  static List<SloganModel> generateMockSlogans() {
    return [
      SloganModel(
        id: 'slogan_1',
        slogan: 'Transformez vos distractions en accomplissements',
        explanation: 'Message de transformation et d\'empowerment. Positionne le produit comme un catalyseur de changement positif.',
        memorabilityScore: 9.2,
        category: 'Transformation',
      ),
      SloganModel(
        id: 'slogan_2',
        slogan: 'Votre temps mérite mieux que le scroll',
        explanation: 'Appel à la valeur personnelle du temps. Référence directe au comportement problématique (scroll).',
        memorabilityScore: 8.8,
        category: 'Sensibilisation',
      ),
      SloganModel(
        id: 'slogan_3',
        slogan: 'Focus. Flow. Fait.',
        explanation: 'Slogan rythmé en 3 temps (très mémorable). Intègre le nom du produit. Progression logique: concentration → état optimal → résultat.',
        memorabilityScore: 9.5,
        category: 'Efficacité',
      ),
      SloganModel(
        id: 'slogan_4',
        slogan: 'Là où l\'intention rencontre l\'action',
        explanation: 'Positionnement philosophique qui valorise l\'utilisateur. Suggère que l\'app est le pont entre vouloir et faire.',
        memorabilityScore: 8.3,
        category: 'Aspiration',
      ),
      SloganModel(
        id: 'slogan_5',
        slogan: 'Productivité sans friction',
        explanation: 'Promesse claire et directe. Le mot "friction" évoque les obstacles que l\'app élimine.',
        memorabilityScore: 8.6,
        category: 'Bénéfice',
      ),
      SloganModel(
        id: 'slogan_6',
        slogan: 'Chaque minute compte. Faites-les compter.',
        explanation: 'Jeu de mots sur "compter" (valeur) et "faire compter" (action). Crée un sentiment d\'urgence positive.',
        memorabilityScore: 8.9,
        category: 'Valeur',
      ),
      SloganModel(
        id: 'slogan_7',
        slogan: 'L\'app qui respecte votre attention',
        explanation: 'Positionnement éthique fort. Contraste avec les apps qui "volent" l\'attention. Résonne avec les préoccupations actuelles.',
        memorabilityScore: 8.4,
        category: 'Éthique',
      ),
      SloganModel(
        id: 'slogan_8',
        slogan: 'De l\'intention à l\'impact',
        explanation: 'Allitération mémorable. Promet une transformation concrète des pensées en résultats.',
        memorabilityScore: 8.7,
        category: 'Résultat',
      ),
      SloganModel(
        id: 'slogan_9',
        slogan: 'Travaillez moins. Accomplissez plus.',
        explanation: 'Paradoxe accrocheur qui promet l\'efficacité. Répond au désir d\'équilibre vie pro/perso.',
        memorabilityScore: 9.1,
        category: 'Productivité',
      ),
      SloganModel(
        id: 'slogan_10',
        slogan: 'Votre copilote pour une journée productive',
        explanation: 'Métaphore du copilote suggère assistance sans prise de contrôle. Ton amical et accessible.',
        memorabilityScore: 8.5,
        category: 'Accompagnement',
      ),
      SloganModel(
        id: 'slogan_11',
        slogan: 'Moins de chaos, plus de clarté',
        explanation: 'Contraste simple et efficace. Promet de l\'ordre dans le désordre quotidien.',
        memorabilityScore: 8.8,
        category: 'Clarté',
      ),
      SloganModel(
        id: 'slogan_12',
        slogan: 'Pensez moins. Faites plus.',
        explanation: 'Slogan minimaliste qui promet de réduire la charge mentale. Encourage l\'action immédiate.',
        memorabilityScore: 9.0,
        category: 'Minimalisme',
      ),
    ];
  }
}
