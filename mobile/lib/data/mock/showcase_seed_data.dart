import 'dar_location_reference.dart';
import '../models/models.dart';
import '../../core/l10n/daily_copy.dart';

class ShowcaseSeedData {
  ShowcaseSeedData._();

  static const Map<UserRole, AppUser> demoProfiles = {
    UserRole.customer: AppUser(
      id: 'demo-customer-001',
      name: 'Amina Juma',
      email: 'demo@bongofoodie.co.tz',
      phone: '+255 712 345 678',
      role: UserRole.customer,
      isDemo: true,
    ),
    UserRole.waiter: AppUser(
      id: 'demo-waiter-001',
      name: 'Salma Rashid (Waiter)',
      email: 'waiter@bongofoodie.co.tz',
      phone: '+255 788 123 456',
      role: UserRole.waiter,
      isDemo: true,
    ),
    UserRole.admin: AppUser(
      id: 'demo-admin-001',
      name: 'Mwijay Davie (Admin)',
      email: 'mwijaydavie@gmail.com',
      phone: '+255 790 942 616',
      role: UserRole.admin,
      isDemo: true,
    ),
  };

  static const List<CategoryModel> categories = [
    CategoryModel(
      id: 'cat-bites',
      name: 'Swahili Bites',
      description: 'Traditional East African street starters & coastal snacks',
    ),
    CategoryModel(
      id: 'cat-choma',
      name: 'Nyama Choma',
      description: 'Charcoal flame-grilled signature Tanzanian meats',
    ),
    CategoryModel(
      id: 'cat-pilau',
      name: 'Rice & Pilau',
      description: 'Zanzibar spice-infused pilau, biryani & coconut rice',
    ),
    CategoryModel(
      id: 'cat-stews',
      name: 'Traditional Stews',
      description: 'Slow-simmered tui la nazi curries & chapati pairings',
    ),
    CategoryModel(
      id: 'cat-specials',
      name: 'Gourmet Specials',
      description: 'Chef fusion burgers & wood-fired Swahili pizzas',
    ),
    CategoryModel(
      id: 'cat-drinks',
      name: 'Vinywaji',
      description: 'Fresh tropical juices, spiced chai & chilled sodas',
    ),
  ];

  static const kachumbari = CustomizationOption(
      id: 'cust-kachumbari', name: 'Kachumbari Extra', price: 1000);
  static const pilipili = CustomizationOption(
      id: 'cust-pilipili', name: 'Pili Pili Kali', price: 500);
  static const ndimu = CustomizationOption(
      id: 'cust-ndimu', name: 'Ndimu (Fresh Lime)', price: 300);
  static const ugali = CustomizationOption(
      id: 'cust-ugali', name: 'Ugali Kipande', price: 1500, type: 'side');
  static const chapati = CustomizationOption(
      id: 'cust-chapati', name: 'Chapati Moja', price: 1000, type: 'side');
  static const avocado = CustomizationOption(
      id: 'cust-avocado', name: 'Avocado Slices', price: 1000);
  static const stoney = CustomizationOption(
      id: 'cust-stoney', name: 'Stoney Tangawizi', price: 1500, type: 'drink');
  // Catalog inventory only, NEVER a fallback for an unlinked product.
  static const defaultSwahiliSides = [
    kachumbari,
    pilipili,
    ndimu,
    ugali,
    chapati,
    avocado,
    stoney
  ];
  static const chipsiAddons = [kachumbari, pilipili, ndimu, stoney];
  static const grillAddons = [kachumbari, pilipili, ndimu, ugali, stoney];
  static const riceAddons = [kachumbari, pilipili, avocado, stoney];
  static const fishAddons = [ndimu, ugali, chapati, stoney];
  static const snackAddons = [pilipili];
  static const fastFoodAddons = [avocado, pilipili, stoney];

