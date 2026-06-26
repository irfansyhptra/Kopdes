import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';

final sellerOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  return ref.watch(orderRepositoryProvider).getOrders();
});

final sellerOrderDetailProvider = FutureProvider.family<OrderModel, String>((ref, id) async {
  return ref.watch(orderRepositoryProvider).getOrderDetail(id);
});

class OrderController extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _repository;
  final Ref _ref;

  OrderController({
    required OrderRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> updateOrderStatus(String orderId, String status) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateOrderStatus(orderId, status);
      state = const AsyncValue.data(null);
      _ref.invalidate(sellerOrdersProvider);
      _ref.invalidate(sellerOrderDetailProvider(orderId));
      _ref.read(sellerDashboardControllerProvider.notifier).refresh();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderControllerProvider = StateNotifierProvider<OrderController, AsyncValue<void>>((ref) {
  return OrderController(
    repository: ref.watch(orderRepositoryProvider),
    ref: ref,
  );
});
