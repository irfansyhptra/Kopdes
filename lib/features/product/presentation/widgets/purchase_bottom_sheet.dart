import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/product.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../../../order/presentation/providers/order_provider.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../../../shared/widgets/success_action_dialog.dart';

class PurchaseBottomSheet extends ConsumerStatefulWidget {
  final Product product;
  final bool initialDirectCheckout;

  const PurchaseBottomSheet({
    super.key,
    required this.product,
    this.initialDirectCheckout = false,
  });

  @override
  ConsumerState<PurchaseBottomSheet> createState() => _PurchaseBottomSheetState();
}

class _PurchaseBottomSheetState extends ConsumerState<PurchaseBottomSheet> {
  int _quantity = 1;
  late String _selectedVariant;
  String _selectedDelivery = 'Diantar Kurir';
  String _selectedPayment = 'QRIS';

  double _oldPrice = 0.0;
  double _newPrice = 0.0;

  @override
  void initState() {
    super.initState();
    // Dynamically set default mock variants based on category
    final categoryName = widget.product.category?.name.toLowerCase() ?? '';
    if (categoryName.contains('minuman') ||
        categoryName.contains('makanan') ||
        categoryName.contains('sembako')) {
      _selectedVariant = '500gr';
    } else {
      _selectedVariant = 'Putih';
    }
    _calculatePrices();
    _oldPrice = _newPrice;
  }

  void _calculatePrices() {
    final double itemPrice = widget.product.price;
    final double shippingFee = _getShippingFee();
    const double serviceFee = 1000.0;
    _newPrice = (itemPrice * _quantity) + shippingFee + serviceFee;
  }

  double _getShippingFee() {
    switch (_selectedDelivery) {
      case 'Ambil di Koperasi':
        return 0.0;
      case 'Diantar Kurir':
        return 8000.0;
      case 'Driver Kopdes':
        return 12000.0;
      default:
        return 0.0;
    }
  }

  void _updateQuantity(int change) {
    final int newQty = _quantity + change;
    if (newQty >= 1 && newQty <= widget.product.stock) {
      setState(() {
        _oldPrice = _newPrice;
        _quantity = newQty;
        _calculatePrices();
      });
    }
  }

  void _updateDelivery(String method) {
    setState(() {
      _oldPrice = _newPrice;
      _selectedDelivery = method;
      _calculatePrices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = widget.product.category?.name.toLowerCase() ?? '';
    final bool isFoodBeverage = categoryName.contains('minuman') ||
        categoryName.contains('makanan') ||
        categoryName.contains('sembako');

    final List<String> variants = isFoodBeverage
        ? ['250gr', '500gr', '1kg']
        : ['Merah', 'Putih', 'Hitam'];

    final double originalItemPrice = widget.product.price * 1.25;
    final double originalSubtotal = originalItemPrice * _quantity;
    final double discount = (originalItemPrice - widget.product.price) * _quantity;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 30,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle Bar
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Preview Section
                    _buildProductPreviewSection(originalItemPrice),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),

                    // Variant Section
                    _buildVariantSection(variants),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),

                    // Quantity Section
                    _buildQuantitySection(),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),

