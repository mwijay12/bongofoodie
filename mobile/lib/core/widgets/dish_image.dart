import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DishImage extends StatelessWidget {
  final String imageRef;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;

  const DishImage({
    super.key,
    String? imageRef,
    String? imageKeyOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 16,
  }) : imageRef = imageRef ?? imageKeyOrUrl ?? 'salad';

  static const Map<String, String> _localAssetMap = {
    'chipsiMayai': 'assets/images/chipsi-mayai.png',
    'nyamaChoma': 'assets/images/nyama-choma.png',
    'pilauYaKuku': 'assets/images/pilau-ya-kuku.png',
    'samakiWaKupaka': 'assets/images/samaki-wa-kupaka.png',
    'mishkakiYaNgombe': 'assets/images/mishkaki-ya-ngombe.png',
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
    final localAsset = resolveLocalAsset(imageRef);

    Widget child;
    if (localAsset != null) {
      child = Image.asset(
        localAsset,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _fallbackBox(),
      );
    } else if (imageRef.startsWith('http://') || imageRef.startsWith('https://')) {
      child = Image.network(
        imageRef,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, widget, progress) {
          if (progress == null) return widget;
          return Container(
            width: width,
            height: height,
            color: AppColors.spiceOrange.withOpacity(0.08),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.spiceOrange,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallbackBox(),
      );
    } else {
      child = _fallbackBox();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }

  Widget _fallbackBox() {
    return Container(
      width: width,
      height: height,
      color: AppColors.spiceOrange.withOpacity(0.12),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant_rounded,
        color: AppColors.spiceOrange,
        size: 32,
      ),
    );
  }
}
