import 'package:isar/isar.dart';
import '../../../../core/storage/cache_records.dart';
import '../../../../core/storage/isar_service.dart';
import '../../../../core/storage/models/cart_cache.dart';
import '../../../../core/storage/models/order_cache.dart';

abstract class OrderLocalDataSource {
  Future<void> saveDraftCart(String userId, List<CachedCartItem> items);
  Future<List<CachedCartItem>> getDraftCart(String userId);
  Future<void> clearDraftCart(String userId);
  Future<void> cacheOrderHistory(String customerId, List<CachedOrder> orders);
  Future<List<CachedOrder>> getCachedOrderHistory(String customerId);
  Future<void> cacheOrderDetail(CachedOrder order);
  Future<CachedOrder?> getCachedOrderDetail(String orderId);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final Isar isar;

  OrderLocalDataSourceImpl({Isar? isar}) : isar = isar ?? IsarService.instance;

  @override
  Future<void> saveDraftCart(String userId, List<CachedCartItem> items) async {
    await isar.writeTxn(() async {
      // Find existing
      final existing = await isar.cartCaches
          .filter()
          .userIdEqualTo(userId)
          .findFirst();
      final cache = existing ?? CartCache();
      cache.userId = userId;
      cache.items = items.map(_cartToIsar).toList();
      cache.updatedAt = DateTime.now();
      await isar.cartCaches.put(cache);
    });
  }

  @override
  Future<List<CachedCartItem>> getDraftCart(String userId) async {
    final cache = await isar.cartCaches
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
    return cache?.items.map(_cartFromIsar).toList() ?? [];
  }

  @override
  Future<void> clearDraftCart(String userId) async {
    await isar.writeTxn(() async {
      final existing = await isar.cartCaches
          .filter()
          .userIdEqualTo(userId)
          .findFirst();
      if (existing != null) {
        await isar.cartCaches.delete(existing.id);
      }
    });
  }

  @override
  Future<void> cacheOrderHistory(
    String customerId,
    List<CachedOrder> orders,
  ) async {
    await isar.writeTxn(() async {
      // Remove old records for this customer
      final old = await isar.orderCaches
          .filter()
          .customerIdEqualTo(customerId)
          .findAll();
      for (var o in old) {
        await isar.orderCaches.delete(o.id);
      }
      // Insert new ones
      await isar.orderCaches.putAll(orders.map(_orderToIsar).toList());
    });
  }

  @override
  Future<List<CachedOrder>> getCachedOrderHistory(String customerId) async {
    final rows = await isar.orderCaches
        .filter()
        .customerIdEqualTo(customerId)
        .sortByCreatedAtDesc()
        .findAll();
    return rows.map(_orderFromIsar).toList();
  }

  @override
  Future<void> cacheOrderDetail(CachedOrder order) async {
    await isar.writeTxn(() async {
      final existing = await isar.orderCaches
          .filter()
          .orderIdEqualTo(order.orderId)
          .findFirst();
      final row = _orderToIsar(order);
      if (existing != null) row.id = existing.id;
      await isar.orderCaches.put(row);
    });
  }

  @override
  Future<CachedOrder?> getCachedOrderDetail(String orderId) async {
    final row = await isar.orderCaches
        .filter()
        .orderIdEqualTo(orderId)
        .findFirst();
    return row == null ? null : _orderFromIsar(row);
  }

  static CartItemCache _cartToIsar(CachedCartItem item) => CartItemCache()
    ..productId = item.productId
    ..umkmProductId = item.umkmProductId
    ..name = item.name
    ..price = item.price
    ..quantity = item.quantity
    ..imageUrl = item.imageUrl;

  static CachedCartItem _cartFromIsar(CartItemCache item) => CachedCartItem(
    productId: item.productId,
    umkmProductId: item.umkmProductId,
    name: item.name,
    price: item.price,
    quantity: item.quantity,
    imageUrl: item.imageUrl,
  );

  static OrderCache _orderToIsar(CachedOrder order) => OrderCache()
    ..orderId = order.orderId
    ..customerId = order.customerId
    ..totalAmount = order.totalAmount
    ..status = order.status
    ..paymentMethod = order.paymentMethod
    ..createdAt = order.createdAt
    ..items = order.items
        .map(
          (item) => OrderItemCache()
            ..productId = item.productId
            ..productName = item.productName
            ..quantity = item.quantity
            ..price = item.price,
        )
        .toList();

  static CachedOrder _orderFromIsar(OrderCache order) => CachedOrder(
    orderId: order.orderId,
    customerId: order.customerId,
    totalAmount: order.totalAmount,
    status: order.status,
    paymentMethod: order.paymentMethod,
    createdAt: order.createdAt,
    items: order.items
        .map(
          (item) => CachedOrderItem(
            productId: item.productId,
            productName: item.productName,
            quantity: item.quantity,
            price: item.price,
          ),
        )
        .toList(),
  );
}
