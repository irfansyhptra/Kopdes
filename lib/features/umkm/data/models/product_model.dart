import 'product_category_model.dart';
import 'product_image_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final ProductCategoryModel? category;
  final List<ProductImageModel> images;
  final bool isApproved;
  final bool isActive;
  final double rating;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.category,
    required this.images,
    this.isApproved = false,
    this.isActive = true,
    this.rating = 0.0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final imageList = json['images'] as List? ?? [];
    final parsedImages = imageList
        .map((img) => ProductImageModel.fromJson(img as Map<String, dynamic>))
        .toList();

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
          ? ProductCategoryModel.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      images: parsedImages,
      isApproved: json['isApproved'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating'].toString()) ?? 0.0,
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
      'isApproved': isApproved,
      'isActive': isActive,
    };
  }
}
