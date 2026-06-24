import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../providers/product_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/product_card.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../order/presentation/providers/cart_provider.dart';

class ProductCatalogScreen extends ConsumerStatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  ConsumerState<ProductCatalogScreen> createState() =>
      _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends ConsumerState<ProductCatalogScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Accumulated products for infinite scroll
  List<dynamic> _allProducts = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _showScrollTop = false;

  // Track the last query that built the list — reset when search/filter changes
  String? _lastQueryKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(catalogQueryProvider).search;
    });
    _scrollController.addListener(() {
      setState(() {
        _showScrollTop = _scrollController.offset > 300;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    _allProducts = [];
    _hasMore = true;
    _lastQueryKey = null;
    ref
        .read(catalogQueryProvider.notifier)
        .update((state) => state.copyWith(search: value, page: 1));
  }

  void _clearSearch() {
    _searchController.clear();
    _allProducts = [];
    _hasMore = true;
    _lastQueryKey = null;
    ref
        .read(catalogQueryProvider.notifier)
        .update((state) => state.copyWith(search: '', page: 1));
  }

  void _loadMore() {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    ref
        .read(catalogQueryProvider.notifier)
        .update((state) => state.copyWith(page: state.page + 1));
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(catalogQueryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsListProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isStaff =
        user != null &&
        (user.role == 'SUPER_ADMIN' || user.role == 'ADMIN_KOPDES');

    final userName = authState.user?.name ?? 'Anggota';
    final cartAsync = ref.watch(cartProvider);
    final notifications = ref.watch(notificationsProvider);
    final cartCount = cartAsync.asData?.value.totalItems ?? 0;
    final unreadNotificationsCount = notifications.where((n) => !n.isRead).length;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final textScale = mediaQuery.textScaleFactor;
    double gridAspectRatio = 0.57;
    if (screenWidth < 360) {
      gridAspectRatio = 0.54;
    } else if (screenWidth > 600) {
      gridAspectRatio = 0.65;
    }
    if (textScale > 1.1) {
      gridAspectRatio -= 0.05;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          // 1. Premium Red Header (Profile + Location + Actions + Search Bar)
          Container(
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
                    _buildCatalogHeaderIconButton(
                      icon: Icons.notifications_none_rounded,
                      badgeCount: unreadNotificationsCount,
                      onTap: () => context.push('/notifications'),
                    ),
                    const SizedBox(width: 8),
                    _buildCatalogHeaderIconButton(
                      icon: Icons.shopping_bag_outlined,
                      badgeCount: cartCount,
                      onTap: () => context.push('/cart'),
                    ),
                    const SizedBox(width: 8),
                    _buildCatalogHeaderIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      showDot: true,
                      onTap: () => context.go('/ai-assistant'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // B. Search Bar Container
                Container(
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
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                            color: Color(0xFF1F2937),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Cari produk koperasi...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: _updateSearch,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF6B7280),
                            size: 20,
                          ),
                          onPressed: _clearSearch,
                        ),
                      GestureDetector(
                        onTap: () {
                          if (isStaff) {
                            context.push('/admin/products');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD32F2F),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isStaff ? Icons.settings_suggest_outlined : Icons.tune_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Horizontal Categories Filter Chips
          categoriesAsync.when(
            data: (categories) {
              return Container(
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final cat = isAll ? null : categories[index - 1];
                    final isSelected = isAll
                        ? query.categoryId.isEmpty
                        : query.categoryId == cat?.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: isSelected
                            ? const Icon(Icons.check, color: Color(0xFFD32F2F), size: 14)
                            : null,
                        label: Text(isAll ? 'Semua' : (cat?.name ?? '')),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref.read(catalogQueryProvider.notifier).update(
                                (state) => state.copyWith(
                                  categoryId: isAll ? '' : (cat?.id ?? ''),
                                  page: 1,
                                ),
                              );
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFFFFF0F3),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFF4B5563),
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFFD32F2F).withOpacity(0.3)
                                : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // 3. Promo Capsules Container (mockup row directly below category chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildCatalogPromoPill(
                    icon: Icons.local_offer_outlined,
                    title: 'Diskon UMKM',
                    subtitle: 'hingga 30%',
                  ),
                  _buildCatalogDivider(),
                  _buildCatalogPromoPill(
                    icon: Icons.local_shipping_outlined,
                    title: 'Gratis Ongkir',
                    subtitle: 'Driver Kopdes',
                  ),
                  _buildCatalogDivider(),
                  _buildCatalogPromoPill(
                    icon: Icons.smart_toy_outlined,
                    title: 'AI Rekomendasi',
                    subtitle: 'Produk Aktif',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 4. Products Grid (Infinite Scroll)
          Expanded(
            child: productsAsync.when(
              data: (newProducts) {
                // Build unique query key from search + category + page
                final queryKey = '${query.search}|${query.categoryId}|${query.page}';

                // If this is a new page result, merge it in
                if (_lastQueryKey != queryKey) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      if (query.page == 1) {
                        // Fresh search / filter — reset list
                        _allProducts = newProducts;
                      } else {
                        // Append next page
                        _allProducts = [..._allProducts, ...newProducts];
                      }
                      _hasMore = newProducts.length >= query.limit;
                      _isLoadingMore = false;
                      _lastQueryKey = queryKey;
                    });
                  });
                }

                final displayProducts = _allProducts.isNotEmpty ? _allProducts : newProducts;

                if (displayProducts.isEmpty) {
                  return _buildEmptyState();
                }

                return Stack(
                  children: [
                    GridView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        top: AppSpacing.sm,
                        bottom: _hasMore ? 100 : 32,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth > 600 ? 3 : 2,
                        childAspectRatio: gridAspectRatio,
                        crossAxisSpacing: AppSpacing.base,
                        mainAxisSpacing: AppSpacing.base,
                      ),
                      itemCount: displayProducts.length,
                      itemBuilder: (context, index) {
                        final product = displayProducts[index];
                        return ProductCard(
                          product: product,
                          showActions: false,
                          onTap: () {
                            context.push('/products/detail/${product.id}');
                          },
                        );
                      },
                    ),

                    // "Lihat Lainnya" footer pinned at bottom
                    if (_hasMore)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.canvas.withValues(alpha: 0.0),
                                AppColors.canvas.withValues(alpha: 0.95),
                                AppColors.canvas,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: _isLoadingMore
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _loadMore,
                                      icon: const Icon(Icons.expand_more_rounded, size: 20),
                                      label: const Text(
                                        'Lihat Lainnya',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: AppColors.primary.withValues(alpha: 0.35),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),

                    // Scroll-to-top FAB
                    if (_showScrollTop)
                      Positioned(
                        bottom: _hasMore ? 68 : 16,
                        right: 16,
                        child: AnimatedOpacity(
                          opacity: _showScrollTop ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: FloatingActionButton.small(
                            heroTag: 'scrollTopCatalog',
                            backgroundColor: Colors.white,
                            elevation: 4,
                            onPressed: () {
                              _scrollController.animateTo(
                                0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => _buildGridSkeleton(gridAspectRatio, screenWidth),
              error: (err, _) => _buildErrorState(err),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Produk Tidak Ditemukan',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Silakan cari dengan kata kunci lain atau ubah kategori filter Anda.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: AppColors.muted,
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Gagal Memuat Produk',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString().contains('SocketException')
                  ? 'Koneksi internet Anda terputus. Silakan periksa jaringan.'
                  : error.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(productsListProvider);
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSkeleton(double gridAspectRatio, double screenWidth) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 600 ? 3 : 2,
        childAspectRatio: gridAspectRatio,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area shimmer
              const ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                child: ShimmerBox(width: double.infinity, height: 140, borderRadius: 0),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 60, height: 10, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                    SizedBox(height: 4),
                    ShimmerBox(width: 100, height: 12, borderRadius: 4),
                    SizedBox(height: 10),
                    ShimmerBox(width: 80, height: 14, borderRadius: 6),
                    SizedBox(height: 8),
                    ShimmerBox(width: double.infinity, height: 32, borderRadius: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCatalogHeaderIconButton({
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

  Widget _buildCatalogPromoPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFD32F2F), size: 14),
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
                      color: Color(0xFF1F2937),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 8.5,
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
    );
  }

  Widget _buildCatalogDivider() {
    return Container(
      width: 1,
      height: 24,
      color: const Color(0xFFE5E7EB),
    );
  }
}
