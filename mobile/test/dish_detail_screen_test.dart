import 'dart:async';

import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/theme/app_tokens.dart';
import 'package:bongo_foodie/core/widgets/dish_hero_image.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_detail_screen.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/menu/dish_detail_screen.dart';
import 'package:bongo_foodie/router/dish_route_args.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Size _screenSize = Size(360, 640);
const AppStrings _englishStrings = AppStrings(AppLanguage.en);
const MenuItemModel _item = MenuItemModel(
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
  categoryName: 'Pilau',
);
const DishRouteArgs _args = DishRouteArgs(
  item: _item,
  heroScope: DishHeroScopes.homeSignature,
);

List<Override> _overrides({Future<List<MenuItemModel>>? menuFuture}) {
  return <Override>[
    appStringsProvider.overrideWithValue(_englishStrings),
    showcaseLatencyProvider.overrideWithValue(Duration.zero),
    allMenuItemsProvider.overrideWith(
      (ref) => menuFuture ?? Future<List<MenuItemModel>>.value(<MenuItemModel>[_item]),
    ),
  ];
}

Widget _host({
  required Widget home,
  required Brightness brightness,
  bool disableAnimations = false,
  double textScaleFactor = 1.3,
}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : buildAppTheme(),
    darkTheme: AppTheme.dark(),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: _screenSize,
        textScaleFactor: textScaleFactor,
        platformBrightness: brightness,
        disableAnimations: disableAnimations,
        padding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
      ),
      child: child!,
    ),
    home: home,
  );
}

Future<void> _configureSurface(WidgetTester tester) async {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}

