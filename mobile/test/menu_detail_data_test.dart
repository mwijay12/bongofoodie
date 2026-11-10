import 'package:bongo_foodie/data/mock/showcase_seed_data.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:bongo_foodie/data/repositories/menu_repository.dart';
import 'package:bongo_foodie/state/menu_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _baseMenuItemJson() => <String, dynamic>{
      'id': 'menu-detail',
      'name': 'Detail Dish',
      'description': 'A dish used for data layer checks.',
      'image_url': 'detailDish',
      'price': 7500,
      'rating': 4.7,
      'rating_count': 21,
      'calories': 500,
      'protein': 22,
      'prep_time_mins': 18,
      'category_id': 'cat-bites',
      'categories': <String, dynamic>{
        'id': 'cat-bites',
        'name': 'Swahili Bites'
      },
    };

void main() {
  test('MenuItemModel.fromJson parses detail fields and nested relations', () {
    final json = _baseMenuItemJson()
      ..addAll(<String, dynamic>{
        'spice_level': 3,
        'ingredients': <String>['rice', 'coconut milk'],
        'allergens': <String>['coconut'],
        'fun_fact_en': 'Coconut milk is used in coastal cooking.',
        'fun_fact_sw': 'Tui la nazi hutumika katika mapishi ya pwani.',
        'available_customizations': <Map<String, dynamic>>[
          <String, dynamic>{
            'customizations': <String, dynamic>{
              'id': 'opt-coconut',
              'name': 'Extra coconut',
              'price': 500,
              'type': 'side',
            },
          },
        ],
      });

    final item = MenuItemModel.fromJson(json);

    expect(item.id, 'menu-detail');
    expect(item.categoryId, 'cat-bites');
    expect(item.categoryName, 'Swahili Bites');
    expect(item.spiceLevel, 3);
    expect(item.ingredients, <String>['rice', 'coconut milk']);
    expect(item.allergens, <String>['coconut']);
    expect(item.funFactEn, 'Coconut milk is used in coastal cooking.');
    expect(item.funFactSw, 'Tui la nazi hutumika katika mapishi ya pwani.');
    expect(item.availableCustomizations.single.id, 'opt-coconut');
  });

  test('MenuItemModel.fromJson uses safe defaults without detail fields', () {
    final item = MenuItemModel.fromJson(_baseMenuItemJson());

    expect(item.spiceLevel, isNull);
    expect(item.ingredients, isEmpty);
    expect(item.allergens, isEmpty);
    expect(item.funFactEn, isNull);
    expect(item.funFactSw, isNull);
    expect(item.availableCustomizations, isEmpty);
  });

  test('MenuItemModel.toJson and copyWith keep detail fields', () {
    final item = MenuItemModel.fromJson(
      _baseMenuItemJson()
        ..addAll(<String, dynamic>{
          'spice_level': 2,
          'ingredients': <String>['plantain'],
          'allergens': <String>[],
          'fun_fact_en': 'Ripe plantains are sweet.',
          'fun_fact_sw': 'Ndizi mbivu ni tamu.',
        }),
    );

    final json = item.toJson();
    expect(json['spice_level'], 2);
    expect(json['ingredients'], <String>['plantain']);
    expect(json['allergens'], <String>[]);
    expect(json['fun_fact_en'], 'Ripe plantains are sweet.');
    expect(json['fun_fact_sw'], 'Ndizi mbivu ni tamu.');

    final updated = item.copyWith(rating: 4.9, price: 8000.0);
    expect(updated.rating, 4.9);
    expect(updated.price, 8000.0);
    expect(updated.spiceLevel, 2);
    expect(updated.ingredients, <String>['plantain']);
    expect(updated.funFactEn, 'Ripe plantains are sweet.');
    expect(updated.funFactSw, 'Ndizi mbivu ni tamu.');
  });

  test('MenuReviewModel.fromJson parses rating rows', () {
    final review = MenuReviewModel.fromJson(<String, dynamic>{
      'id': 'review-1',
      'menu_id': 'menu-detail',
      'profile_id': 'demo-customer-001',
      'rating': 5,
      'comment': '',
      'created_at': '2026-01-14T09:00:00Z',
      'updated_at': '2026-01-14T09:00:00Z',
    });

    expect(review.menuId, 'menu-detail');
    expect(review.rating, 5);
    expect(review.toJson()['rating'], 5);
  });

  test('menuItemByIdProvider resolves from the loaded menu provider', () async {
    final item = ShowcaseSeedData.menuItems.first;
    final container = ProviderContainer(
      overrides: [
        showcaseLatencyProvider.overrideWithValue(Duration.zero),
        allMenuItemsProvider.overrideWith((ref) async => <MenuItemModel>[item]),
      ],
    );
    addTearDown(container.dispose);

    final found = await container.read(menuItemByIdProvider(item.id).future);

    expect(found, isNotNull);
    expect(found!.id, item.id);
    expect(found.funFactEn, item.funFactEn);
  });

  test('menuItemByIdProvider returns null when the dish is missing', () async {
    final item = ShowcaseSeedData.menuItems.first;
    final container = ProviderContainer(
      overrides: [
        showcaseLatencyProvider.overrideWithValue(Duration.zero),
        allMenuItemsProvider.overrideWith((ref) async => <MenuItemModel>[item]),
      ],
    );
    addTearDown(container.dispose);

    final missing =
        await container.read(menuItemByIdProvider('missing-id').future);

    expect(missing, isNull);
  });

  test('dishCustomizationsProvider returns showcase options with zero latency',
      () async {
    final container = ProviderContainer(
      overrides: [
        showcaseLatencyProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    final options = await container
        .read(dishCustomizationsProvider('menu-chipsi-mayai').future);
    final missingOptions =
        await container.read(dishCustomizationsProvider('missing-id').future);

    expect(options, isNotEmpty);
    expect(options.first.id, isNotEmpty);
    expect(missingOptions, isEmpty);
    expect(
        await container.read(dishCustomizationsProvider('menu-stoney').future),
        isEmpty);
  });

  test('dishReviewsProvider returns seed reviews with zero latency', () async {
    final container = ProviderContainer(
      overrides: [
        showcaseLatencyProvider.overrideWithValue(Duration.zero),
      ],
    );
    addTearDown(container.dispose);

    final reviews =
        await container.read(dishReviewsProvider('menu-chipsi-mayai').future);
    final missing =
        await container.read(dishReviewsProvider('missing-id').future);

    expect(reviews.length, 2);
    expect(
      reviews.every((review) => review.menuId == 'menu-chipsi-mayai'),
      isTrue,
    );
    expect(missing, isEmpty);
  });
}
