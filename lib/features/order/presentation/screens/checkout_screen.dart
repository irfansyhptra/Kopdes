import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kopdes/core/theme/theme.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_summary.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'QRIS';
  final String _deliveryAddressId = 'default-mock-address-id';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final directData = ref.read(directCheckoutProvider);
      if (directData != null) {
        setState(() {
          _paymentMethod = (directData.paymentMethod == 'Kas Koperasi') ? 'COD' : directData.paymentMethod;
        });
      }
    });
  }

  Future<void> _submitCheckout() async {
    final directData = ref.read(directCheckoutProvider);
    if (directData != null) {
      final backendPaymentMethod = _paymentMethod;
      final order = await ref
          .read(orderActionProvider.notifier)
          .createDirect(
            items: [
              {
                'productId': directData.product.id,
                'quantity': directData.quantity,
              }
            ],
            deliveryAddressId: _deliveryAddressId,
            paymentMethod: backendPaymentMethod,
          );

      if (order != null && mounted) {
        ref.read(directCheckoutProvider.notifier).state = null; // Clear direct state
        context.go('/order-success/${order.id}');
      } else if (mounted) {
        final state = ref.read(orderActionProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Checkout gagal: ${state.error ?? "Terjadi kesalahan"}',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final cartState = ref.read(cartProvider);
    if (cartState is! AsyncData || cartState.value!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja kosong'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final order = await ref
        .read(orderActionProvider.notifier)
        .checkout(
          deliveryAddressId: _deliveryAddressId,
          paymentMethod: _paymentMethod,
        );

    if (order != null && mounted) {
      context.go('/order-success/${order.id}');
    } else if (mounted) {
      final state = ref.read(orderActionProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Checkout gagal: ${state.error ?? "Terjadi kesalahan"}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildHeaderButton({
    required Widget child,
    Color backgroundColor = const Color(0x26FFFFFF),
    Color borderColor = const Color(0x1AFFFFFF),
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Center(child: child),
    );
  }

  Widget _buildCustomHeader(bool isDirect) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderButton(
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
              onPressed: () {
                if (isDirect) {
                  ref.read(directCheckoutProvider.notifier).state = null;
                }
                context.pop();
              },
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Checkout',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final actionState = ref.watch(orderActionProvider);
    final directData = ref.watch(directCheckoutProvider);
    final bool isDirect = directData != null;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop && isDirect) {
          ref.read(directCheckoutProvider.notifier).state = null;
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.canvas,
            body: Column(
              children: [
                _buildCustomHeader(isDirect),
                Expanded(
                  child: isDirect
                      ? _buildDirectCheckoutBody(directData)
                      : cartAsync.when(
                          data: (cart) {
                            if (cart.items.isEmpty) {
                              return Center(
                                child: Text(
                                  'Keranjang kosong',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              );
                            }
                            return Column(
                              children: [
                                Expanded(
                                  child: ListView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.all(AppSpacing.base),
                                    children: [
                                      // 1. Delivery Address section
                                      _buildAddressCard(),
                                      const SizedBox(height: AppSpacing.md),

                                      // 2. Order Items summary card
                                      _buildItemsSummaryCard(cart.items),
                                      const SizedBox(height: AppSpacing.md),

                                      // 3. Payment Method Selection
                                      _buildPaymentMethodSection(),
                                      const SizedBox(height: AppSpacing.md),

                                      // 4. Financial Summary
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.canvas,
                                          borderRadius: BorderRadius.circular(AppRadius.card),
                                          border: Border.all(color: AppColors.hairlineSoft),
                                          boxShadow: AppElevation.soft,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(AppSpacing.base),
                                          child: OrderSummary(
                                            subtotal: cart.subtotal,
                                            shippingFee: 10000.0,
                                            serviceFee: 2000.0,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                    ],
                                  ),
                                ),

                                // Bottom action bar
                                _buildBottomBar(cart.subtotal),
                              ],
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                          error: (err, _) => Center(
                            child: Text(
                              'Error: $err',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Global Loading overlay
          if (actionState is AsyncLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Alamat Pengiriman',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Budi Santoso (Utama)',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '081234567890',
              style: AppTypography.captionSmall.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Jl. Merdeka No. 10, Sleman, DI Yogyakarta, 55281',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.body),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSummaryCard(List<dynamic> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.soft,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          leading: const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.primary,
          ),
          title: Text(
            'Ringkasan Pesanan (${items.length} Barang)',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.base,
                right: AppSpacing.base,
                bottom: AppSpacing.base,
              ),
              child: Column(
                children: items.map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.name} (${item.quantity}x)',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.body,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          'Rp ${(item.price * item.quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppElevation.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payment_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Metode Pembayaran',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            RadioListTile<String>(
              title: Text(
                'QRIS (Pembayaran Instan)',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                'Scan QR Code digital koperasi',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
              value: 'QRIS',
              groupValue: _paymentMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _paymentMethod = val!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(
                'COD (Bayar di Tempat)',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                'Bayar tunai saat kurir tiba',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
              value: 'COD',
              groupValue: _paymentMethod,
              activeColor: AppColors.primary,
              onChanged: (val) {
                setState(() {
                  _paymentMethod = val!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(double subtotal) {
    const shippingFee = 10000.0;
    const serviceFee = 2000.0;
    final total = subtotal + shippingFee + serviceFee;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        boxShadow: AppElevation.soft,
        border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pembayaran',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  'Konfirmasi & Bayar',
                  style: AppTypography.buttonMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectCheckoutBody(DirectCheckoutData directData) {
    final double subtotal = directData.price * directData.quantity;
    final double shippingFee = _getShippingFeeForDirect(directData.deliveryMethod);
    const double serviceFee = 1000.0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              // 1. Delivery Address section
              _buildAddressCard(),
              const SizedBox(height: AppSpacing.md),

              // 2. Order Items summary card
              _buildItemsSummaryCard([
                DirectItem(
                  name: '${directData.product.name} (${directData.variant})',
                  quantity: directData.quantity,
                  price: directData.price,
                )
              ]),
              const SizedBox(height: AppSpacing.md),

              // 3. Payment Method Selection
              _buildPaymentMethodSection(),
              const SizedBox(height: AppSpacing.md),

              // 4. Financial Summary
              Container(
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.hairlineSoft),
                  boxShadow: AppElevation.soft,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: OrderSummary(
                    subtotal: subtotal,
                    shippingFee: shippingFee,
                    serviceFee: serviceFee,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),

        // Bottom action bar
        _buildDirectBottomBar(directData),
      ],
    );
  }

  Widget _buildDirectBottomBar(DirectCheckoutData directData) {
    final double subtotal = directData.price * directData.quantity;
    final double shippingFee = _getShippingFeeForDirect(directData.deliveryMethod);
    const double serviceFee = 1000.0;
    final double total = subtotal + shippingFee + serviceFee;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        boxShadow: AppElevation.soft,
        border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Pembayaran',
                  style: AppTypography.captionSmall.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _submitCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Text(
                  'Konfirmasi & Bayar',
                  style: AppTypography.buttonMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getShippingFeeForDirect(String method) {
    switch (method) {
      case 'Ambil di Koperasi':
        return 0.0;
      case 'Diantar Kurir':
        return 8000.0;
      case 'Driver Kopdes':
        return 12000.0;
      default:
        return 8000.0;
    }
  }
}

class DirectItem {
  final String name;
  final int quantity;
  final double price;
  DirectItem({required this.name, required this.quantity, required this.price});
}
