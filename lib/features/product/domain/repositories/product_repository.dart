import '../entities/product_draft.dart';
import '../../../../core/network/paginated.dart';
import '../entities/product.dart';
import '../entities/category.dart';

abstract class ProductRepository {
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

    /// Lewati cache dan paksa ambil dari jaringan — untuk tarik-untuk-muat-ulang.
    bool forceRefresh = false,
  });

  Future<Product> getProductDetail(String id, {bool forceRefresh = false});

  Future<List<Category>> getCategories({bool forceRefresh = false});

  // Admin management
  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
    ProductDraft? draft,
  });

  Future<Product> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
    ProductDraft? draft,
  });

  Future<void> deleteProduct(String id);

  Future<Category> createCategory({required String name, String? description});
}
