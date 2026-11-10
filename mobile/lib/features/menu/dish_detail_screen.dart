import '../../core/utils/addon_selection.dart';
import '../../core/widgets/dish_back_scope.dart';
import '../../core/l10n/dish_copy.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/icons/app_icon_key.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/async_skeleton.dart';
import '../../core/widgets/dish_hero_image.dart';
import '../../core/widgets/motion/stagger_in.dart';
import '../../core/widgets/skeleton/skeleton_box.dart';
import '../../core/widgets/skeleton/skeleton_detail_screen.dart';
import '../../core/widgets/state_message.dart';
import '../../data/models/models.dart';
import '../../router/dish_route_args.dart';
import '../../state/cart_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/settings_provider.dart';

/// Full-screen dish detail route. Sections 1-9 and the sticky bar are built;
/// each optional section hides completely when its data is absent.
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
  final Set<String> _selectedCustomizationIds = <String>{};

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

  void _toggleCustomization(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedCustomizationIds.contains(id)) {
        _selectedCustomizationIds.remove(id);
      } else {
        _selectedCustomizationIds.add(id);
      }
    });
  }

  List<CustomizationOption> _selectedCustomizationsFor(MenuItemModel item) {
    final options = ref.read(dishCustomizationsProvider(item.id)).valueOrNull ??
        const <CustomizationOption>[];
    return validatedAddons(options)
        .where((option) => _selectedCustomizationIds.contains(option.id))
        .toList(growable: false);
  }

  double _totalFor(
    MenuItemModel item,
    int quantity,
    List<CustomizationOption> customizations,
  ) {
    return CartItemModel(
      id: item.id,
      name: item.name,
      price: item.price,
      imageUrl: item.imageUrl,
      quantity: quantity,
      customizations: customizations,
    ).lineTotal;
  }

  void _onAdd(MenuItemModel item) {
    final options = ref.read(dishCustomizationsProvider(item.id));
    if (options.isLoading || options.hasError || !options.hasValue) return;
    HapticFeedback.mediumImpact();
    ref.read(cartProvider.notifier).addItem(
          dish: item,
          quantity: _quantity,
          customizations: _selectedCustomizationsFor(item),
        );
    _addedTimer?.cancel();
    setState(() => _added = true);
    _addedTimer = Timer(AppMotion.addedLabel, () {
      if (mounted) setState(() => _added = false);
    });
  }

  Widget _buildStickyBar(MenuItemModel item) {
    final customizations = _selectedCustomizationsFor(item);
    final options = ref.watch(dishCustomizationsProvider(item.id));
    return _DishStickyBar(
      quantity: _quantity,
      total: _totalFor(item, _quantity, customizations),
      added: _added,
      onIncrement: _incrementQuantity,
      onDecrement: _decrementQuantity,
      onAdd: options.hasValue && !options.isLoading && !options.hasError
          ? () => _onAdd(item)
          : null,
    );
  }

  Widget _buildAddOnsSection(MenuItemModel item) {
    final asyncOptions = ref.watch(dishCustomizationsProvider(item.id));
    return AsyncSkeleton<List<CustomizationOption>>(
      value: asyncOptions,
      skeleton: const _AddOnSkeletonRows(),
      isEmpty: (options) => options.isEmpty,
      empty: const SizedBox.shrink(),
      errorWidget: StateMessage.error(
          compact: true,
          onRetry: () => ref.invalidate(dishCustomizationsProvider(item.id))),
      data: (options) => _AddOnsSection(
        options: options,
        selectedIds: _selectedCustomizationIds,
        onToggle: _toggleCustomization,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dishCustomizationsProvider(widget.id));
    final args = widget.args;
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: DishBackScope(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: args != null && args.item.id == widget.id
              ? _DishDetailView(
                  item: args.item,
                  heroScope: args.heroScope,
                  entrance: _entranceController,
                  stickyBarBuilder: _buildStickyBar,
                  addOnsBuilder: _buildAddOnsSection,
                )
              : _DeepLinkView(
                  id: widget.id,
                  entrance: _entranceController,
                  stickyBarBuilder: _buildStickyBar,
                  addOnsBuilder: _buildAddOnsSection,
                ),
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
    required this.addOnsBuilder,
  });

  final String id;
  final AnimationController entrance;
  final Widget Function(MenuItemModel item) stickyBarBuilder;
  final Widget Function(MenuItemModel item) addOnsBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final asyncItem = ref.watch(menuItemByIdProvider(id));
    return Stack(
      fit: StackFit.expand,
      children: [
        AsyncSkeleton<MenuItemModel?>(
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
            addOnsBuilder: addOnsBuilder,
          ),
        ),
        if (asyncItem.valueOrNull == null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpace.sm,
            left: AppSpace.screenH,
            child: BackButton(onPressed: () => backFromDish(context)),
          ),
      ],
    );
  }
}

