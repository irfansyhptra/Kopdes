import '../../../product/domain/entities/product.dart';
import 'address.dart';
import 'invoice.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final Product? product;
  final String? umkmProductId;
  final dynamic umkmProduct;
  final int quantity;
  final double price;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    this.product,
    this.umkmProductId,
    this.umkmProduct,
    required this.quantity,
    required this.price,
  });

  String get name {
    if (product != null) return product!.name;
    if (umkmProduct != null) return umkmProduct['name'] as String;
    return '';
  }

  String get imageUrl {
    if (product != null) return product!.primaryImageUrl;
    if (umkmProduct != null &&
        umkmProduct['images'] != null &&
        (umkmProduct['images'] as List).isNotEmpty) {
      return umkmProduct['images'][0]['url'] as String;
    }
    return '';
  }
}

class Order {
  final String id;
  final String customerId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddressId;
  final Address? deliveryAddress;
  final List<OrderItem> items;
  final Invoice? invoice;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.customerId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddressId,
    this.deliveryAddress,
    required this.items,
    this.invoice,
    required this.createdAt,
    required this.updatedAt,
  });
}
