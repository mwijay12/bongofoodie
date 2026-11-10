import 'package:bongo_foodie/data/repositories/foreground_location_repository.dart';
import 'dart:async';
import 'package:bongo_foodie/core/widgets/tanzania_location_sheet.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/data/mock/dar_location_reference.dart';
import 'package:bongo_foodie/data/repositories/location_repository.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineLocations extends LocationRepository {
  @override
  Future<List<TzRegion>> getRegions() async => throw StateError('offline');
}

class RacingLocations extends LocationRepository {
  final first = Completer<List<TzDistrict>>();
  @override
  Future<List<TzRegion>> getRegions() async => const [
        TzRegion(code: 7, name: 'Dar es Salaam'),
        TzRegion(code: 8, name: 'Other region')
      ];
  @override
  Future<List<TzDistrict>> getDistricts(int region) => region == 7
      ? first.future
      : Future.value(
          const [TzDistrict(code: 800, name: 'Other district', regionCode: 8)]);
}

class FixedLocation extends ForegroundLocationRepository {
  FixedLocation(this.fix) : super(_NoDevice());
  final LocationFix fix;
  int calls = 0;
  @override
  Future<LocationFix> locate() async {
    calls++;
    return fix;
  }
}

class _NoDevice implements ForegroundLocationDevice {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('must not touch device');
}

Future<ProviderContainer> open(
    WidgetTester tester, Size size, bool sw, bool dark,
    {LocationRepository? repo, ForegroundLocationRepository? gps}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
      overrides: [
        appStringsProvider.overrideWithValue(
            AppStrings(sw ? AppLanguage.sw : AppLanguage.en)),
        if (repo != null) locationRepositoryProvider.overrideWithValue(repo),
        if (gps != null) foregroundLocationProvider.overrideWithValue(gps),
      ],
      child: MaterialApp(
          theme: dark ? AppTheme.dark() : buildAppTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () => showTanzaniaLocationPicker(context),
                      child: const Text('Open')))))));
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(
      tester.element(find.byType(TanzaniaLocationSheet)));
}

void main() {
  test(
      'partial reference has unique children and no landmark masquerading as ward',
      () {
    final regions = DarLocationReference.regions.map((r) => r.code).toSet();
    final districts = DarLocationReference.districts.map((d) => d.code).toSet();
    final wards = DarLocationReference.wards.map((w) => w.code).toSet();
    expect(districts.length, DarLocationReference.districts.length);
    expect(wards.length, DarLocationReference.wards.length);
    expect(
        DarLocationReference.districts
            .every((d) => regions.contains(d.regionCode)),
        isTrue);
    expect(
        DarLocationReference.wards
            .every((w) => districts.contains(w.districtCode)),
        isTrue);
    expect(
        DarLocationReference.wards
            .any((w) => w.name.contains('Gezaulole') || w.name.contains('(')),
        isFalse);
    expect(DarLocationReference.placesByWard[70506], ['Gezaulole']);
  });
  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final sw in [false, true]) {
      for (final dark in [false, true]) {
        testWidgets('manual fallback $size sw=$sw dark=$dark', (tester) async {
          final container =
              await open(tester, size, sw, dark, repo: OfflineLocations());
          expect(container.read(deliveryAddressProvider), isEmpty);
          expect(
              tester
                  .widget<ElevatedButton>(
                      find.byKey(const Key('save-location')))
                  .onPressed,
              isNull);
          await tester.ensureVisible(find.byType(SwitchListTile));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(SwitchListTile));
          await tester.pumpAndSettle();
          const address = 'House 14, Near market, Dar es Salaam';
          await tester.enterText(
              find.byKey(const Key('manual-address')), address);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.byKey(const Key('save-location')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('save-location')));
          await tester.pumpAndSettle();
          expect(container.read(deliveryAddressProvider), address);
          expect(
              await container
                  .read(deliveryAddressProvider.notifier)
                  .readSelection(),
              isNull);
          final restarted = DeliveryAddressNotifier();
          await tester.pump();
          expect(restarted.state, address);
          restarted.dispose();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  testWidgets('late district response cannot replace a newer region',
      (tester) async {
    final repo = RacingLocations();
    await open(tester, const Size(430, 932), false, false, repo: repo);
    Future<void> choose(String name) async {
      await tester.tap(find.byKey(const Key('location-region')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    await choose('Dar es Salaam');
    await choose('Other region');
    repo.first.complete(
        const [TzDistrict(code: 701, name: 'Old district', regionCode: 7)]);
    await tester.pumpAndSettle();
    final district = tester.widget<DropdownButtonFormField<TzDistrict>>(
        find.byKey(const Key('location-district')));
    final dropdown = tester.widget<DropdownButton<TzDistrict>>(find.descendant(
        of: find.byKey(const Key('location-district')),
        matching:
            find.byWidgetPredicate((w) => w is DropdownButton<TzDistrict>)));
    expect(dropdown.items!.single.value!.regionCode, 8);
    expect(district.initialValue, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final sw in [false, true]) {
    for (final outcome in LocationOutcome.values) {
      testWidgets('explicit GPS action $outcome sw=$sw retains address control',
          (tester) async {
        final gps = FixedLocation(LocationFix(outcome,
            latitude: 51.5, longitude: -0.1, accuracy: 20));
        final container =
            await open(tester, const Size(360, 640), sw, true, gps: gps);
        expect(gps.calls, 0);
        final action = find.byKey(const Key('use-current-location'));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(gps.calls, 1);
        expect(container.read(deliveryAddressProvider), isEmpty);
        expect(
            tester
                .widget<DropdownButtonFormField<TzRegion>>(
                    find.byKey(const Key('location-region')))
                .initialValue,
            isNull);
        expect(
            tester
                .widget<ElevatedButton>(find.byKey(const Key('save-location')))
                .onPressed,
            isNull);
        expect(
            find.text(sw ? 'Fungua mipangilio' : 'Open settings'),
            outcome == LocationOutcome.deniedForever
                ? findsOneWidget
                : findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('no automatic first region or ward selected', (tester) async {
    await open(tester, const Size(360, 640), false, false);
    expect(
        tester
            .widget<DropdownButtonFormField<TzRegion>>(
                find.byKey(const Key('location-region')))
            .initialValue,
        isNull);
    expect(
        tester
            .widget<ElevatedButton>(find.byKey(const Key('save-location')))
            .onPressed,
        isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
