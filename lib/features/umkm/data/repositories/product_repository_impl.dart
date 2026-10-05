import '../../domain/repositories/product_repository.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';
import '../models/seller_product_page.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductService service;
  ProductRepositoryImpl({required this.service});

  // Tanpa cachedFetch, sengaja: ini daftar stok milik penjual sendiri, yang
  // juga digeser kasir POS. Angka stok 5 menit yang lalu bukan "data basi
  // yang masih berguna" — ia bisa membuat penjual menjual barang yang habis.
  @override
  Future<SellerProductPage> getProducts({
    String? search,
    String? categoryId,
    StockLevel? stockLevel,
    int page = 1,
    int limit = 20,
  }) async => SellerProductPage.fromJson(
    await service.fetchProducts(
      search: search,
      categoryId: categoryId,
      stockStatus: stockLevel?.wire,
      page: page,
      limit: limit,
    ),
  );

  @override
  Future<ProductModel> getProduct(String id) async =>
      ProductModel.fromJson(await service.fetchProduct(id));

  @override
  Future<List<ProductCategoryModel>> getStoreCategories() async =>
      (await service.fetchStoreCategories())
          .whereType<Map<String, dynamic>>()
          .map(ProductCategoryModel.fromJson)
          .toList();

  @override
  Future<ProductModel> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    int? minStock,
    List<dynamic>? images,
  }) => service.createProduct(
    name: name,
    description: description,
    price: price,
    stock: stock,
    categoryId: categoryId,
    minStock: minStock,
    images: images,
  );

  @override
  Future<ProductModel> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    int? minStock,
    bool? isActive,
    List<dynamic>? newImages,
  }) => service.updateProduct(
    id: id,
    name: name,
    description: description,
    price: price,
    stock: stock,
    categoryId: categoryId,
    minStock: minStock,
    isActive: isActive,
    newImages: newImages,
  );

  @override
  Future<void> deleteProduct(String id) => service.deleteProduct(id);

  @override
  Future<void> addProductImage(String id, String path) =>
      service.addProductImage(id, path);

  @override
  Future<List<ProductCategoryModel>> getCategories() => service.getCategories();
}
