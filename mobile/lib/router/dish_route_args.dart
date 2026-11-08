import '../data/models/models.dart';

/// Passed through `GoRouterState.extra` so an in-app tap renders instantly.
/// A deep link without `extra` falls back to `menuItemByIdProvider`.
class DishRouteArgs {
  const DishRouteArgs({required this.item, required this.heroScope});

  final MenuItemModel item;
  final String heroScope;

  String get heroTag => dishHeroTag(heroScope, item.id);
}

abstract final class DishHeroScopes {
  static const String homeSignature = 'home-signature';
  static const String menuList = 'menu-list';
  static const String favorites = 'favorites';
  static const String related = 'related';
  static const String deepLink = 'deep-link';
}

String dishHeroTag(String heroScope, String id) =>
    'dish-image-$heroScope-$id';
