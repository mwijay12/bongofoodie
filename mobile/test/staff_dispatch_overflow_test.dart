import 'dart:convert';
import 'package:bongo_foodie/data/mock/showcase_seed_data.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/features/cart/cart_screen.dart';
import 'package:bongo_foodie/features/chef_ai/chef_ai_screen.dart';
import 'package:bongo_foodie/features/home/home_screen.dart';
import 'package:bongo_foodie/features/menu/search_menu_screen.dart';
import 'package:bongo_foodie/features/profile/profile_screen.dart';
import 'package:bongo_foodie/features/staff/staff_dispatch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Pumps the Staff Dispatch screen at the given size / text scale /
  /// brightness and settles async providers (seeded showcase orders).
  Future<void> pumpStaffScreen(
    WidgetTester tester, {
    required double width,
    required double textScaleFactor,
    required Brightness brightness,
  }) async {
    // Explicit layout fixture: a fresh runtime no longer manufactures orders.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'bongo_orders_v2',
        jsonEncode(ShowcaseSeedData.initialOrders()
            .map((o) => o.toLocalJson())
            .toList()));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          showcaseLatencyProvider.overrideWithValue(Duration.zero),
        ],
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 844),
            textScaleFactor: textScaleFactor,
            platformBrightness: brightness,
          ),
          child: MaterialApp(
            theme: brightness == Brightness.dark
                ? AppTheme.dark()
                : buildAppTheme(),
            darkTheme: AppTheme.dark(),
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: const StaffDispatchScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  /// After every settle: no layout exceptions and every button's right edge
  /// stays within the screen width.
  Future<void> settleAndCheckButtons(
      WidgetTester tester, double screenWidth) async {
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final buttons = find.byType(ElevatedButton);
    for (var i = 0; i < buttons.evaluate().length; i++) {
      final rect = tester.getTopRight(buttons.at(i));
      expect(
        rect.dx,
        lessThanOrEqualTo(screenWidth),
        reason:
            'button ${i + 1} right edge ${rect.dx} overflows screen width $screenWidth',
      );
    }
  }

  group('staff order card overflow', () {
    final widths = <double>[320, 360, 390];
    final scales = <double>[1.0, 1.3];
    final brightnesses = <Brightness>[Brightness.light, Brightness.dark];

    for (final width in widths) {
      for (final scale in scales) {
        for (final brightness in brightnesses) {
          testWidgets(
            'no layout overflow at ${width.toInt()}dp, textScale $scale, ${brightness.name}',
            (tester) async {
              await pumpStaffScreen(
                tester,
                width: width,
                textScaleFactor: scale,
                brightness: brightness,
              );
              expect(tester.takeException(), isNull);
              await settleAndCheckButtons(tester, width);

              // Seeded order bf-983104: preparing, TSh 21,000, Lipa Namba.
              expect(find.text('Mark Ready for Rider'), findsOneWidget);

              // Every state button on this screen: rider assigned, out for
              // delivery, delivered.
              await tester.tap(find.text('Mark Ready for Rider').first);
              await settleAndCheckButtons(tester, width);
              expect(find.text('Dispatch Boda Rider'), findsOneWidget);

              await tester.tap(find.text('Dispatch Boda Rider').first);
              await settleAndCheckButtons(tester, width);
              expect(find.text('Confirm Delivered'), findsOneWidget);

              await tester.tap(find.text('Confirm Delivered').first);
              await settleAndCheckButtons(tester, width);
              expect(find.text('Confirm Delivered'), findsNothing);
            },
          );
        }
      }
    }
  });

  group('360x640 textScaleFactor 1.3 smoke', () {
    for (final route in const <String>[
      '/home',
      '/search',
      '/chef-ai',
      '/cart',
      '/profile',
      '/staff',
    ]) {
      testWidgets('no layout exceptions on $route', (tester) async {
        final router = GoRouter(
          initialLocation: route,
          routes: <RouteBase>[
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            GoRoute(
              path: '/search',
              builder: (_, __) =>
                  const SearchMenuScreen(initialCategory: 'All'),
            ),
            GoRoute(path: '/chef-ai', builder: (_, __) => const ChefAiScreen()),
            GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
            GoRoute(
                path: '/profile', builder: (_, __) => const ProfileScreen()),
            GoRoute(
                path: '/staff',
                builder: (_, __) => const StaffDispatchScreen()),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              showcaseLatencyProvider.overrideWithValue(Duration.zero),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaleFactor: 1.3,
                platformBrightness: Brightness.light,
              ),
              child: MaterialApp.router(
                theme: buildAppTheme(),
                darkTheme: AppTheme.dark(),
                themeMode: ThemeMode.light,
                routerConfig: router,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
