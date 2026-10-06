import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kopdes/core/theme/theme.dart';
import '../../../../core/network/error_message.dart';
import '../../../address/data/address_repository.dart';
import '../../../address/presentation/address_screens.dart';
import '../../../payment/presentation/payment_screen.dart';
import '../../../wallet/data/wallet_repository.dart';
import '../../domain/order_totals.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/orders_page_provider.dart';
import '../widgets/order_summary.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMethod = 'MIDTRANS';

  /// DELIVERY atau PICKUP (`FulfillmentMethod`).
  String _fulfillment = 'DELIVERY';

  /// Alamat yang dipilih; null = alamat utama (atau yang pertama).
  String? _addressId;

  bool get _isPickup => _fulfillment == 'PICKUP';

  bool _compactSegments(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(1) > 1.3 ||
      MediaQuery.sizeOf(context).width < 340;

  /// Pembayaran online dilanjutkan ke Midtrans Snap; COD & saldo selesai di server.
  String _afterCheckout(String orderId) => _paymentMethod == 'MIDTRANS'
      ? PayRoutes.order(orderId)
      : '/order-success/$orderId';

  Address? _selectedAddress(List<Address> list) {
    if (list.isEmpty) return null;
    return list.where((a) => a.id == _addressId).firstOrNull ??
        list.where((a) => a.isDefault).firstOrNull ??
        list.first;
  }

  /// Alamat yang akan dikirim, atau null bila belum ada — sekaligus
  /// mengarahkan pemesan menambahkannya. Ambil sendiri pun memerlukannya:
  /// pesanan selalu mencatat kontak pemesan.
  Future<String?> _resolveAddressId() async {
    final list = await ref
        .read(addressesProvider.future)
        .catchError((_) => const <Address>[]);
    final a = _selectedAddress(list);
    if (a != null) return a.id;
    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tambahkan alamat lebih dulu untuk melanjutkan pesanan.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _addAddress();
    return null;
  }

  Future<void> _addAddress() async {
    final created = await context.push<Address>(AddressRoutes.create);
    if (created != null && mounted) setState(() => _addressId = created.id);
  }

  Future<void> _pickAddress(List<Address> list) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceSoft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheet) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.base),
          children: [
            Text(
              'Pilih Alamat',
              style: AppTypography.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final a in list) ...[
              AddressCard(
                address: a,
                selected: a.id == _selectedAddress(list)?.id,
                onSelect: () => Navigator.pop(sheet, a.id),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextButton.icon(
              onPressed: () => Navigator.pop(sheet, '__new__'),
              icon: const Icon(Icons.add_rounded),
              style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
              label: const Text('Tambah alamat baru'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || picked == null) return;
    if (picked == '__new__') {
      await _addAddress();
    } else {
      setState(() => _addressId = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final directData = ref.read(directCheckoutProvider);
      if (directData != null) {
        setState(() {
          _fulfillment = directData.deliveryMethod == 'Ambil di Koperasi'
              ? 'PICKUP'
              : 'DELIVERY';
          _paymentMethod = switch (directData.paymentMethod) {
            'Saldo KOMIT' => 'WALLET',
            // COD hanya untuk pesanan yang diantar.
            'COD' when !_isPickup => 'COD',
            _ => 'MIDTRANS',
          };
        });
      }
    });
  }

  Future<void> _submitCheckout() async {
    final addressId = await _resolveAddressId();
    if (addressId == null || !mounted) return;
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
              },
            ],
            deliveryAddressId: addressId,
            paymentMethod: backendPaymentMethod,
            fulfillment: _fulfillment,
          );

      if (order != null && mounted) {
        ref.read(directCheckoutProvider.notifier).state =
            null; // Clear direct state
        context.go(_afterCheckout(order.id));
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

    // Hanya produk yang dicentang di halaman Pesanan yang ikut dipesan; sisanya
    // sengaja ditinggalkan di keranjang oleh pemesan.
    final order = await ref
        .read(orderActionProvider.notifier)
        .checkout(
          deliveryAddressId: addressId,
          paymentMethod: _paymentMethod,
          fulfillment: _fulfillment,
          cartItemIds: ref.read(selectedCartItemsProvider).toList(),
        );

    if (order != null && mounted) {
      context.go(_afterCheckout(order.id));
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
              icon: const Icon(
                Icons.chevron_left_rounded,
                color: Colors.white,
                size: 24,
              ),
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
                                    padding: const EdgeInsets.all(
                                      AppSpacing.base,
                                    ),
                                    children: [
                                      // 1. Delivery Address section
                                      _buildAddressCard(),
                                      const SizedBox(height: AppSpacing.md),

                                      // 2. Order Items summary card
                                      _buildItemsSummaryCard(cart.items),
                                      const SizedBox(height: AppSpacing.md),

                                      // 3. Payment Method Selection
                                      _buildPaymentMethodSection(
                                        _totalsFor(cart.subtotal).total,
                                      ),
                                      const SizedBox(height: AppSpacing.md),

                                      // 4. Financial Summary
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.canvas,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.card,
                                          ),
                                          border: Border.all(
                                            color: AppColors.hairlineSoft,
                                          ),
                                          boxShadow: AppElevation.soft,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            AppSpacing.base,
                                          ),
                                          child: OrderSummary(
                                            totals: _totalsFor(cart.subtotal),
                                            note:
                                                'Ongkir dan potongan ditentukan koperasi saat pesanan dibuat.',
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
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
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
    final async = ref.watch(addressesProvider);
    final caption = AppTypography.captionSmall.copyWith(
      fontSize: 12.5,
      color: AppColors.muted,
    );

    Widget addressBody;
    if (async.isLoading && !async.hasValue) {
      addressBody = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LinearProgressIndicator(minHeight: 2),
      );
    } else if (async.hasError && !async.hasValue) {
      addressBody = Row(
        children: [
          Expanded(
            child: Text(
              'Alamat belum termuat. ${networkErrorMessage(async.error!)}',
              style: caption.copyWith(color: AppColors.errorText),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(addressesProvider),
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: const Text('Coba Lagi'),
          ),
        ],
      );
    } else {
      final list = async.value ?? const <Address>[];
      final a = _selectedAddress(list);
      addressBody = a == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Belum ada alamat tersimpan. Tambahkan alamat untuk '
                  'melanjutkan pesanan.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _addAddress,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  label: const Text('Tambah Alamat'),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.recipientName}${a.isDefault ? ' (Utama)' : ''}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(a.phone, style: caption),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        a.oneLine,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _pickAddress(list),
                  style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                  child: const Text('Ganti'),
                ),
              ],
            );
    }

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cara Menerima',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Ikon dilepas pada teks besar: ikon + label dua segmen tidak
            // muat di 320dp, dan labelnya sendiri sudah jelas.
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'DELIVERY',
                  icon: _compactSegments(context)
                      ? null
                      : const Icon(Icons.local_shipping_outlined),
                  label: const Text('Diantar', maxLines: 2),
                ),
                ButtonSegment(
                  value: 'PICKUP',
                  icon: _compactSegments(context)
                      ? null
                      : const Icon(Icons.storefront_outlined),
                  label: const Text(
                    'Ambil Sendiri',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              selected: {_fulfillment},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(minimumSize: const Size(44, 44)),
              onSelectionChanged: (v) => setState(() {
                _fulfillment = v.first;
                // COD hanya untuk pesanan yang diantar (aturan backend).
                if (_isPickup && _paymentMethod == 'COD') {
                  _paymentMethod = 'MIDTRANS';
                }
              }),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isPickup
                  ? 'Barang disiapkan penjual; ambil di Kopdes/toko tanpa antre. '
                        'Alamat di bawah dipakai sebagai kontak pesanan.'
                  : 'Diantar kurir ke alamat di bawah.',
              style: caption,
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    _isPickup ? 'Kontak Pesanan' : 'Alamat Pengiriman',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            addressBody,
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
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            'Rp ${(item.price * item.quantity).toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                            textAlign: TextAlign.right,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
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

  Widget _buildPaymentMethodSection(num total) {
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
                Flexible(
                  child: Text(
                    'Metode Pembayaran',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            RadioListTile<String>(
              title: Text(
                'Bayar Online',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              subtitle: Text(
                'Midtrans Snap Sandbox — pilih QRIS, transfer bank, dompet digital, kartu, atau metode uji lain',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
              value: 'MIDTRANS',
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
                _isPickup
                    ? 'Tidak tersedia untuk ambil sendiri — bayar di muka.'
                    : 'Bayar tunai saat kurir tiba',
                style: AppTypography.captionSmall.copyWith(
                  color: AppColors.muted,
                ),
              ),
              value: 'COD',
              groupValue: _paymentMethod,
              activeColor: AppColors.primary,
              onChanged: _isPickup
                  ? null
                  : (val) {
                      setState(() {
                        _paymentMethod = val!;
                      });
                    },
            ),
            Consumer(
              builder: (context, ref, _) {
                final bal = ref.watch(walletBalanceProvider);
                final balance = bal.valueOrNull?.balance;
                final enough = balance != null && balance >= total;
                final note = bal.isLoading
                    ? 'Memuat saldo…'
                    : balance == null
                    ? 'Saldo belum termuat.'
                    : enough
                    ? 'Saldo ${formatRupiah(balance.round())} — langsung lunas'
                    : 'Saldo ${formatRupiah(balance.round())} tidak cukup. Isi ulang '
                          'di Profil > Saldo.';
                // Saldo turun di bawah total setelah dipilih: kembali ke Snap.
                if (!enough && _paymentMethod == 'WALLET') {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => mounted
                        ? setState(() => _paymentMethod = 'MIDTRANS')
                        : null,
                  );
                }
                return RadioListTile<String>(
                  title: Text(
                    'Saldo KOMIT',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  subtitle: Text(
                    note,
                    style: AppTypography.captionSmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  value: 'WALLET',
                  groupValue: _paymentMethod,
                  activeColor: AppColors.primary,
                  onChanged: enough
                      ? (v) => setState(() => _paymentMethod = v!)
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Komponen uang yang akan ditagihkan.
  ///
  /// Ongkir dan diskon nol karena backend memang belum membebankan keduanya
  /// (lihat `resolveShippingFee` di `order-money.ts`). Sebelumnya layar ini
  /// menambahkan ongkir Rp10.000 dan biaya layanan Rp2.000 sendiri, sehingga
  /// total yang dilihat pemesan selalu Rp12.000 lebih besar daripada yang
  /// benar-benar ditagihkan.
  OrderTotals _totalsFor(double subtotal) =>
      OrderTotals(subtotal: subtotal.round());

  Widget _buildBottomBar(double subtotal) {
    final totals = _totalsFor(subtotal);
    final total = totals.total;

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
          children: [
            Expanded(
              child: Column(
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
                    formatRupiah(total),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Boleh menyempit dan labelnya membungkus: pada teks besar
            // tombol bertinggi tetap 48 dengan label sebaris meluber.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
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
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
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

  Widget _buildDirectCheckoutBody(DirectCheckoutData directData) {
    final totals = _totalsFor(directData.price * directData.quantity);

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
                ),
              ]),
              const SizedBox(height: AppSpacing.md),

              // 3. Payment Method Selection
              _buildPaymentMethodSection(totals.total),
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
                    totals: totals,
                    note:
                        'Ongkir dan potongan ditentukan koperasi saat pesanan dibuat.',
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
    final totals = _totalsFor(directData.price * directData.quantity);
    final total = totals.total;

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
          children: [
            Expanded(
              child: Column(
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
                    formatRupiah(total),
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Boleh menyempit dan labelnya membungkus: pada teks besar
            // tombol bertinggi tetap 48 dengan label sebaris meluber.
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
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
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.buttonMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
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

class DirectItem {
  final String name;
  final int quantity;
  final double price;
  DirectItem({required this.name, required this.quantity, required this.price});
}
