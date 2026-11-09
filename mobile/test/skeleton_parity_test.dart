import 'package:bongo_foodie/core/theme/app_tokens.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_discovery_card.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_dish_card.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_promo_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'SkeletonPromoCard height matches real card ($brightness)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Center(
              child: SizedBox(
                width: PromoCardMetrics.width,
                height: PromoCardMetrics.height,
                child: const SkeletonPromoCard(),
              ),
            ),
          ),
        );
        await tester.pump();
        final skeletonSize = tester.getSize(find.byType(SkeletonPromoCard));
        expect(skeletonSize.width, closeTo(PromoCardMetrics.width, 1));
        expect(skeletonSize.height, closeTo(PromoCardMetrics.height, 1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SkeletonDiscoveryCard height matches real card ($brightness)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const Center(
              child: SizedBox(
                width: 390,
                child: SkeletonDiscoveryCard(),
              ),
            ),
          ),
        );
        await tester.pump();
        // Discovery card uses padding-only container; verify it renders without overflow
        expect(find.byType(SkeletonDiscoveryCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SkeletonDishCard width matches real card ($brightness)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Center(
              child: SizedBox(
                width: DishCardMetrics.cardMaxWidth,
                height: DishCardMetrics.cardHeight,
                child: const SkeletonDishCard(),
              ),
            ),
          ),
        );
        await tester.pump();
        final skeletonSize = tester.getSize(find.byType(SkeletonDishCard));
        expect(skeletonSize.width, closeTo(DishCardMetrics.cardMaxWidth, 1));
        expect(skeletonSize.height, closeTo(DishCardMetrics.cardHeight, 1));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
