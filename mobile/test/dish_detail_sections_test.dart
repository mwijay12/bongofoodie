import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/theme/app_tokens.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/menu/dish_detail_screen.dart';
import 'package:bongo_foodie/router/dish_route_args.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Size _screen = Size(360, 640);
const AppStrings _en = AppStrings(AppLanguage.en);
const AppStrings _sw = AppStrings(AppLanguage.sw);

const Key _factKey = Key('dish-did-you-know-section');
const Key _reviewsKey = Key('dish-reviews-section');
const Key _relatedKey = Key('dish-related-section');

const String _factEn = 'Pilau spices are toasted before the rice is added.';
const String _factSw = 'Viungo vya pilau hukaangwa kabla ya mchele kuwekwa.';

const MenuItemModel _richItem = MenuItemModel(
  id: 'test-pilau',
  name: 'Test Pilau',
  description:
      'A fragrant coastal rice dish cooked with coconut milk, warm spices, '
      'and a slow-simmered Swahili tomato gravy.',
  imageUrl: 'salad',
  price: 7500,
  rating: 4.6,
  ratingCount: 33,
  prepTimeMins: 18,
  categoryId: 'cat-pilau',
  categoryName: 'Pilau',
  spiceLevel: 3,
  ingredients: <String>['Rice', 'Cumin', 'Coconut milk'],
  allergens: <String>['Dairy'],
  funFactEn: _factEn,
  funFactSw: _factSw,
);

/// Same dish with every optional section's data removed.
const MenuItemModel _plainItem = MenuItemModel(
  id: 'test-pilau',
  name: 'Test Pilau',
  description: 'A simple coastal rice dish.',
  imageUrl: 'salad',
  price: 7500,
  categoryId: 'cat-pilau',
  categoryName: 'Pilau',
);

const List<CustomizationOption> _options = <CustomizationOption>[
  CustomizationOption(id: 'side-1', name: 'Kachumbari Extra', price: 1000),
  CustomizationOption(id: 'side-2', name: 'Pili Pili Kali', price: 500),
];

const List<MenuReviewModel> _reviews = <MenuReviewModel>[
  MenuReviewModel(
    id: 'rev-a',
    menuId: 'test-pilau',
    profileId: 'p1',
    rating: 5,
    comment: 'Oldest review',
    createdAt: '2026-01-01T09:00:00Z',
  ),
  MenuReviewModel(
    id: 'rev-b',
    menuId: 'test-pilau',
    profileId: 'p2',
    rating: 4,
    comment: 'Second review',
    createdAt: '2026-01-02T09:00:00Z',
  ),
  MenuReviewModel(
    id: 'rev-c',
    menuId: 'test-pilau',
    profileId: 'p3',
    rating: 5,
    comment: 'Third review',
    createdAt: '2026-01-03T09:00:00Z',
  ),
  MenuReviewModel(
    id: 'rev-d',
    menuId: 'test-pilau',
    profileId: 'p4',
    rating: 3,
    comment: 'Newest review',
    createdAt: '2026-01-04T09:00:00Z',
  ),
];

MenuItemModel _sibling(String id, String name) => MenuItemModel(
      id: id,
      name: name,
      description: 'Another coastal plate from the same category.',
      imageUrl: 'salad',
      price: 8200,
      categoryId: 'cat-pilau',
      categoryName: 'Pilau',
    );

final List<MenuItemModel> _sixSiblings = <MenuItemModel>[
  for (var i = 1; i <= 6; i++) _sibling('r$i', 'Pilau Sibling $i'),
];

/// A repository whose reads are instant and fully controlled by the test.
class _SectionsRepository extends MenuRepository {
  _SectionsRepository({
    required this.menu,
    this.reviews = const <MenuReviewModel>[],
    this.options = const <CustomizationOption>[],
  }) : super(showcaseLatency: Duration.zero);

  final List<MenuItemModel> menu;
  final List<MenuReviewModel> reviews;
  final List<CustomizationOption> options;

  @override
  Future<List<MenuItemModel>> getMenu({
    String category = '',
    String query = '',
  }) async =>
      menu;

