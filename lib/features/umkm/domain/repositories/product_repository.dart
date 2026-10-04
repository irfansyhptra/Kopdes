import '../../data/models/product_model.dart';
import '../../data/models/product_category_model.dart';
import '../../data/models/seller_product_page.dart';

abstract class ProductRepository {
  Future<SellerProductPage> getProducts({
    String? search,
    String? categoryId,
    StockLevel? stockLevel,
    int page = 1,
    int limit = 20,
  });
  Future<ProductModel> getProduct(String id);

  /// Kategori yang dipakai produk toko ini, untuk chip filter.
  Future<List<ProductCategoryModel>> getStoreCategories();
  Future<ProductModel> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
  });
  Future<ProductModel> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
  });
  Future<void> deleteProduct(String id);

  /// Satu foto per panggilan — lihat `ProductService.addProductImage`.
  Future<void> addProductImage(String id, String path);
  Future<List<ProductCategoryModel>> getCategories();
}
