import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/async_skeleton.dart';
import '../../core/widgets/dish_hero_image.dart';
import '../../core/widgets/motion/stagger_in.dart';
import '../../core/widgets/skeleton/skeleton_detail_screen.dart';
import '../../core/widgets/state_message.dart';
import '../../data/models/models.dart';
import '../../router/dish_route_args.dart';
import '../../state/cart_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/settings_provider.dart';

/// Full-screen dish detail route. Only sections 1-3 and the sticky bar are
/// built; sections 4-9 are clearly marked `SizedBox.shrink` placeholders.
class DishDetailScreen extends ConsumerStatefulWidget {
  const DishDetailScreen({super.key, required this.id, this.args});

  final String id;
  final DishRouteArgs? args;

  @override
  ConsumerState<DishDetailScreen> createState() => DishDetailScreenState();
}

class DishDetailScreenState extends ConsumerState<DishDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  bool _entranceScheduled = false;
  int _quantity = DishDetailMetrics.quantityMin;
  bool _added = false;
  Timer? _addedTimer;

  AnimationController get entranceController => _entranceController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entranceController.stop();
      _entranceController.value = 1;
      return;
    }
    if (_entranceScheduled ||
        _entranceController.status != AnimationStatus.dismissed) {
      return;
    }
    _entranceScheduled = true;
    Future<void>.delayed(AppMotion.slow + AppMotion.staggerDelay).then((_) {
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _addedTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  void _incrementQuantity() {
    if (_quantity >= DishDetailMetrics.quantityMax) return;
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity <= DishDetailMetrics.quantityMin) return;
    setState(() => _quantity--);
  }

  double _totalFor(MenuItemModel item, int quantity) {
    // Prompt 4 owns add-on selection; for now the existing pricing function
    // is used with an empty selection, exactly as the cart notifier does.
    return CartItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      quantity: quantity,
      customizations: const <CustomizationOption>[],
    ).lineTotal;
  }

  void _onAdd(MenuItemModel item) {
    HapticFeedback.mediumImpact();
    ref.read(cartProvider.notifier).addItem(
          dish: item,
          quantity: _quantity,
          customizations: const <CustomizationOption>[],
        );
    _addedTimer?.cancel();
    setState(() => _added = true);
    _addedTimer = Timer(AppMotion.addedLabel, () {
      if (mounted) setState(() => _added = false);
    });
  }

  Widget _buildStickyBar(MenuItemModel item) {
    return _DishStickyBar(
      quantity: _quantity,
      total: _totalFor(item, _quantity),
      added: _added,
      onIncrement: _incrementQuantity,
      onDecrement: _decrementQuantity,
      onAdd: () => _onAdd(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: args != null && args.item.id == widget.id
            ? _DishDetailView(
                item: args.item,
                heroScope: args.heroScope,
                entrance: _entranceController,
                stickyBarBuilder: _buildStickyBar,
              )
            : _DeepLinkView(
                id: widget.id,
                entrance: _entranceController,
                stickyBarBuilder: _buildStickyBar,
              ),
      ),
    );
  }
}

class _DeepLinkView extends ConsumerWidget {
  const _DeepLinkView({
    required this.id,
    required this.entrance,
    required this.stickyBarBuilder,
  });

  final String id;
  final AnimationController entrance;
  final Widget Function(MenuItemModel item) stickyBarBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final asyncItem = ref.watch(menuItemByIdProvider(id));
    return AsyncSkeleton<MenuItemModel?>(
      value: asyncItem,
      skeleton: const SkeletonDetailScreen(),
      onRetry: () => ref.invalidate(menuItemByIdProvider(id)),
      isEmpty: (item) => item == null,
      empty: StateMessage.empty(
        title: t.dishNotFoundTitle,
        body: t.dishNotFoundBody,
        actionLabel: t.backToMenu,
        onAction: () => context.go('/search'),
      ),
      data: (item) => _DishDetailView(
        item: item!,
        heroScope: DishHeroScopes.deepLink,
        entrance: entrance,
        stickyBarBuilder: stickyBarBuilder,
      ),
    );
  }
}

