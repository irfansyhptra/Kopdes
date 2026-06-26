import '../../data/models/product_model.dart';
import '../../data/models/product_category_model.dart';

abstract class ProductRepository {
  Future<List<ProductModel>> getProducts({String? search, String? categoryId, int page = 1, int limit = 10});
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
  Future<List<ProductCategoryModel>> getCategories();
}
