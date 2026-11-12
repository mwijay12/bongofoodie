import 'package:bongo_foodie/core/utils/addon_selection.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/mock/showcase_seed_data.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/state/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

const extra = CustomizationOption(id: 'extra', name: 'Lime', price: 300);
const dish = MenuItemModel(
    id: 'dish', name: 'Fish', description: '', imageUrl: '', price: 10000);
void main() {
  test('successful empty joins stay empty, malformed is not free addons', () {
    expect(linkedAddonsFromRows([]), isEmpty);
    for (final input in [
      null,
      {},
      [
        {'customizations': null}
      ],
      [
        {
          'customizations': {'id': 'x', 'name': 'Extra'}
        }
      ]
    ]) {
      expect(() => linkedAddonsFromRows(input), throwsFormatException);
    }
  });
  test('drinks and unknown products have no fallback sides', () async {
    final repo = MenuRepository(showcaseLatency: Duration.zero);
    for (final id in ['menu-stoney', 'menu-passion-juice', 'unknown']) {
      expect(await repo.getDishCustomizations(id), isEmpty);
    }
    expect(
        (await repo.getDishCustomizations('menu-nyama-choma')).map((c) => c.id),
        contains('cust-ugali'));
    expect(
        (await repo.getDishCustomizations('menu-bongo-burger'))
            .map((c) => c.id),
        isNot(contains('cust-ugali')));
    // Chipsi mayai has four valid addons; the point is that they are the
    // curated ones for that dish, not the grill list.
    expect(
        (await repo.getDishCustomizations('menu-chipsi-mayai'))
            .map((c) => c.id)
            .toSet(),
        {'cust-kachumbari', 'cust-pilipili', 'cust-ndimu', 'cust-stoney'});
  });
  test('seed product options each have unique IDs and valid prices', () {
    for (final item in ShowcaseSeedData.menuItems) {
      expect(validatedAddons(item.availableCustomizations).length,
          item.availableCustomizations.length);
    }
  });
  test('duplicate selections charge once per unit and conflicting IDs fail',
      () {
    expect(validatedAddons([extra, extra]), [extra]);
    expect(
        () => validatedAddons([
              extra,
              const CustomizationOption(id: 'extra', name: 'Lime', price: 500)
            ]),
        throwsFormatException);
    for (final price in [-1.0, double.nan, double.infinity]) {
      expect(
          () => validatedAddons(
              [CustomizationOption(id: 'x', name: 'X', price: price)]),
          throwsFormatException);
    }
    final cart = CartNotifier();
    addTearDown(cart.dispose);
    cart.addItem(dish: dish, quantity: 2, customizations: [extra, extra]);
    expect(cart.state.items.single.customizations.length, 1);
    expect(cart.state.subtotal, 20600);
    cart.addItem(dish: dish, customizations: const [
      CustomizationOption(id: 'extra', name: 'Lime', price: 500)
    ]);
    expect(cart.state.items.single.quantity, 3);
    expect(cart.state.subtotal, 31500);
  });
}
