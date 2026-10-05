import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated.dart';
import 'courier_models.dart';

/// Klien HTTP aplikasi kurir. Semua jalur terikat pada kurir yang masuk,
/// jadi tidak ada parameter id kurir di mana pun.
class CourierService {
  final Dio dio;
  CourierService(this.dio);

  dynamic _data(Response res) => (res.data as Map<String, dynamic>)['data'];

  List<CourierTask> _tasks(Object? data) => ((data as List?) ?? const [])
      .cast<Map<String, dynamic>>()
      .map(CourierTask.fromJson)
      .toList();

  Future<CourierSummary> summary() async => CourierSummary.fromJson(
    _data(await dio.get('/courier/summary')) as Map<String, dynamic>,
  );

  Future<List<CourierTask>> available() async =>
      _tasks(_data(await dio.get('/courier/deliveries/available')));

  Future<List<CourierTask>> myTasks() async =>
      _tasks(_data(await dio.get('/courier/deliveries')));

  Future<CourierTask> detail(String id) async => CourierTask.fromJson(
    _data(await dio.get('/courier/deliveries/$id')) as Map<String, dynamic>,
  );

  Future<Paginated<CourierTask>> history({int page = 1}) async {
    final res = await dio.get(
      '/courier/deliveries/history',
      queryParameters: {'page': page, 'limit': 20},
    );
    return Paginated.fromJson(
      _data(res) as Map<String, dynamic>,
      'deliveries',
      CourierTask.fromJson,
    );
  }

  Future<CourierTask> claim(String id) async => CourierTask.fromJson(
    _data(await dio.post('/courier/deliveries/$id/claim'))
        as Map<String, dynamic>,
  );

  Future<CourierTask> accept(String id) async => CourierTask.fromJson(
    _data(await dio.patch('/courier/deliveries/$id/accept'))
        as Map<String, dynamic>,
  );

  Future<void> release(String id, {String? reason}) => dio.patch(
    '/courier/deliveries/$id/release',
    data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
  );

  Future<CourierTask> pickUp(String id) async => CourierTask.fromJson(
    _data(await dio.patch('/courier/deliveries/$id/pick-up'))
        as Map<String, dynamic>,
  );

  /// Koordinat ikut dikirim bila ada — sisi kurir dari dual-validation.
  Future<void> markDelivered(
    String id, {
    double? lat,
    double? lng,
  }) => dio.patch(
    '/courier/deliveries/$id/mark-delivered',
    data: {
      if (lat != null && lng != null) ...{'latitude': lat, 'longitude': lng},
    },
  );

  Future<void> pushLocation(String id, double lat, double lng) => dio.post(
    '/courier/deliveries/$id/location',
    data: {'latitude': lat, 'longitude': lng},
  );
}

final courierServiceProvider = Provider<CourierService>(
  (ref) => CourierService(ref.watch(dioProvider)),
);

/// Angka dasbor. Tidak di-cache di Isar: kurir memakainya untuk memutuskan
/// berangkat atau tidak, dan angka setengah jam lalu menyesatkan.
final courierSummaryProvider = FutureProvider.autoDispose<CourierSummary>(
  (ref) => ref.watch(courierServiceProvider).summary(),
);

final availableTasksProvider = FutureProvider.autoDispose<List<CourierTask>>(
  (ref) => ref.watch(courierServiceProvider).available(),
);

final myTasksProvider = FutureProvider.autoDispose<List<CourierTask>>(
  (ref) => ref.watch(courierServiceProvider).myTasks(),
);

final courierTaskProvider = FutureProvider.autoDispose
    .family<CourierTask, String>(
      (ref, id) => ref.watch(courierServiceProvider).detail(id),
    );

/// Memuat ulang semua daftar sekaligus. Dipanggil setelah setiap tindakan:
/// satu tugas yang diambil mengubah daftar tersedia, daftar tugas saya, dan
/// angka dasbor sekaligus.
void refreshCourier(WidgetRef ref) {
  ref.invalidate(courierSummaryProvider);
  ref.invalidate(availableTasksProvider);
  ref.invalidate(myTasksProvider);
}

/// Log pengiriman, bertahap per halaman.
class CourierHistoryNotifier
    extends StateNotifier<AsyncValue<Paginated<CourierTask>>> {
  final CourierService _service;
  bool _loadingMore = false;

  CourierHistoryNotifier(this._service) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = await AsyncValue.guard(() => _service.history());
  }

  /// Penjaga `_loadingMore` mencegah gulir cepat memicu permintaan ganda
  /// untuk halaman yang sama.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await _service.history(page: current.page + 1);
      state = AsyncData(
        Paginated(
          items: [...current.items, ...next.items],
          page: next.page,
          totalPages: next.totalPages,
          total: next.total,
        ),
      );
    } catch (_) {
      // Halaman berikutnya gagal: yang sudah tampil dibiarkan, pengguna
      // bisa menggulir lagi untuk mencoba ulang.
    } finally {
      _loadingMore = false;
    }
  }
}

final courierHistoryProvider =
    StateNotifierProvider.autoDispose<
      CourierHistoryNotifier,
      AsyncValue<Paginated<CourierTask>>
    >((ref) => CourierHistoryNotifier(ref.watch(courierServiceProvider)));
