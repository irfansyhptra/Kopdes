import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/isar_service.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/datasources/product_local_data_source.dart';
import '../../data/datasources/product_remote_data_source.dart';
import '../../data/repositories/product_repository_impl.dart';

// 1. Core Providers
final productLocalDataSourceProvider = Provider<ProductLocalDataSource>((ref) {
  return ProductLocalDataSourceImpl(isar: ref.watch(isarProvider));
});

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>((
  ref,
) {
  return ProductRemoteDataSourceImpl(dio: ref.watch(dioProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDataSource: ref.watch(productRemoteDataSourceProvider),
    localDataSource: ref.watch(productLocalDataSourceProvider),
  );
});

// 2. Categories List Provider
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
    this.limit = 10,
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

// 4. Products List Provider (Reacts automatically to catalogQueryProvider)
final productsListProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(catalogQueryProvider);
  return ref
      .watch(productRepositoryProvider)
      .getProducts(
        search: query.search.isEmpty ? null : query.search,
        categoryId: query.categoryId.isEmpty ? null : query.categoryId,
        minPrice: query.minPrice,
        maxPrice: query.maxPrice,
        page: query.page,
        limit: query.limit,
        sortBy: query.sortBy,
        sortOrder: query.sortOrder,
        isActive: true, // Only show active products to customers
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
  return ref
      .watch(productRepositoryProvider)
      .getProducts(
        page: 1,
        limit: 100, // retrieve a larger list for management ease
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );
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
  }
}

final adminProductActionProvider =
    StateNotifierProvider<AdminProductNotifier, AsyncValue<void>>((ref) {
      return AdminProductNotifier(
        repository: ref.watch(productRepositoryProvider),
        ref: ref,
      );
    });