  @override
  Future<List<MenuReviewModel>> getDishReviews(String dishId) async => reviews
      .where((review) => review.menuId == dishId)
      .toList(growable: false);

  @override
  Future<List<CustomizationOption>> getDishCustomizations(String dishId) async =>
      options;
}

List<Override> _overrides(
  _SectionsRepository repo, {
  AppStrings strings = _en,
}) =>
    <Override>[
      appStringsProvider.overrideWithValue(strings),
      showcaseLatencyProvider.overrideWithValue(Duration.zero),
      menuRepositoryProvider.overrideWithValue(repo),
    ];

Widget _host({
  required Widget home,
  required Brightness brightness,
}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : buildAppTheme(),
    darkTheme: AppTheme.dark(),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: _screen,
        textScaler: const TextScaler.linear(1.3),
        platformBrightness: brightness,
        disableAnimations: true,
        padding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
      ),
      child: child!,
    ),
    home: home,
  );
}

void _configureSurface(WidgetTester tester, {Size size = _screen}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required MenuItemModel item,
  required _SectionsRepository repo,
  Brightness brightness = Brightness.light,
  AppStrings strings = _en,
}) async {
  _configureSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(repo, strings: strings),
      child: _host(
        brightness: brightness,
        home: DishDetailScreen(
          id: item.id,
          args: DishRouteArgs(
            item: item,
            heroScope: DishHeroScopes.homeSignature,
          ),
        ),
      ),
    ),
  );
  // Bounded pumps only: the hero float and shimmer never settle.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(AppMotion.slow + AppMotion.staggerDelay);
  await tester.pump(AppMotion.slow);
  await tester.pump(AppMotion.base);
  return ProviderScope.containerOf(
    tester.element(find.byType(DishDetailScreen)),
    listen: false,
  );
}

