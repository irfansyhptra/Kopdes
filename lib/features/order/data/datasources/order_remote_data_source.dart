import 'package:dio/dio.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<CartModel> getCart();
  Future<CartModel> addToCart({
    String? productId,
    String? umkmProductId,
    required int quantity,
  });
  Future<CartModel> updateCartItem({
    String? productId,
    String? umkmProductId,
    required int quantity,
  });
  Future<CartModel> removeFromCart({String? productId, String? umkmProductId});
  Future<CartModel> clearCart();
  Future<OrderModel> checkoutCart({
    required String deliveryAddressId,
    required String paymentMethod,
    String fulfillment = 'DELIVERY',
    List<String>? cartItemIds,
  });
  Future<OrderModel> createDirectOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddressId,
    required String paymentMethod,
    String fulfillment = 'DELIVERY',
  });

  /// Satu halaman riwayat beserta metadata paginasinya.
  Future<({List<OrderModel> orders, int page, int totalPages, int total})>
  getOrderHistory({int page, int limit});
  Future<OrderModel> getOrderDetail(String orderId);
  Future<OrderModel> updateOrderStatus(String orderId, String status);

  /// Pembeli menyatakan barang sudah diterima (validasi ganda langkah 2).
  Future<void> confirmReceipt(String orderId);

  /// Pembeli MENGAJUKAN pembatalan; toko yang menyetujuinya.
  Future<void> requestCancellation(String orderId, String reason);
  Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio dio;

  OrderRemoteDataSourceImpl({required this.dio});

  @override
  Future<CartModel> getCart() async {
    final response = await dio.get('/cart');
    return CartModel.fromJson(response.data['cart'] as Map<String, dynamic>);
  }

  @override
  Future<CartModel> addToCart({
    String? productId,
    String? umkmProductId,
    required int quantity,
  }) async {
    final response = await dio.post(
      '/cart/add',
      data: {
        if (productId != null) 'productId': productId,
        if (umkmProductId != null) 'umkmProductId': umkmProductId,
        'quantity': quantity,
      },
    );
    return CartModel.fromJson(response.data['cart'] as Map<String, dynamic>);
  }

  @override
  Future<CartModel> updateCartItem({
    String? productId,
    String? umkmProductId,
    required int quantity,
  }) async {
    final response = await dio.put(
      '/cart/update',
      data: {
        if (productId != null) 'productId': productId,
        if (umkmProductId != null) 'umkmProductId': umkmProductId,
        'quantity': quantity,
      },
    );
    return CartModel.fromJson(response.data['cart'] as Map<String, dynamic>);
  }

  @override
  Future<CartModel> removeFromCart({
    String? productId,
    String? umkmProductId,
  }) async {
    final response = await dio.delete(
      '/cart/remove',
      queryParameters: {
        if (productId != null) 'productId': productId,
        if (umkmProductId != null) 'umkmProductId': umkmProductId,
      },
    );
    return CartModel.fromJson(response.data['cart'] as Map<String, dynamic>);
  }

  @override
  Future<CartModel> clearCart() async {
    final response = await dio.delete('/cart/clear');
    return CartModel.fromJson(response.data['cart'] as Map<String, dynamic>);
  }

  @override
  Future<OrderModel> checkoutCart({
    required String deliveryAddressId,
    required String paymentMethod,
    String fulfillment = 'DELIVERY',
    List<String>? cartItemIds,
  }) async {
    final response = await dio.post(
      '/orders/checkout',
      data: {
        'deliveryAddressId': deliveryAddressId,
        'paymentMethod': paymentMethod,
        'fulfillment': fulfillment,
        // Dihilangkan berarti seluruh keranjang, sesuai perilaku lama server.
        if (cartItemIds != null && cartItemIds.isNotEmpty)
          'cartItemIds': cartItemIds,
      },
    );
    return OrderModel.fromJson(response.data['order'] as Map<String, dynamic>);
  }

  @override
  Future<OrderModel> createDirectOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddressId,
    required String paymentMethod,
    String fulfillment = 'DELIVERY',
  }) async {
    final response = await dio.post(
      '/orders',
      data: {
        'items': items,
        'deliveryAddressId': deliveryAddressId,
        'paymentMethod': paymentMethod,
        'fulfillment': fulfillment,
      },
    );
    return OrderModel.fromJson(response.data['order'] as Map<String, dynamic>);
  }

  @override
  Future<({List<OrderModel> orders, int page, int totalPages, int total})>
  getOrderHistory({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      '/orders/history',
      queryParameters: {'page': page, 'limit': limit},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['orders'] as List? ?? [];
    final meta = data['meta'] as Map<String, dynamic>? ?? const {};
    return (
      orders: list
          .map((o) => OrderModel.fromJson(o as Map<String, dynamic>))
          .toList(),
      page: meta['page'] as int? ?? page,
      totalPages: meta['totalPages'] as int? ?? 1,
      total: meta['total'] as int? ?? list.length,
    );
  }

  @override
  Future<OrderModel> getOrderDetail(String orderId) async {
    final response = await dio.get('/orders/$orderId');
    return OrderModel.fromJson(response.data['order'] as Map<String, dynamic>);
  }

  @override
  Future<void> confirmReceipt(String orderId) =>
      dio.post('/orders/$orderId/confirm-receipt');

  @override
  Future<void> requestCancellation(String orderId, String reason) =>
      dio.post('/orders/$orderId/cancellation', data: {'reason': reason});

  @override
  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    final response = await dio.put(
      '/orders/$orderId/status',
      data: {'status': status},
    );
    return OrderModel.fromJson(response.data['order'] as Map<String, dynamic>);
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId) async {
    final response = await dio.get('/orders/$orderId/timeline');
    final list = response.data['timeline'] as List? ?? [];
    return list.cast<Map<String, dynamic>>();
  }
}
