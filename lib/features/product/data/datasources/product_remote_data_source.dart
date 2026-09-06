import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';

/// Metode baca mengembalikan JSON mentah, bukan model.
///
/// Cache menyimpan payload apa adanya, jadi data dari jaringan dan data dari
/// cache melewati fungsi `fromJson` yang sama persis. Kalau data source
/// men-decode lebih dulu, cache butuh jalur pemetaannya sendiri — dan jalur
/// kedua itulah yang dulu diam-diam membuang `categoryId` dan `isActive`.
abstract class ProductRemoteDataSource {
  Future<Map<String, dynamic>> fetchProducts({
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
  });

  Future<Map<String, dynamic>> fetchProductDetail(String id);

  Future<List<dynamic>> fetchCategories();

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
  Future<Map<String, dynamic>> fetchProducts({
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
    // Backend mengirim total/page/limit/totalPages DATAR di dalam `data`,
    // bukan bersarang di `meta`. Versi sebelumnya membaca `dataMap['meta']`
    // yang selalu null, sehingga Paginated jatuh ke totalPages = 1 dan
    // halaman kedua katalog tidak pernah dimuat.
    return {
      'products': dataMap['products'] ?? const [],
      'meta': {
        'total': dataMap['total'] ?? 0,
        'page': dataMap['page'] ?? 1,
        'limit': dataMap['limit'] ?? 20,
        'totalPages': dataMap['totalPages'] ?? 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchProductDetail(String id) async {
    final response = await dio.get('/products/$id');
    final responseMap = response.data as Map<String, dynamic>;
    return responseMap['data'] as Map<String, dynamic>? ?? responseMap;
  }

  @override
  Future<List<dynamic>> fetchCategories() async {
    final response = await dio.get('/categories');
    final responseMap = response.data as Map<String, dynamic>;
    return responseMap['data'] as List? ??
        responseMap['categories'] as List? ??
        const [];
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
