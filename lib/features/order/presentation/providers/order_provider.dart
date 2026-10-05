import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/cancellation_repository.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import 'cart_provider.dart';
import '../../../product/domain/entities/product.dart';

class OrderActionNotifier extends StateNotifier<AsyncValue<Order?>> {
  final Ref _ref;

  OrderActionNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<Order?> checkout({
    required String deliveryAddressId,
    required String paymentMethod,
    String fulfillment = 'DELIVERY',
    List<String>? cartItemIds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(orderRepositoryProvider);
      final order = await repo.checkoutCart(
        deliveryAddressId: deliveryAddressId,
        paymentMethod: paymentMethod,
        fulfillment: fulfillment,
        cartItemIds: cartItemIds,
      );
      state = AsyncValue.data(order);
      // Invalidate cart state since it has been cleared on backend
      _ref.invalidate(cartProvider);
      _ref.read(orderHistoryProvider.notifier).load();
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
    String fulfillment = 'DELIVERY',
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(orderRepositoryProvider);
      final order = await repo.createDirectOrder(
        items: items,
        deliveryAddressId: deliveryAddressId,
        paymentMethod: paymentMethod,
        fulfillment: fulfillment,
      );
      state = AsyncValue.data(order);
      _ref.read(orderHistoryProvider.notifier).load();
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
      _ref.read(orderHistoryProvider.notifier).load();
      _ref.invalidate(orderTimelineProvider(orderId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Mengajukan pembatalan. Pesanannya BELUM batal — toko yang memutuskan.
  Future<bool> requestCancellation(String orderId, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _ref
          .read(orderRepositoryProvider)
          .requestCancellation(orderId, reason);
      state = const AsyncValue.data(null);
      _ref.invalidate(orderDetailProvider(orderId));
      _ref.read(orderHistoryProvider.notifier).load();
      _ref.invalidate(cancellationsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// "Konfirmasi Diterima": lewat `POST /orders/:id/confirm-receipt`.
  ///
  /// Bukan `updateStatus(…, 'COMPLETED')` seperti sebelumnya — endpoint
  /// status hanya menerima pembatalan dari pembeli, jadi konfirmasi itu
  /// selalu ditolak 403 dan pesanan tidak pernah selesai.
  Future<bool> confirmReceipt(String orderId) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(orderRepositoryProvider).confirmReceipt(orderId);
      state = const AsyncValue.data(null);
      _ref.invalidate(orderDetailProvider(orderId));
      _ref.read(orderHistoryProvider.notifier).load();
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

/// Satu halaman riwayat yang sudah terkumpul, beserti penanda muat-lebih.
class OrderHistoryState {
  final List<Order> orders;
  final bool hasMore;
  final bool isLoadingMore;

  /// Kegagalan memuat halaman berikutnya. Pesanan yang sudah tampil tetap
  /// di layar dan pengguna diberi tombol coba lagi, bukan daftar kosong.
  final bool loadMoreFailed;
  final int total;

  const OrderHistoryState({
    this.orders = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.total = 0,
  });

  OrderHistoryState copyWith({
    List<Order>? orders,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    int? total,
  }) => OrderHistoryState(
    orders: orders ?? this.orders,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    total: total ?? this.total,
  );
}

/// Riwayat pesanan berhalaman.
///
/// Sebelumnya seluruh riwayat ditarik sekali jalan; pada akun yang sudah lama
/// berbelanja itu berarti satu respons yang terus tumbuh, padahal tab Selesai
/// hanya menampilkan beberapa kartu pertama.
class OrderHistoryNotifier
    extends StateNotifier<AsyncValue<OrderHistoryState>> {
  OrderHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final OrderRepository _repository;

  /// Sepuluh pesanan per halaman — cukup mengisi satu layar penuh sekaligus
  /// menyisakan ruang gulir sebelum permintaan berikutnya dipicu.
  static const int pageSize = 10;

  int _page = 1;

  Future<void> load() async {
    _page = 1;
    try {
      final result = await _repository.getOrderHistory(limit: pageSize);
      if (!mounted) return;
      state = AsyncValue.data(
        OrderHistoryState(
          orders: result.items,
          hasMore: result.hasMore,
          total: result.total,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    // Penjaga ganda: gulir cepat tidak boleh meminta halaman yang sama dua kali.
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await _repository.getOrderHistory(
        page: _page + 1,
        limit: pageSize,
      );
      _page += 1;
      if (!mounted) return;
      state = AsyncValue.data(
        OrderHistoryState(
          orders: [...current.orders, ...next.items],
          hasMore: next.hasMore,
          total: next.total,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

final orderHistoryProvider =
    StateNotifierProvider<OrderHistoryNotifier, AsyncValue<OrderHistoryState>>(
      (ref) => OrderHistoryNotifier(ref.watch(orderRepositoryProvider)),
    );

/// Daftar pesanan yang sudah terkumpul — dipakai layar yang hanya butuh
/// barisnya tanpa ikut mengurus paginasi.
final orderHistoryListProvider = Provider<AsyncValue<List<Order>>>((ref) {
  return ref.watch(orderHistoryProvider).whenData((s) => s.orders);
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

final directCheckoutProvider = StateProvider<DirectCheckoutData?>(
  (ref) => null,
);
