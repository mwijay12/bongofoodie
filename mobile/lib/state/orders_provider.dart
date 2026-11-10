import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/repositories/order_repository.dart';
import 'auth_provider.dart';

final userOrdersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final user = ref.watch(authProvider.select((a) => a.user));
  return OrdersNotifier(repo, user?.id, staffMode: false);
});

final staffOrdersProvider =
    StateNotifierProvider<OrdersNotifier, AsyncValue<List<OrderModel>>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final user = ref.watch(authProvider.select((a) => a.user));
  return OrdersNotifier(repo, user?.id, staffMode: true);
});

class OrdersNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository _repo;
  final String? _userId;
  final bool staffMode;
  StreamSubscription<List<OrderModel>>? _sub;

  OrdersNotifier(this._repo, this._userId, {required this.staffMode})
      : super(const AsyncValue.loading()) {
    refresh();
    _sub = _repo.ordersStream.listen((allOrders) {
      if (staffMode || _userId == null || _userId!.startsWith('demo-')) {
        state = AsyncValue.data(allOrders);
      } else {
        state = AsyncValue.data(
          allOrders.where((o) => o.profileId == _userId).toList(),
        );
      }
    });
  }

  Future<void> refresh() async {
    try {
      final list = staffMode
          ? await _repo.getAllOrders()
          : await _repo.getOrdersForUser(_userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<OrderModel> placeOrder(OrderModel order) async {
    final created = await _repo.createOrder(order);
    if (!mounted) return created;
    // Confirmation is the write response, not a second potentially slow read.
    final previous = state.valueOrNull ?? const <OrderModel>[];
    state = AsyncValue.data(
        [created, ...previous.where((o) => o.id != created.id)]);
    return created;
  }

  Future<void> advanceStatus(String orderId, OrderStatus nextStatus) async {
    await _repo.updateOrderStatus(orderId, nextStatus);
    await refresh();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