Future<void> _scrollToBottom(WidgetTester tester) async {
  final scrollView = find.byType(CustomScrollView).first;
  for (var i = 0; i < 10; i++) {
    await tester.drag(scrollView, const Offset(0, -180));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

_SectionsRepository _repo({
  MenuItemModel item = _richItem,
  List<MenuItemModel>? menu,
  List<MenuReviewModel> reviews = const <MenuReviewModel>[],
  List<CustomizationOption> options = const <CustomizationOption>[],
}) =>
    _SectionsRepository(
      menu: menu ?? <MenuItemModel>[item],
      reviews: reviews,
      options: options,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('section 7: did you know', () {
    testWidgets('hides completely when both facts are null', (tester) async {
      await _pump(tester, item: _plainItem, repo: _repo(item: _plainItem));
      expect(find.byKey(_factKey), findsNothing);
      expect(find.text(_en.didYouKnow), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });

    testWidgets('shows the English fact by locale', (tester) async {
      await _pump(tester, item: _richItem, repo: _repo());
      expect(find.byKey(_factKey), findsOneWidget);
      expect(find.text(_factEn), findsOneWidget);
      expect(find.text(_factSw), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });

    testWidgets('shows the Swahili fact by locale', (tester) async {
      await _pump(
        tester,
        item: _richItem,
        repo: _repo(),
        strings: _sw,
      );
      expect(find.byKey(_factKey), findsOneWidget);
      expect(find.text(_factSw), findsOneWidget);
      expect(find.text(_factEn), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });
  });

  group('section 8: reviews', () {
    testWidgets('hides completely when there are no reviews', (tester) async {
      await _pump(tester, item: _richItem, repo: _repo());
      expect(find.byKey(_reviewsKey), findsNothing);
      expect(find.text(_en.reviews), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });

    testWidgets('shows average, count and the three latest reviews',
        (tester) async {
      await _pump(
        tester,
        item: _richItem,
        repo: _repo(reviews: _reviews),
      );
      expect(find.byKey(_reviewsKey), findsOneWidget);
      expect(find.text(_en.reviews), findsOneWidget);
      expect(find.text('4.6 • 33'), findsOneWidget);
      expect(find.text(_en.customer), findsNWidgets(3));
      expect(find.text('Newest review'), findsOneWidget);
      expect(find.text('Third review'), findsOneWidget);
      expect(find.text('Second review'), findsOneWidget);
      expect(find.text('Oldest review'), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });
  });

  group('section 9: related dishes', () {
    testWidgets('hides completely when there are no siblings', (tester) async {
      await _pump(tester, item: _richItem, repo: _repo());
      expect(find.byKey(_relatedKey), findsNothing);
      expect(find.text(_en.youMayAlsoLike), findsNothing);
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });

    testWidgets('shows a compact card row capped at five siblings',
        (tester) async {
      await _pump(
        tester,
        item: _richItem,
        repo: _repo(
          menu: <MenuItemModel>[_richItem, ..._sixSiblings],
        ),
      );
      expect(find.byKey(_relatedKey), findsOneWidget);
      expect(find.text(_en.youMayAlsoLike), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('dish-related-r1')),
        findsOneWidget,
      );
      // The sixth sibling is excluded by take(5).
      expect(
        find.byKey(const ValueKey<String>('dish-related-r6')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });
  });

  group('add-ons still feed the existing pricing function', () {
    testWidgets('selecting an add-on updates the sticky total and multiplies',
        (tester) async {
      await _pump(tester, item: _richItem, repo: _repo(options: _options));
      expect(
        find.text('${_en.addToCart}  ${AppStrings.formatTzs(7500)}'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('dish-add-on-side-1')));
      await tester.pump(AppMotion.fast);
      expect(
        find.text('${_en.addToCart}  ${AppStrings.formatTzs(8500)}'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip(_en.increaseQuantity));
      await tester.pump(AppMotion.fast);
      expect(
        find.text('${_en.addToCart}  ${AppStrings.formatTzs(17000)}'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('dish-add-on-side-1')));
      await tester.pump(AppMotion.fast);
      expect(
        find.text('${_en.addToCart}  ${AppStrings.formatTzs(15000)}'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });

    testWidgets('add to cart sends the selected customization ids',
        (tester) async {
      final container = await _pump(
        tester,
        item: _richItem,
        repo: _repo(options: _options),
      );
      await tester.tap(find.byKey(const ValueKey<String>('dish-add-on-side-1')));
      await tester.pump(AppMotion.fast);
      await tester.tap(find.byWidgetPredicate((widget) => widget is FilledButton));
      await tester.pump(AppMotion.fast);

      final cart = container.read(cartProvider);
      expect(cart.items, hasLength(1));
      expect(
        cart.items.single.customizations.map((option) => option.id),
        contains('side-1'),
      );
      expect(cart.items.single.lineTotal, 8500.0);
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });
  });

  testWidgets('related tap pushes a route with the related hero scope',
      (tester) async {
    _configureSurface(tester, size: const Size(800, 1200));
    final router = GoRouter(
      initialLocation: '/detail',
      routes: <RouteBase>[
        GoRoute(
          path: '/detail',
          builder: (_, __) => DishDetailScreen(
            id: _richItem.id,
            args: const DishRouteArgs(
              item: _richItem,
              heroScope: DishHeroScopes.homeSignature,
            ),
          ),
        ),
        GoRoute(
          path: '/dish/:id',
          builder: (context, state) {
            final extra = state.extra;
            final scope = extra is DishRouteArgs ? extra.heroScope : 'none';
            return Scaffold(body: Text('route-scope:$scope'));
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          _repo(menu: <MenuItemModel>[_richItem, ..._sixSiblings]),
        ),
        child: MaterialApp.router(
          routerConfig: router,
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(AppMotion.slow + AppMotion.staggerDelay);
    await tester.pump(AppMotion.slow);
    await tester.pump(AppMotion.base);

    final card = find.byKey(const ValueKey<String>('dish-related-r1'));
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(AppMotion.slow);
    await tester.pump(AppMotion.slow);

    expect(find.text('route-scope:related'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'no overflow at 360x640, textScale 1.3, $brightness, all sections',
      (tester) async {
        await _pump(
          tester,
          item: _richItem,
          repo: _repo(
            menu: <MenuItemModel>[_richItem, ..._sixSiblings],
            reviews: _reviews,
            options: _options,
          ),
          brightness: brightness,
        );
        await _scrollToBottom(tester);
        expect(tester.takeException(), isNull);
        await _disposeTree(tester);
      },
    );
  }
}