Future<ProviderContainer> _pumpDetail(
  WidgetTester tester, {
  required String id,
  DishRouteArgs? args,
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
  Future<List<MenuItemModel>>? menuFuture,
}) async {
  await _configureSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(menuFuture: menuFuture),
      child: _host(
        brightness: brightness,
        disableAnimations: disableAnimations,
        home: DishDetailScreen(id: id, args: args),
      ),
    ),
  );
  // Bounded pumps only: the hero float and skeleton shimmer never settle.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(AppMotion.slow + AppMotion.staggerDelay);
  await tester.pump(AppMotion.slow);
  await tester.pump(AppMotion.base);
  return ProviderScope.containerOf(
    tester.element(find.byType(DishDetailScreen)),
    listen: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('instant args render without a deep-link skeleton',
      (tester) async {
    await _pumpDetail(tester, id: _item.id, args: _args);
    expect(find.text(_item.name), findsOneWidget);
    expect(find.byType(DishHeroImage), findsOneWidget);
    expect(find.byType(SkeletonDetailScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('sticky bar price matches the existing pricing function',
      (tester) async {
    await _pumpDetail(
      tester,
      id: _item.id,
      args: _args,
      disableAnimations: true,
    );
    final CartItemModel expected = CartItemModel(
      id: _item.id,
      name: _item.name,
      price: _item.price,
      imageUrl: _item.imageUrl,
      quantity: DishDetailMetrics.quantityMin,
      customizations: const <CustomizationOption>[],
    );
    expect(
      find.text('${_englishStrings.addToCart}  ${AppStrings.formatTzs(expected.lineTotal)}'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(_englishStrings.increaseQuantity));
    await tester.pump(AppMotion.fast);
    final CartItemModel doubled = CartItemModel(
      id: _item.id,
      name: _item.name,
      price: _item.price,
      imageUrl: _item.imageUrl,
      quantity: 2,
      customizations: const <CustomizationOption>[],
    );
    expect(
      find.text('${_englishStrings.addToCart}  ${AppStrings.formatTzs(doubled.lineTotal)}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('quantity stepper stays within 1..20', (tester) async {
    await _pumpDetail(
      tester,
      id: _item.id,
      args: _args,
      disableAnimations: true,
    );
    for (var i = 0; i < DishDetailMetrics.quantityMax + 5; i++) {
      await tester.tap(
        find.byTooltip(_englishStrings.increaseQuantity),
        warnIfMissed: false,
      );
      await tester.pump(AppMotion.fast);
    }
    expect(find.text('${DishDetailMetrics.quantityMax}'), findsOneWidget);

    for (var i = 0; i < DishDetailMetrics.quantityMax + 5; i++) {
      await tester.tap(
        find.byTooltip(_englishStrings.decreaseQuantity),
        warnIfMissed: false,
      );
      await tester.pump(AppMotion.fast);
    }
    expect(find.text('${DishDetailMetrics.quantityMin}'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('add to cart morphs to Added and updates the cart badge',
      (tester) async {
    final container = await _pumpDetail(
      tester,
      id: _item.id,
      args: _args,
      disableAnimations: true,
    );
    await tester.tap(
      find.byTooltip(_englishStrings.increaseQuantity),
      warnIfMissed: false,
    );
    await tester.pump(AppMotion.fast);

    await tester.tap(
      find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    await tester.pump(AppMotion.fast);
    expect(find.text(_englishStrings.added), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byType(DishDetailScreen), findsOneWidget);
    expect(container.read(cartProvider).totalItems, 2);
    expect(container.read(cartProvider).items.single.quantity, 2);
    expect(container.read(cartProvider).items.single.lineTotal, 15000.0);

    await tester.pump(AppMotion.addedLabel + AppMotion.fast);
    expect(
      find.text('${_englishStrings.addToCart}  ${AppStrings.formatTzs(15000)}'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('deep link shows the skeleton and then the resolved dish',
      (tester) async {
    final pending = Completer<List<MenuItemModel>>();
    await _pumpDetail(
      tester,
      id: _item.id,
      menuFuture: pending.future,
      disableAnimations: true,
    );
    expect(find.byType(SkeletonDetailScreen), findsOneWidget);
    expect(find.text(_item.name), findsNothing);

    pending.complete(<MenuItemModel>[_item]);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(AppMotion.base);
    expect(find.text(_item.name), findsOneWidget);
    expect(find.byType(SkeletonDetailScreen), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('unknown deep-link id shows the not-found state',
      (tester) async {
    await _pumpDetail(
      tester,
      id: 'missing-dish',
      disableAnimations: true,
    );
    expect(find.text(_englishStrings.dishNotFoundTitle), findsOneWidget);
    expect(find.text(_englishStrings.backToMenu), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('same dish with two hero scopes produces unique hero tags',
      (tester) async {
    await _configureSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: _host(
          brightness: Brightness.light,
          home: Scaffold(
            body: Row(
              children: <Widget>[
                DishHeroImage(
                  item: _item,
                  heroScope: DishHeroScopes.homeSignature,
                  width: AppSpace.v92,
                  height: AppSpace.v92,
                ),
                DishHeroImage(
                  item: _item,
                  heroScope: DishHeroScopes.menuList,
                  width: AppSpace.v92,
                  height: AppSpace.v92,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Hero), findsNWidgets(2));
    final tags = <Object?>[
      tester.widget<Hero>(find.byType(Hero).at(0)).tag,
      tester.widget<Hero>(find.byType(Hero).at(1)).tag,
    ];
    expect(tags.toSet().length, 2);
    expect(tags, contains(dishHeroTag(DishHeroScopes.homeSignature, _item.id)));
    expect(tags, contains(dishHeroTag(DishHeroScopes.menuList, _item.id)));
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets('no overflow at 360x640, textScale 1.3, $brightness',
        (tester) async {
      await _pumpDetail(
        tester,
        id: _item.id,
        args: _args,
        brightness: brightness,
      );
      expect(tester.takeException(), isNull);
      await _disposeTree(tester);
    });
  }

  testWidgets('float and entrance stop under disableAnimations',
      (tester) async {
    await _pumpDetail(
      tester,
      id: _item.id,
      args: _args,
      disableAnimations: true,
    );
    final hero = tester.state<DishHeroState>(find.byType(DishHero));
    final screen = tester.state<DishDetailScreenState>(
      find.byType(DishDetailScreen),
    );
    expect(hero.floatController.isAnimating, isFalse);
    expect(hero.floatController.value, 0);
    expect(screen.entranceController.value, 1);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('hero responds when reduced motion changes while mounted',
      (tester) async {
    final reducedMotion = ValueNotifier<bool>(false);
    addTearDown(reducedMotion.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(),
        child: ValueListenableBuilder<bool>(
          valueListenable: reducedMotion,
          builder: (context, disabled, child) => _host(
            brightness: Brightness.light,
            disableAnimations: disabled,
            home: const Scaffold(
              body: DishHero(
                item: _item,
                heroScope: DishHeroScopes.homeSignature,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final hero = tester.state<DishHeroState>(find.byType(DishHero));
    expect(hero.floatController.isAnimating, isTrue);
    reducedMotion.value = true;
    await tester.pump();
    expect(hero.floatController.isAnimating, isFalse);
    expect(hero.floatController.value, 0);
    reducedMotion.value = false;
    await tester.pump();
    expect(hero.floatController.isAnimating, isTrue);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

}