  static const List<MenuItemModel> menuItems = [
    MenuItemModel(
      id: 'menu-chipsi-mayai',
      name: 'Chipsi Mayai',
      description:
          'Iconic Dar es Salaam golden French fry omelette served hot with fresh tomato-onion kachumbari and house tamarind pili pili.',
      imageUrl: 'chipsiMayai',
      price: 5500,
      rating: 4.9,
      ratingCount: 84,
      calories: 580,
      protein: 18,
      prepTimeMins: 12,
      categoryId: 'cat-bites',
      categoryName: 'Swahili Bites',
      availableCustomizations: chipsiAddons,
      spiceLevel: 2,
      ingredients: [
        'French fries',
        'eggs',
        'tomatoes',
        'onions',
        'tamarind',
        'chili'
      ],
      allergens: ['egg'],
      funFactEn:
          'Chipsi mayai combines fried potatoes with eggs in one omelette.',
      funFactSw:
          'Chipsi mayai huchanganya viazi vya kukaanga na mayai katika omeleti moja.',
    ),
    MenuItemModel(
      id: 'menu-nyama-choma',
      name: 'Nyama Choma & Ugali',
      description:
          'Charcoal-grilled tender beef ribs basted in ginger-lime marinade, paired with warm sembe ugali, mchicha wa nazi, and kachumbari.',
      imageUrl: 'nyamaChoma',
      price: 13500,
      rating: 4.9,
      ratingCount: 126,
      calories: 780,
      protein: 46,
      prepTimeMins: 25,
      categoryId: 'cat-choma',
      categoryName: 'Nyama Choma',
      availableCustomizations: grillAddons,
      spiceLevel: 2,
      ingredients: [
        'beef',
        'maize flour',
        'spinach',
        'coconut milk',
        'tomatoes',
        'onions',
        'ginger',
        'lime'
      ],
      allergens: ['coconut'],
      funFactEn:
          'Ugali is a firm maize-meal porridge often served with grilled meat.',
      funFactSw:
          'Ugali ni uji mzito wa unga wa mahindi unaotolewa mara nyingi na nyama ya kuchoma.',
    ),
    MenuItemModel(
      id: 'menu-pilau-kuku',
      name: 'Zanzibar Pilau',
      description:
          'Fragrant Zanzibar spiced basmati rice slow-cooked with caramelized onions, whole cardamom, cloves, tender beef, and kachumbari.',
      imageUrl: 'zanzibarPilau',
      price: 10000,
      rating: 4.8,
      ratingCount: 97,
      calories: 640,
      protein: 32,
      prepTimeMins: 20,
      categoryId: 'cat-pilau',
      categoryName: 'Rice & Pilau',
      availableCustomizations: riceAddons,
      spiceLevel: 3,
      ingredients: [
        'basmati rice',
        'beef',
        'onions',
        'cardamom',
        'cloves',
        'tomatoes'
      ],
      allergens: <String>[],
      funFactEn:
          'Pilau is rice cooked with whole spices such as cardamom and cloves.',
      funFactSw:
          'Pilau ni wali unaopikwa na viungo vizima kama iliki na karafuu.',
    ),
    MenuItemModel(
      id: 'menu-samaki-kupaka',
      name: 'Samaki wa Kupaka',
      description:
          'Charcoal-seared Indian Ocean snapper simmered in rich Tui la Nazi (fresh coconut cream), turmeric, garlic, and tamarind glaze.',
      imageUrl: 'samakiWaKupaka',
      price: 15000,
      rating: 4.9,
      ratingCount: 73,
      calories: 690,
      protein: 40,
      prepTimeMins: 25,
      categoryId: 'cat-stews',
      categoryName: 'Traditional Stews',
      availableCustomizations: fishAddons,
      spiceLevel: 2,
      ingredients: [
        'snapper',
        'coconut cream',
        'turmeric',
        'garlic',
        'mango',
        'tamarind'
      ],
      allergens: ['fish', 'coconut'],
      funFactEn:
          'Samaki wa kupaka is fish simmered in coconut cream or coconut milk.',
      funFactSw: 'Samaki wa kupaka hupikwa kwa tui la nazi au maziwa ya nazi.',
    ),
    MenuItemModel(
      id: 'menu-mishkaki',
      name: "Mishkaki ya Ng'ombe",
      description:
          'Four smoky beef tenderloin skewers marinated overnight in papaya, crushed ginger, garlic, and Zanzibar black pepper over glowing mkaa.',
      imageUrl: 'mishkakiYaNgombe',
      price: 7500,
      rating: 4.7,
      ratingCount: 64,
      calories: 460,
      protein: 35,
      prepTimeMins: 15,
      categoryId: 'cat-choma',
      categoryName: 'Nyama Choma',
      availableCustomizations: grillAddons,
      spiceLevel: 3,
      ingredients: ['beef', 'papaya', 'ginger', 'garlic', 'black pepper'],
      allergens: <String>[],
      funFactEn: 'Mishkaki are small pieces of meat grilled on skewers.',
      funFactSw:
          'Mishkaki ni vipande vidogo vya nyama vinavyochomwa kwenye vijiti.',
    ),
    MenuItemModel(
      id: 'menu-wali-nazi',
      name: 'Wali wa Nazi na Maharage',
      description:
          'Creamy coconut-steamed rice paired with velvety red kidney beans braised in fresh coconut milk and sweet coastal cardamom.',
      imageUrl: '',
      price: 6000,
      rating: 4.6,
      ratingCount: 42,
      calories: 540,
      protein: 16,
      prepTimeMins: 15,
      categoryId: 'cat-pilau',
      categoryName: 'Rice & Pilau',
      availableCustomizations: riceAddons,
      spiceLevel: 1,
      ingredients: ['rice', 'coconut milk', 'red kidney beans', 'cardamom'],
      allergens: ['coconut'],
      funFactEn: 'Wali wa nazi is rice cooked with coconut milk.',
      funFactSw: 'Wali wa nazi hupikwa kwa tui la nazi.',
    ),
    MenuItemModel(
      id: 'menu-kuku-chapati',
      name: 'Mchuzi wa Kuku na Chapati',
      description:
          'Rich coastal chicken coconut curry served with two flaky pan-layered golden chapatis brushed with ghee.',
      imageUrl: '',
      price: 9500,
      rating: 4.8,
      ratingCount: 58,
      calories: 660,
      protein: 30,
      prepTimeMins: 18,
      categoryId: 'cat-stews',
      categoryName: 'Traditional Stews',
      availableCustomizations: fishAddons,
      spiceLevel: 2,
      ingredients: ['chicken', 'coconut milk', 'wheat flour', 'ghee', 'spices'],
      allergens: ['gluten', 'milk'],
      funFactEn: 'Chapati is a layered flatbread cooked on a hot pan.',
      funFactSw:
          'Chapati ni mkate bapa wenye tabaka unaopikwa kwenye sufuria moto.',
    ),
    MenuItemModel(
      id: 'menu-bongo-burger',
      name: 'Bongo Pili-Pili Smash Burger',
      description:
          'Double flame-seared Tanzanian beef patty, melted cheddar, smoky pili-pili aioli, avocado, and crispy onions on toasted brioche.',
      imageUrl: 'burgerOne',
      price: 11000,
      rating: 4.8,
      ratingCount: 51,
      calories: 740,
      protein: 38,
      prepTimeMins: 15,
      categoryId: 'cat-specials',
      categoryName: 'Gourmet Specials',
      availableCustomizations: fastFoodAddons,
      spiceLevel: 3,
      ingredients: [
        'beef',
        'cheddar',
        'aioli',
        'avocado',
        'onions',
        'brioche bun'
      ],
      allergens: ['gluten', 'egg', 'milk'],
      funFactEn:
          'A smash burger is made by pressing the patty flat on a hot surface.',
      funFactSw:
          'Smash burger hutengenezwa kwa kubana nyama iliyo bapa kwenye uso moto.',
    ),
    MenuItemModel(
      id: 'menu-zanzibar-pizza',
      name: 'Zanzibar Spice Wood-Fired Pizza',
      description:
          'Artisan sourdough crust topped with spiced suki beef, mozzarella, roasted sweet peppers, red onions, and fresh coriander.',
      imageUrl: 'pizzaOne',
      price: 16000,
      rating: 4.8,
      ratingCount: 45,
      calories: 860,
      protein: 36,
      prepTimeMins: 22,
      categoryId: 'cat-specials',
      categoryName: 'Gourmet Specials',
      availableCustomizations: fastFoodAddons,
      spiceLevel: 2,
      ingredients: [
        'sourdough crust',
        'beef',
        'mozzarella',
        'sweet peppers',
        'red onions',
        'coriander'
      ],
      allergens: ['gluten', 'milk'],
      funFactEn:
          'Sourdough crust is made with a fermented flour-and-water starter.',
      funFactSw:
          'Ukoko wa sourdough hutengenezwa kwa chachu ya unga na maji iliyochachuka.',
    ),
    MenuItemModel(
      id: 'menu-passion-juice',
      name: 'Juisi ya Passion & Embe Baridi',
      description:
          'Freshly pressed Morogoro passion fruit and ripe coastal mango juice served chilled with fresh mint.',
      imageUrl: '',
      price: 3500,
      rating: 4.9,
      ratingCount: 68,
      calories: 160,
      protein: 2,
      prepTimeMins: 5,
      categoryId: 'cat-drinks',
      categoryName: 'Vinywaji',
      availableCustomizations: [],
      spiceLevel: 0,
      ingredients: ['passion fruit', 'mango', 'mint'],
      allergens: <String>[],
      funFactEn: 'Passion fruit and mango grow in tropical regions.',
      funFactSw: 'Matunda ya passion na embe hukua katika maeneo ya kitropiki.',
    ),
    MenuItemModel(
      id: 'menu-stoney',
      name: 'Stoney Tangawizi Baridi',
      description:
          'Ice-cold East African fiery ginger soda — the undisputed companion to hot Nyama Choma and Mishkaki.',
      imageUrl: '',
      price: 2000,
      rating: 4.8,
      ratingCount: 91,
      calories: 140,
      protein: 0,
      prepTimeMins: 2,
      categoryId: 'cat-drinks',
      categoryName: 'Vinywaji',
      availableCustomizations: [],
      spiceLevel: 1,
      ingredients: ['ginger soda'],
      allergens: <String>[],
      funFactEn: 'Ginger soda gets its sharp taste from ginger.',
      funFactSw:
          'Soda ya tangawizi hupata ladha yake kali kutoka kwa tangawizi.',
    ),
  ];