class _DishDetailView extends ConsumerWidget {
  const _DishDetailView({
    required this.item,
    required this.heroScope,
    required this.entrance,
    required this.stickyBarBuilder,
  });

  final MenuItemModel item;
  final String heroScope;
  final AnimationController entrance;
  final Widget Function(MenuItemModel item) stickyBarBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DishHero(item: item, heroScope: heroScope),
              ),
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 0,
                  child: _TitleBlock(item: item),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 1,
                  child: _DescriptionBlock(item: item),
                ),
              ),
              // SLOT 4: nutrition facts (Prompt 4).
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              // SLOT 5: add-ons / customizations (Prompt 4).
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              // SLOT 6: ingredients and allergens (Prompt 4).
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              // SLOT 7: fun fact (Prompt 4).
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              // SLOT 8: ratings and reviews (Prompt 4).
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              // SLOT 9: related dishes (Prompt 4).
              const SliverToBoxAdapter(child: SizedBox.shrink()),
              SliverPadding(
                padding: EdgeInsets.only(
                  bottom: DishDetailMetrics.stickyBarHeight +
                      MediaQuery.paddingOf(context).bottom,
                ),
                sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),
            ],
          ),
        ),
        Positioned(
          left: AppSpace.v0,
          right: AppSpace.v0,
          bottom: AppSpace.v0,
          child: stickyBarBuilder(item),
        ),
      ],
    );
  }
}

class _DishStickyBar extends ConsumerWidget {
  const _DishStickyBar({
    required this.quantity,
    required this.total,
    required this.added,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAdd,
  });

  final int quantity;
  final double total;
  final bool added;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final canIncrease = quantity < DishDetailMetrics.quantityMax;
    final canDecrease = quantity > DishDetailMetrics.quantityMin;
    final addLabel = '${t.addToCart}  ${AppStrings.formatTzs(total)}';

    return SafeArea(
      top: false,
      child: Container(
        height: DishDetailMetrics.stickyBarHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.screenH,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline,
              width: AppSpace.hairline,
            ),
          ),
        ),
        child: Row(
          children: [
            Semantics(
              label: t.quantity,
              value: '$quantity',
              increasedValue: canIncrease ? '${quantity + 1}' : null,
              decreasedValue: canDecrease ? '${quantity - 1}' : null,
              onIncrease: canIncrease ? onIncrement : null,
              onDecrease: canDecrease ? onDecrement : null,
              child: ExcludeSemantics(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.v14),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        tooltip: t.decreaseQuantity,
                        enabled: canDecrease,
                        onPressed: onDecrement,
                      ),
                      AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: Text(
                          '$quantity',
                          key: ValueKey<int>(quantity),
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        tooltip: t.increaseQuantity,
                        enabled: canIncrease,
                        onPressed: onIncrement,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpace.v14),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: added
                      ? const Icon(
                          Icons.check_rounded,
                          key: ValueKey('dish-added-icon'),
                        )
                      : const Icon(
                          Icons.shopping_bag_rounded,
                          key: ValueKey('dish-cart-icon'),
                        ),
                ),
                label: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: added
                      ? Text(
                          t.added,
                          key: const ValueKey('dish-added-label'),
                        )
                      : FittedBox(
                          key: ValueKey<double>(total),
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            addLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        constraints: const BoxConstraints.tightFor(
          width: AppSpace.huge,
          height: AppSpace.huge,
        ),
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: AppSpace.v24),
      ),
    );
  }
}

class DishHero extends StatefulWidget {
  const DishHero({super.key, required this.item, required this.heroScope});

  final MenuItemModel item;
  final String heroScope;

  @override
  State<DishHero> createState() => DishHeroState();
}

class DishHeroState extends State<DishHero> with SingleTickerProviderStateMixin {
  late final AnimationController _floatController = AnimationController(
    vsync: this,
    duration: AppMotion.float,
  );

