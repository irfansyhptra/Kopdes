import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/order.dart';
import 'cart_provider.dart';
import '../../../product/domain/entities/product.dart';

class OrderActionNotifier extends StateNotifier<AsyncValue<Order?>> {
  final Ref _ref;

  OrderActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<Order?> checkout({
    required String deliveryAddressId,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(orderRepositoryProvider);
      final order = await repo.checkoutCart(
        deliveryAddressId: deliveryAddressId,
        paymentMethod: paymentMethod,
      );
      state = AsyncValue.data(order);
      // Invalidate cart state since it has been cleared on backend
      _ref.invalidate(cartProvider);
      _ref.invalidate(orderHistoryProvider);
      return order;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Order?> createDirect({
    required List<Map<String, dynamic>> items,
    required String deliveryAddressId,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(orderRepositoryProvider);
      final order = await repo.createDirectOrder(
        items: items,
        deliveryAddressId: deliveryAddressId,
        paymentMethod: paymentMethod,
      );
      state = AsyncValue.data(order);
      _ref.invalidate(orderHistoryProvider);
      return order;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateStatus(String orderId, String status) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(orderRepositoryProvider);
      await repo.updateOrderStatus(orderId, status);
      state = const AsyncValue.data(null);
      // Invalidate specific order detail, history, and timeline caches
      _ref.invalidate(orderDetailProvider(orderId));
      _ref.invalidate(orderHistoryProvider);
      _ref.invalidate(orderTimelineProvider(orderId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderActionProvider =
    StateNotifierProvider<OrderActionNotifier, AsyncValue<Order?>>((ref) {
      return OrderActionNotifier(ref);
    });

final orderHistoryProvider = FutureProvider<List<Order>>((ref) async {
  return ref.watch(orderRepositoryProvider).getOrderHistory();
});

final orderDetailProvider = FutureProvider.family<Order, String>((
  ref,
  id,
) async {
  return ref.watch(orderRepositoryProvider).getOrderDetail(id);
});

final orderTimelineProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
      return ref.watch(orderRepositoryProvider).getOrderTimeline(id);
    });

class DirectCheckoutData {
  final Product product;
  final int quantity;
  final String variant;
  final String deliveryMethod;
  final String paymentMethod;
  final double price;

  const DirectCheckoutData({
    required this.product,
    required this.quantity,
    required this.variant,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.price,
  });
}

final directCheckoutProvider = StateProvider<DirectCheckoutData?>((ref) => null);