  static const List<MenuReviewModel> menuReviews = [
    MenuReviewModel(
      id: 'review-chipsi-1',
      menuId: 'menu-chipsi-mayai',
      profileId: 'demo-customer-001',
      rating: 5,
      comment: '',
      createdAt: '2026-01-14T09:00:00Z',
      updatedAt: '2026-01-14T09:00:00Z',
    ),
    MenuReviewModel(
      id: 'review-chipsi-2',
      menuId: 'menu-chipsi-mayai',
      profileId: 'demo-customer-002',
      rating: 4,
      comment: '',
      createdAt: '2026-01-18T12:30:00Z',
      updatedAt: '2026-01-18T12:30:00Z',
    ),
    MenuReviewModel(
      id: 'review-nyama-choma-1',
      menuId: 'menu-nyama-choma',
      profileId: 'demo-customer-001',
      rating: 5,
      comment: '',
      createdAt: '2026-01-21T18:15:00Z',
      updatedAt: '2026-01-21T18:15:00Z',
    ),
    MenuReviewModel(
      id: 'review-pilau-1',
      menuId: 'menu-pilau-kuku',
      profileId: 'demo-customer-003',
      rating: 4,
      comment: '',
      createdAt: '2026-01-25T13:45:00Z',
      updatedAt: '2026-01-25T13:45:00Z',
    ),
  ];

