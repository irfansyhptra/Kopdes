import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/admin_service.dart';
import '../../data/admin_models.dart';

final adminServiceProvider = Provider<AdminService>(
  (ref) => AdminService(dio: ref.watch(dioProvider)),
);

// ── Mitra ──
// Filter status aktif untuk daftar mitra (null = semua).
final mitraStatusFilterProvider = StateProvider<String?>((ref) => null);

final mitraListProvider = FutureProvider<List<Mitra>>((ref) async {
  final status = ref.watch(mitraStatusFilterProvider);
  return ref.watch(adminServiceProvider).getMitra(status: status);
});

// ── Takedown produk UMKM ──
final umkmProductsProvider = FutureProvider<List<UmkmProductAdmin>>((
  ref,
) async {
  return ref.watch(adminServiceProvider).getUmkmProducts();
});

// ── Pesanan ──
final orderStatusFilterProvider = StateProvider<String?>((ref) => null);

/// Halaman daftar pesanan yang sedang dibuka. Kembali ke 1 setiap filter
/// berganti — halaman 4 dari filter lama tidak berarti apa-apa untuk filter
/// baru, dan sering kosong.
final orderPageProvider = StateProvider<int>((ref) {
  ref.watch(orderStatusFilterProvider);
  return 1;
});

typedef AdminOrderPage = ({
  List<AdminOrder> items,
  int page,
  int totalPages,
  int total,
});

final adminOrderPageProvider = FutureProvider<AdminOrderPage>((ref) async {
  final status = ref.watch(orderStatusFilterProvider);
  final page = ref.watch(orderPageProvider);
  return ref.watch(adminServiceProvider).getOrders(status: status, page: page);
});

/// Daftar pesanan halaman berjalan. Dipertahankan agar layar yang hanya butuh
/// barisnya tidak perlu ikut mengurus metadata paginasi.
final adminOrdersProvider = Provider<AsyncValue<List<AdminOrder>>>((ref) {
  return ref.watch(adminOrderPageProvider).whenData((p) => p.items);
});

// ── Kurir ──
final couriersProvider = FutureProvider<List<Courier>>((ref) async {
  return ref.watch(adminServiceProvider).getCouriers();
});

final deliveriesProvider = FutureProvider<List<AdminDelivery>>((ref) async {
  return ref.watch(adminServiceProvider).getDeliveries();
});

/// Notifier aksi mutatif bersama (loading overlay + error).
class AdminActionNotifier extends StateNotifier<AsyncValue<void>> {
  AdminActionNotifier(this._ref) : super(const AsyncData(null));
  final Ref _ref;

  Future<bool> _run(
    Future<void> Function(AdminService s) op, {
    List<ProviderOrFamily> invalidate = const [],
  }) async {
    state = const AsyncLoading();
    try {
      await op(_ref.read(adminServiceProvider));
      for (final p in invalidate) {
        _ref.invalidate(p);
      }
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> verifyMitra(String id, String status, {String? reason}) => _run(
    (s) => s.verifyMitra(id, status, reason: reason),
    invalidate: [mitraListProvider],
  );

  Future<bool> setProductActive(String id, bool isActive, {String? reason}) =>
      _run(
        (s) => s.setProductActive(id, isActive, reason: reason),
        invalidate: [umkmProductsProvider],
      );

  Future<bool> updateOrderStatus(String id, String status) => _run(
    (s) => s.updateOrderStatus(id, status),
    invalidate: [adminOrderPageProvider],
  );

  Future<bool> updateUmkmLocation(
    String id, {
    double? latitude,
    double? longitude,
    String? category,
  }) => _run(
    (s) => s.updateUmkmLocation(
      id,
      latitude: latitude,
      longitude: longitude,
      category: category,
    ),
    invalidate: [mitraListProvider],
  );

  Future<bool> assignCourier(String deliveryId, String courierId) => _run(
    (s) => s.assignCourier(deliveryId, courierId),
    invalidate: [deliveriesProvider, couriersProvider],
  );
}

final adminActionProvider =
    StateNotifierProvider<AdminActionNotifier, AsyncValue<void>>(
      (ref) => AdminActionNotifier(ref),
    );
