import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/env_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_image.dart';
import '../../core/widgets/tanzania_location_sheet.dart';
import '../../data/mock/showcase_seed_data.dart';
import '../../data/models/models.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/menu_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/settings_provider.dart';
import '../menu/widgets/dish_detail_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openSpiceTriviaSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final user = ref.read(authProvider).user;
    final repo = ref.read(menuRepositoryProvider);
    final alreadyPlayed = await repo.hasAttemptedTriviaToday(user?.id);
    if (!context.mounted) return;

    final daySeed = DateTime.now().day;
    final question = ShowcaseSeedData
        .triviaQuestions[daySeed % ShowcaseSeedData.triviaQuestions.length];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _SpiceTriviaSheet(
        question: question,
        alreadyPlayed: alreadyPlayed,
        userId: user?.id,
      ),
    );
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    final val = int.tryParse('FF$clean', radix: 16);
    return val != null ? Color(val) : AppColors.primary;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final auth = ref.watch(authProvider);
    final address = ref.watch(deliveryAddressProvider);
    final promotionsAsync = ref.watch(promotionsProvider);
    final discoveriesAsync = ref.watch(dailyDiscoveriesProvider);
    final menuAsync = ref.watch(allMenuItemsProvider);
    final favorites = ref.watch(favoritesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(promotionsProvider);
            ref.invalidate(allMenuItemsProvider);
            await ref.read(dailyDiscoveriesProvider.notifier).refresh();
          },
          child: CustomScrollView(
            slivers: [
              // 1. Top Location + Role/Mode Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => showTanzaniaLocationPicker(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t.deliverTo.toUpperCase(),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (EnvConfig.hasSupabaseCredentials
                                                ? AppColors.success
                                                : AppColors.primary)
                                            .withOpacity(0.14),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        EnvConfig.hasSupabaseCredentials
                                            ? t.liveMode
                                            : t.showcaseMode,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: EnvConfig
                                                  .hasSupabaseCredentials
                                              ? AppColors.success
                                              : AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      size: 17,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
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
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: const Icon(
                              Icons.soup_kitchen_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            backgroundColor: AppColors.espresso,
                            label: const Text(
                              'Staff Live',
                              style: TextStyle(
                                color: Colors.white,
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
                          backgroundColor:
                              AppColors.primary.withOpacity(0.14),
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
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.karibuTitle}, ${(auth.user?.name ?? 'Foodie').split(' ').first} 👋',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.heroSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                      ),
                      const SizedBox(height: 16),

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
                child: promotionsAsync.when(
                  data: (promos) => SizedBox(
                    height: 148,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: promos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final p = promos[index];
                        final bg = _parseHex(p.bgColorHex);
                        return InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => context.go(
                            '/search?category=${Uri.encodeComponent(p.targetCategory)}',
                          ),
                          child: Container(
                            width: 285,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (p.badgeText.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.22),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            p.badgeText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Text(
                                        p.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 17,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p.subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                DishImage(
                                  imageRef: p.imageKey,
                                  width: 76,
                                  height: 76,
                                  borderRadius: 16,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // 4. Daily Swahili Discovery + Trivia Challenge Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  child: discoveriesAsync.when(
                    data: (list) {
                      final featured = list.isNotEmpty
                          ? list.first
                          : ShowcaseSeedData.discoveries.first;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.28),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_rounded,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.dailyDiscovery,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
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
                            Text(
                              featured.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // 5. Signature Dishes Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      Text(
                        t.popularDishes,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/search'),
                        child: Text(
                          t.isSw ? 'Ona Menyu Yote →' : 'Full Menu →',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Signature Dishes Responsive Grid
              menuAsync.when(
                data: (items) {
                  final featured = items.take(8).toList();
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 230,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 270,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final dish = featured[index];
                          final isFav = favorites.contains(dish.id);
                          return _SignatureDishCard(
                            dish: dish,
                            isFavorite: isFav,
                            onTap: () => showDishDetailSheet(context, dish),
                            onToggleFavorite: () => ref
                                .read(favoritesProvider.notifier)
                                .toggle(dish.id),
                            onQuickAdd: () {
                              ref
                                  .read(cartProvider.notifier)
                                  .addItem(dish: dish);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${dish.name} added to your Cart!'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          );
                        },
                        childCount: featured.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error loading menu: $e')),
                ),
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
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
      ),
      child: Material(
        color: const Color(0xFF25231F),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF35322B), Color(0xFF171C19)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -55,
                  top: -65,
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(.08), width: 30),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('BONGO FOODIE  /  CHEF AI',
                              style: TextStyle(color: Color(0xFFF3B676), fontSize: 9,
                                letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            Text(title, style: const TextStyle(color: Colors.white,
                              fontSize: 22, height: 1.15, fontWeight: FontWeight.w700,
                              letterSpacing: -.5)),
                            const SizedBox(height: 8),
                            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.72),
                              fontSize: 12, height: 1.45)),
                            const SizedBox(height: 18),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(action, style: const TextStyle(color: Color(0xFFFFC98D),
                                fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 7),
                              const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFC98D), size: 16),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const DishImage(imageRef: 'bongoChefMascot', width: 92, height: 118, borderRadius: 22),
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

class _SignatureDishCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
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
                    child: DishImage(
                      imageRef: dish.imageUrl,
                      width: 112,
                      height: 112,
                      borderRadius: 18,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: onToggleFavorite,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black : Colors.white)
                              .withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isFavorite ? AppColors.error : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 3),
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
              const SizedBox(height: 4),
              Text(
                dish.name,
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
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Add ${dish.name} to cart',
                    child: InkWell(
                    onTap: onQuickAdd,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
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
    final isCorrect = _pickedIndex == widget.question.correctIndex;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Daily Swahili Spice Trivia',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.alreadyPlayed && !_submitted
                ? 'You already unlocked today’s reward — feel free to practice again or copy code KARIBU2000!'
                : 'Answer right to unlock code KARIBU2000 (TSh 2,000 OFF at checkout)!',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            widget.question.question,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(widget.question.options.length, (i) {
            final option = widget.question.options[i];
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
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (isCorrect ? AppColors.success : AppColors.primary)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect
                        ? 'Hongera! Reward Code Unlocked: KARIBU2000 🎉'
                        : 'Good try! ${widget.question.rewardNote}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  if (isCorrect)
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'KARIBU2000'),
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Promo code KARIBU2000 copied for Cart!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Code KARIBU2000'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
