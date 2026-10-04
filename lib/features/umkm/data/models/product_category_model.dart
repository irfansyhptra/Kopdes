class ProductCategoryModel {
  final String id;
  final String name;
  final String? description;

  /// Jumlah produk toko di kategori ini — hanya dari
  /// `GET /seller/products/categories`.
  final int? productCount;

  const ProductCategoryModel({
    required this.id,
    required this.name,
    this.description,
    this.productCount,
  });

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      productCount: (json['productCount'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description};
  }
}
