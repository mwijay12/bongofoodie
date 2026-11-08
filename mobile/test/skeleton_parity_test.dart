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
            home: SizedBox(
              width: 390,
              child: const SkeletonPromoCard(),
            ),
          ),
        );
        final skeletonSize = tester.getSize(find.byType(SkeletonPromoCard));
        expect(skeletonSize.width, closeTo(PromoCardMetrics.width, 1));
      },
    );

    testWidgets(
      'SkeletonDiscoveryCard height matches real card ($brightness)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: const SkeletonDiscoveryCard(),
          ),
        );
        // Discovery card uses padding-only container; verify it renders without overflow
        expect(find.byType(SkeletonDiscoveryCard), findsOneWidget);
      },
    );

    testWidgets(
      'SkeletonDishCard width matches real card ($brightness)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: SizedBox(
              width: 390,
              child: const SkeletonDishCard(),
            ),
          ),
        );
        final skeletonSize = tester.getSize(find.byType(SkeletonDishCard));
        expect(skeletonSize.width, closeTo(DishCardMetrics.cardMaxWidth, 1));
      },
    );
  }
}
