import '../../domain/entities/cart.dart';
import '../../domain/entities/order.dart';
import '../../../product/domain/entities/product.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';
import '../datasources/order_local_data_source.dart';
import '../../../../core/storage/models/cart_cache.dart';
import '../../../../core/storage/models/order_cache.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final OrderLocalDataSource localDataSource;

  // Let's use a dummy customer ID since we can extract it if needed, or get from session
  final String _currentUserId = 'current-user-id';

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Cart> getCart() async {
    try {
      final cartModel = await remoteDataSource.getCart();
      // Cache locally
      final cacheItems = cartModel.items.map((item) {
        return CartItemCache()
          ..productId = item.productId
          ..umkmProductId = item.umkmProductId
          ..name = item.name
          ..price = item.price
          ..quantity = item.quantity
          ..imageUrl = item.imageUrl;
      }).toList();
      await localDataSource.saveDraftCart(_currentUserId, cacheItems);
      return cartModel.toEntity();
    } catch (e) {
      // Fallback to local cache
      final cachedItems = await localDataSource.getDraftCart(_currentUserId);
      final items = cachedItems.map((c) {
        return CartItem(
          id: c.productId ?? c.umkmProductId ?? '',
          cartId: '',
          productId: c.productId,
          umkmProductId: c.umkmProductId,
          quantity: c.quantity,
          product: c.productId != null
              ? Product(
                  id: c.productId!,
                  name: c.name,
                  description: '',
                  price: c.price,
                  stock: 99,
                  categoryId: '',
                  images: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                )
              : null,
          umkmProduct: c.umkmProductId != null
              ? {
                  'name': c.name,
                  'price': c.price,
                  'images': [
                    {'url': c.imageUrl ?? ''},
                  ],
                }
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
      return Cart(
        id: '',
        userId: _currentUserId,
        items: items,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<Cart> addToCart({
    String? productId,
    String? umkmProductId,
    required int quantity,
  }) async {
    // Write directly through remote
    final cartModel = await remoteDataSource.addToCart(
      productId: productId,
      umkmProductId: umkmProductId,
      quantity: quantity,
    );
    // Update local cache
    final cacheItems = cartModel.items.map((item) {
      return CartItemCache()
        ..productId = item.productId
        ..umkmProductId = item.umkmProductId
        ..name = item.name
        ..price = item.price
        ..quantity = item.quantity
        ..imageUrl = item.imageUrl;
    }).toList();
    await localDataSource.saveDraftCart(_currentUserId, cacheItems);
    return cartModel.toEntity();
  }

  @override
  Future<Cart> updateCartItem({
    String? productId,
    String? umkmProductId,
    required int quantity,
  }) async {
    final cartModel = await remoteDataSource.updateCartItem(
      productId: productId,
      umkmProductId: umkmProductId,
      quantity: quantity,
    );
    final cacheItems = cartModel.items.map((item) {
      return CartItemCache()
        ..productId = item.productId
        ..umkmProductId = item.umkmProductId
        ..name = item.name
        ..price = item.price
        ..quantity = item.quantity
        ..imageUrl = item.imageUrl;
    }).toList();
    await localDataSource.saveDraftCart(_currentUserId, cacheItems);
    return cartModel.toEntity();
  }

  @override
  Future<Cart> removeFromCart({
    String? productId,
    String? umkmProductId,
  }) async {
    final cartModel = await remoteDataSource.removeFromCart(
      productId: productId,
      umkmProductId: umkmProductId,
    );
    final cacheItems = cartModel.items.map((item) {
      return CartItemCache()
        ..productId = item.productId
        ..umkmProductId = item.umkmProductId
        ..name = item.name
        ..price = item.price
        ..quantity = item.quantity
        ..imageUrl = item.imageUrl;
    }).toList();
    await localDataSource.saveDraftCart(_currentUserId, cacheItems);
    return cartModel.toEntity();
  }

  @override
  Future<Cart> clearCart() async {
    final cartModel = await remoteDataSource.clearCart();
    await localDataSource.clearDraftCart(_currentUserId);
    return cartModel.toEntity();
  }

  @override
  Future<Order> checkoutCart({
    required String deliveryAddressId,
    required String paymentMethod,
  }) async {
    final orderModel = await remoteDataSource.checkoutCart(
      deliveryAddressId: deliveryAddressId,
      paymentMethod: paymentMethod,
    );
    // Clear local draft cart
    await localDataSource.clearDraftCart(_currentUserId);
    // Cache order details
    final orderCache = _mapToOrderCache(orderModel);
    await localDataSource.cacheOrderDetail(orderCache);
    return orderModel.toEntity();
  }

  @override
  Future<Order> createDirectOrder({
    required List<Map<String, dynamic>> items,
    required String deliveryAddressId,
    required String paymentMethod,
  }) async {
    final orderModel = await remoteDataSource.createDirectOrder(
      items: items,
      deliveryAddressId: deliveryAddressId,
      paymentMethod: paymentMethod,
    );
    // Cache order details
    final orderCache = _mapToOrderCache(orderModel);
    await localDataSource.cacheOrderDetail(orderCache);
    return orderModel.toEntity();
  }

  @override
  Future<List<Order>> getOrderHistory() async {
    try {
      final orders = await remoteDataSource.getOrderHistory();
      final cacheOrders = orders.map((o) => _mapToOrderCache(o)).toList();
      await localDataSource.cacheOrderHistory(_currentUserId, cacheOrders);
      return orders.map((o) => o.toEntity()).toList();
    } catch (e) {
      // Fallback
      final cached = await localDataSource.getCachedOrderHistory(
        _currentUserId,
      );
      return cached.map((c) => _mapFromOrderCache(c)).toList();
    }
  }

  @override
  Future<Order> getOrderDetail(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderDetail(orderId);
      final cacheOrder = _mapToOrderCache(order);
      await localDataSource.cacheOrderDetail(cacheOrder);
      return order.toEntity();
    } catch (e) {
      final cached = await localDataSource.getCachedOrderDetail(orderId);
      if (cached != null) {
        return _mapFromOrderCache(cached);
      }
      rethrow;
    }
  }

  @override
  Future<Order> updateOrderStatus(String orderId, String status) async {
    final order = await remoteDataSource.updateOrderStatus(orderId, status);
    final cacheOrder = _mapToOrderCache(order);
    await localDataSource.cacheOrderDetail(cacheOrder);
    return order.toEntity();
  }

  @override
  Future<List<Map<String, dynamic>>> getOrderTimeline(String orderId) async {
    try {
      return await remoteDataSource.getOrderTimeline(orderId);
    } catch (e) {
      // Return simple offline status if no internet
      final cached = await localDataSource.getCachedOrderDetail(orderId);
      if (cached != null) {
        return [
          {
            'action': 'ORDER_STATUS_UPDATED',
            'details': 'Status offline: ${cached.status}',
            'createdAt': DateTime.now().toIso8601String(),
          },
        ];
      }
      return [];
    }
  }

  OrderCache _mapToOrderCache(OrderModel o) {
    final items = o.items.map((i) {
      return OrderItemCache()
        ..productId = i.productId ?? i.umkmProductId ?? ''
        ..productName = i.name
        ..quantity = i.quantity
        ..price = i.price;
    }).toList();

    return OrderCache()
      ..orderId = o.id
      ..customerId = o.customerId
      ..totalAmount = o.totalAmount
      ..status = o.status
      ..paymentMethod = o.paymentMethod
      ..createdAt = o.createdAt
      ..items = items;
  }

  Order _mapFromOrderCache(OrderCache c) {
    final items = c.items.map((i) {
      return OrderItem(
        id: '',
        orderId: c.orderId,
        productId: i.productId,
        product: Product(
          id: i.productId,
          name: i.productName,
          description: '',
          price: i.price,
          stock: 99,
          categoryId: '',
          images: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        quantity: i.quantity,
        price: i.price,
      );
    }).toList();

    return Order(
      id: c.orderId,
      customerId: c.customerId,
      totalAmount: c.totalAmount,
      status: c.status,
      paymentMethod: c.paymentMethod,
      paymentStatus: '',
      deliveryAddressId: '',
      items: items,
      createdAt: c.createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
