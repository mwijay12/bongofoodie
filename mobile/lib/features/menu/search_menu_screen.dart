import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_hero_image.dart';
import '../../router/dish_route_args.dart';
import '../../core/widgets/skeleton/shimmer.dart';
import '../../core/widgets/skeleton/skeleton_chip_row.dart';
import '../../core/widgets/skeleton/skeleton_dish_card.dart';
import '../../core/widgets/skeleton/skeleton_menu_row.dart';
import '../../core/widgets/state_message.dart';
import '../../data/models/models.dart';
import '../../state/cart_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/settings_provider.dart';


abstract final class _MenuMetrics {
  static const gridImage = 108.0;
  static const listImage = 84.0;
  static const gridRatio = 0.74;
  static const gap = AppSpace.v14;
  static const padding = AppSpace.md;
}

enum MenuSortOption { topRated, priceLowHigh, fastestPrep }

class SearchMenuScreen extends ConsumerStatefulWidget {
  final String initialCategory;

  const SearchMenuScreen({super.key, this.initialCategory = 'All'});

  @override
  ConsumerState<SearchMenuScreen> createState() => _SearchMenuScreenState();
}

class _SearchMenuScreenState extends ConsumerState<SearchMenuScreen> {
  final _searchCtrl = TextEditingController();
  late String _selectedCategory;
  MenuSortOption _sortBy = MenuSortOption.topRated;
  bool _gridMode = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory.isEmpty ? 'All' : widget.initialCategory;
  }

  @override
  void didUpdateWidget(covariant SearchMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory.isNotEmpty &&
        widget.initialCategory != oldWidget.initialCategory) {
      setState(() => _selectedCategory = widget.initialCategory);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MenuItemModel> _applyFilters(List<MenuItemModel> allItems) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final catTarget = _selectedCategory.trim().toLowerCase();

    var filtered = allItems.where((item) {
      // Fixed v2: Match against BOTH category Name and category UUID
      final matchesCat = catTarget == 'all' ||
          item.categoryName.toLowerCase() == catTarget ||
          item.categoryId.toLowerCase() == catTarget;
      final matchesQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q) ||
          item.categoryName.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();

    switch (_sortBy) {
      case MenuSortOption.topRated:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case MenuSortOption.priceLowHigh:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case MenuSortOption.fastestPrep:
        filtered.sort((a, b) => a.prepTimeMins.compareTo(b.prepTimeMins));
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final menuAsync = ref.watch(allMenuItemsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator.adaptive(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(categoriesProvider);
            ref.invalidate(allMenuItemsProvider);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.v20, AppSpace.v14, AppSpace.v20, AppSpace.v10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.isSw ? 'Menyu ya BongoFoodie' : 'Explore Our Menu',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                  PopupMenuButton<MenuSortOption>(
                    tooltip: 'Sort dishes',
                    initialValue: _sortBy,
                    onSelected: (val) => setState(() => _sortBy = val),
                    icon: const Icon(Icons.tune_rounded),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: MenuSortOption.topRated,
                        child: Text('Top Rated'),
                      ),
                      PopupMenuItem(
                        value: MenuSortOption.priceLowHigh,
                        child: Text('Lowest Price'),
                      ),
                      PopupMenuItem(
                        value: MenuSortOption.fastestPrep,
                        child: Text('Fastest Prep'),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: _gridMode ? 'Switch to List' : 'Switch to Grid',
                    onPressed: () => setState(() => _gridMode = !_gridMode),
                    icon: Icon(
                      _gridMode
                          ? Icons.view_agenda_outlined
                          : Icons.grid_view_rounded,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: t.searchPlaceholder,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.v12),

            // Category Filter Chips
            SizedBox(
              height: AppSpace.v42,
              child: categoriesAsync.when(
                skipLoadingOnRefresh: true,
                data: (cats) {
                  final names = ['All', ...cats.map((c) => c.name)];
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screenH),
                    scrollDirection: Axis.horizontal,
                    itemCount: names.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpace.v8),
                    itemBuilder: (context, index) {
                      final catName = names[index];
                      final selected = _selectedCategory.toLowerCase() ==
                          catName.toLowerCase();
                      return ChoiceChip(
                        selected: selected,
                        selectedColor: AppColors.primary,
                        label: Text(
                          catName == 'All' ? t.allCategories : catName,
                          style: TextStyle(
                            color: selected ? AppColors.surface : null,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedCategory = catName),
                      );
                    },
                  );
                },
                loading: () => const SkeletonChipRow(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: AppSpace.v12),

            // Filtered Results
            Expanded(
              child: menuAsync.when(
                skipLoadingOnRefresh: true,
                data: (allItems) {
                  if (allItems.isEmpty) {
                    return StateMessage.empty(
                      title: t.emptyMenuTitle,
                      body: t.emptyMenuBody,
                    );
                  }
                  final items = _applyFilters(allItems);
                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.xxl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 54, color: AppColors.primary),
                            const SizedBox(height: AppSpace.v12),
                            Text(
                              t.isSw
                                  ? 'Hakuna chakula kilichopatikana'
                                  : 'No matching dishes found',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppSpace.v8),
                            TextButton(
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _selectedCategory = 'All');
                              },
                              child: Text(t.clearSearch),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (_gridMode) {
                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.xs, AppSpace.screenH, context.navClearance),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: _MenuMetrics.gap,
                        crossAxisSpacing: _MenuMetrics.gap,
                        childAspectRatio: _MenuMetrics.gridRatio,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final dish = items[i];
                        return _MenuGridTile(
                          dish: dish,
                          isDark: isDark,
                          onOpen: () => context.push('/dish/${dish.id}', extra: DishRouteArgs(item: dish, heroScope: DishHeroScopes.menuList)),
                          onAdd: () {
                            ref.read(cartProvider.notifier).addItem(dish: dish);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${dish.name} added to Cart!'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.xs, AppSpace.screenH, context.navClearance),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpace.v12),
                    itemBuilder: (ctx, i) {
                      final dish = items[i];
                      return _MenuListTile(
                        dish: dish,
                        isDark: isDark,
                        onOpen: () => context.push('/dish/${dish.id}', extra: DishRouteArgs(item: dish, heroScope: DishHeroScopes.menuList)),
                        onAdd: () {
                          ref.read(cartProvider.notifier).addItem(dish: dish);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${dish.name} added to Cart!'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => Semantics(
                  label: t.loading,
                  child: ExcludeSemantics(
                    child: Shimmer(
                      child: _gridMode
                          ? GridView.builder(
                              padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.xs,
                                  AppSpace.screenH, context.navClearance),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: _MenuMetrics.gap,
                                crossAxisSpacing: _MenuMetrics.gap,
                                childAspectRatio: _MenuMetrics.gridRatio,
                              ),
                              itemCount: 6,
                              itemBuilder: (_, __) => const SkeletonDishCard(),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.xs,
                                  AppSpace.screenH, context.navClearance),
                              itemCount: 6,
                              separatorBuilder: (_, __) => const SizedBox(height: AppSpace.v12),
                              itemBuilder: (_, __) => const SkeletonMenuRow(),
                            ),
                    ),
                  ),
                ),
                error: (_, __) => StateMessage.error(
                  onRetry: () => ref.invalidate(allMenuItemsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _MenuGridTile extends StatelessWidget {
  final MenuItemModel dish;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  const _MenuGridTile({
    required this.dish,
    required this.isDark,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(_MenuMetrics.padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
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
                  heroScope: DishHeroScopes.menuList,
                  width: _MenuMetrics.gridImage,
                  height: _MenuMetrics.gridImage,
                  borderRadius: AppRadius.v16,
                ),
              ),
              const SizedBox(height: AppSpace.v10),
              Text(
                dish.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpace.v2),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.formatTzs(dish.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(AppRadius.v10),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpace.v6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.v10),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: AppColors.surface,
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

class _MenuListTile extends StatelessWidget {
  final MenuItemModel dish;
  final bool isDark;
  final VoidCallback onOpen;
  final VoidCallback onAdd;

  const _MenuListTile({
    required this.dish,
    required this.isDark,
    required this.onOpen,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(_MenuMetrics.padding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            children: [
              DishHeroImage(
                item: dish,
                heroScope: DishHeroScopes.menuList,
                width: _MenuMetrics.listImage,
                height: _MenuMetrics.listImage,
                borderRadius: AppRadius.v16,
              ),
              const SizedBox(width: AppSpace.v14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: AppSpace.v4),
                    Text(
                      dish.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.v8),
                    Row(
                      children: [
                        Text(
                          AppStrings.formatTzs(dish.price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: AppSpace.v10),
                        Text(
                          '${dish.rating.toStringAsFixed(1)} • ${dish.prepTimeMins}m',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, color: AppColors.surface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
