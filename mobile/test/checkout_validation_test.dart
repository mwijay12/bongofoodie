import 'package:bongo_foodie/core/utils/checkout_validation.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/order_repository.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const dish = MenuItemModel(
    id: 'demo-pilau',
    name: 'Pilau',
    description: '',
    imageUrl: '',
    price: 10000);
void main() {
  test('normalizes TZ mobile formats without inventing a number', () {
    for (final input in [
      '0712345678',
      '+255 712 345 678',
      '255712345678',
      '(0712) 345-678'
    ]) {
      expect(CheckoutValidation.normalizeTzPhone(input), '+255712345678');
    }
    for (final input in [
      '',
      '123',
      '+254712345678',
      '07123456789',
      '0712abc678',
      '+255212345678'
    ]) {
      expect(CheckoutValidation.normalizeTzPhone(input), isNull);
    }
    expect(CheckoutValidation.validName(''), isFalse);
    expect(CheckoutValidation.validName('12345'), isFalse);
    expect(CheckoutValidation.validName('Asha Juma'), isTrue);
    expect(CheckoutValidation.validAddress('Dar'), isFalse);
  });
  test('IDs have UUIDv4 entropy, not repeating timestamps', () {
    final ids = List.generate(1000, (_) => CheckoutValidation.newOrderId());
    expect(ids.toSet().length, ids.length);
    expect(
        ids.every((id) => RegExp(
                r'^BF-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')
            .hasMatch(id)),
        isTrue);
  });
  test('confirmation cannot erase a newer cart', () {
    final cart = CartNotifier();
    cart.addItem(dish: dish);
    final reviewed = cart.state;
    cart.incrementQuantity(reviewed.items.single.signatureKey);
    cart.clearConfirmedSnapshot(reviewed);
    expect(cart.state.totalItems, 2);
    cart.clearConfirmedSnapshot(cart.state);
    expect(cart.state.items, isEmpty);
    cart.dispose();
  });
  test('demo creation validates input and same-ID replay; no seeded orders',
      () async {
    SharedPreferences.setMockInitialValues({});
    final repo = OrderRepository();
    addTearDown(repo.dispose);
    expect(await repo.getOrdersForUser(null), isEmpty);
    final cart = CartNotifier();
    cart.addItem(dish: dish);
    addTearDown(cart.dispose);
    OrderModel order({String name = 'Asha Juma'}) => OrderModel(
        id: 'BF-demo-replay',
        customerName: name,
        customerPhone: '+255712345678',
        deliveryLocation: 'House 14, Kinondoni, Dar es Salaam',
        items: cart.state.items,
        totalPrice: cart.state.grandTotal,
        createdAt: DateTime.utc(2026));
    await expectLater(repo.createOrder(order(name: '')), throwsArgumentError);
    await repo.createOrder(order());
    await repo.createOrder(order());
    expect((await repo.getOrdersForUser(null)).length, 1);
    await expectLater(
        repo.createOrder(order(name: 'Other Person')), throwsStateError);
  });
}
