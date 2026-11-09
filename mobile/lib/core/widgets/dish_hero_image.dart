import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../router/dish_route_args.dart';
import '../theme/app_tokens.dart';
import 'dish_image.dart';

/// Hero wrapper around [DishImage]. Cards keep the clipped, rounded treatment;
/// the detail page passes `clip: false` and `transparentFallback: true` so the
/// image is not clipped into a box and no white backing is added behind it.
class DishHeroImage extends StatelessWidget {
  const DishHeroImage({
    super.key,
    required this.item,
    required this.heroScope,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.v16,
    this.clip = true,
    this.transparentFallback = false,
  });

  final MenuItemModel item;
  final String heroScope;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool clip;
  final bool transparentFallback;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: dishHeroTag(heroScope, item.id),
      transitionOnUserGestures: true,
      child: DishImage(
        imageRef: item.imageUrl,
        dishId: item.id,
        width: width,
        height: height,
        fit: fit,
        borderRadius: borderRadius,
        clip: clip,
        transparentFallback: transparentFallback,
      ),
    );
  }
}
