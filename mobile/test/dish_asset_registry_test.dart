import 'dart:io';
import 'package:bongo_foodie/core/utils/dish_asset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registered dish IDs have checked-in canonical files', () {
    for (final id in dishAssetIds) {
      final path = resolveDishAsset(id, fallback: 'https://example.com/food.png');
      expect(path, 'assets/dishes/$id.png');
      expect(File(path).existsSync(), isTrue, reason: '$id must have a file');
    }
  });
  test('unknown IDs preserve their source without guessing a different dish', () {
    expect(resolveDishAsset('unknown', fallback: 'https://example.com/food.png'),
        'https://example.com/food.png');
    expect(resolveDishAsset('unknown', fallback: ''), '');
  });
}
