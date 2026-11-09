import 'package:bongo_foodie/core/widgets/dish_back_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter routerFor(String location) => GoRouter(
      initialLocation: location,
      routes: [
        for (final path in ['/home', '/search'])
          GoRoute(
              path: path,
              builder: (context, state) => Scaffold(
                    body: TextButton(
                        onPressed: () => context.push('/dish/a'),
                        child: Text(path)),
                  )),
        GoRoute(
            path: '/dish/:id',
            builder: (context, state) => DishBackScope(
                  child: Scaffold(
                    appBar: AppBar(
                        leading:
                            BackButton(onPressed: () => backFromDish(context))),
                    body: TextButton(
                        onPressed: () => context.push('/dish/b'),
                        child: Text(state.pathParameters['id']!)),
                  ),
                )),
      ],
    );

void main() {
  for (final source in ['/home', '/search']) {
    testWidgets('detail back returns to its caller $source', (tester) async {
      final router = routerFor(source);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text(source));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(BackButton));
      await tester.pump(const Duration(milliseconds: 400));
      expect(router.routeInformationProvider.value.uri.path, source);
    });
  }
  testWidgets('direct link system back falls back to menu', (tester) async {
    final router = routerFor('/dish/a');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    expect(router.routeInformationProvider.value.uri.path, '/search');
  });
  testWidgets('related dish back retains the previous dish', (tester) async {
    final router = routerFor('/dish/a');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('a'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(BackButton).last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(router.routeInformationProvider.value.uri.path, '/dish/a');
  });
}
