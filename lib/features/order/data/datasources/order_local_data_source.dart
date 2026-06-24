import 'package:isar/isar.dart';
import '../../../../core/storage/models/cart_cache.dart';
import '../../../../core/storage/models/order_cache.dart';

abstract class OrderLocalDataSource {
  Future<void> saveDraftCart(String userId, List<CartItemCache> items);
  Future<List<CartItemCache>> getDraftCart(String userId);
  Future<void> clearDraftCart(String userId);
  Future<void> cacheOrderHistory(String customerId, List<OrderCache> orders);
  Future<List<OrderCache>> getCachedOrderHistory(String customerId);
  Future<void> cacheOrderDetail(OrderCache order);
  Future<OrderCache?> getCachedOrderDetail(String orderId);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final Isar isar;

  OrderLocalDataSourceImpl({required this.isar});

  @override
  Future<void> saveDraftCart(String userId, List<CartItemCache> items) async {
    await isar.writeTxn(() async {
      // Find existing
      final existing = await isar.cartCaches
          .filter()
          .userIdEqualTo(userId)
          .findFirst();
      final cache = existing ?? CartCache();
      cache.userId = userId;
      cache.items = items;
      cache.updatedAt = DateTime.now();
      await isar.cartCaches.put(cache);
    });
  }

  @override
  Future<List<CartItemCache>> getDraftCart(String userId) async {
    final cache = await isar.cartCaches
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
    return cache?.items ?? [];
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
    List<OrderCache> orders,
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
      await isar.orderCaches.putAll(orders);
    });
  }

  @override
  Future<List<OrderCache>> getCachedOrderHistory(String customerId) async {
    return isar.orderCaches
        .filter()
        .customerIdEqualTo(customerId)
        .sortByCreatedAtDesc()
        .findAll();
  }

  @override
  Future<void> cacheOrderDetail(OrderCache order) async {
    await isar.writeTxn(() async {
      final existing = await isar.orderCaches
          .filter()
          .orderIdEqualTo(order.orderId)
          .findFirst();
      if (existing != null) {
        order.id = existing.id;
      }
      await isar.orderCaches.put(order);
    });
  }

  @override
  Future<OrderCache?> getCachedOrderDetail(String orderId) async {
    return isar.orderCaches.filter().orderIdEqualTo(orderId).findFirst();
  }
}
