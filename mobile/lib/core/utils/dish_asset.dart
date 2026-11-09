/// Only list IDs whose cutout files are checked into assets/dishes/.
/// The registry/file parity test must pass whenever a dish is added here.
const Set<String> dishAssetIds = {
  'menu-chipsi-mayai',
  'menu-nyama-choma',
  'menu-pilau-kuku',
  'menu-samaki-kupaka',
  'menu-mishkaki',
};

String resolveDishAsset(String dishId,
    {required String fallback, String productName = ''}) {
  if (dishAssetIds.contains(dishId)) return 'assets/dishes/$dishId.png';
  // Reject only known legacy substitutions, never infer a remote image's content.
  final name = productName.toLowerCase();
  if ((fallback == 'orangeJuiceIcon' &&
          (name.contains('passion') ||
              name.contains('pasheni') ||
              name.contains('stoney'))) ||
      (fallback == 'fries' &&
          (name.contains('ndizi') || name.contains('plantain'))) ||
      (fallback == 'samakiWaKupaka' &&
          (name.contains('kuku') || name.contains('chicken'))) ||
      (fallback == 'pilauYaKuku' &&
          (name.contains('wali wa nazi') || name.contains('coconut rice')))) {
    return '';
  }
  return fallback;
}

/// Compatibility keys used by promotions and onboarding, not product names.
const Map<String, String> dishImageKeys = {
  'chipsiMayai': 'menu-chipsi-mayai',
  'nyamaChoma': 'menu-nyama-choma',
  'zanzibarPilau': 'menu-pilau-kuku',
  'samakiWaKupaka': 'menu-samaki-kupaka',
  'mishkakiYaNgombe': 'menu-mishkaki',
};