  AnimationController get floatController => _floatController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _floatController.stop();
      _floatController.value = 0;
    } else if (!_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height *
            DishDetailMetrics.heroHeightFactor)
        .clamp(0.0, DishDetailMetrics.heroMaxHeight)
        .toDouble();
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final topInset = MediaQuery.paddingOf(context).top + AppSpace.sm;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    scheme.brightness == Brightness.dark
                        ? scheme.surface
                        : AppColors.primarySoft,
                    scheme.surface,
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.08),
            child: Container(
              width: DishDetailMetrics.heroCircleSize,
              height: DishDetailMetrics.heroCircleSize,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.v24),
              child: Container(
                width: DishDetailMetrics.contactShadowWidth,
                height: DishDetailMetrics.contactShadowHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(
                      DishDetailMetrics.contactShadowWidth / 2,
                      DishDetailMetrics.contactShadowHeight / 2,
                    ),
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.scrim.withOpacity(0.18),
                      blurRadius: DishDetailMetrics.contactShadowBlur,
                      offset: const Offset(0, AppSpace.v6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  final curved = CurvedAnimation(
                    parent: _floatController,
                    curve: AppMotion.floatCurve,
                  );
                  final offset = reduceMotion
                      ? 0.0
                      : (curved.value - 0.5) *
                          2 *
                          DishDetailMetrics.floatDistance;
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: child,
                  );
                },
                child: DishHeroImage(
                  item: widget.item,
                  heroScope: widget.heroScope,
                  width: DishDetailMetrics.heroImageSize,
                  height: DishDetailMetrics.heroImageSize,
                  fit: BoxFit.contain,
                  borderRadius: AppSpace.v0,
                  clip: false,
                  transparentFallback: true,
                ),
              ),
            ),
          ),
          Positioned(
            top: topInset,
            left: AppSpace.screenH,
            child: _HeroCircleButton(
              icon: Icons.arrow_back_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          Positioned(
            top: topInset,
            right: AppSpace.screenH,
            child: _FavoriteHeart(item: widget.item),
          ),
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  const _HeroCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: AppSpace.huge,
        height: AppSpace.huge,
        child: Material(
          color: AppColors.clear,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _FavoriteHeart extends ConsumerStatefulWidget {
  const _FavoriteHeart({required this.item});

  final MenuItemModel item;

  @override
  ConsumerState<_FavoriteHeart> createState() => _FavoriteHeartState();
}

class _FavoriteHeartState extends ConsumerState<_FavoriteHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: AppMotion.fast,
  );

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    if (!MediaQuery.disableAnimationsOf(context)) {
      _pop.forward(from: 0).then((_) {
        if (mounted) _pop.reverse();
      });
    }
    ref.read(favoritesProvider.notifier).toggle(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    final isFav = ref.watch(favoritesProvider).contains(widget.item.id);
    return Semantics(
      label: t.favorite,
      toggled: isFav,
      child: ExcludeSemantics(
        child: ScaleTransition(
          scale: Tween<double>(begin: 1, end: AppMotion.popScale).animate(
            CurvedAnimation(parent: _pop, curve: AppMotion.enter),
          ),
          child: _HeroCircleButton(
            icon: isFav
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            tooltip: t.favorite,
            onPressed: _toggle,
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends ConsumerWidget {
  const _TitleBlock({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.screenH,
        vertical: AppSpace.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpace.v4),
          Text(t.dishSecondaryName, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              _Chip(
                icon: Icons.star_rounded,
                label:
                    '${item.rating.toStringAsFixed(1)} (${item.ratingCount})',
              ),
              _Chip(
                icon: Icons.schedule_rounded,
                label: '${item.prepTimeMins}m',
              ),
              _Chip(
                icon: Icons.restaurant_rounded,
                label: item.categoryName,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            AppStrings.formatTzs(item.price),
            style: theme.textTheme.displaySmall?.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.v6,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpace.v14, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpace.v4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _DescriptionBlock extends ConsumerStatefulWidget {
  const _DescriptionBlock({required this.item});

  final MenuItemModel item;

  @override
  ConsumerState<_DescriptionBlock> createState() => _DescriptionBlockState();
}

class _DescriptionBlockState extends ConsumerState<_DescriptionBlock> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.item.description,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSpace.huge, AppSpace.huge),
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? t.readLess : t.readMore),
          ),
        ],
      ),
    );
  }
}
