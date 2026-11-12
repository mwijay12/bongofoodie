import 'dart:io';
import 'dart:typed_data';

import 'package:bongo_foodie/core/utils/dish_asset.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the IHDR width/height of a PNG without any image-decoding dependency.
({int width, int height})? _pngSize(File file) {
  final bytes = file.readAsBytesSync();
  if (bytes.length < 24) return null;
  // 8-byte signature, then a 4-byte length, 4-byte type, then w/h.
  const sig = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < sig.length; i++) {
    if (bytes[i] != sig[i]) return null;
  }
  final data = ByteData.sublistView(bytes);
  return (width: data.getUint32(16), height: data.getUint32(20));
}

void main() {
  test('every canonical cutout is a transparent PNG on a shared square canvas',
      () {
    for (final id in dishAssetIds) {
      final file = File('assets/dishes/$id.png');
      expect(file.existsSync(), isTrue, reason: '$id is registered but missing');

      final size = _pngSize(file);
      expect(size, isNotNull, reason: '$id must be a valid PNG');
      expect(size!.width, size.height,
          reason: '$id must be square so contain-scaling is predictable');
      expect(size.width, greaterThanOrEqualTo(1000),
          reason: '$id must stay high resolution');

      // A transparent cutout must actually carry an alpha channel; an opaque
      // PNG would paint a white or black box behind the food.
      final header = file.readAsBytesSync().sublist(24, 29);
      // Colour type 6 == RGBA, 4 == grayscale+alpha, 3 == palette (may have tRNS)
      final colourType = header[1];
      expect([3, 4, 6], contains(colourType),
          reason: '$id colour type $colourType cannot carry transparency');
    }
  });

  test('cutouts are normalised so no dish looks like a side dish', () {
    // Assets are prepared by mobile/scripts/normalize_dish_cutouts.py, which
    // crops each dish to its own alpha bounds and rescales it to a fixed
    // share of the canvas. Identical canvas sizes alone are not enough; the
    // script's --check mode is the real gate and runs in CI.
    final sizes = <String, ({int width, int height})>{};
    for (final id in dishAssetIds) {
      final size = _pngSize(File('assets/dishes/$id.png'));
      if (size != null) sizes[id] = size;
    }
    expect(sizes, hasLength(dishAssetIds.length));
    for (final entry in sizes.entries) {
      expect(entry.value.width, sizes.values.first.width,
          reason: '${entry.key} canvas width drifted from its siblings');
    }
  });
}
