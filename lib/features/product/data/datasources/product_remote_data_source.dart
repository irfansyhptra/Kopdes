import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
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
  });

  Future<ProductModel> getProductDetail(String id);

  Future<List<CategoryModel>> getCategories();

  // Admin CRUD
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

  Future<CategoryModel> createCategory({
    required String name,
    String? description,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;

  ProductRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ProductModel>> getProducts({
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
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
    };

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      queryParameters['categoryId'] = categoryId;
    }
    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice;
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice;
    }
    if (inStock != null) {
      queryParameters['inStock'] = inStock;
    }
    if (isActive != null) {
      queryParameters['isActive'] = isActive;
    }

    final response = await dio.get(
      '/products',
      queryParameters: queryParameters,
    );

    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    final productsList = dataMap['products'] as List? ?? [];

    return productsList
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ProductModel> getProductDetail(String id) async {
    final response = await dio.get('/products/$id');
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return ProductModel.fromJson(dataMap);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await dio.get('/categories');
    final responseMap = response.data as Map<String, dynamic>;
    final categoriesList =
        responseMap['data'] as List? ??
        responseMap['categories'] as List? ??
        [];
    return categoriesList
        .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  @override
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

    final response = await dio.post('/products', data: formData);
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return ProductModel.fromJson(dataMap);
  }

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
  }) async {
    final formData = FormData();
    if (name != null) formData.fields.add(MapEntry('name', name));
    if (description != null) {
      formData.fields.add(MapEntry('description', description));
    }
    if (price != null) formData.fields.add(MapEntry('price', price.toString()));
    if (stock != null) formData.fields.add(MapEntry('stock', stock.toString()));
    if (categoryId != null) {
      formData.fields.add(MapEntry('categoryId', categoryId));
    }
    if (isActive != null) {
      formData.fields.add(MapEntry('isActive', isActive.toString()));
    }

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

    final response = await dio.put('/products/$id', data: formData);
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return ProductModel.fromJson(dataMap);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await dio.delete('/products/$id');
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null) body['description'] = description;

    final response = await dio.post('/categories', data: body);
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>? ?? responseMap;
    return CategoryModel.fromJson(dataMap);
  }
}