                    // Delivery Option Section
                    _buildDeliverySection(),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),

                    // Payment Method Section
                    _buildPaymentSection(),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 16),

                    // Price Summary Breakdown
                    _buildSummarySection(originalSubtotal, discount),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Sticky Footer Actions
            _buildStickyFooter(originalItemPrice),
          ],
        ),
      ),
    );
  }

  Widget _buildProductPreviewSection(double originalItemPrice) {
    final String storeLabel = widget.product.stock % 2 == 0
        ? 'Kopdes Merah Putih'
        : 'UMKM Desa Lamteh';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 84,
            height: 84,
            child: ProductImageLoader(
              imageUrl: widget.product.primaryImageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (widget.product.category?.name ?? 'UMKM').toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.name,
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                storeLabel,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Rp ${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Rp ${originalItemPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Stok: ${widget.product.stock} unit tersedia',
                style: TextStyle(
                  color: widget.product.stock > 5 ? const Color(0xFF2E7D32) : AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariantSection(List<String> variants) {
    final categoryName = widget.product.category?.name.toLowerCase() ?? '';
    final bool isFoodBeverage = categoryName.contains('minuman') ||
        categoryName.contains('makanan') ||
        categoryName.contains('sembako');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFoodBeverage ? 'Pilih Ukuran' : 'Pilih Warna',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: variants.map((variant) {
            final isSelected = _selectedVariant == variant;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVariant = variant;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFEAEA) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    variant,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuantitySection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Jumlah Pembelian',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            _buildQuantityButton(
              icon: Icons.remove_rounded,
              onTap: _quantity > 1 ? () => _updateQuantity(-1) : null,
            ),
            const SizedBox(width: 12),
            AnimatedQuantityText(quantity: _quantity),
            const SizedBox(width: 12),
            _buildQuantityButton(
              icon: Icons.add_rounded,
              onTap: _quantity < widget.product.stock ? () => _updateQuantity(1) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityButton({required IconData icon, VoidCallback? onTap}) {
    final bool isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isEnabled ? Colors.white : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isEnabled ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6),
            width: 1.2,
          ),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isEnabled ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildDeliverySection() {
    final List<Map<String, dynamic>> deliveryOptions = [
      {
        'method': 'Ambil di Koperasi',
        'desc': 'Gratis Ongkir',
        'icon': Icons.store_mall_directory_outlined,
      },
      {
        'method': 'Diantar Kurir',
        'desc': 'Rp 8.000 (1-2 hari)',
        'icon': Icons.local_shipping_outlined,
      },
      {
        'method': 'Driver Kopdes',
        'desc': 'Rp 12.000 (Sama hari)',
        'icon': Icons.moped_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pengiriman',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: deliveryOptions.map((opt) {
            final isSelected = _selectedDelivery == opt['method'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _updateDelivery(opt['method']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFEAEA) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt['icon'],
                        color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['method'],
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : const Color(0xFF1F2937),
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt['desc'],
                              style: TextStyle(
                                color: isSelected ? AppColors.primary.withOpacity(0.7) : const Color(0xFF6B7280),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final List<Map<String, dynamic>> paymentOptions = [
      {'name': 'QRIS', 'icon': Icons.qr_code_scanner_rounded},
      {'name': 'Transfer Bank', 'icon': Icons.account_balance_rounded},
      {'name': 'E-Wallet', 'icon': Icons.account_balance_wallet_rounded},
      {'name': 'Kas Koperasi', 'icon': Icons.monetization_on_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metode Pembayaran',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: paymentOptions.map((opt) {
            final isSelected = _selectedPayment == opt['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPayment = opt['name'];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFEAEA) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      opt['icon'],
                      color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        opt['name'],
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : const Color(0xFF374151),
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSummarySection(double originalSubtotal, double discount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Pembayaran',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildSummaryRow('Subtotal', originalSubtotal),
        const SizedBox(height: 8),
        _buildSummaryRow('Diskon Promosi', -discount, isDiscount: true),
        const SizedBox(height: 8),
        _buildSummaryRow('Estimasi Ongkir', _getShippingFee()),
        const SizedBox(height: 8),
        _buildSummaryRow('Biaya Layanan', 1000.0),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    final String amountStr = amount >= 0
        ? 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}'
        : '-Rp ${amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          amountStr,
          style: TextStyle(
            color: isDiscount ? const Color(0xFF22C55E) : const Color(0xFF374151),
            fontSize: 12,
            fontWeight: isDiscount ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(double originalItemPrice) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF3F4F6))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Total Display (Left)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: _oldPrice, end: _newPrice),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  builder: (context, val, child) {
                    return Text(
                      'Rp ${val.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Add to Cart Button
          GestureDetector(
            onTap: _onAddToCartClicked,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'Masukkan Keranjang',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Buy Now Button
          Expanded(
            child: GestureDetector(
              onTap: _onBuyNowClicked,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD32F2F).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Bayar Langsung',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAddToCartClicked() async {
    // 1. Validate Stock
    if (widget.product.stock < _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok tidak mencukupi untuk jumlah pembelian ini.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Call CartProvider
    final success = await ref.read(cartProvider.notifier).addToCart(
          productId: widget.product.id,
          quantity: _quantity,
        );

    if (success) {
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        showSuccessActionDialog(
          context,
          title: 'Berhasil Ditambahkan',
          description: '${widget.product.name} telah masuk ke keranjang belanja Anda.',
          primaryButtonLabel: 'Lihat Keranjang',
          onPrimaryPressed: () {
            Navigator.pop(context); // Close success dialog
            context.go('/cart'); // Route to cart screen
          },
          secondaryButtonLabel: 'Lanjut Belanja',
          onSecondaryPressed: () {
            Navigator.pop(context); // Close success dialog
          },
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menambahkan ke keranjang. Silakan coba lagi.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onBuyNowClicked() {
    // 1. Validate Stock
    if (widget.product.stock < _quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok tidak mencukupi untuk jumlah pembelian ini.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Set direct checkout provider
    ref.read(directCheckoutProvider.notifier).state = DirectCheckoutData(
      product: widget.product,
      quantity: _quantity,
      variant: _selectedVariant,
      deliveryMethod: _selectedDelivery,
      paymentMethod: _selectedPayment,
      price: widget.product.price,
    );

    // 3. Close Bottom Sheet & Navigate to Checkout
    Navigator.pop(context);
    context.push('/checkout');
  }

  }


class AnimatedQuantityText extends StatefulWidget {
  final int quantity;
  const AnimatedQuantityText({super.key, required this.quantity});

  @override
  State<AnimatedQuantityText> createState() => _AnimatedQuantityTextState();
}

class _AnimatedQuantityTextState extends State<AnimatedQuantityText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.88), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.88, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant AnimatedQuantityText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quantity != widget.quantity) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(
        '${widget.quantity}',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }
}

void showPurchaseBottomSheet(
  BuildContext context, {
  required Product product,
  bool isDirectCheckout = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (context) => PurchaseBottomSheet(
      product: product,
      initialDirectCheckout: isDirectCheckout,
    ),
  );
}
