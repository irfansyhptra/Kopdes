import '../../domain/entities/order.dart';
import '../../../product/data/models/product_model.dart';
import 'address_model.dart';
import 'invoice_model.dart';

class OrderItemModel extends OrderItem {
  const OrderItemModel({
    required super.id,
    required super.orderId,
    super.productId,
    super.product,
    super.umkmProductId,
    super.umkmProduct,
    required super.quantity,
    required super.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      productId: json['productId'] as String?,
      product: json['product'] != null
          ? ProductModel.fromJson(
              json['product'] as Map<String, dynamic>,
            ).toEntity()
          : null,
      umkmProductId: json['umkmProductId'] as String?,
      umkmProduct: json['umkmProduct'],
      quantity: json['quantity'] as int? ?? 1,
      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'umkmProductId': umkmProductId,
      'quantity': quantity,
      'price': price,
    };
  }

  OrderItem toEntity() {
    return OrderItem(
      id: id,
      orderId: orderId,
      productId: productId,
      product: product,
      umkmProductId: umkmProductId,
      umkmProduct: umkmProduct,
      quantity: quantity,
      price: price,
    );
  }
}

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.customerId,
    required super.totalAmount,
    required super.status,
    required super.paymentMethod,
    required super.paymentStatus,
    required super.deliveryAddressId,
    super.deliveryAddress,
    required List<OrderItemModel> super.items,
    super.invoice,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItemModel> parsedItems = itemsList
        .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      totalAmount: json['totalAmount'] is num
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String? ?? 'QRIS',
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      deliveryAddressId: json['deliveryAddressId'] as String? ?? '',
      deliveryAddress: json['deliveryAddress'] != null
          ? AddressModel.fromJson(
              json['deliveryAddress'] as Map<String, dynamic>,
            ).toEntity()
          : null,
      items: parsedItems,
      invoice: json['invoice'] != null
          ? InvoiceModel.fromJson(
              json['invoice'] as Map<String, dynamic>,
            ).toEntity()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'totalAmount': totalAmount,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'deliveryAddressId': deliveryAddressId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Order toEntity() {
    return Order(
      id: id,
      customerId: customerId,
      totalAmount: totalAmount,
      status: status,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      deliveryAddressId: deliveryAddressId,
      deliveryAddress: deliveryAddress,
      items: items,
      invoice: invoice,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
