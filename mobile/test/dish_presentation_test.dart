import 'dart:io';
import 'dart:ui' as ui;
import 'package:bongo_foodie/core/l10n/dish_copy.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/utils/dish_asset.dart';
import 'package:bongo_foodie/core/utils/dish_image_cache.dart';
import 'package:bongo_foodie/core/widgets/dish_hero_image.dart';
import 'package:bongo_foodie/core/widgets/dish_image.dart';
import 'package:bongo_foodie/core/widgets/promo_dish_image.dart';
import 'package:bongo_foodie/data/mock/showcase_seed_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bongo_foodie/features/onboarding/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('canonical files are 1600px RGBA cutouts, not renamed JPEGs', () async {
    for (final id in dishAssetIds) {
      final bytes = File('assets/dishes/$id.png').readAsBytesSync();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes,
          targetWidth: 80, targetHeight: 80);
      final image = (await codec.getNextFrame()).image;
      final rgba = (await image.toByteData())!.buffer.asUint8List();
      expect(rgba[3], 0, reason: '$id top-left corner');
      expect(rgba[rgba.length - 1], 0, reason: '$id bottom-right corner');
      expect([for (var i = 3; i < rgba.length; i += 4) rgba[i]], contains(255),
          reason: '$id must not be entirely transparent');
      expect([
        for (var i = 0; i < rgba.length; i += 4) rgba[i]
      ], contains(greaterThan(30)), reason: '$id must retain food colours');
      image.dispose();
      codec.dispose();
      // PNG IHDR dimensions: 1600 = 0x00000640, colour type 6 = RGBA.
      expect(bytes.sublist(16, 24), [0, 0, 6, 64, 0, 0, 6, 64]);
      expect(bytes[25], 6);
    }
  });

  test('wrong product substitutions are not shown and prices stay unchanged',
      () {
    for (final id in [
      'menu-wali-nazi',
      'menu-kuku-chapati',
      'menu-ndizi-mzuzu',
      'menu-passion-juice',
      'menu-stoney'
    ]) {
      final item =
          ShowcaseSeedData.menuItems.firstWhere((item) => item.id == id);
      expect(item.imageUrl, isEmpty, reason: '$id needs its own photograph');
    }
    expect(dishName('menu-ndizi-mzuzu', '', isSw: true), 'Ndizi za Kukaanga');
    expect(dishName('menu-ndizi-mzuzu', '', isSw: false), 'Fried Plantains');
    expect(dishDescription('menu-passion-juice', '', isSw: false),
        contains('passion fruit and mango'));
    expect(dishName('live-uuid', 'Kitchen special', isSw: true),
        'Kitchen special');
    expect(dishDescription('live-uuid', 'From the kitchen', isSw: true),
        'From the kitchen');
    expect(
        ShowcaseSeedData.menuItems
            .firstWhere((d) => d.id == 'menu-passion-juice')
            .price,
        3500);
  });

  for (final dark in [false, true]) {
    testWidgets('hero and promo have no clip or white backing, dark=$dark',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const heroKey = Key('cutout-hero');
      const promoKey = Key('cutout-promo');
      await tester.pumpWidget(MaterialApp(
        theme: dark ? AppTheme.dark() : buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
              textScaler: TextScaler.linear(1.3), devicePixelRatio: 2),
          child: Scaffold(
              body: Column(children: [
            DishHeroImage(
              key: heroKey,
              item: ShowcaseSeedData.menuItems.first,
              heroScope: 'test-hero',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
              clip: false,
              transparentFallback: true,
            ),
            const PromoDishImage(key: promoKey, imageRef: 'mishkakiYaNgombe'),
          ])),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      for (final key in [heroKey, promoKey]) {
        final scope = find.byKey(key);
        expect(find.descendant(of: scope, matching: find.byType(ClipRRect)),
            findsNothing);
        final boxes = tester.widgetList<DecoratedBox>(
            find.descendant(of: scope, matching: find.byType(DecoratedBox)));
        expect(
            boxes.where((box) =>
                box.decoration is BoxDecoration &&
                (box.decoration as BoxDecoration).color == Colors.white),
            isEmpty);
      }
      final image = tester.widgetList<Image>(find.byType(Image)).first;
      expect(image.fit, BoxFit.contain);
      expect(image.image, isA<ResizeImage>());
      expect((image.image as ResizeImage).width, 600);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'cutout cards use a circle without clipping; opaque images stay rounded',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Row(children: [
      DishImage(
          key: Key('cutout'),
          dishId: 'menu-chipsi-mayai',
          imageRef: '',
          width: 140,
          height: 140),
      DishImage(
          key: Key('opaque'), imageRef: 'pilauYaKuku', width: 140, height: 140),
    ]))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(
        find.descendant(
            of: find.byKey(const Key('cutout')),
            matching: find.byType(ClipRRect)),
        findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('opaque')),
            matching: find.byType(ClipRRect)),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('precache sizing uses logical width times DPR', (tester) async {
    int? width;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(devicePixelRatio: 3),
      child: Builder(builder: (context) {
        width = dishDecodeWidth(context, 140);
        expect(dishDecodeWidth(context, null), isNull);
        return const SizedBox.shrink();
      }),
    )));
    expect(width, 420);
  });

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final dark in [false, true]) {
      testWidgets('onboarding slides fit $size at 1.3 text, dark=$dark',
          (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
          theme: dark ? AppTheme.dark() : buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.3),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: const OnboardingScreen(),
        )));
        await tester.pump(const Duration(milliseconds: 100));
        for (var slide = 0; slide < 3; slide++) {
          final error = tester.takeException();
          if (error != null) {
            for (final element in find.byType(Row).evaluate()) {
              final flex = element.renderObject! as RenderFlex;
              if (!flex.hasSize) continue;
              for (RenderBox? child = flex.firstChild; child != null;) {
                final data = child.parentData! as FlexParentData;
                if (child.hasSize &&
                    data.offset.dx + child.size.width > flex.size.width + 1) {
                  debugPrint('::error::Onboarding slide $slide overflow: '
                      '${flex.debugCreator}; width=${flex.size.width}; '
                      'childEnd=${data.offset.dx + child.size.width}');
                  break;
                }
                child = data.nextSibling;
              }
            }
          }
          expect(error, isNull, reason: 'onboarding slide $slide at $size');
          if (slide < 2) {
            await tester.tap(find.byType(OutlinedButton));
            await tester.pump(const Duration(milliseconds: 350));
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 50));
      });
    }
  }
}
