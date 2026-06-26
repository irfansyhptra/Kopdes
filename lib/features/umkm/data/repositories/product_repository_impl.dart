import '../../domain/repositories/product_repository.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductService service;
  ProductRepositoryImpl({required this.service});

  @override
  Future<List<ProductModel>> getProducts({String? search, String? categoryId, int page = 1, int limit = 10}) =>
      service.getProducts(search: search, categoryId: categoryId, page: page, limit: limit);

  @override
  Future<ProductModel> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
  }) => service.createProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
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
    bool? isActive,
    List<dynamic>? newImages,
  }) => service.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        isActive: isActive,
        newImages: newImages,
      );

  @override
  Future<void> deleteProduct(String id) => service.deleteProduct(id);

  @override
  Future<List<ProductCategoryModel>> getCategories() => service.getCategories();
}
