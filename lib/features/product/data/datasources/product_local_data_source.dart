import 'package:isar/isar.dart';
import '../../../../core/storage/models/product_cache.dart';
import '../models/product_model.dart';
import '../../domain/entities/category.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getCachedProducts();
  Future<void> cacheProducts(List<ProductModel> products);
  Future<ProductModel?> getCachedProductDetail(String id);
  Future<void> cacheProductDetail(ProductModel product);
  Future<void> clearCache();
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final Isar isar;

  ProductLocalDataSourceImpl({required this.isar});

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    final caches = await isar.productCaches
        .where()
        .sortByCachedAtDesc()
        .findAll();
    return caches.map((c) => _mapCacheToModel(c)).toList();
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    await isar.writeTxn(() async {
      // Clear old listings first to avoid stale pagination results
      await isar.productCaches.clear();

      final caches = products.map((p) => _mapModelToCache(p)).toList();
      await isar.productCaches.putAll(caches);
    });
  }

  @override
  Future<ProductModel?> getCachedProductDetail(String id) async {
    final cache = await isar.productCaches
        .where()
        .productIdEqualTo(id)
        .findFirst();
    if (cache == null) return null;
    return _mapCacheToModel(cache);
  }

  @override
  Future<void> cacheProductDetail(ProductModel product) async {
    await isar.writeTxn(() async {
      // Remove any existing cache for this product ID to prevent duplicates
      final existing = await isar.productCaches
          .where()
          .productIdEqualTo(product.id)
          .findFirst();
      if (existing != null) {
        await isar.productCaches.delete(existing.id);
      }

      final cache = _mapModelToCache(product);
      await isar.productCaches.put(cache);
    });
  }

  @override
  Future<void> clearCache() async {
    await isar.writeTxn(() async {
      await isar.productCaches.clear();
    });
  }

  ProductModel _mapCacheToModel(ProductCache cache) {
    return ProductModel(
      id: cache.productId,
      name: cache.name,
      description: cache.description,
      price: cache.price,
      stock: cache.stock,
      categoryId: '',
      category: Category(id: '', name: cache.category),
      images: cache.imageUrls
          .map(
            (url) => ProductImageModel(
              id: '',
              url: url,
              isPrimary: url == cache.imageUrls.firstOrNull,
            ),
          )
          .toList(),
      isActive: true,
      createdAt: cache.cachedAt,
      updatedAt: cache.cachedAt,
    );
  }

  ProductCache _mapModelToCache(ProductModel model) {
    return ProductCache()
      ..productId = model.id
      ..name = model.name
      ..description = model.description
      ..price = model.price
      ..stock = model.stock
      ..category = model.category?.name ?? 'Koperasi'
      ..imageUrls = model.images.map((img) => img.url).toList()
      ..cachedAt = DateTime.now();
  }
}