  static const List<PromotionModel> promotions = [
    PromotionModel(
      id: 'promo-1',
      title: 'KARIBU BONGO FEAST',
      subtitle: 'Save TSh 2,000 on any Swahili main dish with code KARIBU2000',
      discountBadge: 'TSh 2,000 OFF',
      promoCode: 'KARIBU2000',
      bgHex: '#F6821F',
      imageKey: 'nyamaChoma',
    ),
    PromotionModel(
      id: 'promo-2',
      title: 'IJUMAA PILAU & JUICE',
      subtitle: 'Zanzibar Beef Pilau + Fresh Passion Mango Juice combo',
      discountBadge: '15% OFF',
      promoCode: 'KARIBU2000',
      bgHex: '#0F5132',
      imageKey: 'zanzibarPilau',
    ),
    PromotionModel(
      id: 'promo-3',
      title: 'WEEKEND PIZZA & BURGER',
      subtitle: 'Wood-fired Zanzibar Pizza & Smash Burger family deal',
      discountBadge: '20% OFF',
      promoCode: 'KARIBU2000',
      bgHex: '#181C2E',
      imageKey: 'pizzaOne',
    ),
  ];

  static const List<DiscoveryModel> discoveries = DailyCopy.discoveries;
  static const List<TriviaQuestion> triviaQuestions = DailyCopy.trivia;

  static const List<TzRegion> regions = [
    TzRegion(code: 7, name: 'Dar es Salaam'),
    TzRegion(code: 2, name: 'Arusha'),
    TzRegion(code: 19, name: 'Mwanza'),
    TzRegion(code: 1, name: 'Dodoma'),
    TzRegion(code: 29, name: 'Mjini Magharibi (Zanzibar)'),
    TzRegion(code: 3, name: 'Kilimanjaro'),
    TzRegion(code: 4, name: 'Tanga'),
    TzRegion(code: 5, name: 'Morogoro'),
    TzRegion(code: 12, name: 'Mbeya'),
    TzRegion(code: 6, name: 'Pwani'),
    TzRegion(code: 11, name: 'Iringa'),
  ];

