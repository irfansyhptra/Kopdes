import 'package:isar/isar.dart';

part 'order_cache.g.dart';

@collection
class OrderCache {
  Id id = Isar.autoIncrement;

  @Index()
  late String orderId;
  late String customerId;
  late double totalAmount;
  late String status;
  late String paymentMethod;
  late DateTime createdAt;
  late List<OrderItemCache> items;
}

@embedded
class OrderItemCache {
  late String productId;
  late String productName;
  late int quantity;
  late double price;
}
