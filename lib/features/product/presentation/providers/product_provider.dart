import '../../domain/entities/product_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/storage/api_cache.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/datasources/product_remote_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';

// 1. Core Providers
final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((
  ref,
) {
  return ProductRemoteDataSourceImpl(dio: ref.watch(dioProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    cache: ref.watch(apiCacheProvider),
  );
});

// 2. Categories List Provider
// Kategori: cache 12 jam. Beranda & Marketplace sama-sama memintanya, dan
// dedup GET di dio_client menyatukan keduanya bila sempat berbarengan.
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(productRepositoryProvider).getCategories();
});

// 3. Catalog Filter & State Models
class CatalogQuery {
  final String search;
  final String categoryId;
  final double? minPrice;
  final double? maxPrice;
  final int page;
  final int limit;
  final String sortBy;
  final String sortOrder;

  const CatalogQuery({
    this.search = '',
    this.categoryId = '',
    this.minPrice,
    this.maxPrice,
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });

  CatalogQuery copyWith({
    String? search,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) {
    return CatalogQuery(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

final catalogQueryProvider = StateProvider<CatalogQuery>((ref) {
  return const CatalogQuery();
});

// 4. Daftar produk — berhalaman, dengan muat-lebih-banyak.
//
// Sebelumnya provider ini meminta `page: 1, limit: 10` dan tidak pernah
// meminta halaman kedua: sisa katalog tidak bisa dijangkau sama sekali, dan
// metadata paginasi dari backend dibuang.
class ProductListState {
  final List<Product> items;
  final bool hasMore;
  final bool isLoadingMore;
  final int total;

  const ProductListState({
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.total = 0,
  });

  ProductListState copyWith({
    List<Product>? items,
    bool? hasMore,
    bool? isLoadingMore,
    int? total,
  }) => ProductListState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    total: total ?? this.total,
  );
}

class ProductListNotifier extends StateNotifier<AsyncValue<ProductListState>> {
  final ProductRepository _repository;
  final CatalogQuery _query;

  ProductListNotifier(this._repository, this._query)
    : super(const AsyncValue.loading()) {
    load();
  }

  int _page = 1;

  Future<void> load({bool forceRefresh = false}) async {
    _page = 1;
    if (forceRefresh) state = const AsyncValue.loading();
    try {
      final result = await _fetch(1, forceRefresh: forceRefresh);
      state = AsyncValue.data(
        ProductListState(
          items: result.items,
          hasMore: result.hasMore,
          total: result.total,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Muat halaman berikutnya dan sambung ke daftar yang sudah tampil.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    // Penjaga: tanpa ini, scroll cepat memicu beberapa permintaan untuk
    // halaman yang sama dan produknya muncul dobel.
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(_page + 1);
      _page += 1;
      state = AsyncValue.data(
        ProductListState(
          items: [...current.items, ...next.items],
          hasMore: next.hasMore,
          total: next.total,
        ),
      );
    } catch (_) {
      // Halaman berikutnya gagal bukan alasan membuang yang sudah tampil.
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  Future<Paginated<Product>> _fetch(int page, {bool forceRefresh = false}) {
    return _repository.getProducts(
      search: _query.search.isEmpty ? null : _query.search,
      categoryId: _query.categoryId.isEmpty ? null : _query.categoryId,
      minPrice: _query.minPrice,
      maxPrice: _query.maxPrice,
      page: page,
      limit: _query.limit,
      sortBy: _query.sortBy,
      sortOrder: _query.sortOrder,
      isActive: true,
      forceRefresh: forceRefresh,
    );
  }
}

final productsListProvider =
    StateNotifierProvider<ProductListNotifier, AsyncValue<ProductListState>>((
      ref,
    ) {
      return ProductListNotifier(
        ref.watch(productRepositoryProvider),
        ref.watch(catalogQueryProvider),
      );
    });

// 5. Product Detail Provider (family to allow caching specific product details)
final productDetailProvider = FutureProvider.family<Product, String>((
  ref,
  id,
) async {
  return ref.watch(productRepositoryProvider).getProductDetail(id);
});

// 6. Admin Product List Provider (no active-only restrictions, lists all products)
final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  // ponytail: satu halaman 50 untuk konsol admin. Kalau satu koperasi tembus
  // 50 produk, pakai ProductListNotifier di sini juga, bukan naikkan limit.
  final page = await ref
      .watch(productRepositoryProvider)
      .getProducts(page: 1, limit: 50, sortBy: 'createdAt', sortOrder: 'desc');
  return page.items;
});

// 7. Admin CRUD Action Notifier
class AdminProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repository;
  final Ref _ref;

  AdminProductNotifier({
    required ProductRepository repository,
    required Ref ref,
  }) : _repository = repository,
       _ref = ref,
       super(const AsyncValue.data(null));

  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
    ProductDraft? draft,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        images: images,
        draft: draft,
      );
      state = const AsyncValue.data(null);
      _refreshProductProviders();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
    ProductDraft? draft,
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
        draft: draft,
      );
      state = const AsyncValue.data(null);
      _refreshProductProviders();
      _ref.invalidate(productDetailProvider(id));
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
      _refreshProductProviders();
      _ref.invalidate(productDetailProvider(id));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> createCategory({
    required String name,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createCategory(name: name, description: description);
      state = const AsyncValue.data(null);
      _ref.invalidate(categoriesProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _refreshProductProviders() {
    _ref.invalidate(productsListProvider);
    _ref.invalidate(adminProductsProvider);
    _ref.invalidate(categoriesProvider);
  }
}

final adminProductActionProvider =
    StateNotifierProvider<AdminProductNotifier, AsyncValue<void>>((ref) {
      return AdminProductNotifier(
        repository: ref.watch(productRepositoryProvider),
        ref: ref,
      );
    });