  static const List<TzDistrict> districts = [
    // Dar es Salaam
    ...DarLocationReference.districts,
    TzDistrict(code: 201, name: 'Arusha Mjini', regionCode: 2),
    TzDistrict(code: 202, name: 'Arumeru', regionCode: 2),
    TzDistrict(code: 1901, name: 'Nyamagana', regionCode: 19),
    TzDistrict(code: 1902, name: 'Ilemela', regionCode: 19),
    TzDistrict(code: 101, name: 'Dodoma Mjini', regionCode: 1),
    TzDistrict(code: 2901, name: 'Mjini (Stone Town)', regionCode: 29),
    TzDistrict(code: 2902, name: 'Magharibi A', regionCode: 29),
    TzDistrict(code: 301, name: 'Moshi Mjini', regionCode: 3),
    TzDistrict(code: 401, name: 'Tanga Mjini', regionCode: 4),
    TzDistrict(code: 501, name: 'Morogoro Mjini', regionCode: 5),
    TzDistrict(code: 1201, name: 'Mbeya Mjini', regionCode: 12),
    TzDistrict(code: 601, name: 'Kibaha Mjini', regionCode: 6),
    TzDistrict(code: 602, name: 'Bagamoyo', regionCode: 6),
    TzDistrict(code: 1101, name: 'Iringa Mjini', regionCode: 11),
  ];

  static const List<TzWard> wards = [
    ...DarLocationReference.wards,
    // Other regions
    TzWard(code: 20101, name: 'Sekei', districtCode: 201),
    TzWard(code: 20102, name: 'Kaloleni', districtCode: 201),
    TzWard(code: 20201, name: 'Usa River', districtCode: 202),
    TzWard(code: 190101, name: 'Capri Point', districtCode: 1901),
    TzWard(code: 190201, name: 'Kirumba', districtCode: 1902),
    TzWard(code: 10101, name: 'Majengo (Dodoma CBD)', districtCode: 101),
    TzWard(code: 290101, name: 'Shangani (Stone Town)', districtCode: 2901),
    TzWard(code: 290201, name: 'Bububu', districtCode: 2902),
    TzWard(code: 30101, name: 'Mawenzi', districtCode: 301),
    TzWard(code: 40101, name: 'Chumbageni', districtCode: 401),
    TzWard(code: 50101, name: 'Boma', districtCode: 501),
    TzWard(code: 120101, name: 'Iyunga', districtCode: 1201),
    TzWard(code: 60101, name: 'Tumbi', districtCode: 601),
    TzWard(code: 60201, name: 'Dunda', districtCode: 602),
    TzWard(code: 110101, name: 'Gangilonga', districtCode: 1101),
  ];

  static List<OrderModel> initialOrders() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 'bf-983104',
        profileId: 'demo-customer-001',
        tableNumber: 'Delivery',
        items: const [
          CartItemModel(
            id: 'menu-nyama-choma',
            name: 'Nyama Choma & Ugali',
            price: 13500,
            imageUrl: 'nyamaChoma',
            quantity: 1,
            customizations: [
              CustomizationOption(
                id: 'cust-kachumbari',
                name: 'Kachumbari Extra',
                price: 1000,
              ),
            ],
          ),
          CartItemModel(
            id: 'menu-chipsi-mayai',
            name: 'Chipsi Mayai',
            price: 5500,
            imageUrl: 'chipsiMayai',
            quantity: 1,
          ),
        ],
        status: OrderStatus.preparing,
        totalPrice: 21000,
        deliveryLocation: 'Kijitonyama, Kinondoni, Dar es Salaam',
        customerName: 'Amina Juma',
        customerEmail: 'demo@bongofoodie.co.tz',
        customerPhone: '+255 712 345 678',
        paymentMethod: 'lipanamba',
        createdAt: now.subtract(const Duration(minutes: 18)),
      ),
      OrderModel(
        id: 'bf-512098',
        profileId: 'demo-customer-001',
        tableNumber: 'Delivery',
        items: const [
          CartItemModel(
            id: 'menu-pilau-kuku',
            name: 'Zanzibar Pilau',
            price: 10000,
            imageUrl: 'zanzibarPilau',
            quantity: 2,
          ),
        ],
        status: OrderStatus.delivered,
        totalPrice: 21000,
        deliveryLocation: 'Mikocheni, Kinondoni, Dar es Salaam',
        customerName: 'Amina Juma',
        customerEmail: 'demo@bongofoodie.co.tz',
        customerPhone: '+255 712 345 678',
        paymentMethod: 'cash',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
