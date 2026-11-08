import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/widgets/app_sheet.dart';
import 'package:bongo_foodie/core/widgets/app_shell.dart';
import 'package:bongo_foodie/core/widgets/bongo_glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter makeRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(
          body: shell,
          nav: BongoGlassNavBar(
            currentIndex: shell.currentIndex,
            cartCount: 3,
            onTap: (index) => shell.goBranch(index),
          ),
        ),
        branches: [
          for (final path in ['/home', '/search', '/chef-ai', '/cart', '/profile'])
            StatefulShellBranch(routes: [
              GoRoute(path: path, builder: (context, state) => Scaffold(
                body: Center(child: TextButton(
                  onPressed: () => showAppSheet<void>(context,
                    builder: (_) => const SizedBox(height: 300, child: Text('Test sheet'))),
                  child: Text('Open $path'),
                )),
              )),
            ]),
        ],
      ),
    ],
  );
}

Widget testApp(GoRouter router, Brightness brightness, {double keyboard = 0}) {
  return MaterialApp.router(
    routerConfig: router,
    theme: buildAppTheme(),
    darkTheme: AppTheme.dark(),
    themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        viewInsets: EdgeInsets.only(bottom: keyboard),
        textScaler: const TextScaler.linear(1.3),
      ),
      child: child!,
    ),
  );
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('nav pinned to screen bottom at three sizes ($brightness)', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = makeRouter();
      addTearDown(router.dispose);
      for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(testApp(router, brightness));
        await tester.pumpAndSettle();
        final bottom = tester.getBottomLeft(find.byType(BongoGlassNavBar)).dy;
        expect(bottom, greaterThan(size.height - 40));
        expect(bottom, lessThanOrEqualTo(size.height));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('keyboard slides nav off screen ($brightness)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = makeRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(testApp(router, brightness));
      await tester.pumpAndSettle();
      await tester.pumpWidget(testApp(router, brightness, keyboard: 300));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(BongoGlassNavBar)).dy, greaterThan(844));
    });

    testWidgets('root sheet barrier blocks the nav ($brightness)', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = makeRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(testApp(router, brightness));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open /home'));
      await tester.pumpAndSettle();
      expect(find.text('Test sheet'), findsOneWidget);
      await tester.tap(find.byType(BongoGlassNavBar), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(tester.widget<BongoGlassNavBar>(find.byType(BongoGlassNavBar)).currentIndex, 0);
    });
  }
}
