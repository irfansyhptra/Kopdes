import '../../../../core/network/paginated.dart';
import '../../../../core/storage/api_cache.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ApiCache cache;

  ProductRepositoryImpl({required this.remoteDataSource, required this.cache});

  @override
  Future<Paginated<Product>> getProducts({
    String? search,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    int page = 1,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool? isActive,
    bool forceRefresh = false,
  }) {
    // Kunci cache harus mencerminkan SETIAP filter, kalau tidak hasil
    // pencarian "beras" bisa tersaji untuk pencarian "gula".
    final key = CacheKeys.productList(
      [
        'p=$page',
        'l=$limit',
        's=${search ?? ''}',
        'c=${categoryId ?? ''}',
        'min=${minPrice ?? ''}',
        'max=${maxPrice ?? ''}',
        'stock=${inStock ?? ''}',
        'active=${isActive ?? ''}',
        'sort=$sortBy.$sortOrder',
      ].join('&'),
    );

    return cachedFetch(
      cache: cache,
      key: key,
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remoteDataSource.fetchProducts(
        search: search,
        categoryId: categoryId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStock: inStock,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
        isActive: isActive,
      ),
      decode: (json) => Paginated.fromJson(
        json,
        'products',
        ProductModel.fromJson,
      ).map((m) => m.toEntity()),
    );
  }

  @override
  Future<Product> getProductDetail(String id, {bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: CacheKeys.productDetail(id),
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remoteDataSource.fetchProductDetail(id),
      decode: (json) =>
          ProductModel.fromJson(json as Map<String, dynamic>).toEntity(),
    );
  }

  @override
  Future<List<Category>> getCategories({bool forceRefresh = false}) {
    // Kategori hampir tidak pernah berubah — TTL panjang, dan tidak lagi
    // mengembalikan daftar kosong saat gagal (dulu itu membuat kegagalan
    // jaringan tampak seperti "koperasi ini memang tidak punya kategori").
    return cachedFetch(
      cache: cache,
      key: CacheKeys.categories,
      ttl: CacheTtl.long,
      forceRefresh: forceRefresh,
      fetch: () => remoteDataSource.fetchCategories(),
      decode: (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map((c) => CategoryModel.fromJson(c).toEntity())
          .toList(growable: false),
    );
  }

  @override
  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
  }) async {
    final product = await remoteDataSource.createProduct(
      name: name,
      description: description,
      price: price,
      stock: stock,
      categoryId: categoryId,
      images: images,
    );
    await _invalidateProductCaches();
    return product.toEntity();
  }

  @override
  Future<Product> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
  }) async {
    final product = await remoteDataSource.updateProduct(
      id: id,
      name: name,
      description: description,
      price: price,
      stock: stock,
      categoryId: categoryId,
      isActive: isActive,
      newImages: newImages,
    );
    await _invalidateProductCaches(id);
    return product.toEntity();
  }

  @override
  Future<void> deleteProduct(String id) async {
    await remoteDataSource.deleteProduct(id);
    await _invalidateProductCaches(id);
  }

  /// Setiap tulis harus membatalkan cache baca yang terdampak, kalau tidak
  /// pengguna melihat data lamanya sendiri selama TTL masih berjalan.
  Future<void> _invalidateProductCaches([String? id]) async {
    await cache.invalidatePrefix(CacheKeys.productListPrefix);
    if (id != null) await cache.invalidate(CacheKeys.productDetail(id));
  }

  @override
  Future<Category> createCategory({
    required String name,
    String? description,
  }) async {
    final category = await remoteDataSource.createCategory(
      name: name,
      description: description,
    );
    await cache.invalidate(CacheKeys.categories);
    return category.toEntity();
  }
}
