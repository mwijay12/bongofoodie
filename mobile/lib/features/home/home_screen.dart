import '../../core/l10n/daily_copy.dart';
import '../../core/utils/daily_selection.dart';
import '../../core/widgets/catalog_cache_notice.dart';
import '../../core/widgets/promo_offer_card.dart';
import '../../core/utils/dish_image_cache.dart';
import '../../core/l10n/dish_copy.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/icons/app_icon_key.dart';
import '../../core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/config/env_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_image.dart';
import '../../core/widgets/skeleton/shimmer.dart';
import '../../core/widgets/skeleton/skeleton_dish_card.dart';
import '../../core/widgets/skeleton/skeleton_discovery_card.dart';
import '../../core/widgets/skeleton/skeleton_promo_card.dart';
import '../../core/widgets/state_message.dart';
import '../../core/widgets/tanzania_location_sheet.dart';
import '../../data/mock/showcase_seed_data.dart';
import '../../data/models/models.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/menu_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/settings_provider.dart';
import '../../core/widgets/dish_hero_image.dart';
import '../../router/dish_route_args.dart';

/// Shared metrics for dish cards — kept in app_tokens.dart (DishCardMetrics)
/// so the real card and its skeleton stay in sync.

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.showEnvBadge = EnvConfig.showEnvBadge});

  final bool showEnvBadge;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _imagesWarmed = false;
  final Set<String> _warmedPromoAssets = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesWarmed) return;
    _imagesWarmed = true;
    precacheDishAssetsAfterFrame(
      context,
      ['chipsiMayai', 'nyamaChoma', 'zanzibarPilau']
          .map((key) => DishImage.resolveLocalAsset(key)!),
      DishCardMetrics.imageSize,
    );
  }

  Future<void> _openSpiceTriviaSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final user = ref.read(authProvider).user;
    final repo = ref.read(menuRepositoryProvider);
    final alreadyPlayed = await repo.hasAttemptedTriviaToday(user?.id);
    if (!context.mounted) return;

    final question = selectDaily(ShowcaseSeedData.triviaQuestions,
        DateTime.now(), (q) => q.id.toString())!;

    showAppSheet<void>(
      context,
      showDragHandle: true,
      builder: (ctx) => _SpiceTriviaSheet(
        question: question,
        alreadyPlayed: alreadyPlayed,
        userId: user?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    final auth = ref.watch(authProvider);
    final address = ref.watch(deliveryAddressProvider);
    final promotionsAsync = ref.watch(promotionsProvider);
    ref.listen<AsyncValue<List<PromotionModel>>>(promotionsProvider, (_, next) {
      final assets = (next.valueOrNull ?? const <PromotionModel>[])
          .take(2)
          .map((p) => DishImage.resolveLocalAsset(p.imageKey))
          .whereType<String>()
          .where(_warmedPromoAssets.add)
          .toList();
      if (assets.isNotEmpty) {
        precacheDishAssetsAfterFrame(
            context, assets, PromoCardMetrics.imageSize);
      }
    });
    final discoveriesAsync = ref.watch(dailyDiscoveriesProvider);
    final menuAsync = ref.watch(allMenuItemsProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomClearance = context.navClearance;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator.adaptive(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(promotionsProvider);
            ref.invalidate(allMenuItemsProvider);
            try {
              await ref.read(dailyDiscoveriesProvider.notifier).refresh();
            } catch (_) {}
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: CatalogCacheNotice()),
              // 1. Top Location + Role/Mode Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screenH,
                      AppSpace.md, AppSpace.screenH, AppSpace.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.v14),
                          onTap: () => showTanzaniaLocationPicker(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.xs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t.deliverTo.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primaryDeep,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    if (widget.showEnvBadge)
                                      const SizedBox(width: AppSpace.v6),
                                    if (widget.showEnvBadge)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpace.v7,
                                            vertical: AppSpace.v2),
                                        decoration: BoxDecoration(
                                          color:
                                              (EnvConfig.hasSupabaseCredentials
                                                      ? AppColors.success
                                                      : AppColors.primary)
                                                  .withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.pill),
                                        ),
                                        child: Text(
                                          EnvConfig.hasSupabaseCredentials
                                              ? t.liveMode
                                              : t.showcaseMode,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                EnvConfig.hasSupabaseCredentials
                                                    ? AppColors.success
                                                    : AppColors.primaryDark,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.v3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 17,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: AppSpace.v4),
                                    Flexible(
                                      child: Text(
                                        address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 18),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (auth.user?.role.isStaff == true)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpace.v8),
                          child: ActionChip(
                            avatar: const Icon(
                              Icons.soup_kitchen_rounded,
                              size: 16,
                              color: AppColors.surface,
                            ),
                            backgroundColor: AppColors.espresso,
                            label: const Text(
                              'Staff Live',
                              style: TextStyle(
                                color: AppColors.surface,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onPressed: () => context.push('/staff'),
                          ),
                        ),
                      IconButton.filledTonal(
                        tooltip: 'Switch Language (EN / SW)',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.14),
                        ),
                        onPressed: () => ref
                            .read(appSettingsProvider.notifier)
                            .toggleLanguage(),
                        icon: Text(
                          t.isSw ? 'SW' : 'EN',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Greeting + Chef AI Atelier Hero Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screenH,
                      AppSpace.v0, AppSpace.screenH, AppSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.karibuTitle}, ${(auth.user?.name ?? 'Foodie').split(' ').first}',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: AppSpace.v4),
                      Text(
                        t.heroSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpace.v16),
                      _ChefAtelierCard(
                        title: t.chefAiBannerTitle,
                        subtitle: t.chefAiBannerSub,
                        action: t.isSw ? 'Ongea na Chef' : 'Meet your chef',
                        onTap: () => context.go('/chef-ai'),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Special Promotions Carousel
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.lg),
                  child: promotionsAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (promos) => promos.isEmpty
                        ? const SizedBox.shrink()
                        : SizedBox(
                            height: PromoCardMetrics.height,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpace.screenH),
                              scrollDirection: Axis.horizontal,
                              itemCount: promos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpace.v14),
                              itemBuilder: (context, index) {
                                final p = promos[index];
                                return PromoOfferCard(
                                  promotion: p,
                                  actionLabel: t.isSw
                                      ? 'Angalia menyu'
                                      : 'Explore the menu',
                                  onTap: () => context.go(
                                    '/search?category=${Uri.encodeComponent(p.targetCategory)}',
                                  ),
                                );
                              },
                            ),
                          ),
                    loading: () => SizedBox(
                      height: PromoCardMetrics.height,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.screenH),
                        scrollDirection: Axis.horizontal,
                        itemCount: 2,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppSpace.v14),
                        itemBuilder: (_, __) => const SkeletonPromoCard(),
                      ),
                    ),
                    error: (_, __) => StateMessage.error(
                      compact: true,
                      onRetry: () => ref.invalidate(promotionsProvider),
                    ),
                  ),
                ),
              ),

              // 4. Daily Swahili Discovery + Trivia Challenge Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screenH,
                      AppSpace.v0, AppSpace.screenH, AppSpace.lg),
                  child: discoveriesAsync.when(
                    skipLoadingOnRefresh: true,
                    data: (list) {
                      final selected =
                          selectDaily(list, DateTime.now(), (d) => d.id);
                      if (selected == null) {
                        return StateMessage.empty(
                          compact: true,
                          title: t.isSw
                              ? 'Hakuna dokezo la leo'
                              : 'No discovery today',
                          body: t.isSw
                              ? 'Rudi baadaye kwa dokezo jipya.'
                              : 'Check back later for another food story.',
                        );
                      }
                      final featured =
                          DailyCopy.discovery(selected, isSw: t.isSw);
                      return Container(
                        padding: const EdgeInsets.all(AppSpace.lg),
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkCard : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const AppIcon(
                                  iconKey: AppIconKey.idea,
                                  color: AppColors.primary,
                                  tinted: true,
                                ),
                                const SizedBox(width: AppSpace.v8),
                                Expanded(
                                  child: Text(
                                    t.dailyDiscovery,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: isDark
                                          ? AppColors.heroLight
                                          : AppColors.primaryDeep,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(
                                        AppSpace.huge, AppSpace.huge),
                                  ),
                                  onPressed: () =>
                                      _openSpiceTriviaSheet(context, ref),
                                  icon: const Icon(Icons.emoji_events_rounded,
                                      size: 17),
                                  label: Text(
                                    t.playSpiceTrivia,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AppIcon(
                                  iconKey: featured.iconKey ??
                                      appIconKeyForText(featured.title),
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpace.v8),
                                Expanded(
                                  child: Text(
                                    featured.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.v4),
                            Text(
                              featured.description,
                              style: TextStyle(
                                fontSize: 12.8,
                                height: 1.4,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => SkeletonDiscoveryCard(),
                    error: (_, __) => StateMessage.error(
                        compact: true,
                        onRetry: () => ref
                            .read(dailyDiscoveriesProvider.notifier)
                            .refresh()),
                  ),
                ),
              ),

              // 5. Signature Dishes Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screenH,
                      AppSpace.v0, AppSpace.screenH, AppSpace.lg),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.popularDishes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Flexible(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            minimumSize:
                                const Size(AppSpace.huge, AppSpace.huge),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.sm,
                            ),
                          ),
                          onPressed: () => context.go('/search'),
                          child: Text(
                            t.isSw ? 'Ona Menyu Yote →' : 'Full Menu →',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Signature Dishes Responsive Grid
              menuAsync.when(
                skipLoadingOnRefresh: true,
                data: (items) {
                  final featured = items.take(8).toList();
                  if (featured.isEmpty) {
                    return SliverToBoxAdapter(
                      child: StateMessage.empty(
                        title: t.emptyMenuTitle,
                        body: t.emptyMenuBody,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.screenH),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: DishCardMetrics.cardMaxWidth,
                        mainAxisSpacing: DishCardMetrics.gap,
                        crossAxisSpacing: DishCardMetrics.gap,
                        mainAxisExtent: DishCardMetrics.cardHeight,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final dish = featured[index];
                          final isFav = favorites.contains(dish.id);
                          return KeyedSubtree(
                            key: ValueKey('home-dish-${dish.id}'),
                            child: _SignatureDishCard(
                              dish: dish,
                              isFavorite: isFav,
                              onTap: () => context.push('/dish/${dish.id}',
                                  extra: DishRouteArgs(
                                      item: dish,
                                      heroScope: DishHeroScopes.homeSignature)),
                              onToggleFavorite: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(dish.id),
                              onQuickAdd: () {
                                ref
                                    .read(cartProvider.notifier)
                                    .addItem(dish: dish);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${dishName(dish.id, dish.name, isSw: t.isSw)}: ${t.added}'),
                                    duration: const Duration(seconds: 1),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: featured.length,
                      ),
                    ),
                  );
                },
                loading: () => SliverToBoxAdapter(
                  child: Semantics(
                    label: t.loading,
                    child: ExcludeSemantics(
                      child: Shimmer(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpace.screenH,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: DishCardMetrics.cardMaxWidth,
                            mainAxisSpacing: DishCardMetrics.gap,
                            crossAxisSpacing: DishCardMetrics.gap,
                            mainAxisExtent: DishCardMetrics.cardHeight,
                          ),
                          itemCount: 2,
                          itemBuilder: (_, __) => const SkeletonDishCard(),
                        ),
                      ),
                    ),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: StateMessage.error(
                    compact: true,
                    onRetry: () => ref.invalidate(allMenuItemsProvider),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: bottomClearance),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A quiet, editorial invitation rather than another promotional banner.
class _ChefAtelierCard extends StatelessWidget {
  const _ChefAtelierCard({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: Material(
        color: AppColors.ember,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.ember, AppColors.ink],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -AppSpace.v55,
                  top: -AppSpace.v65,
                  child: Container(
                    width: AppSpace.v190,
                    height: AppSpace.v190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.surface.withOpacity(.08),
                          width: AppSpace.v30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpace.v22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BONGO FOODIE  /  CHEF AI',
                                style: TextStyle(
                                    color: AppColors.heroMuted,
                                    fontSize: 9,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: AppSpace.v14),
                            Text(title,
                                style: const TextStyle(
                                    color: AppColors.surface,
                                    fontSize: 22,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.5)),
                            const SizedBox(height: AppSpace.v8),
                            Text(subtitle,
                                style: TextStyle(
                                    color: AppColors.surface.withOpacity(.72),
                                    fontSize: 12,
                                    height: 1.45)),
                            const SizedBox(height: AppSpace.v18),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Flexible(
                                child: Text(
                                  action,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.heroLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpace.v7),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: AppColors.heroLight, size: 16),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.v12),
                      const DishImage(
                          imageRef: 'robotChef',
                          clip: false,
                          transparentFallback: true,
                          width: AppSpace.v92,
                          height: AppSpace.v118,
                          borderRadius: AppRadius.v22),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignatureDishCard extends ConsumerWidget {
  final MenuItemModel dish;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onQuickAdd;

  const _SignatureDishCard({
    required this.dish,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.v22),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.v22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(DishCardMetrics.padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.v22),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Center(
                    child: DishHeroImage(
                      item: dish,
                      heroScope: DishHeroScopes.homeSignature,
                      width: DishCardMetrics.imageSize,
                      height: DishCardMetrics.imageSize,
                      borderRadius: AppRadius.v18,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: onToggleFavorite,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.v6),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.scrim : AppColors.surface)
                              .withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color:
                              isFavorite ? AppColors.error : AppColors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: AppColors.gold),
                  const SizedBox(width: AppSpace.v3),
                  Text(
                    dish.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${dish.prepTimeMins}m',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.v2),
              Text(
                dishName(dish.id, dish.name,
                    isSw: ref.watch(appStringsProvider).isSw),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                dish.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.formatTzs(dish.price),
                      style: const TextStyle(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Tooltip(
                    message:
                        '${ref.watch(appStringsProvider).addToCart}: ${dishName(dish.id, dish.name, isSw: ref.watch(appStringsProvider).isSw)}',
                    child: InkWell(
                      onTap: onQuickAdd,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpace.v6),
                        decoration: BoxDecoration(
                          color: AppColors.cta,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.surface,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpiceTriviaSheet extends ConsumerStatefulWidget {
  final SpiceTriviaQuestion question;
  final bool alreadyPlayed;
  final String? userId;

  const _SpiceTriviaSheet({
    required this.question,
    required this.alreadyPlayed,
    required this.userId,
  });

  @override
  ConsumerState<_SpiceTriviaSheet> createState() => _SpiceTriviaSheetState();
}

class _SpiceTriviaSheetState extends ConsumerState<_SpiceTriviaSheet> {
  int? _pickedIndex;
  bool _submitted = false;

  Future<void> _pickAnswer(int idx) async {
    if (_submitted) return;
    final correct = idx == widget.question.correctIndex;
    setState(() {
      _pickedIndex = idx;
      _submitted = true;
    });
    await ref
        .read(menuRepositoryProvider)
        .recordTriviaAttempt(widget.userId, correct);
  }

  @override
  Widget build(BuildContext context) {
    final sw = ref.watch(appStringsProvider).isSw;
    final question = DailyCopy.question(widget.question, isSw: sw);
    final isCorrect = _pickedIndex == widget.question.correctIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.v22, AppSpace.v6, AppSpace.v22, AppSpace.v30),
      child: SingleChildScrollView(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpace.v8),
              Expanded(
                  child: Text(
                sw ? 'Swali la leo kuhusu chakula' : 'Daily food quiz',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              )),
            ],
          ),
          const SizedBox(height: AppSpace.v6),
          Text(
            widget.alreadyPlayed && !_submitted
                ? (sw
                    ? 'Umeshajibu leo. Unaweza kujaribu tena kwa mazoezi.'
                    : 'You have answered today. You can try again for practice.')
                : (sw
                    ? 'Chagua jibu moja, kisha soma maelezo yake.'
                    : 'Choose an answer, then read the explanation.'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.v16),
          Text(
            question.question,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpace.v14),
          ...List.generate(question.options.length, (i) {
            final option = question.options[i];
            final isAnswer = i == widget.question.correctIndex;
            final isPicked = i == _pickedIndex;

            Color? tileColor;
            if (_submitted) {
              if (isAnswer) {
                tileColor = AppColors.success.withOpacity(0.16);
              } else if (isPicked) {
                tileColor = AppColors.error.withOpacity(0.16);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.v8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.v14),
                  side: BorderSide(
                    color: _submitted && isAnswer
                        ? AppColors.success
                        : AppColors.lightBorder,
                  ),
                ),
                tileColor: tileColor,
                title: Text(
                  option,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                trailing: _submitted && isAnswer
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppColors.success)
                    : null,
                onTap: () => _pickAnswer(i),
              ),
            );
          }),
          if (_submitted) ...[
            const SizedBox(height: AppSpace.v10),
            Container(
              padding: const EdgeInsets.all(AppSpace.v14),
              decoration: BoxDecoration(
                color: (isCorrect ? AppColors.success : AppColors.primary)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.v16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect
                        ? (sw
                            ? 'Sahihi! ${question.explainer}'
                            : 'Correct! ${question.explainer}')
                        : (sw
                            ? 'Si jibu sahihi. ${question.explainer}'
                            : 'Not quite. ${question.explainer}'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpace.v8),
                  if (isCorrect)
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'KARIBU2000'),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(sw
                                ? 'Msimbo KARIBU2000 umenakiliwa.'
                                : 'Code KARIBU2000 copied.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(sw
                          ? 'Nakili msimbo KARIBU2000'
                          : 'Copy code KARIBU2000'),
                    ),
                ],
              ),
            ),
          ],
        ],
      )),
    );
  }
}
