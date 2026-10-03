import '../../domain/entities/product.dart';
import 'category_model.dart';

class ProductImageModel extends ProductImage {
  const ProductImageModel({
    required super.id,
    required super.url,
    super.isPrimary,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as String,
      url: json['url'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'url': url, 'isPrimary': isPrimary};
  }
}

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.stock,
    required super.categoryId,
    super.category,
    required List<ProductImageModel> super.images,
    super.isActive = true,
    required super.createdAt,
    required super.updatedAt,
    super.discountPrice,
    super.unit,
    super.soldCount,
    super.ratingAverage,
    super.ratingCount,
    super.store,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var imageList = json['images'] as List? ?? [];
    List<ProductImageModel> parsedImages = imageList
        .map((img) => ProductImageModel.fromJson(img as Map<String, dynamic>))
        .toList();

    final rating = json['rating'] as Map<String, dynamic>? ?? const {};

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      categoryId: json['categoryId'] as String,
      category: json['category'] != null
          ? CategoryModel.fromJson(
              json['category'] as Map<String, dynamic>,
            ).toEntity()
          : null,
      images: parsedImages,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      discountPrice: json['discountPrice'] is num
          ? (json['discountPrice'] as num).toDouble()
          : double.tryParse('${json['discountPrice']}'),
      unit: json['unit'] as String? ?? 'pcs',
      soldCount: (json['soldCount'] as num?)?.toInt() ?? 0,
      ratingAverage: (rating['average'] as num?)?.toDouble(),
      ratingCount: (rating['count'] as num?)?.toInt() ?? 0,
      store: ProductStore.fromJson(json['kopdes'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      stock: stock,
      categoryId: categoryId,
      category: category,
      images: images,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      // Setiap field baru wajib ikut di sini. Jalur pemetaan kedua yang
      // tertinggal satu field membuat halaman detail kehilangan harga diskon,
      // rating, atau nama tokonya tanpa satu pun galat.
      discountPrice: discountPrice,
      unit: unit,
      soldCount: soldCount,
      ratingAverage: ratingAverage,
      ratingCount: ratingCount,
      store: store,
    );
  }
}
