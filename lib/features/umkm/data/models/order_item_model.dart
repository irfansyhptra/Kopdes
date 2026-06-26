import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String? productId;
  final String? umkmProductId;
  final ProductModel? umkmProduct;
  final int quantity;
  final double price;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    this.productId,
    this.umkmProductId,
    this.umkmProduct,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      productId: json['productId'] as String?,
      umkmProductId: json['umkmProductId'] as String?,
      umkmProduct: json['umkmProduct'] != null
          ? ProductModel.fromJson(json['umkmProduct'] as Map<String, dynamic>)
          : null,
      quantity: json['quantity'] as int? ?? 0,
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }
}
