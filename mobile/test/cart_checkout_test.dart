import 'dart:async';
import 'package:bongo_foodie/core/l10n/app_strings.dart';
import 'package:bongo_foodie/core/theme/app_theme.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/order_repository.dart';
import 'package:bongo_foodie/features/cart/cart_screen.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:bongo_foodie/state/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dish = MenuItemModel(
    id: 'menu-pilau-kuku',
    name: 'Pilau',
    description: 'Pilau',
    imageUrl: '',
    price: 10000);

class _Orders extends OrderRepository {
  int writes = 0;
  Completer<OrderModel> pending = Completer<OrderModel>();
  OrderModel? submitted;
  @override
  Future<List<OrderModel>> getOrdersForUser(String? userId) async => [];
  @override
  Future<OrderModel> createOrder(OrderModel order) {
    writes++;
    submitted = order;
    return pending.future;
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Size size = const Size(360, 640),
  bool dark = false,
  AppLanguage language = AppLanguage.en,
  _Orders? orders,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(overrides: [
    appStringsProvider.overrideWithValue(AppStrings(language)),
    branchSettingsProvider
        .overrideWith((ref) async => const BranchSettingsModel()),
    if (orders != null) orderRepositoryProvider.overrideWithValue(orders),
  ]);
  addTearDown(container.dispose);
  if (orders != null) addTearDown(orders.dispose);
  container.read(cartProvider.notifier).addItem(
      dish: _dish,
      customizations: const [
        CustomizationOption(
            id: 'extra', name: 'Mboga za majani / greens', price: 1000)
      ]);
  await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          theme: dark ? AppTheme.dark() : buildAppTheme(),
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.3),
                  disableAnimations: true),
              child: child!),
          home: const CartScreen())));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  return container;
}

void main() {
  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final dark in [false, true]) {
      for (final language in AppLanguage.values) {
        testWidgets('cart $size dark=$dark $language at text 1.3',
            (tester) async {
          await _pump(tester, size: size, dark: dark, language: language);
          expect(find.byKey(const ValueKey('place-order')).hitTestable(),
              findsOneWidget);
          expect(
              tester
                  .getSize(find.byTooltip(language == AppLanguage.sw
                      ? 'Ongeza idadi'
                      : 'Increase quantity'))
                  .shortestSide,
              greaterThanOrEqualTo(48));
          for (var i = 0; i < 7; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -260));
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 50));
        });
      }
    }
  }
  testWidgets('remove and undo restore the exact line within five seconds',
      (tester) async {
    final container = await _pump(tester);
    final before = container.read(cartProvider).items.single;
    await tester.tap(find.text('Remove'));
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(cartProvider).items, isEmpty);
    expect(find.text('Undo').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 400));
    expect(container.read(cartProvider).items.single, same(before));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
  testWidgets(
      'pending write rejects double tap; failure retains cart; retry clears only on success',
      (tester) async {
    final orders = _Orders();
    final container = await _pump(tester, orders: orders);
    final button = find.byKey(const ValueKey('place-order'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    expect(orders.writes, 1);
    expect(container.read(cartProvider).items, isNotEmpty);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
        orders.submitted!.totalPrice, container.read(cartProvider).grandTotal);
    orders.pending.completeError(Exception('insert rejected'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(cartProvider).items, isNotEmpty);
    expect(find.textContaining('Your cart is saved'), findsOneWidget);
    orders.pending = Completer<OrderModel>();
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    expect(orders.writes, 2);
    orders.pending.complete(orders.submitted!);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(cartProvider).items, isEmpty);
    expect(find.text('Track Order'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
