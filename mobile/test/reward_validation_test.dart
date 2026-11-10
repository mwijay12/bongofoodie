import 'dart:async';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/data/repositories/reward_repository.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const dish = MenuItemModel(
    id: 'dish', name: 'Pilau', description: '', imageUrl: '', price: 10000);

class Quotes extends RewardRepository {
  final pending = Completer<RewardQuote>();
  @override
  Future<RewardQuote> quote(String code, List<CartItemModel> items) =>
      pending.future;
}

const valid = RewardQuote(
    code: 'TEST', subtotal: 10000, deliveryFee: 2000, discount: 2000);
void main() {
  test('live sync path cannot accept configured or hardcoded codes', () {
    final cart = CartNotifier(liveRewards: true);
    addTearDown(cart.dispose);
    cart.addItem(dish: dish);
    expect(
        cart.applyPromoCode(
            code: 'KARIBU2000', settings: const BranchSettingsModel()),
        isFalse);
    expect(cart.state.effectiveDiscount, 0);
  });
  test('inactive demo settings cannot be bypassed by legacy code', () {
    final cart = CartNotifier(liveRewards: false);
    addTearDown(cart.dispose);
    cart.addItem(dish: dish);
    expect(
        cart.applyPromoCode(
            code: 'KARIBU2000',
            settings: const BranchSettingsModel(promoActive: false)),
        isFalse);
  });
  test('quote applies once then any basket or fee change invalidates it',
      () async {
    final cart = CartNotifier(liveRewards: true);
    addTearDown(cart.dispose);
    cart.addItem(dish: dish);
    final repo = Quotes();
    final applied = cart.applyLivePromo(' test ', repo);
    repo.pending.complete(valid);
    expect(await applied, isTrue);
    expect(cart.state.effectiveDiscount, 2000);
    cart.syncDeliveryFee(3000);
    expect(cart.state.effectiveDiscount, 0);
  });
  for (final change in ['quantity', 'owner', 'fee', 'remove']) {
    test('late quote rejected after $change change', () async {
      final cart = CartNotifier(liveRewards: true);
      addTearDown(cart.dispose);
      cart.addItem(dish: dish);
      final repo = Quotes();
      final pending = cart.applyLivePromo('TEST', repo);
      switch (change) {
        case 'quantity':
          cart.incrementQuantity(cart.state.items.single.signatureKey);
        case 'owner':
          cart.changeOwner('other');
        case 'fee':
          cart.syncDeliveryFee(3000);
        case 'remove':
          cart.removeItem(cart.state.items.single.signatureKey);
      }
      repo.pending.complete(valid);
      expect(await pending, isFalse);
      expect(cart.state.effectiveDiscount, 0);
    });
  }
  for (final discount in [double.nan, double.infinity, -1.0, 10001.0]) {
    test('invalid quote amount $discount is rejected', () async {
      final cart = CartNotifier(liveRewards: true);
      addTearDown(cart.dispose);
      cart.addItem(dish: dish);
      final repo = Quotes();
      final pending = cart.applyLivePromo('TEST', repo);
      repo.pending.complete(RewardQuote(
          code: 'TEST',
          subtotal: 10000,
          deliveryFee: 2000,
          discount: discount));
      expect(await pending, isFalse);
    });
  }
  test('legacy fabricated wins ignored and demo replay cannot earn twice',
      () async {
    SharedPreferences.setMockInitialValues({'bongo_quiz_wins_v2': 99});
    final repo = MenuRepository();
    expect(await repo.getTriviaWinsCount(), 0);
    await repo.recordTriviaAttempt(null, true);
    await repo.recordTriviaAttempt(null, true);
    expect(await repo.getTriviaWinsCount(), 1);
  });
}
