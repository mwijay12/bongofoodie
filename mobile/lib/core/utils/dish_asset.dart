/// Only list IDs whose cutout files are checked into assets/dishes/.
/// The registry/file parity test must pass whenever a dish is added here.
const Set<String> dishAssetIds = {
  'menu-chipsi-mayai',
  'menu-nyama-choma',
  'menu-pilau-kuku',
  'menu-samaki-kupaka',
  'menu-mishkaki',
};

String resolveDishAsset(String dishId, {required String fallback}) =>
    dishAssetIds.contains(dishId) ? 'assets/dishes/$dishId.png' : fallback;

/// Compatibility keys used by promotions and onboarding, not product names.
const Map<String, String> dishImageKeys = {
  'chipsiMayai': 'menu-chipsi-mayai',
  'nyamaChoma': 'menu-nyama-choma',
  'zanzibarPilau': 'menu-pilau-kuku',
  'samakiWaKupaka': 'menu-samaki-kupaka',
  'mishkakiYaNgombe': 'menu-mishkaki',
};
