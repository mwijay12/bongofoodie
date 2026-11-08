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
      isSw ? 'UGUNDUZI WA KISWAHILI LEO' : 'DAILY SWAHILI DISCOVERY';
  String get playSpiceTrivia => isSw ? 'Cheza Trivia' : 'Spice Trivia';
  String get popularDishes => isSw ? 'Sahani Pendwa' : 'Signature Dishes';
  String get searchPlaceholder => isSw
      ? 'Tafuta Nyama Choma, Pilau, Samaki wa Kupaka...'
      : 'Search Nyama Choma, Pilau, Samaki wa Kupaka...';
  String get allCategories => isSw ? 'Zote' : 'All';
  String get addToCart => isSw ? 'Weka Kikapuni' : 'Add to Cart';
  String get clearSearch => isSw ? 'Safisha Tafuta' : 'Clear Search';

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
      isSw ? 'Tuzo za Mla Chakula Bora' : 'Swahili Foodie Badges';
  String get signOut => isSw ? 'Ondoka / Badili Akaunti' : 'Sign Out / Switch Role';

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
