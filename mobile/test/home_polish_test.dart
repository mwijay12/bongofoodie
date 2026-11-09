import 'package:bongo_foodie/core/config/env_config.dart';
import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/theme/app_colors.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/theme/app_tokens.dart';
import 'package:bongo_foodie/core/widgets/app_shell.dart';
import 'package:bongo_foodie/core/widgets/bongo_glass_nav_bar.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/auth/sign_in_screen.dart';
import 'package:bongo_foodie/features/cart/cart_screen.dart';
import 'package:bongo_foodie/features/chef_ai/chef_ai_screen.dart';
import 'package:bongo_foodie/features/home/home_screen.dart';
import 'package:bongo_foodie/features/menu/search_menu_screen.dart';
import 'package:bongo_foodie/features/onboarding/onboarding_screen.dart';
import 'package:bongo_foodie/features/profile/profile_screen.dart';
import 'package:bongo_foodie/main.dart';
import 'package:bongo_foodie/router/app_router.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Size _screenSize = Size(360, 640);
const AppStrings _englishStrings = AppStrings(AppLanguage.en);
const String _longTitle = 'KARIBU BONGO FEAST SAVE TWO THOUSAND TZS';
const String _longSubtitle =
    'Save TSh 2,000 on any Swahili main dish with KARIBU2000, fresh '
    'passion juice, and a slow-simmered coastal tomato gravy tonight.';

const MenuItemModel _item = MenuItemModel(
  id: 'polish-pilau',
  name: 'Polish Pilau',
  description: 'A fragrant coastal rice dish with warm spices and coconut gravy.',
  imageUrl: 'salad',
  price: 7500,
  rating: 4.6,
  ratingCount: 33,
  prepTimeMins: 18,
  categoryName: 'Pilau',
);

const PromotionModel _longPromo = PromotionModel(
  id: 'polish-promo',
  title: _longTitle,
  subtitle: _longSubtitle,
  discountBadge: 'TSh 2,000 OFF',
);

const List<String> _tabPaths = <String>[
  '/home',
  '/search',
  '/chef-ai',
  '/cart',
  '/profile',
];

Widget _tabWidget(String path) {
  switch (path) {
    case '/home':
      return const HomeScreen(showEnvBadge: false);
    case '/search':
      return const SearchMenuScreen(initialCategory: 'All');
    case '/chef-ai':
      return const ChefAiScreen();
    case '/cart':
      return const CartScreen();
    case '/profile':
      return const ProfileScreen();
    default:
      throw ArgumentError('Unknown tab: $path');
  }
}

List<Override> _overrides({
  Future<List<MenuItemModel>>? menu,
  Future<List<PromotionModel>>? promos,
}) {
  return <Override>[
    appStringsProvider.overrideWithValue(_englishStrings),
    showcaseLatencyProvider.overrideWithValue(Duration.zero),
    allMenuItemsProvider.overrideWith(
      (ref) => menu ??
          Future<List<MenuItemModel>>.value(const <MenuItemModel>[_item]),
    ),
    promotionsProvider.overrideWith(
      (ref) => promos ??
          Future<List<PromotionModel>>.value(const <PromotionModel>[]),
    ),
    categoriesProvider.overrideWith((ref) async => <CategoryModel>[]),
  ];
}

