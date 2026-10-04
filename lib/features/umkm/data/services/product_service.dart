import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../models/product_category_model.dart';

class ProductService {
  final Dio dio;
  ProductService({required this.dio});

  /// Satu halaman produk toko, JSON apa adanya: `products`, `meta`,
  /// `summary`, `lowStockThreshold`.
  Future<Map<String, dynamic>> fetchProducts({
    String? search,
    String? categoryId,
    String? stockStatus,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get(
      '/seller/products',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (stockStatus != null) 'stockStatus': stockStatus,
      },
    );
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchProduct(String id) async {
    final response = await dio.get('/seller/products/$id');
    return (response.data as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  /// Kategori yang dipakai produk toko ini (bukan seluruh katalog).
  Future<List<dynamic>> fetchStoreCategories() async {
    final response = await dio.get('/seller/products/categories');
    return (response.data as Map<String, dynamic>)['data'] as List? ?? [];
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

    final response = await dio.put('/seller/products/$id', data: formData);
    final responseMap = response.data as Map<String, dynamic>;
    return ProductModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  /// Menambah SATU foto ke produk lewat `PUT /seller/products/:id`.
  ///
  /// Satu foto per permintaan, sengaja: Vercel menolak badan permintaan di
  /// atas 4,5 MB, dan lima foto ponsel dalam satu kiriman melewatinya —
  /// produk gagal tersimpan seluruhnya. Foto pertama yang masuk ke produk
  /// tanpa foto menjadi foto utama, jadi urutan unggah = urutan tampil.
  Future<void> addProductImage(String id, String path) async {
    final name = path.split(Platform.pathSeparator).last;
    await dio.put(
      '/seller/products/$id',
      data: FormData.fromMap({
        // Nama berkas berekstensi: Dio menebak Content-Type darinya, dan
        // backend hanya menerima image/jpeg, png, webp.
        'images': await MultipartFile.fromFile(path, filename: name),
      }),
    );
  }

  Future<void> deleteProduct(String id) async {
    await dio.delete('/seller/products/$id');
  }

  Future<List<ProductCategoryModel>> getCategories() async {
    final response = await dio.get('/categories');
    final responseMap = response.data as Map<String, dynamic>;
    final list = responseMap['data'] as List? ?? [];
    return list
        .map((c) => ProductCategoryModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
