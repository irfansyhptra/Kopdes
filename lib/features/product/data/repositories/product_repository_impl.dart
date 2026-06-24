import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<Product>> getProducts({
    String? search,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool? isActive,
  }) async {
    try {
      final remoteProducts = await remoteDataSource.getProducts(
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
      );

      // Cache products locally (only on page 1 to keep cache fresh and clean)
      if (page == 1 &&
          (search == null || search.isEmpty) &&
          (categoryId == null || categoryId.isEmpty)) {
        await localDataSource.cacheProducts(remoteProducts);
      }

      return remoteProducts.map((p) => p.toEntity()).toList();
    } catch (_) {
      // Offline fallback: load from local cache
      final cached = await localDataSource.getCachedProducts();
      if (cached.isNotEmpty) {
        return cached.map((p) => p.toEntity()).toList();
      }
      rethrow; // If no cache exists, propagate error
    }
  }

  @override
  Future<Product> getProductDetail(String id) async {
    try {
      final remoteProduct = await remoteDataSource.getProductDetail(id);
      await localDataSource.cacheProductDetail(remoteProduct);
      return remoteProduct.toEntity();
    } catch (e) {
      final cached = await localDataSource.getCachedProductDetail(id);
      if (cached != null) {
        return cached.toEntity();
      }
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategories() async {
    try {
      final remoteCategories = await remoteDataSource.getCategories();
      return remoteCategories.map((c) => c.toEntity()).toList();
    } catch (_) {
      // If offline, return a fallback empty list or allow UI to handle
      return [];
    }
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
    return product.toEntity();
  }

  @override
  Future<void> deleteProduct(String id) async {
    await remoteDataSource.deleteProduct(id);
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
    return category.toEntity();
  }
}
