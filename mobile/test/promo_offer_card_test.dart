import 'package:bongo_foodie/core/theme/app_colors.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/core/theme/app_tokens.dart';
import 'package:bongo_foodie/core/widgets/promo_offer_card.dart';
import 'package:bongo_foodie/core/widgets/promo_dish_image.dart';
import 'package:bongo_foodie/core/widgets/skeleton/skeleton_promo_card.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PromotionModel offer(bool sw, bool green) => PromotionModel(
    id: 'test',
    title: sw
        ? 'KARIBU CHAKULA CHA PWANI CHENYE LADHA'
        : 'KARIBU BONGO FEAST SAVE TWO THOUSAND TZS',
    subtitle: sw
        ? 'Tumia msimbo KARIBU2000 kupata punguzo la TSh 2,000 kwa chakula chako.'
        : 'Save TSh 2,000 on a Swahili main dish with code KARIBU2000 tonight.',
    discountBadge: 'TSh 2,000 OFF',
    imageKey: 'nyamaChoma',
    bgHex: green ? '#16694A' : '#F58220');

void main() {
  test('offer copy contrast reaches AA at both campaign endpoints', () {
    for (final entry in [
      (AppColors.ink, AppColors.promoOrange),
      (AppColors.surface, AppColors.promoGreen)
    ]) {
      for (final background in entry.$2.colors) {
        final a = entry.$1.computeLuminance();
        final b = background.computeLuminance();
        expect(((a > b ? a : b) + .05) / ((a < b ? a : b) + .05),
            greaterThanOrEqualTo(4.5));
      }
    }
  });
  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final dark in [false, true]) {
      for (final sw in [false, true]) {
        for (final green in [false, true]) {
          testWidgets('food-led offer $size dark=$dark sw=$sw green=$green',
              (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            addTearDown(semantics.dispose);
            var taps = 0;
            final promo = offer(sw, green);
            final action = sw ? 'Angalia menyu' : 'Explore the menu';
            await tester.pumpWidget(MaterialApp(
                theme: dark ? AppTheme.dark() : buildAppTheme(),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(1.3),
                        devicePixelRatio: 2,
                        disableAnimations: true),
                    child: child!),
                home: Scaffold(
                    body: Center(
                        child: PromoOfferCard(
                            promotion: promo,
                            actionLabel: action,
                            onTap: () => taps++)))));
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull);
            final card = tester.getRect(find.byType(PromoOfferCard));
            final art = tester.getRect(find.byType(PromoDishImage));
            final title = tester.getRect(find.text(promo.title));
            final subtitle = tester.getRect(find.text(promo.subtitle));
            expect(art.width, 148);
            expect(art.height, 148);
            expect(card.contains(art.topLeft) && card.contains(art.bottomRight),
                isTrue);
            expect(title.overlaps(art), isFalse);
            expect(subtitle.top, greaterThanOrEqualTo(art.bottom));
            final image = tester.widget<Image>(find.descendant(
                of: find.byType(PromoDishImage), matching: find.byType(Image)));
            expect(image.fit, BoxFit.contain);
            expect((image.image as ResizeImage).width, 296);
            expect(
                find.descendant(
                    of: find.byType(PromoDishImage),
                    matching: find.byType(ClipRRect)),
                findsNothing);
            final node = tester.getSemantics(find.byType(PromoOfferCard));
            expect(node.label, contains(promo.title));
            expect(node.label, contains(promo.subtitle));
            expect(node.label, contains(action));
            await tester.tap(find.byType(PromoOfferCard));
            expect(taps, 1);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(milliseconds: 50));
          });
        }
      }
    }
  }
  testWidgets('loading geometry matches real image and card metrics',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: Center(child: SkeletonPromoCard()))));
    final size = tester.getSize(find.byType(SkeletonPromoCard));
    expect(size, const Size(PromoCardMetrics.width, PromoCardMetrics.height));
    expect(PromoCardMetrics.imageSize, greaterThanOrEqualTo(148));
    expect(tester.takeException(), isNull);
  });
}
