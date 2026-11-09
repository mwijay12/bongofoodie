import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/icons/app_icon_key.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../state/auth_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/settings_provider.dart';

class StaffDispatchScreen extends ConsumerStatefulWidget {
  const StaffDispatchScreen({super.key});

  @override
  ConsumerState<StaffDispatchScreen> createState() =>
      _StaffDispatchScreenState();
}

class _StaffDispatchScreenState extends ConsumerState<StaffDispatchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String _statusFilter = 'active';
  final _discTitleCtrl = TextEditingController();
  final _discBodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _discTitleCtrl.dispose();
    _discBodyCtrl.dispose();
    super.dispose();
  }

  OrderStatus? _nextStatusFor(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.inTransit;
      case OrderStatus.inTransit:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }

  String _actionLabelFor(OrderStatus current) {
    switch (current) {
      case OrderStatus.pending:
        return 'Start Cooking';
      case OrderStatus.preparing:
        return 'Mark Ready for Rider';
      case OrderStatus.ready:
        return 'Dispatch Boda Rider';
      case OrderStatus.inTransit:
        return 'Confirm Delivered';
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final ordersAsync = ref.watch(staffOrdersProvider);
    final discoveriesAsync = ref.watch(dailyDiscoveriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = ref.watch(appStringsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.staffDispatchTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpace.v2),
                  Text(
                    '${(user?.role.value ?? 'staff').toUpperCase()} • Kijitonyama Live Queue',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
        actions: [
          TextButton(
            onPressed: () => context.go('/home'),
            style: TextButton.styleFrom(
              minimumSize: const Size.square(AppSpace.huge),
            ),
            child: const Text('Storefront →'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const AppIcon(
                    iconKey: AppIconKey.delivery,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpace.v4),
                  Flexible(
                    child: Text(
                      'Live Orders',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const AppIcon(
                    iconKey: AppIconKey.idea,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpace.v4),
                  Flexible(
                    child: Text(
                      'Daily Discoveries',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Live Kitchen & Waiter Order Queue
          ordersAsync.when(
            data: (allOrders) {
              final filtered = _statusFilter == 'active'
                  ? allOrders
                      .where((o) =>
                          o.status != OrderStatus.delivered &&
                          o.status != OrderStatus.cancelled)
                      .toList()
                  : allOrders;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Row(
                      children: [
                        ChoiceChip(
                          selected: _statusFilter == 'active',
                          selectedColor: AppColors.primary,
                          label: Text(
                            'Active Queue (${allOrders.where((o) => o.status != OrderStatus.delivered).length})',
                            style: TextStyle(
                              color: _statusFilter == 'active'
                                  ? AppColors.surface
                                  : null,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _statusFilter = 'active'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          selected: _statusFilter == 'all',
                          selectedColor: AppColors.primary,
                          label: Text(
                            'All Orders (${allOrders.length})',
                            style: TextStyle(
                              color:
                                  _statusFilter == 'all' ? AppColors.surface : null,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _statusFilter = 'all'),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () =>
                              ref.read(staffOrdersProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                AppIcon(
                                  iconKey: AppIconKey.celebration,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: AppSpace.v8),
                                Flexible(
                                  child: Text(
                                    'All active orders have been dispatched!',
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(20, 6, 20, 32),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final order = filtered[i];
                              final next = _nextStatusFor(order.status);
                              return Container(
                                padding: const EdgeInsets.all(AppSpace.lg),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCard
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '#${order.id} • ${order.customerName}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: AppSpace.xs),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.14),
                                            borderRadius:
                                                BorderRadius.circular(AppRadius.pill),
                                          ),
                                          child: Text(
                                            order.status.labelEn,
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const AppIcon(
                                          iconKey: AppIconKey.location,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: AppSpace.v6),
                                        Expanded(
                                          child: Text(
                                            order.deliveryAddress,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const AppIcon(
                                          iconKey: AppIconKey.phone,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: AppSpace.v6),
                                        Expanded(
                                          child: Text(
                                            order.customerPhone,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 18),
                                    ...order.items.map(
                                      (item) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          '• ${item.quantity}× ${item.name}${item.customizations.isNotEmpty ? ' (+${item.customizations.map((c) => c.name).join(', ')})' : ''}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _OrderCardFooter(
                                      total: AppStrings.formatTzs(order.totalAmount),
                                      paymentMethod: order.paymentMethodType.label,
                                      actionLabel:
                                          next == null ? null : _actionLabelFor(order.status),
                                      onAdvance: () async {
                                        await ref
                                            .read(staffOrdersProvider.notifier)
                                            .advanceStatus(order.id, next!);
                                        await ref
                                            .read(userOrdersProvider.notifier)
                                            .refresh();
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading queue: $e')),
          ),

          // TAB 2: Admin Daily Swahili Discoveries Manager
          ListView(
            padding: const EdgeInsets.all(AppSpace.screenH),
            children: [
              const Text(
                'Publish Daily Swahili Food Fact',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _discTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title (e.g. Siri ya Karafuu za Pemba)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _discBodyCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Culinary fact or tip shown on Customer Home',
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  if (_discTitleCtrl.text.trim().isEmpty ||
                      _discBodyCtrl.text.trim().isEmpty) {
                    return;
                  }
                  await ref.read(dailyDiscoveriesProvider.notifier).addDiscovery(
                        _discTitleCtrl.text.trim(),
                        _discBodyCtrl.text.trim(),
                      );
                  _discTitleCtrl.clear();
                  _discBodyCtrl.clear();
                },
                icon: const Icon(Icons.publish_rounded),
                label: const Text('Publish Discovery'),
              ),
              const SizedBox(height: 20),
              discoveriesAsync.when(
                data: (items) => Column(
                  children: items
                      .map(
                        (d) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(
                              d.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(d.description),
                            trailing: IconButton(
                              onPressed: () => ref
                                  .read(dailyDiscoveriesProvider.notifier)
                                  .removeDiscovery(d.id),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Order-card footer: total + payment method on row 1, full-width action on row 2.
/// The button spans the full card width so it can never clip past the right edge
/// of the card or the screen, even at large text scale factors.
class _OrderCardFooter extends StatelessWidget {
  const _OrderCardFooter({
    required this.total,
    required this.paymentMethod,
    required this.actionLabel,
    required this.onAdvance,
  });

  final String total;
  final String paymentMethod;
  final String? actionLabel;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Card content width: screen width minus the queue ListView horizontal
    // padding (2 x AppSpace.screenH) and the card container padding (2 x AppSpace.lg).
    final cardWidth =
        MediaQuery.sizeOf(context).width - 2 * AppSpace.screenH - 2 * AppSpace.lg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    total,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpace.v2),
                  Text(
                    paymentMethod,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.inkMuted,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.v10),
        if (actionLabel != null)
          SizedBox(
            width: cardWidth,
            height: AppSpace.huge,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpace.huge),
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
              ),
              onPressed: onAdvance,
              child: Text(
                actionLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
