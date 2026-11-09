import 'dart:async';
import 'package:flutter/material.dart';

int? dishDecodeWidth(BuildContext context, double? logicalWidth) {
  if (logicalWidth == null || !logicalWidth.isFinite || logicalWidth <= 0) {
    return null;
  }
  return (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
}

/// Match Image.asset's ResizeImage cache key, only after the first frame.
void precacheDishAssetsAfterFrame(BuildContext context,
    Iterable<String> assets, double logicalWidth) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    final width = dishDecodeWidth(context, logicalWidth);
    for (final asset in assets) {
      unawaited(precacheImage(
        ResizeImage.resizeIfNeeded(width, null, AssetImage(asset)),
        context,
      ));
    }
  });
}
