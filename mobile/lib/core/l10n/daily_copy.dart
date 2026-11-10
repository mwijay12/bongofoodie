import '../../data/models/models.dart';

/// Reviewed bundled copy only. Never translate arbitrary staff/live rows by ID.
abstract final class DailyCopy {
  static const discoveries = <DiscoveryModel>[
    DiscoveryModel(
        id: 'disc-1',
        title: 'Karafuu and the spice islands',
        description:
            'Zanzibar is known for its spice farming. Karafuu means cloves; mdalasini means cinnamon, and iliki means cardamom.'),
    DiscoveryModel(
        id: 'disc-2',
        title: 'Chipsi mayai, simply put',
        description:
            'Chipsi mayai brings chips and eggs together in one pan. Kachumbari is a familiar accompaniment.'),
    DiscoveryModel(
        id: 'disc-3',
        title: 'The aroma of pilau',
        description:
            'Cumin, cardamom, cloves and cinnamon are common pilau spices. The mix and cooking method vary from kitchen to kitchen.'),
    DiscoveryModel(
        id: 'disc-4',
        title: 'Cooking with coconut milk',
        description:
            'Tui la nazi is coconut milk. It adds richness to dishes such as wali wa nazi, beans and coastal fish preparations.'),
    DiscoveryModel(
        id: 'disc-5',
        title: 'Mishkaki over charcoal',
        description:
            'Mishkaki are pieces of marinated meat threaded onto skewers and grilled. Marinades vary; ginger, garlic and lime are common choices.'),
  ];
  static const discoveriesSw = <DiscoveryModel>[
    DiscoveryModel(
        id: 'disc-1',
        title: 'Karafuu na viungo vya Zanzibar',
        description:
            'Zanzibar inajulikana kwa kilimo cha viungo. Karafuu, mdalasini na iliki ni baadhi ya viungo vinavyotumika kuongeza harufu na ladha kwenye chakula.'),
    DiscoveryModel(
        id: 'disc-2',
        title: 'Chipsi mayai kwa kifupi',
        description:
            'Chipsi mayai hutengenezwa kwa kuchanganya chipsi na mayai kwenye kikaango. Mara nyingi huliwa pamoja na kachumbari.'),
    DiscoveryModel(
        id: 'disc-3',
        title: 'Harufu ya pilau',
        description:
            'Bizari, iliki, karafuu na mdalasini ni viungo vinavyotumika sana kwenye pilau. Mchanganyiko na namna ya kupika hutofautiana kati ya wapishi.'),
    DiscoveryModel(
        id: 'disc-4',
        title: 'Kupika kwa tui la nazi',
        description:
            'Tui hupatikana kwa kukamua nazi iliyokunwa. Hutumika kuongeza ladha kwenye wali wa nazi, maharage na baadhi ya mapishi ya samaki wa pwani.'),
    DiscoveryModel(
        id: 'disc-5',
        title: 'Mishkaki ya kuchoma',
        description:
            'Mishkaki ni vipande vya nyama vilivyowekwa kwenye vijiti na kuchomwa. Viungo hutofautiana; tangawizi, kitunguu saumu na limau hutumika mara nyingi.'),
  ];
  static DiscoveryModel discovery(DiscoveryModel source, {required bool isSw}) {
    if (!isSw) return source;
    for (var i = 0; i < discoveries.length; i++) {
      final original = discoveries[i];
      if (source.id == original.id &&
          source.title == original.title &&
          source.description == original.description) {
        return discoveriesSw[i];
      }
    }
    return source;
  }

  static const trivia = <TriviaQuestion>[
    TriviaQuestion(
        id: 1,
        question: 'Which spice is called mdalasini in Kiswahili?',
        options: ['Cloves', 'Cinnamon', 'Cardamom', 'Ginger'],
        correctIndex: 1,
        explainer:
            'Mdalasini is cinnamon, a spice made from tree bark and used in dishes and drinks such as pilau and chai.'),
    TriviaQuestion(
        id: 2,
        question: 'What is tui la nazi?',
        options: ['Coconut milk', 'Ghee', 'Tamarind sauce', 'Mango juice'],
        correctIndex: 0,
        explainer:
            'Tui la nazi is coconut milk, extracted from grated coconut. It is used in dishes such as wali wa nazi and maharage ya nazi.'),
    TriviaQuestion(
        id: 3,
        question: 'Which food is made by grilling pieces of meat on skewers?',
        options: ['Vitumbua', 'Mishkaki', 'Kachumbari', 'Mandazi'],
        correctIndex: 1,
        explainer:
            'Mishkaki are marinated pieces of meat grilled on skewers. The choice of meat and marinade varies.'),
  ];
  static const triviaSw = <TriviaQuestion>[
    TriviaQuestion(
        id: 1,
        question: 'Ni kiungo gani huitwa cinnamon kwa Kiingereza?',
        options: ['Karafuu', 'Mdalasini', 'Iliki', 'Tangawizi'],
        correctIndex: 1,
        explainer:
            'Mdalasini hutokana na gome la mti. Hutumika kuongeza harufu na ladha kwenye pilau, chai na mapishi mengine.'),
    TriviaQuestion(
        id: 2,
        question: 'Tui la nazi ni nini?',
        options: [
          'Maji yanayokamuliwa kwenye nazi iliyokunwa',
          'Samli',
          'Mchuzi wa ukwaju',
          'Juisi ya embe'
        ],
        correctIndex: 0,
        explainer:
            'Tui hupatikana kwa kukamua nazi iliyokunwa. Hutumika kwenye mapishi kama wali wa nazi na maharage ya nazi.'),
    TriviaQuestion(
        id: 3,
        question:
            'Ni chakula gani hutengenezwa kwa kuchoma vipande vya nyama kwenye vijiti?',
        options: ['Vitumbua', 'Mishkaki', 'Kachumbari', 'Mandazi'],
        correctIndex: 1,
        explainer:
            'Mishkaki hutengenezwa kwa nyama iliyowekwa viungo na kuchomwa kwenye vijiti. Aina ya nyama na viungo hutofautiana.'),
  ];
  static TriviaQuestion question(TriviaQuestion source, {required bool isSw}) {
    for (var i = 0; i < trivia.length; i++) {
      if (identical(source, trivia[i])) return isSw ? triviaSw[i] : source;
    }
    return source;
  }
}
