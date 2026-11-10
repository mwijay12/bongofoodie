import 'dart:async';
import '../../core/config/env_config.dart';
import '../../core/utils/checkout_validation.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../models/models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final repo = OrderRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

class OrderRepository {
  static const _ordersPrefKey = 'bongo_orders_v2';

  final StreamController<List<OrderModel>> _ordersStreamController =
      StreamController<List<OrderModel>>.broadcast();
  RealtimeChannel? _realtimeChannel;

  OrderRepository() {
    _initRealtimeIfAvailable();
  }

  Stream<List<OrderModel>> get ordersStream => _ordersStreamController.stream;

  void _initRealtimeIfAvailable() {
    final sb = SupabaseService.client;
    if (sb == null) return;

    try {
      _realtimeChannel = sb
          .channel('bongo-mobile-orders')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (_) async {
              final latest = await getAllOrders();
              if (!_ordersStreamController.isClosed) {
                _ordersStreamController.add(latest);
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<List<OrderModel>> _loadLocalOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersPrefKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        return decoded
            .whereType<Map>()
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> _saveLocalOrders(List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordersPrefKey,
      jsonEncode(orders.map((o) => o.toLocalJson()).toList()),
    );
    if (!_ordersStreamController.isClosed) {
      _ordersStreamController.add(orders);
    }
  }

  Future<OrderModel> createOrder(OrderModel order) async {
    // Fail closed until server totals, ownership, service-area and replay contracts
    // are implemented/deployed. A configured-but-unavailable client is not demo.
    if (EnvConfig.hasSupabaseCredentials || SupabaseService.client != null) {
      throw StateError('live_checkout_not_available');
    }
    if (!CheckoutValidation.validName(order.customerName) ||
        CheckoutValidation.normalizeTzPhone(order.customerPhone) == null ||
        !CheckoutValidation.validAddress(order.deliveryLocation) ||
        order.items.isEmpty ||
        !order.totalPrice.isFinite ||
        order.totalPrice < 0 ||
        order.status != OrderStatus.pending) {
      throw ArgumentError('invalid_demo_checkout');
    }
    final local = await _loadLocalOrders();
    for (final previous in local) {
      if (previous.id == order.id) {
        if (jsonEncode(previous.toLocalJson()) !=
            jsonEncode(order.toLocalJson())) {
          throw StateError('order_id_payload_mismatch');
        }
        return previous;
      }
    }
    await _saveLocalOrders([order, ...local]);
    return order;
  }

  Future<List<OrderModel>> getOrdersForUser(String? userId) async {
    final sb = SupabaseService.client;
    if (sb != null && userId != null && !userId.startsWith('demo-')) {
      try {
        final rows = await sb
            .from('orders')
            .select('*')
            .eq('profile_id', userId)
            .order('created_at', ascending: false);
        if (rows.isNotEmpty) {
          return rows
              .map<OrderModel>(
                  (r) => OrderModel.fromJson(Map<String, dynamic>.from(r)))
              .toList();
        }
      } catch (_) {}
    }

    final local = await _loadLocalOrders();
    if (userId == null || userId.startsWith('demo-')) {
      return local;
    }
    return local.where((o) => o.profileId == userId).toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final sb = SupabaseService.client;
    if (sb != null) {
      try {
        final rows = await sb
            .from('orders')
            .select('*')
            .order('created_at', ascending: false)
            .limit(40);
        if (rows.isNotEmpty) {
          return rows
              .map<OrderModel>(
                  (r) => OrderModel.fromJson(Map<String, dynamic>.from(r)))
              .toList();
        }
      } catch (_) {}
    }
    return _loadLocalOrders();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus nextStatus) async {
    final local = await _loadLocalOrders();
    final updated = local
        .map((o) => o.id == orderId ? o.copyWith(status: nextStatus) : o)
        .toList();
    await _saveLocalOrders(updated);

    final sb = SupabaseService.client;
    if (sb != null) {
      try {
        await sb.from('orders').update({
          'status': nextStatus.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', orderId);
      } catch (_) {}
    }
  }

  void dispose() {
    final sb = SupabaseService.client;
    if (sb != null && _realtimeChannel != null) {
      sb.removeChannel(_realtimeChannel!);
    }
    _ordersStreamController.close();
  }
}
