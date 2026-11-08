import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_image.dart';
import '../../data/models/models.dart';
import '../../state/auth_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/settings_provider.dart';
import '../menu/widgets/dish_detail_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openFavoritesModal(
    BuildContext context,
    List<MenuItemModel> favDishes,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '❤️ Saved Favorites (${favDishes.length})',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: favDishes.isEmpty
                    ? const Center(
                        child: Text(
                            'Tap the heart icon on any dish to save it here!'),
                      )
                    : ListView.separated(
                        controller: controller,
                        itemCount: favDishes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, idx) {
                          final dish = favDishes[idx];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: DishImage(
                              imageRef: dish.imageUrl,
                              width: 52,
                              height: 52,
                              borderRadius: 12,
                            ),
                            title: Text(
                              dish.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(AppStrings.formatTzs(dish.price)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.pop(ctx);
                              showDishDetailSheet(context, dish);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(appStringsProvider);
    final settings = ref.watch(appSettingsProvider);
    final auth = ref.watch(authProvider);
    final ordersAsync = ref.watch(userOrdersProvider);
    final favorites = ref.watch(favoritesProvider);
    final allMenu = ref.watch(allMenuItemsProvider).valueOrNull ?? const [];
    final favDishes =
        allMenu.where((item) => favorites.contains(item.id)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = auth.user;
    final orders = ordersAsync.valueOrNull ?? const <OrderModel>[];

    final achievements = [
      (
        icon: '🔥',
        title: 'Mkaa Connoisseur',
        unlocked: orders.isNotEmpty,
        desc: 'Placed a Swahili order',
      ),
      (
        icon: '🌶️',
        title: 'Pilipili Shujaa',
        unlocked: favorites.length >= 2,
        desc: 'Saved 2+ favorite dishes',
      ),
      (
        icon: '👨‍🍳',
        title: 'Chef AI Co-Creator',
        unlocked: orders.any((o) => o.items.any((i) => i.isCustomAiDish)),
        desc: 'Ordered a Chef AI dish',
      ),
      (
        icon: '🥥',
        title: 'Pwani Explorer',
        unlocked: true,
        desc: 'Explored coastal menu',
      ),
      (
        icon: '🏆',
        title: 'Spice Scholar',
        unlocked: true,
        desc: 'Daily Trivia participant',
      ),
      (
        icon: '💎',
        title: 'Bongo VIP',
        unlocked: orders.length >= 3,
        desc: '3+ orders completed',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
          children: [
            // 1. User Identity Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.ember, AppColors.ink],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          user?.initials ?? 'BF',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?.name ?? 'Guest Foodie',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.surface,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.sm, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.28),
                                    borderRadius: BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    (user?.role.value ?? 'guest').toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.heroLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? 'Sign in to sync across devices',
                              style: TextStyle(
                                color: AppColors.surface.withOpacity(0.76),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Role Switcher / Staff Console CTA
                  Row(
                    children: [
                      if (user?.role.isStaff == true)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/staff'),
                            icon: const Icon(Icons.soup_kitchen_rounded,
                                size: 18),
                            label: Text(t.staffDispatch),
                          ),
                        )
                      else
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.surface,
                              side: BorderSide(
                                  color: AppColors.surface.withOpacity(0.3)),
                            ),
                            onPressed: () async {
                              await ref
                                  .read(authProvider.notifier)
                                  .signInDemo(UserRole.admin);
                              if (context.mounted) context.push('/staff');
                            },
                            icon: const Icon(Icons.admin_panel_settings_rounded,
                                size: 18),
                            label: const Text('Preview Staff/Admin Console'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Stats Row
            Row(
              children: [
                _StatCard(
                  title: t.myOrders,
                  value: '${orders.length}',
                  icon: Icons.receipt_long_rounded,
                  onTap: null,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  title: t.favorites,
                  value: '${favorites.length}',
                  icon: Icons.favorite_rounded,
                  onTap: () => _openFavoritesModal(context, favDishes),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  title: 'Badges',
                  value:
                      '${achievements.where((a) => a.unlocked).length}/${achievements.length}',
                  icon: Icons.workspace_premium_rounded,
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Preferences Card (Dark Mode + Language)
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined,
                        color: AppColors.primary),
                    title: Text(
                      t.darkMode,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    value: settings.isDark,
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        ref.read(appSettingsProvider.notifier).toggleDarkMode(v),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.translate_rounded,
                        color: AppColors.primary),
                    title: Text(
                      t.languageLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: SegmentedButton<AppLanguage>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: AppLanguage.en,
                          label: Text('EN'),
                        ),
                        ButtonSegment(
                          value: AppLanguage.sw,
                          label: Text('SW'),
                        ),
                      ],
                      selected: {settings.language},
                      onSelectionChanged: (s) => ref
                          .read(appSettingsProvider.notifier)
                          .setLanguage(s.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Live 4-Step Order Tracker
            Row(
              children: [
                Text(
                  t.isSw ? 'Fuatilia Oda Live' : 'Live Order Tracker',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Refresh Orders',
                  onPressed: () =>
                      ref.read(userOrdersProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpace.screenH),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'No orders yet — place an order from Cart to watch live 4-step kitchen & rider updates!',
                ),
              )
            else
              ...orders.take(5).map((order) => _LiveOrderCard(order: order)),

            const SizedBox(height: 18),

            // 5. Swahili Foodie Achievements Grid
            Text(
              t.achievements,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.98,
              ),
              itemCount: achievements.length,
              itemBuilder: (_, idx) {
                final badge = achievements[idx];
                return Opacity(
                  opacity: badge.unlocked ? 1.0 : 0.45,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: badge.unlocked
                            ? AppColors.primary.withOpacity(0.4)
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(badge.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(
                          badge.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 6. Sign Out / Switch Account Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.45)),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go('/sign-in');
              },
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                user == null ? 'Sign In / Switch Role' : t.signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveOrderCard extends StatelessWidget {
  final OrderModel order;

  const _LiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = ['Preparing', 'Ready', 'On Way', 'Delivered'];
    final activeStep = order.status.stepIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppSpace.lg),
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
              Text(
                '#${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
              ),
              const Spacer(),
              Text(
                AppStrings.formatTzs(order.totalAmount),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            order.items.map((i) => '${i.quantity}× ${i.name}').join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (order.status == OrderStatus.cancelled)
            const Text(
              'Order Cancelled',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w800),
            )
          else
            Row(
              children: List.generate(steps.length, (i) {
                final done = i <= activeStep;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.success
                              : AppColors.inkMuted.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[i],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              done ? FontWeight.w800 : FontWeight.w500,
                          color: done ? AppColors.success : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
