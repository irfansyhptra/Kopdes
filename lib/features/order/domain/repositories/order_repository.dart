import '../../domain/entities/cart.dart';
import '../../domain/entities/order.dart';

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
  });
  Future<Order> createDirectOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddressId,
    required String paymentMethod,
  });
  Future<List<Order>> getOrderHistory();
  Future<Order> getOrderDetail(String orderId);
  Future<Order> updateOrderStatus(String orderId, String status);
  Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId);
}
