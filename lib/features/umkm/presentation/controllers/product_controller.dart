import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_category_model.dart';
import '../../data/models/seller_product_page.dart';
import '../../domain/repositories/product_repository.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';

/// Filter daftar produk penjual. Semuanya dikirim ke server.
class ProductSearchQuery {
  final String search;
  final String categoryId;

  /// null = semua status stok.
  final StockLevel? stockLevel;
  final int limit;

  const ProductSearchQuery({
    this.search = '',
    this.categoryId = '',
    this.stockLevel,
    this.limit = 20,
  });

  bool get isFiltered =>
      search.isNotEmpty || categoryId.isNotEmpty || stockLevel != null;

  ProductSearchQuery copyWith({
    String? search,
    String? categoryId,
    StockLevel? stockLevel,
    bool clearStockLevel = false,
  }) {
    return ProductSearchQuery(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      stockLevel: clearStockLevel ? null : (stockLevel ?? this.stockLevel),
      limit: limit,
    );
  }
}

final sellerProductQueryProvider = StateProvider<ProductSearchQuery>((ref) {
  return const ProductSearchQuery();
});

/// Seluruh kategori katalog — untuk memilih kategori di form produk.
final sellerCategoriesProvider = FutureProvider<List<ProductCategoryModel>>((
  ref,
) async {
  return ref.watch(productRepositoryProvider).getCategories();
});

/// Kategori yang dipakai produk toko ini — untuk chip filter.
final sellerStoreCategoriesProvider =
    FutureProvider<List<ProductCategoryModel>>((ref) async {
      return ref.watch(productRepositoryProvider).getStoreCategories();
    });

/// Satu produk toko, langsung dari `GET /seller/products/:id`.
final sellerProductDetailProvider = FutureProvider.family<ProductModel, String>(
  (ref, id) => ref.read(productRepositoryProvider).getProduct(id),
);

class SellerProductListState {
  final List<ProductModel> items;
  final bool hasMore;

  /// Jumlah produk yang cocok dengan SEMUA filter, termasuk status stok.
  final int total;
  final StockSummary summary;
  final int lowStockThreshold;
  final bool isLoadingMore;

  const SellerProductListState({
    required this.items,
    required this.hasMore,
    required this.total,
    required this.summary,
    required this.lowStockThreshold,
    this.isLoadingMore = false,
  });

  StockLevel levelOf(ProductModel p) =>
      StockLevel.of(p.stock, lowStockThreshold);

  SellerProductListState copyWith({
    List<ProductModel>? items,
    bool? hasMore,
    int? total,
    StockSummary? summary,
    bool? isLoadingMore,
  }) => SellerProductListState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    total: total ?? this.total,
    summary: summary ?? this.summary,
    lowStockThreshold: lowStockThreshold,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
  );
}

