/// Presentation-only translations for the showcase catalog's stable IDs.
/// Unknown/live IDs retain their supplied text. Prices, ingredients and order
/// snapshots are not rewritten by this display layer.
const _copy = <String, ({String en, String sw, String descriptionEn, String descriptionSw})>{
  'menu-chipsi-mayai': (
    en: 'Chipsi Mayai', sw: 'Chipsi Mayai',
    descriptionEn: 'A potato-chip omelette served with tomato-onion kachumbari and tamarind chilli sauce.',
    descriptionSw: 'Omeleti ya chipsi na mayai, ikitolewa na kachumbari ya nyanya na vitunguu pamoja na pilipili ya ukwaju.',
  ),
  'menu-nyama-choma': (
    en: 'Grilled Beef & Ugali', sw: 'Nyama Choma na Ugali',
    descriptionEn: 'Charcoal-grilled beef served with ugali, coconut spinach and kachumbari.',
    descriptionSw: 'Nyama ya ng’ombe iliyochomwa kwa mkaa, ikitolewa na ugali, mchicha wa nazi na kachumbari.',
  ),
  'menu-pilau-kuku': (
    en: 'Zanzibar Beef Pilau', sw: 'Pilau ya Nyama ya Ng’ombe',
    descriptionEn: 'Spiced basmati rice cooked with beef, onions, cardamom and cloves, served with kachumbari.',
    descriptionSw: 'Wali wa basmati uliopikwa na nyama ya ng’ombe, vitunguu, iliki na karafuu, ukitolewa na kachumbari.',
  ),
  'menu-samaki-kupaka': (
    en: 'Fish in Coconut Sauce', sw: 'Samaki wa Kupaka',
    descriptionEn: 'Grilled fish coated in coconut cream sauce with turmeric, garlic and tamarind.',
    descriptionSw: 'Samaki aliyechomwa na kupakwa mchuzi wa tui la nazi wenye manjano, kitunguu saumu na ukwaju.',
  ),
  'menu-mishkaki': (
    en: 'Beef Skewers', sw: 'Mishkaki ya Ng’ombe',
    descriptionEn: 'Beef skewers marinated with papaya, ginger, garlic and black pepper, then charcoal-grilled.',
    descriptionSw: 'Mishkaki ya nyama ya ng’ombe iliyolowekwa kwenye papai, tangawizi, kitunguu saumu na pilipili manga, kisha kuchomwa kwa mkaa.',
  ),
  'menu-wali-nazi': (
    en: 'Coconut Rice & Beans', sw: 'Wali wa Nazi na Maharage',
    descriptionEn: 'Coconut-steamed rice served with red kidney beans cooked in coconut milk.',
    descriptionSw: 'Wali uliopikwa kwa tui la nazi, ukitolewa na maharage mekundu ya nazi.',
  ),
  'menu-kuku-chapati': (
    en: 'Chicken Curry & Chapati', sw: 'Kuku wa Nazi na Chapati',
    descriptionEn: 'Chicken coconut curry served with two layered chapatis brushed with ghee.',
    descriptionSw: 'Mchuzi wa kuku wa nazi, ukitolewa na chapati mbili za tabaka zilizopakwa samli.',
  ),
  'menu-ndizi-mzuzu': (
    en: 'Fried Plantains', sw: 'Ndizi za Kukaanga',
    descriptionEn: 'Ripe plantain slices fried until golden, served with tamarind chilli sauce.',
    descriptionSw: 'Vipande vya ndizi mzuzu mbivu vilivyokaangwa hadi kuwa vya dhahabu, vikitolewa na pilipili ya ukwaju.',
  ),
  'menu-bongo-burger': (
    en: 'Bongo Chilli Beef Burger', sw: 'Baga ya Nyama na Pilipili',
    descriptionEn: 'A beef burger with cheddar, chilli aioli, avocado and crispy onions in a toasted brioche bun.',
    descriptionSw: 'Baga ya nyama ya ng’ombe yenye jibini la cheddar, aioli ya pilipili, parachichi na vitunguu vya kukaanga kwenye mkate wa brioche.',
  ),
  'menu-zanzibar-pizza': (
    en: 'Spiced Beef Pizza', sw: 'Piza ya Nyama na Viungo',
    descriptionEn: 'A wood-fired sourdough pizza topped with spiced beef, mozzarella, sweet peppers and red onions. Not the folded Zanzibar street snack.',
    descriptionSw: 'Piza ya tanuruni yenye mkate wa sourdough, nyama yenye viungo, mozzarella, pilipili hoho na vitunguu vyekundu. Si kitafunwa cha kukunjwa cha Zanzibar.',
  ),
  'menu-passion-juice': (
    en: 'Passion Fruit & Mango Juice', sw: 'Juisi ya Pasheni na Embe',
    descriptionEn: 'Chilled passion fruit and mango juice with fresh mint. No orange juice.',
    descriptionSw: 'Juisi baridi ya pasheni na embe yenye mnanaa. Si juisi ya chungwa.',
  ),
  'menu-stoney': (
    en: 'Stoney Ginger Soda', sw: 'Stoney ya Tangawizi',
    descriptionEn: 'Chilled ginger soda to enjoy with your meal.',
    descriptionSw: 'Soda baridi ya tangawizi ya kunywa pamoja na chakula.',
  ),
};

String dishName(String id, String fallback, {required bool isSw}) =>
    _copy[id] == null ? fallback : (isSw ? _copy[id]!.sw : _copy[id]!.en);

String dishDescription(String id, String fallback, {required bool isSw}) =>
    _copy[id] == null ? fallback :
        (isSw ? _copy[id]!.descriptionSw : _copy[id]!.descriptionEn);

String dishOtherName(String id, {required bool isSw}) =>
    _copy[id] == null ? '' : (isSw ? _copy[id]!.en : _copy[id]!.sw);
