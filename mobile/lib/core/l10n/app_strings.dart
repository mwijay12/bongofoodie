enum AppLanguage { en, sw }

typedef S = AppStrings;

class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  bool get isSw => lang == AppLanguage.sw;

  // Loading and content states
  String get loading => isSw ? 'Inapakia' : 'Loading';
  String get errorTitle => isSw ? 'Kuna hitilafu' : 'Something went wrong';
  String get errorBody => isSw
      ? 'Hatukuweza kupakia. Angalia mtandao kisha jaribu tena.'
      : 'We could not load this. Check your connection and try again.';
  String get retry => isSw ? 'Jaribu tena' : 'Try again';

  // Connection honesty: say what actually happened instead of blaming the user's network.
  String get offlineTitle =>
      isSw ? 'Hakuna muunganisho wa data' : 'No data connection';
  String get offlineBody => isSw
      ? 'Programu haiwezi kufikia seva kwa sasa. Angalia mtandao wako.'
      : 'The app cannot reach the server right now. Check your connection.';
  String get serverTitle =>
      isSw ? 'Seva haipatikani' : 'Server unavailable';
  String get serverBody => isSw
      ? 'Muunganisho wako uko sawa, lakini seva ya BongoFoodie haijajibu. Jaribu tena baada ya muda mfupi.'
      : 'Your connection is fine, but the BongoFoodie server did not respond. Try again in a moment.';
  String get showcaseNoticeTitle =>
      isSw ? 'Hali ya maonyesho' : 'Showcase mode';
  String get showcaseNoticeBody => isSw
      ? 'Data ya maonyesho inaonyeshwa. Rekebisha funguo za Supabase kuunganisha data halisi.'
      : 'Showing showcase data. Configure the Supabase keys to load the live catalog.';
  String get emptyMenuTitle => isSw ? 'Hakuna sahani zilizopatikana' : 'No dishes found';
  String get emptyMenuBody => isSw ? 'Jaribu kutafuta kwa jina jingine.' : 'Try a different search.';
  String get emptyFavoritesTitle => isSw ? 'Bado huna vipendwa' : 'No favorites yet';
  String get emptyFavoritesBody => isSw ? 'Weka sahani unazopenda hapa ili uzipate kwa urahisi.' : 'Save dishes you love to find them here.';
  String get emptyOrdersTitle => isSw ? 'Bado hujaagiza' : 'No orders yet';
  String get emptyOrdersBody => isSw ? 'Oda zako zitaonekana hapa.' : 'Your orders will appear here.';
  String get browseMenu => isSw ? 'Angalia menyu' : 'Browse menu';

  // Navigation
  String get navHome => isSw ? 'Nyumbani' : 'Home';
  String get navSearch => isSw ? 'Menyu' : 'Menu';
  String get navChefAi => 'Chef AI';
  String get navCart => isSw ? 'Kikapu' : 'Cart';
  String get navProfile => isSw ? 'Wasifu' : 'Profile';

  // Auth & Showcase
  String get signInTitle => isSw ? 'Karibu BongoFoodie' : 'Welcome to BongoFoodie';
  String get showcaseHint => isSw
      ? 'Bonyeza nafasi yoyote hapa chini kujaribu mfumo mzima papo hapo bila kuweka funguo za Supabase:'
      : 'Tap any role below to explore the complete Dar es Salaam restaurant platform immediately:';
  String get demoCustomer => isSw ? 'Mteja (Customer Demo)' : 'Customer Showcase';
  String get demoWaiter => isSw ? 'Mhudumu (Waiter POS)' : 'Waiter Dispatch Demo';
  String get demoAdmin => isSw ? 'Msimamizi (Admin)' : 'Restaurant Admin Demo';

  // Home & Menu
  String get deliverTo => isSw ? 'Peleka Kwenda' : 'Deliver To';
  String get liveMode => 'LIVE CLOUD';
  String get showcaseMode => 'SHOWCASE';
  String get karibuTitle => isSw ? 'Karibu' : 'Karibu';
  String get heroSubtitle => isSw
      ? 'Chakula halisi cha Kiswahili kutoka jikoni Kijitonyama hadi mlangoni kwako.'
      : 'Authentic Swahili gastronomy crafted hot in Kijitonyama, Dar es Salaam.';
  String get chefAiBannerTitle =>
      isSw ? 'Ongea na Mpishi Mkuu AI' : 'Consult Executive Chef AI';
  String get chefAiBannerSub => isSw
      ? 'Uliza siri za viungo au unda sahani yako maalum ya Kiswahili na uiagize!'
      : 'Ask for spice pairings or design a custom Swahili fusion dish to order now!';
  String get dailyDiscovery =>
      isSw ? 'DOKEZO LA LEO' : 'TODAY’S FOOD STORY';
  String get playSpiceTrivia => isSw ? 'Swali la leo' : 'Food quiz';
  String get popularDishes => isSw ? 'Sahani Pendwa' : 'Signature Dishes';
  String get searchPlaceholder => isSw
      ? 'Tafuta Nyama Choma, Pilau, Samaki wa Kupaka...'
      : 'Search Nyama Choma, Pilau, Samaki wa Kupaka...';
  String get allCategories => isSw ? 'Zote' : 'All';
  String get addToCart => isSw ? 'Weka Kikapuni' : 'Add to cart';
  String get added => isSw ? 'Imewekwa' : 'Added';
  String get readMore => isSw ? 'Soma zaidi' : 'Read more';
  String get readLess => isSw ? 'Soma kidogo' : 'Read less';
  String get quantity => isSw ? 'Idadi' : 'Quantity';
  String get backToMenu => isSw ? 'Rudi kwenye menyu' : 'Back to menu';
  String get increaseQuantity => isSw ? 'Ongeza idadi' : 'Increase quantity';
  String get decreaseQuantity => isSw ? 'Punguza idadi' : 'Decrease quantity';
  String get favorite => isSw ? 'Kipendwa' : 'Favorite';
  String get dishSecondaryName => isSw ? 'Jina la Kiswahili' : 'Swahili name';
  String get spice => isSw ? 'Kiwango cha ukali' : 'Spice level';
  String get spiceMild => isSw ? 'Ukali mdogo' : 'Mild';
  String get spiceMedium => isSw ? 'Ukali wastani' : 'Medium';
  String get spiceHot => isSw ? 'Kali' : 'Hot';
  String get spiceExtraHot => isSw ? 'Kali sana' : 'Extra hot';
  String get ingredients => isSw ? 'Viungo vilivyotumika' : 'Ingredients';
  String get contains => isSw ? 'Ina' : 'Contains';
  String get addOns => isSw ? 'Nyongeza' : 'Add-ons';
  String get didYouKnow => isSw ? 'Je, ulijua?' : 'Did you know?';
  String get reviews => isSw ? 'Maoni ya wateja' : 'Reviews';
  String get noReviews => isSw ? 'Bado hakuna maoni' : 'No reviews yet';
  String get youMayAlsoLike => isSw ? 'Huenda ukapenda pia' : 'You may also like';
  String get customer => isSw ? 'Mteja' : 'Customer';
  String get dishNotFoundTitle => isSw ? 'Sahani haipatikani' : 'Dish not found';
  String get dishNotFoundBody => isSw
      ? 'Sahani hii haipatikani tena kwenye menyu.'
      : 'This dish is no longer available on the menu.';
  String get clearSearch => isSw ? 'Safisha Tafuta' : 'Clear Search';

  // Chef AI (emoji-free copy, EN and natural SW)
  String get chefAiWelcome => isSw
      ? 'Karibu kwenye BongoFoodie Chef Atelier! Niulize chochote kwa Kiswahili au Kiingereza — kuhusu viungo, chakula cha leo Dar es Salaam, au badilisha kwenda "Buni Sahani" ili uunde sahani yako ya Kiswahili!'
      : 'Welcome to the BongoFoodie Chef Atelier! Ask me anything in Kiswahili or English — spice pairings, what to eat tonight in Dar es Salaam, or switch to "Dish Creator" to invent your own Swahili plate!';
  String get chefAiBespoke =>
      isSw ? 'SAHANI MAALUM YA CHEF' : 'CHEF BESPOKE';
  String get chefAiAddedToCart =>
      isSw ? 'imeongezwa kwenye Kikapu!' : 'added to Cart!';

  // Cart & Checkout
  String get emptyCartTitle =>
      isSw ? 'Kikapu Chako Kiko Tupu' : 'Your Cart is Empty';
  String get emptyCartSub => isSw
      ? 'Chagua Nyama Choma, Pilau au unda sahani mpya na Chef AI!'
      : 'Explore our Swahili menu or co-create a custom dish in Chef Atelier!';
  String get applyPromo => isSw ? 'Tumia' : 'Apply';
  String get subtotal => isSw ? 'Jumla ya Chakula' : 'Subtotal';
  String get deliveryFee => isSw ? 'Gharama ya Usafiri' : 'Delivery Fee';
  String get total => isSw ? 'Jumla Kuu' : 'Grand Total';
  String get placeOrder => isSw ? 'Kamilisha Oda' : 'Place Order';

  // Profile & Staff
  String get staffDispatch =>
      isSw ? 'Dashibodi ya Jikoni & Wahudumu' : 'Open Staff Dispatch Console';
  String get staffDispatchTitle => isSw ? 'Pelekezi ya Jikoni' : 'Kitchen Dispatch';
  String get myOrders => isSw ? 'Oda Zangu' : 'Orders';
  String get favorites => isSw ? 'Pendwa' : 'Favorites';
  String get darkMode => isSw ? 'Mwonekano wa Giza' : 'Dark Mode';
  String get languageLabel => isSw ? 'Lugha ya Programu' : 'App Language';
  String get achievements =>
      isSw ? 'Beji zako' : 'Your food milestones';
  String get signOut => isSw ? 'Ondoka / Badili Akaunti' : 'Sign Out / Switch Role';

  String spiceLevelSemantics(int level) => isSw
      ? 'Kiwango cha ukali $level kati ya 5'
      : 'Spice level $level of 5';

  static String formatTzs(num value) {
    final intVal = value.round();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      buffer.write(str[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'TSh $buffer';
  }
}
