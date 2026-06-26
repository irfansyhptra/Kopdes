class InventoryModel {
  final String productId;
  final String productName;
  final int stock;
  final String categoryName;

  const InventoryModel({
    required this.productId,
    required this.productName,
    required this.stock,
    required this.categoryName,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    return InventoryModel(
      productId: json['id'] as String,
      productName: json['name'] as String,
      stock: json['stock'] as int? ?? 0,
      categoryName: json['category'] != null ? json['category']['name'] as String : '',
    );
  }
}
