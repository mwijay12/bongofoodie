import 'package:bongo_foodie/core/config/env_config.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'configured live cannot fall back to local orders or perform unsafe insert',
      () async {
    SharedPreferences.setMockInitialValues({});
    final repo = OrderRepository();
    addTearDown(repo.dispose);
    final order = OrderModel(
        id: 'test-only',
        items: const [],
        totalPrice: 0,
        deliveryLocation: '',
        createdAt: DateTime.utc(2026));
    await expectLater(
        repo.createOrder(order),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', 'live_checkout_not_available')));
    expect((await SharedPreferences.getInstance()).getString('bongo_orders_v2'),
        isNull);
  }, skip: !EnvConfig.hasSupabaseCredentials);
}