/// Daftar produk penjual, berhalaman, mengikuti pola `ProductListNotifier`.
///
/// Penulisan yang sudah diterima server menambal baris yang terdampak
/// ([applyStock], [patch], [remove]) alih-alih memuat ulang semuanya.
class SellerProductListNotifier
    extends StateNotifier<AsyncValue<SellerProductListState>> {
  final ProductRepository _repository;
  final ProductSearchQuery _query;
  int _page = 1;

  SellerProductListNotifier(this._repository, this._query)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    _page = 1;
    try {
      final result = await _fetch(1);
      if (!mounted) return;
      state = AsyncValue.data(_toState(result));
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  /// Tarik-untuk-muat-ulang: daftar lama tetap tampil sampai yang baru tiba.
  Future<void> refresh() => load();

  /// Coba lagi dari keadaan galat: kembali ke skeleton dulu.
  Future<void> retry() {
    state = const AsyncValue.loading();
    return load();
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    // Penjaga: scroll cepat tidak boleh meminta halaman yang sama dua kali.
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(_page + 1);
      if (!mounted) return;
      _page += 1;
      final seen = current.items.map((p) => p.id).toSet();
      state = AsyncValue.data(
        _toState(next).copyWith(
          // Produk yang bergeser halaman karena ada yang baru ditambahkan
          // tidak boleh muncul dua kali.
          items: [
            ...current.items,
            ...next.page.items.where((p) => !seen.contains(p.id)),
          ],
        ),
      );
    } catch (_) {
      if (!mounted) return;
      // Halaman berikutnya gagal bukan alasan membuang yang sudah tampil.
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  /// Stok satu produk berubah menjadi [stock] menurut server.
  void applyStock(String productId, int stock) {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.items.indexWhere((p) => p.id == productId);
    if (index < 0) return;

    final before = current.items[index];
    if (before.stock == stock) return;
    final after = before.copyWith(stock: stock);
    state = AsyncValue.data(
      current.copyWith(
        items: [...current.items]..[index] = after,
        summary: current.summary.move(
          current.levelOf(before),
          current.levelOf(after),
        ),
      ),
    );
  }

  /// Ganti satu baris dengan versi yang sudah diterima server.
  void patch(ProductModel product) {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.items.indexWhere((p) => p.id == product.id);
    if (index < 0) return;
    state = AsyncValue.data(
      current.copyWith(items: [...current.items]..[index] = product),
    );
  }

  void remove(String productId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final index = current.items.indexWhere((p) => p.id == productId);
    if (index < 0) return;
    final gone = current.items[index];
    state = AsyncValue.data(
      current.copyWith(
        items: [...current.items]..removeAt(index),
        total: current.total - 1,
        summary: current.summary.remove(current.levelOf(gone)),
      ),
    );
  }

  SellerProductListState _toState(SellerProductPage result) =>
      SellerProductListState(
        items: result.page.items,
        hasMore: result.page.hasMore,
        total: result.page.total,
        summary: result.summary,
        lowStockThreshold: result.lowStockThreshold,
      );

  Future<SellerProductPage> _fetch(int page) => _repository.getProducts(
    search: _query.search.isEmpty ? null : _query.search,
    categoryId: _query.categoryId.isEmpty ? null : _query.categoryId,
    stockLevel: _query.stockLevel,
    page: page,
    limit: _query.limit,
  );
}

final sellerProductListProvider =
    StateNotifierProvider<
      SellerProductListNotifier,
      AsyncValue<SellerProductListState>
    >((ref) {
      return SellerProductListNotifier(
        ref.watch(productRepositoryProvider),
        ref.watch(sellerProductQueryProvider),
      );
    });

class ProductController extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repository;
  final Ref _ref;

  ProductController({required ProductRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref,
      super(const AsyncValue.data(null));

  Future<bool> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        isActive: isActive,
        newImages: newImages,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(sellerProductDetailProvider(id));
      final onlyActiveChanged =
          isActive != null &&
          name == null &&
          description == null &&
          price == null &&
          stock == null &&
          categoryId == null &&
          newImages == null;
      if (onlyActiveChanged) {
        final list = _ref.read(sellerProductListProvider).valueOrNull;
        final row = list?.items.where((p) => p.id == id).firstOrNull;
        if (row != null) {
          _ref
              .read(sellerProductListProvider.notifier)
              .patch(row.copyWith(isActive: isActive));
        }
      } else {
        // Nama, harga, kategori, atau foto bisa memindahkan produk keluar
        // dari filter yang sedang aktif — tambalan lokal akan berbohong.
        _ref.invalidate(sellerProductListProvider);
        _ref.invalidate(sellerStoreCategoriesProvider);
      }
      _refreshDashboard();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteProduct(id);
      state = const AsyncValue.data(null);
      _ref.read(sellerProductListProvider.notifier).remove(id);
      _ref.invalidate(sellerStoreCategoriesProvider);
      _refreshDashboard();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _refreshDashboard() =>
      _ref.read(sellerDashboardControllerProvider.notifier).refresh();
}

final productControllerProvider =
    StateNotifierProvider<ProductController, AsyncValue<void>>((ref) {
      return ProductController(
        repository: ref.watch(productRepositoryProvider),
        ref: ref,
      );
    });
