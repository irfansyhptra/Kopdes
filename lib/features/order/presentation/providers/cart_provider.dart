import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart.dart';
import '../../domain/repositories/order_repository.dart';
import '../../data/datasources/order_remote_data_source.dart';
import '../../data/datasources/order_local_data_source.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../notification/domain/entities/notification_item.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(
    remoteDataSource: OrderRemoteDataSourceImpl(dio: ref.watch(dioProvider)),
    localDataSource: OrderLocalDataSourceImpl(),
  );
});

class CartNotifier extends StateNotifier<AsyncValue<Cart>> {
  final OrderRepository _repository;
  final Ref _ref;

  CartNotifier(this._repository, this._ref)
    : super(const AsyncValue.loading()) {
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

  /// Menambah barang ke keranjang.
  ///
  /// Notifikasinya dicatat di sini, bukan di tiap layar yang punya tombol
  /// "+": beranda, detail produk, etalase toko, dan carousel semuanya lewat
  /// metode ini, jadi satu tempat sudah cukup — dan tidak ada layar baru
  /// yang bisa lupa melakukannya.
  Future<bool> addToCart({
    String? productId,
    String? umkmProductId,
    required int quantity,
    String? productName,
  }) async {
    try {
      final cart = await _repository.addToCart(
        productId: productId,
        umkmProductId: umkmProductId,
        quantity: quantity,
      );
      state = AsyncValue.data(cart);

      final label = productName?.trim();
      unawaited(
        _ref
            .read(notificationsProvider.notifier)
            .add(
              type: NotificationType.cartAdded,
              title: 'Masuk Keranjang',
              description: label == null || label.isEmpty
                  ? '$quantity barang ditambahkan ke keranjang belanja Anda.'
                  : '$label (${quantity}x) ditambahkan ke keranjang belanja '
                        'Anda.',
            ),
      );
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

  /// Mengubah jumlah satu baris dengan pembaruan optimistis.
  ///
  /// Angka di layar berubah seketika, lalu permintaan dikirim. Bila gagal,
  /// keranjang dikembalikan persis ke keadaan sebelumnya — rollback itulah
  /// syarat yang membuat pembaruan optimistis aman dipakai di sini.
  ///
  /// Mengembalikan `null` bila berhasil, atau pesan kesalahan bila gagal.
  Future<String?> setItemQuantity(CartItem item, int quantity) async {
    final current = state.valueOrNull;
    if (current == null) return 'Keranjang belum siap';
    if (quantity < 1) return null;

    final previous = current;
    state = AsyncValue.data(
      current.copyWithItems([
        for (final row in current.items)
          row.id == item.id ? row.copyWithQuantity(quantity) : row,
      ]),
    );

    try {
      final cart = await _repository.updateCartItem(
        productId: item.productId,
        umkmProductId: item.umkmProductId,
        quantity: quantity,
      );
      state = AsyncValue.data(cart);
      return null;
    } catch (e) {
      state = AsyncValue.data(previous);
      return _failureMessage(e);
    }
  }

  /// Menghapus satu baris. Sengaja tidak optimistis: menghilangkan kartu lebih
  /// dulu lalu memunculkannya lagi ketika gagal jauh lebih membingungkan
  /// daripada menunggu sebentar.
  Future<String?> removeCartItem(CartItem item) async {
    try {
      final cart = await _repository.removeFromCart(
        productId: item.productId,
        umkmProductId: item.umkmProductId,
      );
      state = AsyncValue.data(cart);
      return null;
    } catch (e) {
      return _failureMessage(e);
    }
  }

  String _failureMessage(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('stock') || text.contains('stok')
        ? 'Stok tidak mencukupi'
        : 'Perubahan belum tersimpan';
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
  return CartNotifier(ref.watch(orderRepositoryProvider), ref);
});
