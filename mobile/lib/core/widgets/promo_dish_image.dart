import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'dish_image.dart';

/// Image-only promo content: no clip or opaque backing inside the campaign.
class PromoDishImage extends StatelessWidget {
  const PromoDishImage({super.key, required this.imageRef});
  final String imageRef;

  @override
  Widget build(BuildContext context) => DishImage(
        imageRef: imageRef,
        width: PromoCardMetrics.imageSize,
        height: PromoCardMetrics.imageSize,
        fit: BoxFit.contain,
        clip: false,
        transparentFallback: true,
      );
}