Widget _host({
  required Widget home,
  required Brightness brightness,
  double textScale = 1.3,
  double safeBottom = 0,
}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark() : buildAppTheme(),
    darkTheme: AppTheme.dark(),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        padding: EdgeInsets.only(bottom: safeBottom),
        viewInsets: EdgeInsets.zero,
        viewPadding: EdgeInsets.only(bottom: safeBottom),
        platformBrightness: brightness,
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

Future<void> _pumpHome(
  WidgetTester tester, {
  required Brightness brightness,
  bool showEnvBadge = false,
  Future<List<MenuItemModel>>? menu,
  Future<List<PromotionModel>>? promos,
  double safeBottom = 0,
}) async {
  await _configureSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(menu: menu, promos: promos),
      child: _host(
        brightness: brightness,
        safeBottom: safeBottom,
        home: HomeScreen(showEnvBadge: showEnvBadge),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _pumpRoutedApp(
  WidgetTester tester, {
  required Brightness brightness,
  required String initialLocation,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'bongo_theme_dark_v2': brightness == Brightness.dark,
    'bongo_onboarded_v2': true,
  });
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: <GoRoute>[
      for (final path in _tabPaths)
        GoRoute(path: path, builder: (context, state) => _tabWidget(path)),
    ],
  );
  addTearDown(router.dispose);
  await _configureSurface(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ..._overrides(
          menu: Future<List<MenuItemModel>>.value(const <MenuItemModel>[_item]),
          promos: Future<List<PromotionModel>>.value(const <PromotionModel>[]),
        ),
        appRouterProvider.overrideWithValue(router),
      ],
      child: const BongoFoodieApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('shared promo and nav metrics stay in sync', () {
    expect(PromoCardMetrics.height, AppSpace.v190);
    expect(AppSpace.navClearance, AppSpace.navHeight + AppSpace.lg);
  });

  test('release env badge flag is hidden by default', () {
    const bool dartDefine =
        bool.fromEnvironment('SHOW_ENV_BADGE', defaultValue: false);
    expect(EnvConfig.shouldShowEnvBadge(debugMode: false), isFalse);
    expect(EnvConfig.shouldShowEnvBadge(debugMode: true), isTrue);
    expect(EnvConfig.showEnvBadge, kDebugMode || dartDefine);
    expect(EnvConfig.showEnvBadge, isTrue);
  });

  testWidgets('release-style flag hides the env badge', (tester) async {
    await _pumpHome(
      tester,
      brightness: Brightness.light,
      showEnvBadge: false,
      menu: Future<List<MenuItemModel>>.value(const <MenuItemModel>[]),
      promos: Future<List<PromotionModel>>.value(const <PromotionModel>[]),
    );
    expect(find.text('LIVE CLOUD'), findsNothing);
    expect(find.text('SHOWCASE'), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  testWidgets('debug flag still shows the env badge', (tester) async {
    await _pumpHome(
      tester,
      brightness: Brightness.light,
      showEnvBadge: true,
      menu: Future<List<MenuItemModel>>.value(const <MenuItemModel>[]),
      promos: Future<List<PromotionModel>>.value(const <PromotionModel>[]),
    );
    expect(find.text('SHOWCASE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      '40-char promo copy has no overflow at 360dp and textScale 1.3 '
      '($brightness)',
      (tester) async {
        await _pumpHome(
          tester,
          brightness: brightness,
          menu: Future<List<MenuItemModel>>.value(const <MenuItemModel>[_item]),
          promos: Future<List<PromotionModel>>.value(
            const <PromotionModel>[_longPromo],
          ),
        );
        expect(find.text(_longTitle), findsOneWidget);
        expect(find.text(_longSubtitle), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _disposeTree(tester);
      },
    );
  }

  for (final dark in <bool>[false, true]) {
    testWidgets(
      'Home status bar icons are ${dark ? 'light' : 'dark'} in '
      '${dark ? 'dark' : 'light'} mode',
      (tester) async {
        await _pumpRoutedApp(
          tester,
          brightness: dark ? Brightness.dark : Brightness.light,
          initialLocation: '/home',
        );
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byKey(const ValueKey('app-system-ui')),
        );
        expect(
          region.value.statusBarIconBrightness,
          dark ? Brightness.light : Brightness.dark,
        );
        expect(region.value.statusBarColor, Colors.transparent);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          tester
              .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
                find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
              )
              .length,
          1,
        );
        expect(tester.takeException(), isNull);
        await _disposeTree(tester);
      },
    );
  }

  for (final brightness in Brightness.values) {
    for (final path in _tabPaths) {
      testWidgets('$path uses only the root overlay ($brightness)',
          (tester) async {
        await _pumpRoutedApp(
          tester,
          brightness: brightness,
          initialLocation: path,
        );
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byKey(const ValueKey('app-system-ui')),
        );
        expect(
          region.value.statusBarIconBrightness,
          brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        );
        expect(
          tester
              .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
                find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
              )
              .length,
          1,
        );
        expect(tester.takeException(), isNull);
        await _disposeTree(tester);
      });
    }
  }

  for (final dark in <bool>[false, true]) {
    for (final entry in <String, Widget>{
      'onboarding': const OnboardingScreen(),
      'sign-in': const SignInScreen(),
    }.entries) {
      testWidgets(
        '${entry.key} dark-hero overlay uses light icons '
        '(${dark ? 'dark' : 'light'} theme)',
        (tester) async {
          await _configureSurface(tester);
          await tester.pumpWidget(
            ProviderScope(
              overrides: _overrides(
                menu: Future<List<MenuItemModel>>.value(
                  const <MenuItemModel>[],
                ),
                promos: Future<List<PromotionModel>>.value(
                  const <PromotionModel>[],
                ),
              ),
              child: _host(
                brightness: dark ? Brightness.dark : Brightness.light,
                home: entry.value,
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump(const Duration(milliseconds: 100));
          final region =
              tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byKey(ValueKey('${entry.key}-system-ui')),
          );
          expect(region.value.statusBarIconBrightness, Brightness.light);
          expect(region.value.statusBarColor, AppColors.ember);
          expect(tester.takeException(), isNull);
          await _disposeTree(tester);
        },
      );
    }
  }

  testWidgets('last Home item clears the floating nav at scroll end',
      (tester) async {
    const double safeBottom = 24;
    await _configureSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(
          menu: Future<List<MenuItemModel>>.value(const <MenuItemModel>[_item]),
          promos: Future<List<PromotionModel>>.value(const <PromotionModel>[]),
        ),
        child: _host(
          brightness: Brightness.light,
          safeBottom: safeBottom,
          home: AppShell(
            body: const HomeScreen(showEnvBadge: false),
            nav: BongoGlassNavBar(
              currentIndex: 0,
              cartCount: 0,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -5000),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final lastBottom = tester
        .getBottomLeft(find.byKey(ValueKey('home-dish-${_item.id}')))
        .dy;
    final navTop = tester.getTopLeft(find.byType(BongoGlassNavBar)).dy;
    expect(lastBottom, lessThan(navTop));
    expect(
      navTop - lastBottom,
      greaterThanOrEqualTo(AppSpace.lg - AppSpace.md),
    );
    expect(tester.takeException(), isNull);
    await _disposeTree(tester);
  });
}
