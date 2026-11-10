import 'package:bongo_foodie/core/widgets/location_map_card.dart';
import 'package:bongo_foodie/core/utils/map_links.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final sw in [false, true]) {
    for (final size in [const Size(360, 640), const Size(430, 932)]) {
      testWidgets(
          'map consent, tile failure/retry and external links $sw $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final opened = <Uri>[];
        var requests = 0;
        final client = MockClient((request) async {
          requests++;
          return http.Response('unavailable', 503);
        });
        addTearDown(client.close);
        await tester.pumpWidget(ProviderScope(
            overrides: [
              externalMapLauncherProvider.overrideWithValue((uri) async {
                opened.add(uri);
                return false;
              }),
              mapTileProviderFactoryProvider.overrideWithValue(() =>
                  NetworkTileProvider(
                      httpClient: client,
                      cachingProvider: const DisabledMapCachingProvider())),
            ],
            child: MaterialApp(
                theme: buildAppTheme(),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.3)),
                    child: child!),
                home: Scaffold(
                    body: SingleChildScrollView(
                        child: LocationMapCard(
                            sw: sw,
                            target: const MapTarget(
                                latitude: -6.8, longitude: 39.2)))))));
        expect(find.byType(FlutterMap), findsNothing);
        expect(requests, 0);
        await tester.tap(find.byKey(const Key('load-location-map')));
        await tester.pumpAndSettle();
        expect(requests, greaterThan(0));
        expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
        expect(find.byKey(const Key('retry-location-map')), findsOneWidget);
        final count = requests;
        await tester.ensureVisible(find.byKey(const Key('retry-location-map')));
        await tester.tap(find.byKey(const Key('retry-location-map')));
        await tester.pumpAndSettle();
        expect(requests, greaterThan(count));
        await tester.ensureVisible(find.text('Google Maps'));
        await tester.tap(find.text('Google Maps'));
        await tester.pumpAndSettle();
        expect(opened.single.host, 'www.google.com');
        expect(opened.single.queryParameters['query'], '-6.8,39.2');
        expect(find.byType(SnackBar), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets(
      'empty target keeps external actions disabled without tile requests',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            home: Scaffold(
                body: LocationMapCard(sw: false, target: const MapTarget())))));
    expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Google Maps'))
            .onPressed,
        isNull);
    expect(find.byType(FlutterMap), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
