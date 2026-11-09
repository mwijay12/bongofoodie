import 'package:bongo_foodie/core/widgets/dish_image.dart';
import 'package:bongo_foodie/core/widgets/motion/stagger_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cutouts resolve without replacing chicken or coconut rice artwork', () {
    expect(DishImage.resolveLocalAsset('chipsiMayai'),
        'assets/dishes/chipsi_mayai.png');
    expect(DishImage.resolveLocalAsset('nyamaChoma'),
        'assets/dishes/nyama_choma_ugali.png');
    expect(DishImage.resolveLocalAsset('zanzibarPilau'),
        'assets/dishes/zanzibar_pilau.png');
    expect(DishImage.resolveLocalAsset('pilauYaKuku'),
        'assets/images/pilau-ya-kuku.png');
    expect(DishImage.resolveLocalAsset('https://example.com/pilau.png'), isNull);
  });

  testWidgets('stagger reaches final state and bypasses reduced motion',
      (tester) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(milliseconds: 480),
    );
    addTearDown(controller.dispose);

    Future<void> show({bool reducedMotion = false}) => tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reducedMotion),
              child: StaggerIn(
                animation: controller,
                child: const Text('Chipsi Mayai'),
              ),
            ),
          ),
        );

    await show();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    controller.forward();
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    controller.value = 0;
    await show(reducedMotion: true);
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('Chipsi Mayai'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
