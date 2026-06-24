import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/domain/entities/category.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../../../../shared/widgets/product_image_loader.dart';
import '../../../product/presentation/widgets/product_card.dart';
import '../../../product/presentation/widgets/purchase_bottom_sheet.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;
  String _selectedFilterLabel = 'Semua';

  // Hardcoded category icons and metadata
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Sembako', 'icon': Icons.rice_bowl_outlined, 'color': Color(0xFFE8F5E9)},
    {'name': 'Minuman', 'icon': Icons.local_drink_outlined, 'color': Color(0xFFE3F2FD)},
    {'name': 'Makanan Instan', 'icon': Icons.soup_kitchen_outlined, 'color': Color(0xFFFFF3E0)},
    {'name': 'Perawatan Tubuh', 'icon': Icons.clean_hands_outlined, 'color': Color(0xFFF3E5F5)},
    {'name': 'Kosmetik', 'icon': Icons.face_retouching_natural_outlined, 'color': Color(0xFFFCE4EC)},
    {'name': 'Kebersihan', 'icon': Icons.dry_cleaning_outlined, 'color': Color(0xFFE0F2F1)},
    {'name': 'Produk UMKM', 'icon': Icons.storefront_outlined, 'color': Color(0xFFFFEBEE)},
    {'name': 'Lainnya', 'icon': Icons.grid_view_rounded, 'color': Color(0xFFECEFF1)},
  ];

  final List<Map<String, String>> _banners = [
    {
      'title': 'Diskon UMKM Desa',
      'subtitle': 'Dukung produk lokal desa dengan promo potongan harga spesial.',
      'tag': 'UMKM LOKAL',
    },
    {
      'title': 'Belanja Hemat Minggu Ini',
      'subtitle': 'Penuhi kebutuhan sembako dan harian Anda langsung dari koperasi.',
      'tag': 'KOPERASI',
    },
    {
      'title': 'Produk Lokal Pilihan',
      'subtitle': 'Kurasi kerajinan dan komoditas terbaik dari warga desa.',
      'tag': 'TERBAIK',
    },
  ];

  // Map local filter label to catalog category query
  void _onFilterChipSelected(String label, List<Category> backendCategories) {
    setState(() {
      _selectedFilterLabel = label;
    });

    String targetCategoryId = '';
    if (label != 'Semua') {
      // Find category in backend matching name
      final matchedCat = backendCategories.firstWhere(
        (cat) => cat.name.toLowerCase().contains(label.toLowerCase()) || 
                 label.toLowerCase().contains(cat.name.toLowerCase()),
        orElse: () => Category(id: '', name: '', description: ''),
      );
      targetCategoryId = matchedCat.id;
    }

    // Update query provider to filter list
    ref.read(catalogQueryProvider.notifier).update(
      (state) => state.copyWith(categoryId: targetCategoryId, page: 1),
    );
  }

  // Map category button clicks
  void _onCategorySelected(String name, List<Category> backendCategories) {
    String categoryId = '';
    final matchedCat = backendCategories.firstWhere(
      (cat) => cat.name.toLowerCase().contains(name.toLowerCase()) || 
               name.toLowerCase().contains(cat.name.toLowerCase()),
      orElse: () => Category(id: '', name: '', description: ''),
    );
    categoryId = matchedCat.id;

    // Set filter and route to catalog page
    ref.read(catalogQueryProvider.notifier).update(
      (state) => state.copyWith(categoryId: categoryId, search: '', page: 1),
    );
    context.go('/products');
  }

  @override
  void initState() {
    super.initState();
    // Auto slide banners
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerPage + 1) % _banners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: AppAnimation.slow,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart(Product product) async {
    final success = await ref.read(cartProvider.notifier).addToCart(
      productId: product.id,
      quantity: 1,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success 
              ? '${product.name} berhasil ditambahkan ke keranjang' 
              : 'Gagal menambahkan produk ke keranjang',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Anggota';
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsListProvider);
    final backendCategories = categoriesAsync.asData?.value ?? [];

    final cartAsync = ref.watch(cartProvider);
    final notifications = ref.watch(notificationsProvider);
    final cartCount = cartAsync.asData?.value.totalItems ?? 0;
    final unreadNotificationsCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Premium Header Section with Red Background & Floating White Card
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Red Header Background
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 56, // Extra bottom padding for overlap
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. Profile Row
                      Row(
                        children: [
                          // White circular KOPDES Logo
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(5),
                            child: SvgPicture.asset(
                              'assets/svg/kopdes_logo.svg',
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFD32F2F),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name & Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selamat Datang Kembali,',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.stars_rounded,
                                      color: Color(0xFFFFD700), // Gold
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white70,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Desa Lamteh, Banda Aceh',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Action Buttons (Bell, Cart, Chat)
                          _buildHeaderIconButton(
                            icon: Icons.notifications_none_rounded,
                            badgeCount: unreadNotificationsCount,
                            onTap: () => context.push('/notifications'),
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderIconButton(
                            icon: Icons.shopping_bag_outlined,
                            badgeCount: cartCount,
                            onTap: () => context.push('/cart'),
                          ),
                          const SizedBox(width: 8),
                          _buildHeaderIconButton(
                            icon: Icons.chat_bubble_outline_rounded,
                            showDot: true,
                            onTap: () => context.go('/ai-assistant'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // B. Search Bar Container
                      GestureDetector(
                        onTap: () => context.go('/products'),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.05),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF6B7280),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Cari kebutuhan koperasi...',
                                  style: TextStyle(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD32F2F),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // C. 3 Promo / Layanan Pills
                      Row(
                        children: [
                          _buildPromoPill(
                            icon: Icons.local_offer_outlined,
                            title: 'Diskon UMKM',
                            subtitle: 'hingga 30%',
                            onTap: () => context.go('/products'),
                          ),
                          const SizedBox(width: 8),
                          _buildPromoPill(
                            icon: Icons.local_shipping_outlined,
                            title: 'Gratis Ongkir',
                            subtitle: 'Driver Kopdes',
                            onTap: () => context.push('/orders/history'),
                          ),
                          const SizedBox(width: 8),
                          _buildPromoPill(
                            icon: Icons.smart_toy_outlined,
                            title: 'AI Rekomendasi',
                            subtitle: 'Produk Aktif',
                            onTap: () => context.go('/ai-assistant'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // D. Floating Member Info Card
                Positioned(
                  bottom: -36, // Overlap bottom boundary
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // 1. Saldo Anggota
                        Expanded(
                          child: _buildMemberInfoColumn(
                            icon: Icons.account_balance_wallet_outlined,
                            iconBgColor: const Color(0xFFFFF0F3),
                            iconColor: const Color(0xFFD32F2F),
                            title: 'Saldo Anggota',
                            value: 'Rp 250.000',
                            buttonLabel: 'Top Up',
                            buttonColor: const Color(0xFFFFF0F3),
                            buttonTextColor: const Color(0xFFD32F2F),
                            onButtonTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur Top Up Saldo sedang dikembangkan.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        _buildVerticalDivider(),
                        // 2. Poin Belanja
                        Expanded(
                          child: _buildMemberInfoColumn(
                            icon: Icons.star_outline_rounded,
                            iconBgColor: const Color(0xFFFFFDF0),
                            iconColor: const Color(0xFFFFB300),
                            title: 'Poin Belanja',
                            value: '1.250 Poin',
                            buttonLabel: 'Lihat Poin',
                            buttonColor: const Color(0xFFFFFDF0),
                            buttonTextColor: const Color(0xFFFF8F00),
                            onButtonTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Fitur Poin Belanja sedang dikembangkan.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        _buildVerticalDivider(),
                        // 3. Status Anggota
                        Expanded(
                          child: _buildMemberInfoColumn(
                            icon: Icons.verified_user_outlined,
                            iconBgColor: const Color(0xFFE8F5E9),
                            iconColor: const Color(0xFF2E7D32),
                            title: 'Status Anggota',
                            value: 'VIP',
                            buttonLabel: 'Lihat Detail',
                            buttonColor: const Color(0xFFE8F5E9),
                            buttonTextColor: const Color(0xFF2E7D32),
                            onButtonTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Status Anggota Anda adalah VIP.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Spacer for floating card
          const SliverToBoxAdapter(
            child: SizedBox(height: 52),
          ),

          // 2. Slider Banners Section
          SliverToBoxAdapter(
            child: Container(
              height: screenWidth < 360 ? 145 : 160,
              margin: const EdgeInsets.only(top: AppSpacing.lg),
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _bannerController,
                      onPageChanged: (page) {
                        setState(() {
                          _currentBannerPage = page;
                        });
                      },
                      itemCount: _banners.length,
                      itemBuilder: (context, index) {
                        final banner = _banners[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD32F2F), Color(0xFFE53935)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(211, 47, 47, 0.15),
                                offset: Offset(0, 8),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 360 ? AppSpacing.md : AppSpacing.lg,
                              vertical: screenWidth < 360 ? AppSpacing.sm : AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          banner['tag']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        banner['title']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth < 360 ? 16 : 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        banner['subtitle']!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: screenWidth < 360 ? 10 : 11,
                                          height: 1.25,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: Icon(
                                    Icons.shopping_basket_rounded,
                                    color: Colors.white.withOpacity(0.2),
                                    size: screenWidth < 360 ? 48 : 64,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_banners.length, (index) {
                      final isDotActive = _currentBannerPage == index;
                      return AnimatedContainer(
                        duration: AppAnimation.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 5,
                        width: isDotActive ? 12 : 5,
                        decoration: BoxDecoration(
                          color: isDotActive ? AppColors.primary : const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

            // 5. Category Horizontal Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kategori Produk',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/products'),
                            child: const Text(
                              'Lihat Semua',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 96,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: GestureDetector(
                              onTap: () => _onCategorySelected(cat['name']!, backendCategories),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: cat['color'] as Color,
                                      borderRadius: BorderRadius.circular(16), // Rounded 16px
                                    ),
                                    child: Icon(
                                      cat['icon'] as IconData,
                                      color: AppColors.ink.withOpacity(0.75),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: 64,
                                    alignment: Alignment.center,
                                    child: Text(
                                      cat['name']!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 6. Promo Terbaik Horizontal Grid (Loads real products from backend)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        'Promo Terbaik',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 340,
                      child: productsAsync.when(
                        data: (products) {
                          if (products.isEmpty) {
                            return const Center(
                              child: Text(
                                'Tidak ada produk promo tersedia.',
                                style: TextStyle(color: AppColors.mutedSoft),
                              ),
                            );
                          }
                          // Show first 6 products for promo list
                          final promoProducts = products.take(6).toList();
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: promoProducts.length,
                            itemBuilder: (context, index) {
                              final product = promoProducts[index];
                              return SizedBox(
                                width: 160,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ProductCard(
                                    product: product,
                                    onTap: () {
                                      context.push('/products/detail/${product.id}');
                                    },
                                    onAddToCart: () {
                                      showPurchaseBottomSheet(context, product: product, isDirectCheckout: false);
                                    },
                                    onBuyNow: () {
                                      showPurchaseBottomSheet(context, product: product, isDirectCheckout: true);
                                    },
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        loading: () => SizedBox(
                          height: 340,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            itemCount: 4,
                            itemBuilder: (context, _) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: 160,
                                child: ProductCardSkeleton(),
                              ),
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Recommended Filter Chips (Semua, Minuman, Sembako, Kebersihan, Kosmetik, UMKM)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        'Rekomendasi Untuk Anda',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Horizontal scroll chips
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        children: [
                          'Semua',
                          'Minuman',
                          'Sembako',
                          'Kebersihan',
                          'Kosmetik',
                          'UMKM',
                        ].map((label) {
                          final isSelected = _selectedFilterLabel == label;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (_) => _onFilterChipSelected(label, backendCategories),
                              backgroundColor: const Color(0xFFF5F5F5),
                              selectedColor: AppColors.primaryTint,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 8. Product Vertical List (Modern Horizontal Marketplace Cards)
            productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'Belum ada rekomendasi produk.',
                          style: TextStyle(color: AppColors.mutedSoft),
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildRecommendationCard(product),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: List.generate(
                      4,
                      (_) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                          ),
                          child: Row(
                            children: const [
                              ShimmerBox(width: 120, height: 120, borderRadius: 0),
                              SizedBox(width: 12),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ShimmerBox(width: 140, height: 14, borderRadius: 4),
                                      SizedBox(height: 6),
                                      ShimmerBox(width: 80, height: 10, borderRadius: 4),
                                      Spacer(),
                                      ShimmerBox(width: 100, height: 16, borderRadius: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('Gagal memuat rekomendasi: $err'),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }

  // Header icon style
  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
    bool showDot = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
              ),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else if (showDot)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  // Promo / Layanan Pill
  Widget _buildPromoPill({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFFFD700), // Yellow gold
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // Member status column helper
  Widget _buildMemberInfoColumn({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String value,
    required String buttonLabel,
    required Color buttonColor,
    required Color buttonTextColor,
    required VoidCallback onButtonTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9CA3AF),
                          size: 11,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onButtonTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                buttonLabel,
                style: TextStyle(
                  color: buttonTextColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vertical divider for member card
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFF3F4F6),
    );
  }



  // Recommended list card (horizontal modern layout)
  Widget _buildRecommendationCard(Product product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth < 360 ? 128.0 : 120.0;
    final imageWidth = screenWidth < 360 ? 100.0 : 120.0;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.03),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => context.push('/products/detail/${product.id}'),
          child: Row(
            children: [
              // Left: Image
              SizedBox(
                width: imageWidth,
                height: double.infinity,
                child: ProductImageLoader(
                  imageUrl: product.primaryImageUrl,
                  fit: BoxFit.cover,
                ),
              ),

              // Right: Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? AppSpacing.sm : AppSpacing.base,
                    vertical: screenWidth < 360 ? 8 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product.name,
                        style: TextStyle(
                          color: const Color(0xFF1F2937),
                          fontSize: screenWidth < 360 ? 12 : 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Store Name
                      const Text(
                        'Kopdes Merah Putih',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Stock status & rating row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.stock > 0
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.stock > 0 ? 'Tersedia' : 'Habis',
                              style: TextStyle(
                                color: product.stock > 0 ? const Color(0xFF2E7D32) : AppColors.primary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '4.8',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Price and action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: screenWidth < 360 ? 13 : 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Row(
                            children: [
                              // Favorite
                              InkWell(
                                onTap: () {},
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: screenWidth < 360 ? 28 : 32,
                                  height: screenWidth < 360 ? 28 : 32,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFF0F0F0)),
                                  ),
                                  child: Icon(
                                    Icons.favorite_border_rounded,
                                    color: AppColors.primary,
                                    size: screenWidth < 360 ? 14 : 16,
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth < 360 ? 6 : 8),
                              // Add to Cart
                              InkWell(
                                onTap: () => _handleAddToCart(product),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: screenWidth < 360 ? 28 : 32,
                                  height: screenWidth < 360 ? 28 : 32,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: screenWidth < 360 ? 16 : 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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
