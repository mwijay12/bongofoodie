import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/dish_image.dart';
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
    setState(() => _placingOrder = true);

    final user = ref.read(authProvider).user;
    final now = DateTime.now();
    final shortCode = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
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

    await ref.read(userOrdersProvider.notifier).placeOrder(order);
    await ref.read(staffOrdersProvider.notifier).refresh();
    ref.read(cartProvider.notifier).clearCart();

    if (!mounted) return;
    setState(() => _placingOrder = false);
    _showReceiptDialog(order, branch);
  }

  void _showReceiptDialog(OrderModel order, BranchSettingsModel branch) {
    final receiptText = '''
🧾 BONGOFOODIE OFFICIAL RECEIPT
Order: #${order.id}
Customer: ${order.customerName}
Deliver to: ${order.deliveryAddress}
Items:
${order.items.map((i) => '• ${i.quantity}x ${i.name} (${AppStrings.formatTzs(i.lineTotal)})').join('\n')}
Total Paid/Due: ${AppStrings.formatTzs(order.totalAmount)}
Payment: ${order.paymentMethodType.label}${order.paymentMethodType == PaymentMethod.lipaNamba ? ' (Till ${branch.lipaNamba})' : ''}
Asante kwa kuchagua BongoFoodie TZ! 🇹🇿
''';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded,
                color: AppColors.success, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Oda Imepokelewa! (#${order.id})',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kitchen dispatch in Kijitonyama is now preparing your meal (${order.items.length} item${order.items.length == 1 ? '' : 's'}).',
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: ${AppStrings.formatTzs(order.totalAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.paymentMethodType == PaymentMethod.lipaNamba
                        ? 'Lipa Namba: ${branch.lipaNamba} (${branch.lipaName})'
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
        ),
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
            child: const Text('Track Live'),
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
    final branch =
        ref.watch(branchSettingsProvider).valueOrNull ?? const BranchSettingsModel();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sync live delivery fee from settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartProvider.notifier).syncDeliveryFee(branch.deliveryFee);
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
                  const SizedBox(height: 18),
                  Text(
                    t.emptyCartTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.emptyCartSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/search'),
                    icon: const Icon(Icons.restaurant_menu_rounded),
                    label: Text(t.isSw ? 'Fungua Menyu' : 'Browse Swahili Menu'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 130),
          children: [
            Row(
              children: [
                Text(
                  '${t.navCart} (${cart.totalItems})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: AppColors.error, size: 18),
                  label: Text(
                    t.isSw ? 'Futa Yote' : 'Clear',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 1. Cart Line Items with transparent Customization Chips
            ...cart.items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        DishImage(
                          imageRef: item.imageUrl,
                          width: 68,
                          height: 68,
                          borderRadius: 14,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (item.isCustomAiDish)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.formatTzs(item.lineTotal),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .decrementQuantity(item.signatureKey),
                              icon: const Icon(
                                  Icons.remove_circle_outline_rounded),
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .incrementQuantity(item.signatureKey),
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (item.customizations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.customizations
                            .map(
                              (c) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpace.sm, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
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

            const SizedBox(height: 6),

            // 2. Delivery Location Card
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
              tileColor: isDark ? AppColors.darkCard : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Icon(Icons.location_on_rounded, color: AppColors.primary),
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
            const SizedBox(height: 12),

            // Contact Phone + Kitchen Notes
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText:
                    t.isSw ? 'Namba ya Simu ya Mpokeaji' : 'Delivery Phone (TZ)',
                prefixIcon: const Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Promo Code Box (KARIBU2000)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Promo code (try KARIBU2000)',
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
                const SizedBox(width: 10),
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
                              ? '🎉 Promo applied! Discount unlocked.'
                              : 'Invalid promo code. Play Daily Spice Trivia or try KARIBU2000!',
                        ),
                      ),
                    );
                  },
                  child: Text(t.applyPromo),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Payment Method Selector (Lipa Namba vs Cash)
            Text(
              t.isSw ? 'Chagua Njia ya Malipo' : 'Payment Method',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PaymentChoiceCard(
                    selected: _paymentMethod == PaymentMethod.lipaNamba,
                    icon: Icons.phonelink_ring_rounded,
                    title: 'Lipa Namba',
                    subtitle: 'M-Pesa / Mixx / Airtel',
                    onTap: () =>
                        setState(() => _paymentMethod = PaymentMethod.lipaNamba),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PaymentChoiceCard(
                    selected: _paymentMethod == PaymentMethod.cashOnDelivery,
                    icon: Icons.payments_outlined,
                    title: 'Cash',
                    subtitle: 'Pay rider at door',
                    onTap: () => setState(
                        () => _paymentMethod = PaymentMethod.cashOnDelivery),
                  ),
                ),
              ],
            ),

            if (_paymentMethod == PaymentMethod.lipaNamba) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Till / Lipa Namba: ${branch.lipaNamba}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            'Name: ${branch.lipaName}',
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
                            content: Text(
                                'Till ${branch.lipaNamba} copied to clipboard!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 15),
                      label: const Text('Copy Till'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 5. Transparent Order Summary Card
            Container(
              padding: const EdgeInsets.all(AppSpace.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: t.subtotal,
                    value: AppStrings.formatTzs(cart.subtotal),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: t.deliveryFee,
                    value: AppStrings.formatTzs(cart.effectiveDeliveryFee),
                  ),
                  if (cart.effectiveDiscount > 0) ...[
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Promo (${cart.appliedPromoCode})',
                      value: '- ${AppStrings.formatTzs(cart.effectiveDiscount)}',
                      valueColor: AppColors.success,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(),
                  ),
                  _SummaryRow(
                    label: t.total,
                    value: AppStrings.formatTzs(cart.grandTotal),
                    isBold: true,
                    valueColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _placingOrder
                    ? null
                    : () => _submitOrder(cart, branch, address),
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  '${t.placeOrder} • ${AppStrings.formatTzs(cart.grandTotal)}',
                ),
              ),
            ),
          ],
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.14)
              : (isDark ? AppColors.darkCard : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
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
                color: selected ? AppColors.primary : AppColors.inkMuted, size: 22),
            const SizedBox(width: 10),
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
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontSize: isBold ? 16 : 13.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isBold ? 18 : 14,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
