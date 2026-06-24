import 'category.dart';

class ProductImage {
  final String id;
  final String url;
  final bool isPrimary;

  const ProductImage({
    required this.id,
    required this.url,
    this.isPrimary = false,
  });
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final Category? category;
  final List<ProductImage> images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.category,
    required this.images,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  String get primaryImageUrl {
    if (images.isEmpty) return '';
    for (final img in images) {
      if (img.isPrimary) return img.url;
    }
    return images.first.url;
  }
}
