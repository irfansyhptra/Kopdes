import 'package:dio/dio.dart';

import '../../../core/network/paginated.dart';
import '../../../core/storage/api_cache.dart';
import '../domain/employee_dashboard.dart';

/// Klien HTTP dashboard pegawai.
///
/// Mengembalikan JSON mentah, bukan model: cache menyimpan payload apa adanya
/// sehingga data dari jaringan dan dari cache melewati `fromJson` yang sama.
/// Kalau data source men-decode lebih dulu, cache butuh jalur pemetaannya
/// sendiri — dan jalur kedua itulah yang diam-diam kehilangan field.
class EmployeeRemoteDataSource {
  final Dio dio;

  const EmployeeRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, dynamic>? query,
  ]) async {
    final res = await dio.get<dynamic>(path, queryParameters: query);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> summary() => _get('/admin/dashboard/summary');

  Future<Map<String, dynamic>> todayOrders({int limit = 3}) =>
      _get('/admin/dashboard/today-orders', {'limit': limit});

  Future<Map<String, dynamic>> stockSummary() =>
      _get('/admin/dashboard/stock-summary');

  Future<Map<String, dynamic>> finance(String period) =>
      _get('/admin/dashboard/finance', {'period': period});

  Future<Map<String, dynamic>> storeStatus() =>
      _get('/admin/dashboard/store-status');

  Future<Map<String, dynamic>> stockList({
    required String filter,
    int page = 1,
    int limit = 20,
  }) async {
    final json = await _get('/admin/inventory/products', {
      'filter': filter,
      'page': page,
      'limit': limit,
    });
    return {'items': json['items'] ?? const [], 'meta': json['meta'] ?? {}};
  }

  Future<Map<String, dynamic>> stockHistory({
    int page = 1,
    int limit = 20,
  }) async {
    final json = await _get('/admin/inventory/transactions', {
      'page': page,
      'limit': limit,
    });
    // Endpoint riwayat memakai bentuk datar (items/total/page/limit);
    // dibungkus di sini supaya sisi Flutter hanya mengenal satu bentuk meta.
    final total = json['total'] as int? ?? 0;
    final size = json['limit'] as int? ?? limit;
    return {
      'items': json['items'] ?? const [],
      'meta': {
        'total': total,
        'page': json['page'] ?? page,
        'limit': size,
        'totalPages': size == 0
            ? 1
            : ((total + size - 1) ~/ size).clamp(1, 1 << 30),
      },
    };
  }

  Future<void> updateOrderStatus(String orderId, String status) =>
      dio.patch('/admin/orders/$orderId/status', data: {'status': status});

  Future<void> adjustStock({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
  }) => dio.post(
    '/admin/inventory/adjust',
    data: {
      'productId': productId,
      'type': type,
      'quantity': quantity,
      'reason': reason,
    },
  );

  Future<void> stockOpname({
    required String productId,
    required int countedStock,
    String? note,
  }) => dio.post(
    '/admin/inventory/opname',
    data: {
      'productId': productId,
      'countedStock': countedStock,
      if (note != null && note.isNotEmpty) 'note': note,
    },
  );
}

/// Repository dashboard pegawai.
///
/// Setiap bacaan dibungkus [cachedFetch]: cache segar tampil tanpa jaringan,
/// cache basi tampil seketika lalu disegarkan di latar belakang. Angka
/// operasional bergerak cepat, jadi seluruhnya memakai TTL pendek — kecuali
/// identitas toko yang praktis tidak berubah sepanjang hari.
class EmployeeRepository {
  final EmployeeRemoteDataSource remote;
  final ApiCache cache;

  const EmployeeRepository({required this.remote, required this.cache});

  Future<DashboardSummary> summary({bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: CacheKeys.employeeSummary,
      ttl: CacheTtl.veryShort,
      forceRefresh: forceRefresh,
      fetch: remote.summary,
      decode: (json) => DashboardSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<List<TodayOrder>> todayOrders({
    int limit = 3,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.employeeTodayOrdersPrefix}$limit',
      ttl: CacheTtl.veryShort,
      forceRefresh: forceRefresh,
      fetch: () => remote.todayOrders(limit: limit),
      decode: (json) => TodayOrder.listFrom(json as Map<String, dynamic>),
    );
  }

  Future<StockSummary> stockSummary({bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: CacheKeys.employeeStockSummary,
      ttl: CacheTtl.veryShort,
      forceRefresh: forceRefresh,
      fetch: remote.stockSummary,
      decode: (json) => StockSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<FinanceSummary> finance(String period, {bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.employeeFinancePrefix}$period',
      ttl: CacheTtl.veryShort,
      forceRefresh: forceRefresh,
      fetch: () => remote.finance(period),
      decode: (json) => FinanceSummary.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<StoreStatus?> storeStatus({bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: CacheKeys.employeeStoreStatus,
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: remote.storeStatus,
      decode: (json) => StoreStatus.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Paginated<StockItem>> stockList({
    required String filter,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.employeeStockListPrefix}$filter:p$page:l$limit',
      ttl: CacheTtl.veryShort,
      forceRefresh: forceRefresh,
      fetch: () => remote.stockList(filter: filter, page: page, limit: limit),
      decode: (json) => Paginated.fromJson(json, 'items', StockItem.fromJson),
    );
  }

  Future<Paginated<StockMovement>> stockHistory({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.employeeStockHistoryPrefix}p$page:l$limit',
      ttl: CacheTtl.veryShort,
      forceRefresh: forceRefresh,
      fetch: () => remote.stockHistory(page: page, limit: limit),
      decode: (json) =>
          Paginated.fromJson(json, 'items', StockMovement.fromJson),
    );
  }

  // ── Tulis ────────────────────────────────────────────────────────────────
  /// Setiap tulis membatalkan bacaan yang terdampak; tanpa itu pegawai
  /// menekan "Proses" lalu melihat pesanan yang sama tetap berstatus Baru
  /// selama TTL masih berjalan.
  Future<void> updateOrderStatus(String orderId, String status) async {
    await remote.updateOrderStatus(orderId, status);
    await _invalidateOperational();
  }

  Future<void> adjustStock({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
  }) async {
    await remote.adjustStock(
      productId: productId,
      type: type,
      quantity: quantity,
      reason: reason,
    );
    await _invalidateStock();
  }

  Future<void> stockOpname({
    required String productId,
    required int countedStock,
    String? note,
  }) async {
    await remote.stockOpname(
      productId: productId,
      countedStock: countedStock,
      note: note,
    );
    await _invalidateStock();
  }

  Future<void> _invalidateOperational() async {
    await cache.invalidate(CacheKeys.employeeSummary);
    await cache.invalidatePrefix(CacheKeys.employeeTodayOrdersPrefix);
  }

  Future<void> _invalidateStock() async {
    await cache.invalidate(CacheKeys.employeeSummary);
    await cache.invalidate(CacheKeys.employeeStockSummary);
    await cache.invalidatePrefix(CacheKeys.employeeStockListPrefix);
    await cache.invalidatePrefix(CacheKeys.employeeStockHistoryPrefix);
    // Stok yang berubah juga mengubah daftar produk di etalase.
    await cache.invalidatePrefix(CacheKeys.productListPrefix);
  }
}
