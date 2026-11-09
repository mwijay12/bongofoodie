import '../../core/l10n/dish_copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_image.dart';
import '../../core/widgets/skeleton/skeleton_box.dart';
import '../../core/widgets/tanzania_location_sheet.dart';
import '../../data/models/models.dart';
import '../../data/repositories/location_repository.dart';
import '../../state/auth_provider.dart';
import '../../state/cart_provider.dart';
import '../../state/menu_provider.dart';
import '../../state/orders_provider.dart';
import '../../state/settings_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+255 754 123 456');
  final _notesCtrl = TextEditingController();
  PaymentMethod _paymentMethod = PaymentMethod.lipaNamba;
  bool _placingOrder = false;
  bool _orderFailed = false;

  void _removeLine(CartItemModel item) {
    final t = ref.read(appStringsProvider);
    final notifier = ref.read(cartProvider.notifier);
    final index = ref.read(cartProvider).items.indexOf(item);
    notifier.removeItem(item.signatureKey);
    final deadline = DateTime.now().add(CheckoutMetrics.undoDuration);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: CheckoutMetrics.undoDuration,
      content: Text(t.isSw ? 'Bidhaa imeondolewa' : 'Item removed'),
      action: SnackBarAction(
        label: t.isSw ? 'Rejesha' : 'Undo',
        onPressed: () {
          if (!_placingOrder && DateTime.now().isBefore(deadline)) {
            notifier.restoreItem(item, index: index);
          }
        },
      ),
    ));
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(
    CartState cart,
    BranchSettingsModel branch,
    String deliveryAddress,
  ) async {
    if (cart.items.isEmpty || _placingOrder) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _placingOrder = true;
      _orderFailed = false;
    });

    final cartNotifier = ref.read(cartProvider.notifier);
    final user = ref.read(authProvider).user;
    final now = DateTime.now();
    final shortCode =
        (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
    final order = OrderModel(
      id: 'BF-$shortCode',
      profileId: user?.id,
      customerName: user?.name ?? 'Dar es Salaam Guest',
      customerEmail: user?.email ?? '',
      customerPhone: _phoneCtrl.text.trim().isNotEmpty
          ? _phoneCtrl.text.trim()
          : (user?.phone ?? '+255 754 123 456'),
      deliveryLocation: deliveryAddress,
      items: cart.items,
      totalPrice: cart.grandTotal,
      paymentMethod: _paymentMethod.dbValue,
      notes: _notesCtrl.text.trim(),
      status: OrderStatus.preparing,
      createdAt: now,
    );

    try {
      final confirmed =
          await ref.read(userOrdersProvider.notifier).placeOrder(order);
      // A navigation away must not prevent clearing a confirmed order's cart.
      // The notifier is captured before awaiting because WidgetRef can be disposed.
      cartNotifier.clearCart();
      if (!mounted) return;
      _showReceiptDialog(confirmed, branch);
    } catch (_) {
      if (mounted) setState(() => _orderFailed = true);
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  void _showReceiptDialog(OrderModel order, BranchSettingsModel branch) {
    final t = ref.read(appStringsProvider);
    final receiptText = '''
BONGOFOODIE OFFICIAL RECEIPT
Order: #${order.id}
Customer: ${order.customerName}
Deliver to: ${order.deliveryAddress}
Items:
${order.items.map((i) => '• ${i.quantity}x ${i.name} (${AppStrings.formatTzs(i.lineTotal)})').join('\n')}
Total Paid/Due: ${AppStrings.formatTzs(order.totalAmount)}
Payment: ${order.paymentMethodType.label}${order.paymentMethodType == PaymentMethod.lipaNamba ? ' (Till ${branch.lipaNamba})' : ''}
Asante kwa kuchagua BongoFoodie TZ!
''';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.v24)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: AppColors.success, size: 28),
            const SizedBox(width: AppSpace.v10),
            Expanded(
              child: Text(
                t.isSw
                    ? 'Oda Imepokelewa! (#${order.id})'
                    : 'Order received! (#${order.id})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.isSw
                  ? 'Jiko linatayarisha oda yako.'
                  : 'The kitchen is preparing your order.',
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: AppSpace.v12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.v14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.total}: ${AppStrings.formatTzs(order.totalAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpace.v4),
                  Text(
                    order.paymentMethodType == PaymentMethod.lipaNamba
                        ? 'Lipa Namba: ${branch.lipaNamba} (${branch.lipaName})'
                        : t.isSw
                            ? 'Malipo: Pesa taslimu'
                            : 'Payment: Cash on Delivery',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
        actions: [
          OutlinedButton.icon(
            onPressed: () {
              Share.share(receiptText);
            },
            icon: const Icon(Icons.share_rounded, size: 16),
            label: const Text('Share Receipt'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/profile');
            },
            child: Text(t.isSw ? 'Fuatilia Oda' : 'Track Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appStringsProvider);
    final cart = ref.watch(cartProvider);
    final address = ref.watch(deliveryAddressProvider);
    final branchAsync = ref.watch(branchSettingsProvider);
    final branch = branchAsync.valueOrNull ?? const BranchSettingsModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sync live delivery fee from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_placingOrder && branchAsync.hasValue) {
        ref.read(cartProvider.notifier).syncDeliveryFee(branch.deliveryFee);
      }
    });

    if (cart.items.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.v18),
                  Text(
                    t.emptyCartTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpace.v8),
                  Text(
                    t.emptyCartSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpace.v22),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.restaurant_menu_rounded),
                    label: Text(t.browseMenu),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(AppSpace.screenH, AppSpace.sm,
            AppSpace.screenH, context.navClearance),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_orderFailed) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  t.isSw
                      ? 'Oda haijatumwa. Kikapu chako kimehifadhiwa. Jaribu tena.'
                      : 'Order not sent. Your cart is saved. Please retry.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const ValueKey('place-order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  foregroundColor: AppColors.surface,
                  minimumSize: const Size(AppSpace.huge, AppSpace.v56),
                ),
                onPressed: _placingOrder ||
                        !branchAsync.hasValue ||
                        branchAsync.hasError
                    ? null
                    : () => _submitOrder(cart, branch, address),
                child: Text(
                  _placingOrder
                      ? (t.isSw ? 'Inatuma oda…' : 'Sending order…')
                      : '${_orderFailed ? (t.isSw ? 'Jaribu tena' : 'Retry') : t.placeOrder} • ${AppStrings.formatTzs(cart.grandTotal)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: _placingOrder,
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                AppSpace.screenH, AppSpace.md, AppSpace.screenH, AppSpace.xl),
            children: [
              if (branchAsync.isLoading) ...[
                const SkeletonBox(height: AppSpace.huge),
                const SizedBox(height: AppSpace.md),
              ],
              if (branchAsync.hasError) ...[
                Text(t.isSw
                    ? 'Gharama za usafirishaji hazijapakiwa.'
                    : 'Delivery charges could not be loaded.'),
                TextButton(
                  onPressed: () => ref.invalidate(branchSettingsProvider),
                  child: Text(t.isSw ? 'Jaribu tena' : 'Retry'),
                ),
              ],
              Row(
                children: [
                  Expanded(
                      child: Text(
                    '${t.navCart} (${cart.totalItems})',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  )),
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(cartProvider.notifier).clearCart(),
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: AppColors.error, size: 18),
                    label: Text(
                      t.isSw ? 'Futa Yote' : 'Clear',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.v10),

              // 1. Cart Line Items with transparent Customization Chips
              ...cart.items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpace.v12),
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          DishImage(
                            imageRef: item.imageUrl,
                            dishId: item.id,
                            productName: item.name,
                            width: MenuImageMetrics.cartImage,
                            height: MenuImageMetrics.cartImage,
                            borderRadius: AppRadius.v14,
                          ),
                          const SizedBox(width: AppSpace.v12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (item.isCustomAiDish)
                                      const Padding(
                                        padding:
                                            EdgeInsets.only(right: AppSpace.v4),
                                        child: Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        dishName(item.id, item.name,
                                            isSw: t.isSw),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpace.v4),
                                Text(
                                  '${AppStrings.formatTzs(item.unitPrice)} × ${item.quantity} = ${AppStrings.formatTzs(item.lineTotal)}',
                                  style: const TextStyle(
                                    color: isDark
                                        ? AppColors.heroLight
                                        : AppColors.primaryDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        spacing: AppSpace.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            constraints: const BoxConstraints(
                                minWidth: AppSpace.huge,
                                minHeight: AppSpace.huge),
                            tooltip:
                                t.isSw ? 'Punguza idadi' : 'Decrease quantity',
                            onPressed: item.quantity <= 1
                                ? null
                                : () => ref
                                    .read(cartProvider.notifier)
                                    .decrementQuantity(item.signatureKey),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          Semantics(
                            liveRegion: true,
                            label: t.isSw ? 'Idadi' : 'Quantity',
                            child: Text('${item.quantity}'),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(
                                minWidth: AppSpace.huge,
                                minHeight: AppSpace.huge),
                            tooltip:
                                t.isSw ? 'Ongeza idadi' : 'Increase quantity',
                            onPressed: item.quantity >= 20
                                ? null
                                : () => ref
                                    .read(cartProvider.notifier)
                                    .incrementQuantity(item.signatureKey),
                            icon: const Icon(Icons.add_rounded),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                                minimumSize:
                                    const Size(AppSpace.huge, AppSpace.huge)),
                            onPressed: () => _removeLine(item),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: Text(t.isSw ? 'Ondoa' : 'Remove'),
                          ),
                        ],
                      ),
                      if (item.customizations.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.v8),
                        Wrap(
                          spacing: AppSpace.v6,
                          runSpacing: AppSpace.v4,
                          children: item.customizations
                              .map(
                                (c) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpace.sm,
                                      vertical: AppSpace.v3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    '+ ${c.name} (${AppStrings.formatTzs(c.price)})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: AppSpace.v6),

              // 2. Delivery Location Card
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg, vertical: AppSpace.xs),
                tileColor: isDark ? AppColors.darkCard : AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.v18),
                  side: BorderSide(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child:
                      Icon(Icons.location_on_rounded, color: AppColors.primary),
                ),
                title: Text(
                  t.deliverTo,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  address,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                trailing: TextButton(
                  onPressed: () => showTanzaniaLocationPicker(context),
                  child: Text(t.isSw ? 'Badili' : 'Change'),
                ),
              ),
              const SizedBox(height: AppSpace.v12),

              // Contact Phone + Kitchen Notes
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: t.isSw
                      ? 'Namba ya Simu ya Mpokeaji'
                      : 'Delivery Phone (TZ)',
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: AppSpace.v12),

              TextField(
                controller: _notesCtrl,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t.isSw
                      ? 'Maelekezo kwa jiko (si lazima)'
                      : 'Kitchen notes (optional)',
                ),
              ),
              const SizedBox(height: AppSpace.md),

              // 3. Promo Code Box (KARIBU2000)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: t.isSw ? 'Msimbo wa punguzo' : 'Promo code',
                        prefixIcon: const Icon(Icons.local_offer_outlined),
                        suffixIcon: cart.appliedPromoCode.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _promoCtrl.clear();
                                  ref
                                      .read(cartProvider.notifier)
                                      .removePromoCode();
                                },
                                icon: const Icon(Icons.close_rounded),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.v10),
                  ElevatedButton(
                    onPressed: () {
                      final ok = ref.read(cartProvider.notifier).applyPromoCode(
                            code: _promoCtrl.text,
                            settings: branch,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? (t.isSw
                                    ? 'Punguzo limetumika.'
                                    : 'Promo applied.')
                                : (t.isSw
                                    ? 'Msimbo si sahihi.'
                                    : 'Invalid promo code.'),
                          ),
                        ),
                      );
                    },
                    child: Text(t.applyPromo),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.v16),

              // 4. Payment Method Selector (Lipa Namba vs Cash)
              Text(
                t.isSw ? 'Chagua Njia ya Malipo' : 'Payment Method',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(height: AppSpace.v8),
              Row(
                children: [
                  Expanded(
                    child: _PaymentChoiceCard(
                      selected: _paymentMethod == PaymentMethod.lipaNamba,
                      icon: Icons.phonelink_ring_rounded,
                      title: 'Lipa Namba',
                      subtitle: 'M-Pesa / Mixx / Airtel',
                      onTap: () => setState(
                          () => _paymentMethod = PaymentMethod.lipaNamba),
                    ),
                  ),
                  const SizedBox(width: AppSpace.v10),
                  Expanded(
                    child: _PaymentChoiceCard(
                      selected: _paymentMethod == PaymentMethod.cashOnDelivery,
                      icon: Icons.payments_outlined,
                      title: t.isSw ? 'Taslimu' : 'Cash',
                      subtitle: t.isSw ? 'Lipa ukipokea' : 'Pay on delivery',
                      onTap: () => setState(
                          () => _paymentMethod = PaymentMethod.cashOnDelivery),
                    ),
                  ),
                ],
              ),

              if (_paymentMethod == PaymentMethod.lipaNamba) ...[
                const SizedBox(height: AppSpace.v10),
                Container(
                  padding: const EdgeInsets.all(AppSpace.v14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.v16),
                    border:
                        Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lipa Namba: ${branch.lipaNamba}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                            Text(
                              '${t.isSw ? 'Jina' : 'Name'}: ${branch.lipaName}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: branch.lipaNamba),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.isSw
                                  ? 'Lipa Namba imenakiliwa.'
                                  : 'Till number copied.'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: Text(t.isSw ? 'Nakili' : 'Copy Till'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.v16),

              // 5. Transparent Order Summary Card
              Container(
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: t.subtotal,
                      value: AppStrings.formatTzs(cart.subtotal),
                    ),
                    const SizedBox(height: AppSpace.v8),
                    _SummaryRow(
                      label: t.deliveryFee,
                      value: AppStrings.formatTzs(cart.effectiveDeliveryFee),
                    ),
                    if (cart.effectiveDiscount > 0) ...[
                      const SizedBox(height: AppSpace.v8),
                      _SummaryRow(
                        label: 'Promo (${cart.appliedPromoCode})',
                        value:
                            '- ${AppStrings.formatTzs(cart.effectiveDiscount)}',
                        valueColor: AppColors.success,
                      ),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpace.v10),
                      child: Divider(),
                    ),
                    _SummaryRow(
                      label: t.total,
                      value: AppStrings.formatTzs(cart.grandTotal),
                      isBold: true,
                      valueColor:
                          isDark ? AppColors.heroLight : AppColors.primaryDeep,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.v16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentChoiceCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.v16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpace.huge),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.14)
                : (isDark ? AppColors.darkCard : AppColors.surface),
            borderRadius: BorderRadius.circular(AppRadius.v16),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: selected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: selected ? AppColors.primary : AppColors.inkMuted,
                  size: 22),
              const SizedBox(width: AppSpace.v10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: isBold ? 16 : 13.5,
          ),
        )),
        const SizedBox(width: AppSpace.sm),
        Flexible(
            child: Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isBold ? 18 : 14,
            color: valueColor,
          ),
        )),
      ],
    );
  }
}
