import '../core/config/env_config.dart';
import '../data/repositories/reward_repository.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';

class CartState {
  final List<CartItemModel> items;
  final bool restoring;
  final String appliedPromoCode;
  // Fixed v2: Promo discount ALWAYS starts at 0 until user explicitly applies a valid code
  final double promoDiscount;
  final double deliveryFee;

  const CartState({
    this.items = const [],
    this.restoring = false,
    this.appliedPromoCode = '',
    this.promoDiscount = 0,
    this.deliveryFee = 2000,
  });

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get effectiveDeliveryFee => items.isEmpty ? 0 : deliveryFee;

  double get effectiveDiscount =>
      items.isEmpty ? 0 : promoDiscount.clamp(0, subtotal);

  double get grandTotal {
    if (items.isEmpty) return 0;
    final raw = subtotal + effectiveDeliveryFee - effectiveDiscount;
    return raw < 0 ? 0 : raw;
  }

  CartState copyWith({
    List<CartItemModel>? items,
    bool? restoring,
    String? appliedPromoCode,
    double? promoDiscount,
    double? deliveryFee,
  }) {
    return CartState(
      items: items ?? this.items,
      restoring: restoring ?? this.restoring,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final notifier = CartNotifier(
      persist: true, owner: ref.read(authProvider).user?.id ?? 'guest');
  ref.listen<String?>(authProvider.select((a) => a.user?.id), (previous, next) {
    if (previous != next) notifier.changeOwner(next ?? 'guest');
  });
  return notifier;
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier(
      {bool persist = false, String owner = 'guest', bool? liveRewards})
      : _liveRewards = liveRewards ?? EnvConfig.hasSupabaseCredentials,
        _persist = persist,
        _owner = owner,
        super(CartState(restoring: persist)) {
    _restoring = persist;
    ready = persist ? _restore() : Future<void>.value();
  }
  final bool _persist;
  final bool _liveRewards;
  String _owner;
  int _revision = 0;
  Future<void> _writes = Future<void>.value();
  late Future<void> ready;
  bool _restoring = false;
  String? _pendingOwner;
  Future<void> get flushed => _writes;
  String get _key => 'bongo_cart_v1:$_owner';

  @override
  set state(CartState value) {
    if (!identical(value.items, state.items) ||
        value.deliveryFee != state.deliveryFee) {
      value = value.copyWith(appliedPromoCode: '', promoDiscount: 0);
    }
    super.state = value;
    _revision++;
    if (!_persist) return;
    final key = _key;
    // Discounts and fees are deliberately not restored as live entitlements.
    final payload = jsonEncode(
        {'version': 1, 'items': value.items.map((i) => i.toJson()).toList()});
    _writes = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, payload);
    }).catchError((Object _) {
      /* Keep in-memory editing usable on disk failure. */
    });
  }

  Future<void> _restore() async {
    final revision = _revision;
    final owner = _owner;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['version'] != 1) return;
      final rows = json['items'] as List;
      final items = rows
          .map((r) =>
              CartItemModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .where((i) =>
              i.id.isNotEmpty &&
              i.price.isFinite &&
              i.price >= 0 &&
              i.customizations.every((c) => c.price.isFinite && c.price >= 0))
          .map((i) => i.copyWith(quantity: i.quantity.clamp(1, 20)))
          .toList();
      if (mounted && owner == _owner && revision == _revision) {
        super.state = CartState(items: items, deliveryFee: state.deliveryFee);
      }
    } catch (_) {
      /* Corrupt or unavailable local data is not an order failure. */
    } finally {
      _restoring = false;
      if (mounted) super.state = state.copyWith(restoring: false);
    }
  }

  /// Carry guest selections into login; never expose a previous account's cart.
  void changeOwner(String next) {
    if (_restoring) {
      _pendingOwner = next;
      ready.then((_) {
        if (mounted && _pendingOwner == next) changeOwner(next);
      });
      return;
    }
    if (next == _owner) return;
    final previousKey = _key;
    final wasGuest = _owner == 'guest';
    _owner = next;
    _revision++;
    if (_persist) {
      _writes = _writes.then((_) async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(previousKey);
      }).catchError((Object _) {});
    }
    if (wasGuest && next != 'guest' && state.items.isNotEmpty) {
      state = state; // Preserve the current guest cart on optional sign-in.
    } else {
      super.state = CartState(restoring: _persist);
      if (_persist) {
        _restoring = true;
        ready = _restore();
      }
    }
  }

  void syncDeliveryFee(double fee) {
    if (fee >= 0 && fee != state.deliveryFee) {
      // A fee refresh must not overwrite a cart while its disk restore is pending.
      super.state = state.copyWith(deliveryFee: fee);
    }
  }

  void addItem({
    required MenuItemModel dish,
    int quantity = 1,
    List<CustomizationOption> customizations = const [],
    bool isCustomAiDish = false,
  }) {
    final candidate = CartItemModel(
      id: dish.id,
      name: dish.name,
      price: dish.price,
      imageUrl: dish.imageUrl,
      quantity: quantity.clamp(1, 20),
      customizations: customizations,
      isAiCreated: isCustomAiDish,
    );

    final existingIdx =
        state.items.indexWhere((i) => i.signatureKey == candidate.signatureKey);

    if (existingIdx >= 0) {
      final updated = List<CartItemModel>.from(state.items);
      final current = updated[existingIdx];
      updated[existingIdx] = current.copyWith(
          quantity: (current.quantity + quantity).clamp(1, 20));
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, candidate]);
    }
  }

  void incrementQuantity(String signatureKey) {
    final updated = state.items.map((item) {
      if (item.signatureKey == signatureKey) {
        return item.copyWith(quantity: (item.quantity + 1).clamp(1, 20));
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void decrementQuantity(String signatureKey) {
    final updated = <CartItemModel>[];
    for (final item in state.items) {
      if (item.signatureKey != signatureKey) {
        updated.add(item);
      } else {
        updated.add(item.copyWith(quantity: (item.quantity - 1).clamp(1, 20)));
      }
    }
    state = state.copyWith(
      items: updated,
      appliedPromoCode: updated.isEmpty ? '' : state.appliedPromoCode,
      promoDiscount: updated.isEmpty ? 0 : state.promoDiscount,
    );
  }

  void removeItem(String signatureKey) {
    final updated =
        state.items.where((i) => i.signatureKey != signatureKey).toList();
    state = state.copyWith(
      items: updated,
      appliedPromoCode: updated.isEmpty ? '' : state.appliedPromoCode,
      promoDiscount: updated.isEmpty ? 0 : state.promoDiscount,
    );
  }

  /// Restore one removed line without discarding subsequent cart edits.
  void restoreItem(CartItemModel item, {required int index}) {
    final updated = List<CartItemModel>.from(state.items);
    final existing =
        updated.indexWhere((i) => i.signatureKey == item.signatureKey);
    if (existing >= 0) {
      updated[existing] = updated[existing].copyWith(
        quantity: (updated[existing].quantity + item.quantity).clamp(1, 20),
      );
    } else {
      updated.insert(index.clamp(0, updated.length), item);
    }
    state = state.copyWith(items: updated);
  }

  bool applyPromoCode({
    required String code,
    required BranchSettingsModel settings,
  }) {
    removePromoCode();
    final normalized = code.trim().toUpperCase();
    if (_liveRewards ||
        state.items.isEmpty ||
        normalized.isEmpty ||
        !settings.promoActive ||
        !settings.promoDiscount.isFinite ||
        settings.promoDiscount <= 0 ||
        normalized != settings.promoCode.trim().toUpperCase()) return false;
    state = state.copyWith(
        appliedPromoCode: normalized, promoDiscount: settings.promoDiscount);
    return true;
  }

  /// Quote is provisional. The database revalidates and consumes at order insert.
  Future<bool> applyLivePromo(String code, RewardRepository repository) async {
    removePromoCode();
    final revision = _revision;
    final owner = _owner;
    final snapshot = state;
    if (!_liveRewards || snapshot.items.isEmpty) return false;
    final quote = await repository.quote(code, snapshot.items);
    if (!mounted || revision != _revision || owner != _owner) return false;
    if (quote.code != code.trim().toUpperCase() ||
        !quote.discount.isFinite ||
        quote.discount <= 0 ||
        quote.discount > snapshot.subtotal ||
        quote.subtotal != snapshot.subtotal ||
        quote.deliveryFee != snapshot.effectiveDeliveryFee) return false;
    state = state.copyWith(
        appliedPromoCode: quote.code, promoDiscount: quote.discount);
    return true;
  }

  void removePromoCode() {
    state = state.copyWith(appliedPromoCode: '', promoDiscount: 0);
  }

  void clearCart() {
    state = state.copyWith(
      items: const [],
      appliedPromoCode: '',
      promoDiscount: 0,
    );
  }
}
