import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/datasources/order_local_data_source.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/isar_service.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    remoteDataSource: OrderRemoteDataSourceImpl(dio: ref.watch(dioProvider)),
    localDataSource: OrderLocalDataSourceImpl(isar: ref.watch(isarProvider)),
  );
});

class CartNotifier extends StateNotifier<AsyncValue<Cart>> {
  final OrderRepository _repository;

  CartNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    try {
      state = const AsyncValue.loading();
      final cart = await _repository.getCart();
      state = AsyncValue.data(cart);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addToCart({
    String? productId,
    String? umkmProductId,
    required int quantity,
  }) async {
    try {
      final cart = await _repository.addToCart(
        productId: productId,
        umkmProductId: umkmProductId,
        quantity: quantity,
      );
      state = AsyncValue.data(cart);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateQuantity({
    String? productId,
    String? umkmProductId,
    required int quantity,
  }) async {
    try {
      final cart = await _repository.updateCartItem(
        productId: productId,
        umkmProductId: umkmProductId,
        quantity: quantity,
      );
      state = AsyncValue.data(cart);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeItem({String? productId, String? umkmProductId}) async {
    try {
      final cart = await _repository.removeFromCart(
        productId: productId,
        umkmProductId: umkmProductId,
      );
      state = AsyncValue.data(cart);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearCart() async {
    try {
      final cart = await _repository.clearCart();
      state = AsyncValue.data(cart);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<Cart>>((
  ref,
) {
  return CartNotifier(ref.watch(orderRepositoryProvider));
});
