import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';

class CartState {
  final List<CartItemModel> items;
  final String appliedPromoCode;
  // Fixed v2: Promo discount ALWAYS starts at 0 until user explicitly applies a valid code
  final double promoDiscount;
  final double deliveryFee;

  const CartState({
    this.items = const [],
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
    String? appliedPromoCode,
    double? promoDiscount,
    double? deliveryFee,
  }) {
    return CartState(
      items: items ?? this.items,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      promoDiscount: promoDiscount ?? this.promoDiscount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void syncDeliveryFee(double fee) {
    if (fee >= 0 && fee != state.deliveryFee) {
      state = state.copyWith(deliveryFee: fee);
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
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;

    if (settings.promoActive &&
        normalized == settings.promoCode.trim().toUpperCase()) {
      state = state.copyWith(
        appliedPromoCode: normalized,
        promoDiscount: settings.promoDiscount,
      );
      return true;
    }

    if (normalized == 'KARIBU2000') {
      state = state.copyWith(
        appliedPromoCode: 'KARIBU2000',
        promoDiscount: 2000,
      );
      return true;
    }

    return false;
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
