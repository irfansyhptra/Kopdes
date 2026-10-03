import '../../../../core/network/paginated.dart';
import '../entities/cart.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<Cart> getCart();
  Future<Cart> addToCart({
    String? productId,
    String? umkmProductId,
    required int quantity,
  });
  Future<Cart> updateCartItem({
    String? productId,
    String? umkmProductId,
    required int quantity,
  });
  Future<Cart> removeFromCart({String? productId, String? umkmProductId});
  Future<Cart> clearCart();
  Future<Order> checkoutCart({
    required String deliveryAddressId,
    required String paymentMethod,
    List<String>? cartItemIds,
  });
  Future<Order> createDirectOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddressId,
    required String paymentMethod,
  });

  /// Satu halaman riwayat pesanan. Halaman pertama juga disimpan ke cache
  /// lokal sebagai bekal saat jaringan mati.
  Future<Paginated<Order>> getOrderHistory({int page, int limit});
  Future<Order> getOrderDetail(String orderId);
  Future<Order> updateOrderStatus(String orderId, String status);
  Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId);
}
