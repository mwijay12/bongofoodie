import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/dish_asset.dart';
import '../theme/app_tokens.dart';
import '../theme/skeleton_colors.dart';

class DishImage extends StatelessWidget {
  final String imageRef;
  final String? dishId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool clip;
  final bool transparentFallback;

  const DishImage({
    super.key,
    String? imageRef,
    this.dishId,
    String? imageKeyOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.v16,
    this.clip = true,
    this.transparentFallback = false,
  }) : imageRef = imageRef ?? imageKeyOrUrl ?? 'salad';

  static const Map<String, String> _localAssetMap = {
    'chipsiMayai': 'assets/dishes/menu-chipsi-mayai.png',
    'nyamaChoma': 'assets/dishes/menu-nyama-choma.png',
    'zanzibarPilau': 'assets/dishes/menu-pilau-kuku.png',
    'pilauYaKuku': 'assets/images/pilau-ya-kuku.png',
    'samakiWaKupaka': 'assets/dishes/menu-samaki-kupaka.png',
    'mishkakiYaNgombe': 'assets/dishes/menu-mishkaki.png',
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
    if (_localAssetMap.containsKey(trimmed)) {
      return _localAssetMap[trimmed];
    }
    if (trimmed.startsWith('assets/')) return trimmed;

    final lower = trimmed.toLowerCase();
    for (final entry in _localAssetMap.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }

    if (!lower.startsWith('http://') && !lower.startsWith('https://')) {
      if (lower.contains('chipsi') || lower.contains('mayai')) {
        return _localAssetMap['chipsiMayai'];
      }
      if (lower.contains('nyama') || lower.contains('choma')) {
        return _localAssetMap['nyamaChoma'];
      }
      if (lower.contains('pilau') || lower.contains('wali') || lower.contains('rice')) {
        return _localAssetMap['pilauYaKuku'];
      }
      if (lower.contains('samaki') || lower.contains('kupaka') || lower.contains('fish')) {
        return _localAssetMap['samakiWaKupaka'];
      }
      if (lower.contains('mishkaki') || lower.contains('skewer')) {
        return _localAssetMap['mishkakiYaNgombe'];
      }
      if (lower.contains('burger')) return _localAssetMap['burgerOne'];
      if (lower.contains('pizza')) return _localAssetMap['pizzaOne'];
      if (lower.contains('juice') || lower.contains('drink') || lower.contains('soda')) {
        return _localAssetMap['orangeJuiceIcon'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final source = resolveDishAsset(dishId ?? '', fallback: imageRef);
    final localAsset = resolveLocalAsset(source);

    Widget child;
    if (localAsset != null) {
      child = Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, _, __) => _fallbackBox(context),
      );
    } else if (source.startsWith('http://') || source.startsWith('https://')) {
      child = Image.network(
        source,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || child is _DishImageFallback) return child;
          final reducedMotion = MediaQuery.disableAnimationsOf(context);
          final backdrop = transparentFallback
              ? AppColors.clear
              : SkeletonColors.of(context).base;
          return Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: backdrop),
              ),
              AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: reducedMotion ? Duration.zero : AppMotion.base,
                curve: AppMotion.enter,
                child: child,
              ),
            ],
          );
        },
        errorBuilder: (context, _, __) => _fallbackBox(context),
      );
    } else {
      child = _fallbackBox(context);
    }

    if (!clip) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
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
