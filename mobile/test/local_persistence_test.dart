import 'dart:convert';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:bongo_foodie/core/utils/local_snapshot.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/location_repository.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const dish = MenuItemModel(
    id: 'pilau', name: 'Pilau', description: '', imageUrl: '', price: 8000);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('preference hydration cannot undo immediate user choices', () async {
    final settings = AppSettingsNotifier();
    await Future.wait([
      settings.completeOnboarding(),
      settings.setLanguage(AppLanguage.sw),
      settings.toggleDarkMode(true),
    ]);
    expect(settings.state.hasSeenOnboarding, isTrue);
    expect(settings.state.language, AppLanguage.sw);
    expect(settings.state.themeMode, ThemeMode.dark);
    settings.dispose();
  });
  test('cart restart preserves variants/quantity, not promo entitlement',
      () async {
    final first = CartNotifier(persist: true);
    await first.ready;
    first.addItem(dish: dish, quantity: 3, customizations: const [
      CustomizationOption(id: 'extra', name: 'Extra', price: 500)
    ]);
    first.applyPromoCode(
        code: 'KARIBU2000', settings: const BranchSettingsModel());
    await first.flushed;
    first.dispose();
    final second = CartNotifier(persist: true);
    await second.ready;
    expect(second.state.items.single.quantity, 3);
    expect(second.state.subtotal, 25500);
    expect(second.state.promoDiscount, 0);
    second.clearCart();
    await second.flushed;
    second.dispose();
    final third = CartNotifier(persist: true);
    await third.ready;
    expect(third.state.items, isEmpty);
    third.dispose();
  });
  test('edit and fee refresh during restore cannot erase current selections',
      () async {
    final first = CartNotifier(persist: true);
    first.addItem(dish: dish);
    first.syncDeliveryFee(3000);
    await first.ready;
    await first.flushed;
    expect(first.state.items.single.id, dish.id);
    first.dispose();
    final second = CartNotifier(persist: true);
    second.syncDeliveryFee(4000);
    await second.ready;
    expect(second.state.items.single.id, dish.id);
    expect(second.state.deliveryFee, 4000);
    second.dispose();
  });
  test('guest login carries cart, signout and account switch isolate it',
      () async {
    final cart = CartNotifier(persist: true);
    await cart.ready;
    cart.addItem(dish: dish);
    cart.changeOwner('user-a');
    await cart.flushed;
    expect(cart.state.totalItems, 1);
    final restart = CartNotifier(persist: true, owner: 'user-a');
    await restart.ready;
    expect(restart.state.totalItems, 1);
    restart.dispose();
    cart.changeOwner('guest');
    await cart.ready;
    await cart.flushed;
    expect(cart.state.items, isEmpty);
    cart.changeOwner('user-b');
    await cart.ready;
    expect(cart.state.items, isEmpty);
    cart.dispose();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('bongo_cart_v1:user-a'), isNull);
  });
  test('corrupt and unsupported cart snapshots fail safely', () async {
    final prefs = await SharedPreferences.getInstance();
    for (final raw in [
      'broken',
      jsonEncode({'version': 99, 'items': []})
    ]) {
      await prefs.setString('bongo_cart_v1:guest', raw);
      final cart = CartNotifier(persist: true);
      await cart.ready;
      expect(cart.state.items, isEmpty);
      cart.dispose();
    }
  });
  test('snapshot versions, empty data, freshness, retention and clock rollback',
      () async {
    var now = DateTime.utc(2026, 11, 9);
    final store = LocalSnapshot(now: () => now);
    await store.write('menu', []);
    expect((await store.read('menu'))!.data, isEmpty);
    expect((await store.read('menu'))!.stale, isFalse);
    now = now.add(const Duration(minutes: 16));
    expect((await store.read('menu'))!.stale, isTrue);
    now = now.add(const Duration(days: 8));
    expect(await store.read('menu'), isNull);
    await store.write('menu', [1]);
    now = now.subtract(const Duration(days: 1));
    expect(await store.read('menu'), isNull);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bongo_snapshot_v1:menu', 'bad');
    expect(await store.read('menu'), isNull);
    expect(prefs.getString('bongo_snapshot_v1:menu'), isNull);
  });
  test(
      'structured location survives restart and private address can be cleared',
      () async {
    final first = DeliveryAddressNotifier();
    await first.saveSelection(
        region: 7,
        district: 701,
        ward: 70101,
        street: 'Near market',
        address: 'Near market, Kijitonyama');
    final second = DeliveryAddressNotifier();
    final saved = await second.readSelection();
    expect(saved!['ward'], 70101);
    expect(saved['street'], 'Near market');
    await second.clearPrivateAddress();
    expect(await second.readSelection(), isNull);
    first.dispose();
    second.dispose();
  });
}
