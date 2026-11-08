import '../../../core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dish_image.dart';
import '../../../data/models/models.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../state/cart_provider.dart';
import '../../../state/menu_provider.dart';
import '../../../state/settings_provider.dart';

Future<void> showDishDetailSheet(BuildContext context, MenuItemModel dish) {
  return showAppSheet<void>(
    context,
    backgroundColor: AppColors.clear,
    showDragHandle: false,
    builder: (_) => DishDetailSheet(dish: dish),
  );
}

class DishDetailSheet extends ConsumerStatefulWidget {
  final MenuItemModel dish;

  const DishDetailSheet({super.key, required this.dish});

  @override
  ConsumerState<DishDetailSheet> createState() => _DishDetailSheetState();
}

class _DishDetailSheetState extends ConsumerState<DishDetailSheet> {
  final Set<String> _selectedCustomizationIds = <String>{};
  int _quantity = 1;
  late double _displayRating;
  int _userRatedStars = 0;

  @override
  void initState() {
    super.initState();
    _displayRating = widget.dish.rating;
  }

  List<CustomizationOption> get _selectedCustomizations => widget
      .dish.availableCustomizations
      .where((c) => _selectedCustomizationIds.contains(c.id))
      .toList();

  double get _unitTotal =>
      widget.dish.price +
      _selectedCustomizations.fold<double>(0, (s, c) => s + c.price);

  double get _totalPrice => _unitTotal * _quantity;

  Future<void> _submitRating(int stars) async {
    setState(() => _userRatedStars = stars);
    final updated = await ref.read(menuRepositoryProvider).rateDish(
          menuId: widget.dish.id,
          stars: stars,
          currentRating: _displayRating,
        );
    if (mounted) {
      setState(() => _displayRating = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Asante! Rated ${widget.dish.name} $stars/5 ★'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(widget.dish.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.60,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.v28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpace.v10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.inkMuted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(AppSpace.v22, AppSpace.v14, AppSpace.v22, AppSpace.v24),
                  children: [
                    // Top Action Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.md, vertical: AppSpace.v6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            widget.dish.categoryName,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Share Dish',
                          onPressed: () {
                            Share.share(
                              'Check out ${widget.dish.name} (${AppStrings.formatTzs(widget.dish.price)}) on BongoFoodie Dar es Salaam! 🇹🇿🍲',
                            );
                          },
                          icon: const Icon(Icons.ios_share_rounded),
                        ),
                        IconButton(
                          tooltip: 'Save Favorite',
                          onPressed: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(widget.dish.id),
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav ? AppColors.error : null,
                          ),
                        ),
                      ],
                    ),

                    // Dish Visual
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpace.v10),
                        child: DishImage(
                          imageRef: widget.dish.imageUrl,
                          width: 210,
                          height: 210,
                          borderRadius: AppRadius.v28,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.v8),

                    // Title & Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.dish.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpace.v12),
                        Text(
                          AppStrings.formatTzs(widget.dish.price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.v10),
                    Text(
                      widget.dish.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpace.v18),

                    // Nutrition & Prep Strip
                    Row(
                      children: [
                        _MetricPill(
                          icon: Icons.star_rounded,
                          iconColor: AppColors.gold,
                          label:
                              '${_displayRating.toStringAsFixed(1)} (${widget.dish.ratingCount})',
                        ),
                        const SizedBox(width: AppSpace.v8),
                        _MetricPill(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: AppColors.primaryDeep,
                          label: '${widget.dish.calories} kcal',
                        ),
                        const SizedBox(width: AppSpace.v8),
                        _MetricPill(
                          icon: Icons.fitness_center_rounded,
                          iconColor: AppColors.success,
                          label: '${widget.dish.protein}g prot',
                        ),
                        const SizedBox(width: AppSpace.v8),
                        _MetricPill(
                          icon: Icons.schedule_rounded,
                          iconColor: AppColors.info,
                          label: '${widget.dish.prepTimeMins}m',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.v20),

                    // Customizations Section
                    if (widget.dish.availableCustomizations.isNotEmpty) ...[
                      Text(
                        t.isSw
                            ? 'Ongeza Vikolezo & Sides za Kiswahili'
                            : 'Customize with Swahili Sides & Extras',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: AppSpace.v10),
                      Wrap(
                        spacing: AppSpace.v8,
                        runSpacing: AppSpace.v8,
                        children: widget.dish.availableCustomizations.map((opt) {
                          final selected =
                              _selectedCustomizationIds.contains(opt.id);
                          return FilterChip(
                            selected: selected,
                            selectedColor: AppColors.primary.withOpacity(0.18),
                            checkmarkColor: AppColors.primary,
                            label: Text(
                              '${opt.name} (+${AppStrings.formatTzs(opt.price)})',
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedCustomizationIds.add(opt.id);
                                } else {
                                  _selectedCustomizationIds.remove(opt.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpace.v20),
                    ],

                    // Interactive 5-Star Rating Card
                    Container(
                      padding: const EdgeInsets.all(AppSpace.v14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.v18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.isSw
                                  ? 'ipa alama sahani hii:'
                                  : 'Rate this dish:',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          ...List.generate(5, (index) {
                            final star = index + 1;
                            final active = star <= _userRatedStars;
                            return InkWell(
                              onTap: () => _submitRating(star),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: AppSpace.v3),
                                child: Icon(
                                  active
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: AppColors.gold,
                                  size: 26,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Sticky Quantity + Add to Cart Bar
              SafeArea(
                top: false,
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH, vertical: AppSpace.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.scrim.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.v14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove_rounded, size: 18),
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add_rounded, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.v14),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(cartProvider.notifier).addItem(
                                dish: widget.dish,
                                quantity: _quantity,
                                customizations: _selectedCustomizations,
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${widget.dish.name} ×$_quantity added to Cart!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_rounded, size: 19),
                        label: Text(
                          '${t.addToCart} • ${AppStrings.formatTzs(_totalPrice)}',
                        ),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _MetricPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.v6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: AppSpace.v4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
