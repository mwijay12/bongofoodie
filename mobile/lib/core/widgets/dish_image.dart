import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/dish_asset.dart';
import '../utils/dish_image_cache.dart';
import '../theme/app_tokens.dart';
import '../theme/skeleton_colors.dart';

class DishImage extends StatelessWidget {
  final String imageRef;
  final String? dishId;
  final String productName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool clip;
  final bool transparentFallback;
  final bool showCircle;

  const DishImage({
    super.key,
    String? imageRef,
    this.dishId,
    this.productName = '',
    String? imageKeyOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.v16,
    this.clip = true,
    this.transparentFallback = false,
    this.showCircle = true,
  }) : imageRef = imageRef ?? imageKeyOrUrl ?? 'salad';

  static const Map<String, String> _localAssetMap = {
    'pilauYaKuku': 'assets/images/pilau-ya-kuku.png',
    'burgerOne': 'assets/images/burger-one.png',
    'burgerTwo': 'assets/images/burger-two.png',
    'pizzaOne': 'assets/images/pizza-one.png',
    'buritto': 'assets/images/buritto.png',
    'fries': 'assets/images/fries.png',
    'salad': 'assets/images/salad.png',
    'avocado': 'assets/images/avocado.png',
    'cheese': 'assets/images/cheese.png',
    'bongoChefMascot': 'assets/images/bongo-chef-mascot.png',
    'bongoFoodIcon': 'assets/images/bongo-food-icon.png',
    'chefOnboarding': 'assets/images/chef-onboarding.png',
    'loginGraphic': 'assets/images/login-graphic.png',
    'logo': 'assets/images/logo.png',
    'orangeJuiceIcon': 'assets/images/orange-juice-icon.png',
    'aiChefIcon': 'assets/images/ai-chef-icon.png',
    'robotChef': 'assets/images/robot-chef.png',
    'food3dIcon': 'assets/images/food-3d-icon.png',
  };

  static String? resolveLocalAsset(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (dishAssetIds.contains(trimmed)) {
      return resolveDishAsset(trimmed, fallback: trimmed);
    }
    for (final entry in dishImageKeys.entries) {
      if (entry.key.toLowerCase() == trimmed.toLowerCase()) {
        return resolveDishAsset(entry.value, fallback: trimmed);
      }
    }
    if (_localAssetMap.containsKey(trimmed)) {
      return _localAssetMap[trimmed];
    }
    if (trimmed.startsWith('assets/')) return trimmed;

    final lower = trimmed.toLowerCase();
    for (final entry in _localAssetMap.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final source = resolveDishAsset(dishId ?? '',
        fallback: imageRef, productName: productName);
    final localAsset = resolveLocalAsset(source);

    final cutout = localAsset != null &&
        (localAsset.startsWith('assets/dishes/') ||
            const {
              'assets/images/burger-one.png',
              'assets/images/burger-two.png',
              'assets/images/pizza-one.png',
              'assets/images/robot-chef.png',
              'assets/images/login-graphic.png',
            }.contains(localAsset));
    final imageFit = cutout ? BoxFit.contain : fit;
    Widget child;
    if (localAsset != null) {
      child = Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: imageFit,
        cacheWidth: dishDecodeWidth(context, width),
        frameBuilder: _frameBuilder,
        errorBuilder: (context, _, __) => _fallbackBox(context),
      );
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      child = Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: dishDecodeWidth(context, width),
        frameBuilder: _frameBuilder,
        errorBuilder: (context, _, __) => _fallbackBox(context),
      );
    } else {
      child = _fallbackBox(context);
    }

    if (cutout) {
      if (!showCircle || !clip) return child;
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            child,
          ],
        ),
      );
    }
    if (!clip) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  Widget _frameBuilder(BuildContext context, Widget child, int? frame,
      bool wasSynchronouslyLoaded) {
    if (wasSynchronouslyLoaded) return child;
    return Stack(
      children: [
        if (frame == null)
          Positioned.fill(
            child: ColoredBox(
              color: transparentFallback
                  ? AppColors.clear
                  : SkeletonColors.of(context).base,
            ),
          ),
        AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.base,
          curve: AppMotion.enter,
          child: child,
        ),
      ],
    );
  }

  Widget _fallbackBox(BuildContext context) => _DishImageFallback(
        width: width,
        height: height,
        transparent: transparentFallback,
      );
}

class _DishImageFallback extends StatelessWidget {
  const _DishImageFallback({
    this.width,
    this.height,
    this.transparent = false,
  });
  final double? width;
  final double? height;
  final bool transparent;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        color: transparent ? AppColors.clear : SkeletonColors.of(context).base,
        alignment: Alignment.center,
        child: Icon(
          Icons.restaurant_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: AppSpace.xxl,
        ),
      );
}
