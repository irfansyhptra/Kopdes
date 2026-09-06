import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../../../shared/widgets/skeleton_loaders.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/domain/entities/product.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../widgets/category_list_widget.dart';
import '../widgets/compact_home_header.dart';
import '../widgets/compact_promo_banner.dart';
import '../widgets/membership_summary_card.dart';
import '../widgets/promo_product_widget.dart';
import '../../../koperasi/presentation/widgets/nearby_koperasi_section.dart';
import '../../../koperasi/presentation/widgets/nearby_mitra_section.dart';
import '../../../discovery/domain/discovery.dart';
import '../../../discovery/presentation/widgets/discovery_sections.dart';
import '../../../content/presentation/widgets/local_shopping_banner.dart';
import '../../../content/presentation/widgets/membership_banner.dart';

/// Beranda KMP Mitra.
///
/// Disusun sebagai [CustomScrollView]: bagian atas yang tetap menjadi satu
/// sliver, sementara daftar rekomendasi memakai [SliverList] yang membangun
/// barisnya sesuai viewport. Versi sebelumnya memakai SingleChildScrollView
/// berisi Column, yang membangun setiap baris sekaligus.
///
/// **Navigasi:** `/products`, `/cart`, `/ai-assistant`, dan `/profile` adalah
/// branch dari [StatefulShellRoute], jadi dituju dengan `context.go()`.
/// `context.push()` menumpuk halaman baru di root navigator alih-alih
/// berpindah branch — bilah navigasi hilang, dan Marketplace muncul sebagai
/// halaman penuh yang tampak seperti beranda desain lama karena memakai
/// header serta kartu anggota yang sama.
///
/// Rute di luar shell (`/notifications`, `/orders/history`, detail produk)
/// tetap memakai `push()` supaya tombol kembali bekerja seperti biasa.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedFilterLabel = 'Semua';

  /// Produk yang sedang diproses ke keranjang — mencegah ketukan ganda pada
  /// operasi async yang sama.
  final Set<String> _addingToCart = {};

  static const List<String> _filterLabels = [
    'Semua',
    'Sembako',
    'Minuman',
    'Makanan Instan',
    'Perawatan',
  ];

  /// Tinggi bilah navigasi mengambang; dipakai sebagai padding bawah supaya
  /// produk terakhir tidak tertutup.
  static const double _navBarClearance = 96;

  static const List<PromoProductItemData> _promoProducts = [
    PromoProductItemData(
      id: 'promo-1',
      name: 'Beras Premium',
      subtitle: 'Larisst 5kg',
      discountBadge: '-20%',
      currentPrice: 64000,
      originalPrice: 80000,
      imageUrl: 'https://picsum.photos/id/1050/400/300',
      isFavorite: true,
    ),
    PromoProductItemData(
      id: 'promo-2',
      name: 'Minyak Goreng',
      subtitle: 'Bimoli 2L Pouch',
      discountBadge: '-15%',
      currentPrice: 34000,
      originalPrice: 40000,
      imageUrl: 'https://picsum.photos/id/1051/400/300',
    ),
    PromoProductItemData(
      id: 'promo-3',
      name: 'Indomie Soto Mie',
      subtitle: 'Karton (40x85g)',
      discountBadge: '-18%',
      currentPrice: 95000,
      originalPrice: 116000,
      imageUrl: 'https://picsum.photos/id/1070/400/300',
    ),
    PromoProductItemData(
      id: 'promo-4',
      name: 'Sunlight Jeruk Nipis',
      subtitle: 'Pouch 755ml',
      discountBadge: '-17%',
      currentPrice: 15500,
      originalPrice: 18700,
      imageUrl: 'https://picsum.photos/id/1080/400/300',
    ),
  ];

  Future<void> _onRefresh() async {
    ref.invalidate(categoriesProvider);
    await ref.read(productsListProvider.notifier).load(forceRefresh: true);
  }

  /// Mencocokkan label filter dengan kategori dari backend.
  String _categoryIdFor(String label, List<Category> backendCategories) {
    if (label == 'Semua') return '';
    final matched = backendCategories.firstWhere(
      (cat) =>
          cat.name.toLowerCase().contains(label.toLowerCase()) ||
          label.toLowerCase().contains(cat.name.toLowerCase()),
      orElse: () => const Category(id: '', name: '', description: ''),
    );
    return matched.id;
  }

  void _onFilterChipSelected(String label, List<Category> backendCategories) {
    setState(() => _selectedFilterLabel = label);
    ref
        .read(catalogQueryProvider.notifier)
        .update(
          (state) => state.copyWith(
            categoryId: _categoryIdFor(label, backendCategories),
            page: 1,
          ),
        );
  }

  void _handleCategoryTap(String categoryName) {
    final backendCategories = ref.read(categoriesProvider).asData?.value ?? [];
    ref
        .read(catalogQueryProvider.notifier)
        .update(
          (state) => state.copyWith(
            categoryId: _categoryIdFor(categoryName, backendCategories),
            search: '',
            page: 1,
          ),
        );
    context.go('/products');
  }

  Future<void> _handleAddToCart(Product product) async {
    if (_addingToCart.contains(product.id)) return;
    setState(() => _addingToCart.add(product.id));

    final success = await ref
        .read(cartProvider.notifier)
        .addToCart(productId: product.id, quantity: 1);

    if (!mounted) return;
    setState(() => _addingToCart.remove(product.id));
    _showSnackBarMessage(
      success
          ? '${product.name} berhasil ditambahkan ke keranjang'
          : 'Gagal menambahkan produk ke keranjang',
      isError: !success,
    );
  }

  /// Produk dari section penemuan dipisah dari [_handleAddToCart] karena
  /// bentuk datanya berbeda: [DiscoveryProduct] bisa berasal dari Kopdes
  /// maupun Mitra UMKM, dan endpoint keranjang membedakan keduanya.
  ///
  /// Mengirim id produk UMKM sebagai `productId` membuat backend mencarinya
  /// di tabel Product dan selalu menjawab 404 — jadi sumbernya wajib
  /// menentukan parameter mana yang dipakai.
  Future<void> _handleAddDiscoveryProduct(DiscoveryProduct product) async {
    if (_addingToCart.contains(product.id)) return;
    setState(() => _addingToCart.add(product.id));

    final isUmkm = product.source == ProductSource.umkm;
    final success = await ref
        .read(cartProvider.notifier)
        .addToCart(
          productId: isUmkm ? null : product.id,
          umkmProductId: isUmkm ? product.id : null,
          quantity: 1,
        );

    if (!mounted) return;
    setState(() => _addingToCart.remove(product.id));
    _showSnackBarMessage(
      success
          ? '${product.name} berhasil ditambahkan ke keranjang'
          : 'Gagal menambahkan produk ke keranjang',
      isError: !success,
    );
  }

  void _showSnackBarMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppleRadii.control),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Budi Santoso';
    final backendCategories = ref.watch(categoriesProvider).asData?.value ?? [];
    final cartCount = ref.watch(cartProvider).asData?.value.totalItems ?? 0;
    final unreadCount = ref
        .watch(notificationsProvider)
        .where((n) => !n.isRead)
        .length;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.canvas,
        // Physics & indikator overscroll diatur AppScrollBehavior global.
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1 & 2. Header ringkas + pencarian.
                  CompactHomeHeader(
                    userName: userName,
                    userLocation: 'Desa Lamteh, Banda Aceh',
                    notificationCount: unreadCount,
                    cartCount: cartCount,
                    chatCount: 2,
                    onNotificationTap: () => context.push('/notifications'),
                    onCartTap: () => context.go('/cart'),
                    onChatTap: () => context.go('/ai-assistant'),
                    onSearchTap: () => context.go('/products'),
                    onFilterTap: () => context.go('/products'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3 & 4. Ringkasan keanggotaan + aksi cepat.
                  MembershipSummaryCard(
                    balance: formatRupiah(250000),
                    points: '1.250',
                    statusLabel: 'VIP',
                    onTopUpTap: () =>
                        _showSnackBarMessage('Fitur Top Up Saldo Anggota'),
                    onHistoryTap: () => context.push('/orders/history'),
                    onCouponTap: () => _showSnackBarMessage('Kupon KMP Mitra'),
                    onDetailTap: () => context.go('/profile'),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Banner promosi ringkas.
                  CompactPromoBanner(
                    items: CompactPromoBanner.defaultItems,
                    onCtaTap: (_) => context.go('/products'),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Kopdes Terdekat — punya state lokasi & error sendiri,
                  // sehingga kegagalannya tidak menjatuhkan section lain.
                  const NearbyKoperasiSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // Mitra UMKM Terdekat — juga punya state sendiri.
                  const NearbyMitraSection(),
                  const SizedBox(height: AppSpacing.lg),

                  // 6. Kategori.
                  CategoryListWidget(
                    onCategoryTap: _handleCategoryTap,
                    onSeeAllTap: () => context.go('/products'),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // 7. Promo Terbaik.
                  PromoProductWidget(
                    products: _promoProducts,
                    onProductTap: (_) => context.go('/products'),
                    onAddToCartTap: (item) => _showSnackBarMessage(
                      '${item.name} ditambahkan ke keranjang',
                    ),
                    onFavoriteToggle: (_) {},
                    onSeeAllTap: () => context.go('/products'),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // 6. Produk UMKM Pilihan.
                  FeaturedUmkmSection(onAddToCart: _handleAddDiscoveryProduct),
                  const SizedBox(height: AppSpacing.lg),

                  // 7. Produk Terlaris.
                  BestSellersSection(onAddToCart: _handleAddDiscoveryProduct),
                  const SizedBox(height: AppSpacing.lg),

                  // 8. Rekomendasi Kebutuhan.
                  AppleSectionHeader(
                    title: 'Rekomendasi Kebutuhan',
                    actionLabel: 'Semua',
                    onAction: () => context.go('/products'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _RecommendationFilter(
                    labels: _filterLabels,
                    selected: _selectedFilterLabel,
                    onSelected: (label) =>
                        _onFilterChipSelected(label, backendCategories),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),

            _RecommendationList(
              addingIds: _addingToCart,
              onOpen: (p) => context.push('/products/detail/${p.id}'),
              onAdd: _handleAddToCart,
              onRetry: _onRefresh,
            ),

            // Section 9 & 10 berada di kaki halaman, setelah pengguna
            // melihat isinya lebih dulu.
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.lg),
                child: LocalShoppingBanner(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: MembershipBanner(),
              ),
            ),

            // Ruang bagi bilah navigasi mengambang.
            SliverToBoxAdapter(
              child: SizedBox(
                height: _navBarClearance + MediaQuery.paddingOf(context).bottom,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Deretan pill filter. Dipisah supaya perubahan filter tidak membangun ulang
/// seluruh bagian atas beranda.
class _RecommendationFilter extends StatelessWidget {
  final List<String> labels;
  final String selected;
  final ValueChanged<String> onSelected;

  const _RecommendationFilter({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => AppleChip(
          label: labels[i],
          selected: selected == labels[i],
          onTap: () => onSelected(labels[i]),
        ),
      ),
    );
  }
}

/// Daftar rekomendasi sebagai sliver, dengan keadaan loading, kosong, dan
/// error yang eksplisit.
class _RecommendationList extends ConsumerWidget {
  final Set<String> addingIds;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;
  final Future<void> Function() onRetry;

  const _RecommendationList({
    required this.addingIds,
    required this.onOpen,
    required this.onAdd,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsListProvider);

    return products.when(
      data: (list) {
        if (list.items.isEmpty) {
          return const SliverToBoxAdapter(
            child: _HomeMessage(
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada rekomendasi produk untuk filter ini.',
            ),
          );
        }

        final items = list.items.take(8).toList(growable: false);
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppleRadii.group),
              border: Border.all(color: AppColors.hairlineSoft),
            ),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                indent: 84,
                color: AppColors.hairlineSoft,
              ),
              itemBuilder: (context, index) {
                final product = items[index];
                return AppleProductRow(
                  imageUrl: product.primaryImageUrl,
                  title: product.name,
                  subtitle: 'KMP Mitra Koperasi',
                  price: formatRupiah(product.price),
                  onTap: () => onOpen(product),
                  // Tombol dimatikan selama request berjalan, bukan sekadar
                  // diberi warna lain.
                  onAdd: addingIds.contains(product.id)
                      ? null
                      : () => onAdd(product),
                );
              },
            ),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: GroupedProductListSkeleton(itemCount: 4),
        ),
      ),
      error: (_, __) => SliverToBoxAdapter(
        child: _HomeMessage(
          icon: Icons.wifi_off_rounded,
          message: 'Gagal memuat rekomendasi.',
          onRetry: onRetry,
        ),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Future<void> Function()? onRetry;

  const _HomeMessage({required this.icon, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.mutedSoft),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ],
      ),
    );
  }
}
