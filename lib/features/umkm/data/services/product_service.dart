import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';

class ProductService {
  final Dio dio;
  ProductService({required this.dio});

  Future<List<ProductModel>> getProducts({String? search, String? categoryId, int page = 1, int limit = 10}) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null && categoryId.isNotEmpty) params['categoryId'] = categoryId;

    final response = await dio.get('/seller/products', queryParameters: params);
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>;
    final list = dataMap['products'] as List? ?? [];
    return list.map((p) => ProductModel.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
  }) async {
    final formData = FormData();
    formData.fields.addAll([
      MapEntry('name', name),
      MapEntry('description', description),
      MapEntry('price', price.toString()),
      MapEntry('stock', stock.toString()),
      MapEntry('categoryId', categoryId),
    ]);

    if (images != null) {
      for (var file in images) {
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          formData.files.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(bytes, filename: file.name),
            ),
          );
        }
      }
    }

    final response = await dio.post('/seller/products', data: formData);
    final responseMap = response.data as Map<String, dynamic>;
    return ProductModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
  }) async {
    final formData = FormData();
    if (name != null) formData.fields.add(MapEntry('name', name));
    if (description != null) formData.fields.add(MapEntry('description', description));
    if (price != null) formData.fields.add(MapEntry('price', price.toString()));
    if (stock != null) formData.fields.add(MapEntry('stock', stock.toString()));
    if (categoryId != null) formData.fields.add(MapEntry('categoryId', categoryId));
    if (isActive != null) formData.fields.add(MapEntry('isActive', isActive.toString()));

    if (newImages != null) {
      for (var file in newImages) {
        if (file is XFile) {
          final bytes = await file.readAsBytes();
          formData.files.add(
            MapEntry(
              'images',
              MultipartFile.fromBytes(bytes, filename: file.name),
            ),
          );
        }
      }
    }

    final response = await dio.put('/seller/products/$id', data: formData);
    final responseMap = response.data as Map<String, dynamic>;
    return ProductModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) async {
    await dio.delete('/seller/products/$id');
  }

  Future<List<ProductCategoryModel>> getCategories() async {
    final response = await dio.get('/categories');
    final responseMap = response.data as Map<String, dynamic>;
    final list = responseMap['data'] as List? ?? [];
    return list.map((c) => ProductCategoryModel.fromJson(c as Map<String, dynamic>)).toList();
  }
}