class _DishDetailView extends ConsumerWidget {
  const _DishDetailView({
    required this.item,
    required this.heroScope,
    required this.entrance,
    required this.stickyBarBuilder,
    required this.addOnsBuilder,
  });

  final MenuItemModel item;
  final String heroScope;
  final AnimationController entrance;
  final Widget Function(MenuItemModel item) stickyBarBuilder;
  final Widget Function(MenuItemModel item) addOnsBuilder;

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
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 2,
                  child: _SpiceSection(item: item),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 3,
                  child: _IngredientsSection(item: item),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 4,
                  child: addOnsBuilder(item),
                ),
              ),
              // 7. Did-you-know card (locale-aware, hidden when no fact).
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 5,
                  child: _DidYouKnowSection(item: item),
                ),
              ),
              // 8. Ratings and reviews (hidden when there are none).
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 6,
                  child: _ReviewsSection(item: item),
                ),
              ),
              // 9. Related dishes from the already-loaded menu provider.
              SliverToBoxAdapter(
                child: StaggerIn(
                  animation: entrance,
                  index: 7,
                  child: _RelatedSection(item: item),
                ),
              ),
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
  final VoidCallback? onAdd;

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
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : AppMotion.fast,
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
                key: const Key('dish-add-to-cart'),
                onPressed: onAdd,
                icon: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.fast,
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
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.fast,
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
        padding: EdgeInsets.all(AppSpace.v0),
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

