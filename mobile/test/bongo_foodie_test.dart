import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/data/mock/showcase_seed_data.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/chef_ai_repository.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/main.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CartNotifier v2 Pricing & Promo Logic', () {
    test('starts with 0 promoDiscount (no phantom -1000 discount)', () {
      final cart = CartNotifier();
      final nyama = ShowcaseSeedData.menuItems.first;

      cart.addItem(dish: nyama, quantity: 1);

      expect(cart.state.promoDiscount, 0);
      expect(cart.state.subtotal, nyama.price);
      expect(cart.state.grandTotal, nyama.price + 2000);
    });

    test('includes customization fees transparently and validates KARIBU2000', () {
      final cart = CartNotifier();
      final pilau = ShowcaseSeedData.menuItems[1];
      const extraSide = CustomizationOption(
        id: 'cust-kachumbari',
        name: 'Kachumbari Extra',
        price: 1000,
      );

      cart.addItem(
        dish: pilau,
        quantity: 2,
        customizations: const [extraSide],
      );

      // (13,500 + 1,000) * 2 = 29,000
      expect(cart.state.subtotal, 29000);

      final invalid = cart.applyPromoCode(
        code: 'FAKECODE',
        settings: const BranchSettingsModel(),
      );
      expect(invalid, isFalse);
      expect(cart.state.effectiveDiscount, 0);

      final valid = cart.applyPromoCode(
        code: 'karibu2000',
        settings: const BranchSettingsModel(),
      );
      expect(valid, isTrue);
      expect(cart.state.effectiveDiscount, 2000);
      // 29,000 subtotal + 2,000 delivery - 2,000 discount = 29,000
      expect(cart.state.grandTotal, 29000);
    });
  });

  group('MenuRepository & ChefAiRepository Showcase Fallbacks', () {
    test('filters menu accurately by both Category Name and Category ID', () async {
      final repo = MenuRepository();
      final byName = await repo.getMenu(category: 'Nyama Choma');
      final byId = await repo.getMenu(category: 'cat-choma');

      expect(byName, isNotEmpty);
      expect(byId.length, byName.length);
      expect(byName.every((m) => m.categoryName == 'Nyama Choma'), isTrue);
    });

    test('Chef AI composes custom Swahili dish offline without API keys', () async {
      final chef = ChefAiRepository();
      final dish = await chef.designCustomDish('Grilled samaki with coconut');

      expect(dish.name, isNotEmpty);
      expect(dish.price, greaterThan(0));
      expect(AppStrings.formatTzs(dish.price), startsWith('TSh '));
    });
  });

  testWidgets('BongoFoodieApp boots cleanly into Onboarding Showcase',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BongoFoodieApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BongoFoodie'), findsWidgets);
  });
}
