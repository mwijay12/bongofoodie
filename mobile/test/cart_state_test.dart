import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const dish = MenuItemModel(
    id: 'test',
    name: 'Pilau',
    description: 'Pilau',
    imageUrl: '',
    price: 10000);

void main() {
  test('totals include addons per unit, fee and capped discount', () {
    final cart = CartNotifier();
    addTearDown(cart.dispose);
    cart.addItem(dish: dish, quantity: 2, customizations: const [
      CustomizationOption(id: 'extra', name: 'Extra', price: 1000),
    ]);
    expect(cart.state.subtotal, 22000);
    cart.syncDeliveryFee(3000);
    cart.applyPromoCode(
        code: 'KARIBU2000', settings: const BranchSettingsModel());
    expect(cart.state.grandTotal, 23000);
    cart.clearCart();
    expect(cart.state.grandTotal, 0);
    expect(cart.state.effectiveDeliveryFee, 0);
    expect(cart.state.effectiveDiscount, 0);
  });
  test('quantity stays in 1–20 and decrement does not remove the last unit',
      () {
    final cart = CartNotifier();
    addTearDown(cart.dispose);
    cart.addItem(dish: dish, quantity: 0);
    final key = cart.state.items.single.signatureKey;
    cart.decrementQuantity(key);
    expect(cart.state.items.single.quantity, 1);
    cart.addItem(dish: dish, quantity: 50);
    cart.incrementQuantity(key);
    expect(cart.state.items.single.quantity, 20);
  });
  test('restore preserves line snapshots and merges subsequent additions', () {
    final cart = CartNotifier();
    addTearDown(cart.dispose);
    cart.addItem(dish: dish, quantity: 2);
    final removed = cart.state.items.single;
    cart.removeItem(removed.signatureKey);
    cart.addItem(dish: dish);
    cart.restoreItem(removed, index: 0);
    expect(cart.state.items.single.quantity, 3);
    expect(cart.state.items.single.price, dish.price);
  });
}
