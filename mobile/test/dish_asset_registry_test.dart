import 'dart:io';
import 'package:bongo_foodie/core/utils/dish_asset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registered dish IDs have checked-in canonical files', () {
    for (final id in dishAssetIds) {
      final path =
          resolveDishAsset(id, fallback: 'https://example.com/food.png');
      expect(path, 'assets/dishes/$id.png');
      expect(File(path).existsSync(), isTrue, reason: '$id must have a file');
    }
  });
  test('unknown IDs preserve their source without guessing a different dish',
      () {
    expect(
        resolveDishAsset('unknown', fallback: 'https://example.com/food.png'),
        'https://example.com/food.png');
    expect(resolveDishAsset('unknown', fallback: ''), '');
  });
  test('legacy live placeholders cannot masquerade as different products', () {
    for (final pair in [
      ('Juisi ya Passion & Embe', 'orangeJuiceIcon'),
      ('Stoney Tangawizi', 'orangeJuiceIcon'),
      ('Ndizi Mzuzu Kaanga', 'fries'),
      ('Kuku na Chapati', 'samakiWaKupaka'),
      ('Wali wa Nazi na Maharage', 'pilauYaKuku'),
    ]) {
      expect(
          resolveDishAsset('live-uuid',
              fallback: pair.$2, productName: pair.$1),
          isEmpty);
    }
    expect(
        resolveDishAsset('live-uuid',
            fallback: 'fries', productName: 'French Fries'),
        'fries');
    expect(
        resolveDishAsset('live-uuid',
            fallback: 'https://example.com/drink.png',
            productName: 'Passion Juice'),
        'https://example.com/drink.png');
  });
}