class DishHeroState extends State<DishHero>
    with SingleTickerProviderStateMixin {
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
      _floatController.value = AppSpace.v0;
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
    final height =
        (MediaQuery.sizeOf(context).height * DishDetailMetrics.heroHeightFactor)
            .clamp(AppSpace.v0, DishDetailMetrics.heroMaxHeight)
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
            alignment: Alignment(
              AppSpace.v0,
              DishDetailMetrics.heroCircleAlignmentY,
            ),
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
                      offset: Offset(AppSpace.v0, AppSpace.v6),
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
                  final progress = AppMotion.floatCurve.transform(
                    _floatController.value,
                  );
                  final offset = reduceMotion
                      ? AppSpace.v0
                      : (progress - AppMotion.floatMidpoint) *
                          2 *
                          DishDetailMetrics.floatDistance;
                  return Transform.translate(
                    offset: Offset(AppSpace.v0, offset),
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
              onPressed: () => backFromDish(context),
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
            padding: EdgeInsets.all(AppSpace.v0),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pop.stop();
      _pop.value = 0;
    }
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
            _pop.drive(CurveTween(curve: AppMotion.enter)),
          ),
          child: _HeroCircleButton(
            icon:
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
          Text(dishName(item.id, item.name, isSw: t.isSw),
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpace.v4),
          if (dishOtherName(item.id, isSw: t.isSw).isNotEmpty)
            Text(dishOtherName(item.id, isSw: t.isSw),
                style: theme.textTheme.bodyMedium),
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
            dishDescription(widget.item.id, widget.item.description,
                isSw: t.isSw),
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

class _SectionShell extends StatelessWidget {
  const _SectionShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screenH,
        DishDetailMetrics.sectionTop,
        AppSpace.screenH,
        DishDetailMetrics.sectionBottom,
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

String _spiceIntensityLabel(AppStrings t, int level) {
  if (level <= 1) return t.spiceMild;
  if (level == 2) return t.spiceMedium;
  if (level == 3) return t.spiceHot;
  return t.spiceExtraHot;
}

class _SpiceSection extends ConsumerWidget {
  const _SpiceSection({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = item.spiceLevel;
    if (level == null) return const SizedBox.shrink();
    final t = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clamped = level < 0 ? 0 : (level > 5 ? 5 : level);
    final selectedColor = isDark ? AppColors.heroLight : AppColors.primaryDeep;
    final emptyColor = isDark ? AppColors.darkCard : AppColors.surfaceWarm;

    return _SectionShell(
      key: const Key('dish-spice-section'),
      child: Semantics(
        label: t.spiceLevelSemantics(clamped),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SectionTitle(title: t.spice),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Flexible(
                    child: Text(
                      _spiceIntensityLabel(t, clamped),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: List<Widget>.generate(5, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 4 ? AppSpace.v0 : AppSpace.sm,
                      ),
                      child: Container(
                        height: DishDetailMetrics.spicePillHeight,
                        decoration: BoxDecoration(
                          color: index < clamped ? selectedColor : emptyColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: theme.colorScheme.outline,
                            width: AppSpace.hairline,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientsSection extends ConsumerWidget {
  const _IngredientsSection({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (item.ingredients.isEmpty && item.allergens.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = ref.watch(appStringsProvider);
    return _SectionShell(
      key: const Key('dish-ingredients-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.ingredients.isNotEmpty) ...[
            _SectionTitle(title: t.ingredients),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: item.ingredients
                  .map((ingredient) => _DetailChip(label: ingredient))
                  .toList(),
            ),
          ],
          if (item.allergens.isNotEmpty) ...[
            SizedBox(
              height: item.ingredients.isNotEmpty
                  ? DishDetailMetrics.sectionGap
                  : AppSpace.v0,
            ),
            _SectionTitle(title: t.contains),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: item.allergens
                  .map(
                    (allergen) => _DetailChip(label: allergen, outlined: true),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.label,
    this.outlined = false,
  });

  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.v6,
      ),
      decoration: BoxDecoration(
        color: outlined
            ? (isDark ? AppColors.darkSurface : AppColors.surface)
            : (isDark ? AppColors.darkCard : AppColors.surfaceWarm),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: outlined
            ? Border.all(
                color: theme.colorScheme.outline,
                width: AppSpace.hairline,
              )
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(color: secondary),
      ),
    );
  }
}

class _AddOnsSection extends ConsumerWidget {
  const _AddOnsSection({
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<CustomizationOption> options;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (options.isEmpty) return const SizedBox.shrink();
    final t = ref.watch(appStringsProvider);
    return _SectionShell(
      key: const Key('dish-add-ons-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: t.addOns),
          const SizedBox(height: AppSpace.xs),
          Text(t.isSw
              ? 'Si lazima. Chagua kila nyongeza mara moja kwa kila bidhaa.'
              : 'Optional. Each extra is selected once per item.'),
          const SizedBox(height: AppSpace.md),
          for (final option in options) ...[
            _AddOnRow(
              semanticKey: ValueKey<String>('dish-add-on-${option.id}'),
              option: option,
              selected: selectedIds.contains(option.id),
              onTap: () => onToggle(option.id),
            ),
            if (option != options.last) const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.semanticKey,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final Key semanticKey;
  final CustomizationOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.heroLight : AppColors.primaryDeep;
    return Semantics(
      key: semanticKey,
      checked: selected,
      button: true,
      label: '${option.name}, +${AppStrings.formatTzs(option.price)}',
      child: ExcludeSemantics(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: DishDetailMetrics.addOnRowMinHeight,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '+${AppStrings.formatTzs(option.price)}',
                    maxLines: 1,
                    style: TextStyle(
                      color: selectedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.fast,
                  switchInCurve: AppMotion.enter,
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.add_circle_outline_rounded,
                    key: ValueKey<bool>(selected),
                    size: AppSpace.v24,
                    color: selected ? selectedColor : theme.colorScheme.outline,
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

class _AddOnSkeletonRows extends StatelessWidget {
  const _AddOnSkeletonRows();

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      key: const Key('dish-add-ons-loading'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: AppSpace.v148,
            height: AppSpace.v24,
            radius: AppRadius.sm,
          ),
          const SizedBox(height: AppSpace.md),
          for (var index = 0; index < 2; index++) ...[
            if (index > 0) const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: SkeletonBox(
                    height: AppSpace.v24,
                    radius: AppRadius.sm,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                SkeletonBox(
                  width: AppSpace.v76,
                  height: AppSpace.v24,
                  radius: AppRadius.sm,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections 7-9. Each returns SizedBox.shrink() when its data is missing, so a
// dish with no fact, no reviews and no siblings renders no empty space.
// ---------------------------------------------------------------------------

/// Section 7: the locale-aware "Did you know?" card. It uses the same surface,
/// radius, orange hairline border and header treatment as the Daily Swahili
/// Discovery card on Home, with a real icon instead of an emoji.
class _DidYouKnowSection extends ConsumerWidget {
  const _DidYouKnowSection({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final fact = (t.isSw
            ? (item.funFactSw ?? item.funFactEn)
            : (item.funFactEn ?? item.funFactSw))
        ?.trim();
    if (fact == null || fact.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SectionShell(
      child: Container(
        key: const Key('dish-did-you-know-section'),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary.withOpacity(0.28)),
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
                    t.didYouKnow,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color:
                          isDark ? AppColors.heroLight : AppColors.primaryDeep,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.v8),
            Text(
              fact,
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
      ),
    );
  }
}

/// Section 8: rating summary plus the three most recent reviews. The provider
/// fails silently to an empty section so a slow read never blocks the page.
class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(dishReviewsProvider(item.id));
    return AsyncSkeleton<List<MenuReviewModel>>(
      value: reviewsAsync,
      skeleton: const SizedBox.shrink(),
      isEmpty: (reviews) => reviews.isEmpty,
      empty: const SizedBox.shrink(),
      errorWidget: const SizedBox.shrink(),
      data: (reviews) => _ReviewsContent(item: item, reviews: reviews),
    );
  }
}

class _ReviewsContent extends ConsumerWidget {
  const _ReviewsContent({required this.item, required this.reviews});

  final MenuItemModel item;
  final List<MenuReviewModel> reviews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latest = List<MenuReviewModel>.from(reviews)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final shown = latest.take(3).toList(growable: false);

    return _SectionShell(
      child: Column(
        key: const Key('dish-reviews-section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _SectionTitle(title: t.reviews)),
              const SizedBox(width: AppSpace.sm),
              Flexible(
                child: Text(
                  '${item.rating.toStringAsFixed(1)} • ${item.ratingCount}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.heroLight : AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          for (final review in shown) ...[
            _ReviewRow(review: review),
            if (review != shown.last) const SizedBox(height: AppSpace.sm),
          ],
        ],
      ),
    );
  }
}

class _ReviewRow extends ConsumerWidget {
  const _ReviewRow({required this.review});

  final MenuReviewModel review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded,
                  size: AppSpace.v16, color: AppColors.gold),
              const SizedBox(width: AppSpace.v6),
              Expanded(
                child: Text(
                  t.customer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${review.rating}/5',
                style: TextStyle(
                  color: isDark ? AppColors.heroLight : AppColors.primaryDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.v4),
          Text(
            review.comment.trim().isEmpty ? t.noReviews : review.comment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section 9: up to five same-category dishes from the already-loaded menu.
/// Tapping replaces the current detail route with the "related" hero scope.
class _RelatedSection extends ConsumerWidget {
  const _RelatedSection({required this.item});

  final MenuItemModel item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final menu =
        ref.watch(allMenuItemsProvider).valueOrNull ?? const <MenuItemModel>[];
    final related = menu
        .where(
            (dish) => dish.id != item.id && dish.categoryId == item.categoryId)
        .take(5)
        .toList(growable: false);
    if (related.isEmpty) return const SizedBox.shrink();

    return _SectionShell(
      child: Column(
        key: const Key('dish-related-section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: t.youMayAlsoLike),
          const SizedBox(height: AppSpace.md),
          SizedBox(
            height: DishCardMetrics.cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: related.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpace.md),
              itemBuilder: (_, index) => _RelatedDishCard(
                key: ValueKey<String>('dish-related-${related[index].id}'),
                dish: related[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of the signature dish card, using the shared DishCardMetrics
/// so the real card, its skeleton and this row stay in one geometry.
class _RelatedDishCard extends ConsumerWidget {
  const _RelatedDishCard({super.key, required this.dish});

  final MenuItemModel dish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: DishCardMetrics.cardMaxWidth,
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.v22),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.v22),
          onTap: () => context.push(
            '/dish/${Uri.encodeComponent(dish.id)}',
            extra: DishRouteArgs(
              item: dish,
              heroScope: DishHeroScopes.related,
            ),
          ),
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
                Center(
                  child: DishHeroImage(
                    item: dish,
                    heroScope: DishHeroScopes.related,
                    width: DishCardMetrics.imageSize,
                    height: DishCardMetrics.imageSize,
                    borderRadius: AppRadius.v18,
                  ),
                ),
                const SizedBox(height: AppSpace.v10),
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
                const SizedBox(height: AppSpace.v4),
                Text(
                  '${dish.rating.toStringAsFixed(1)} • ${dish.calories} kcal',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  AppStrings.formatTzs(dish.price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.heroLight : AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
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
