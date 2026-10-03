import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import 'isar_service.dart';
import 'models/cached_response.dart';

/// Kunci cache terpusat. Disimpan di satu tempat supaya invalidasi bisa
/// memakai prefix (mis. buang semua daftar produk tanpa menyentuh detail).
class CacheKeys {
  static const String productListPrefix = 'products:';
  static const String productDetailPrefix = 'product:';
  static const String categories = 'categories';

  static const String koperasiNearbyPrefix = 'koperasi:nearby:';
  static const String koperasiListPrefix = 'koperasi:list:';
  static const String mitraListPrefix = 'mitra:list:';
  static const String koperasiDetailPrefix = 'koperasi:';
  static const String mitraNearbyPrefix = 'mitra:nearby:';
  static const String mitraDetailPrefix = 'mitra:';
  static const String bestSellersPrefix = 'discovery:best-sellers:';
  static const String featuredUmkmPrefix = 'discovery:featured-umkm:';
  static const String banners = 'discovery:banners';
  static const String umkmProductPrefix = 'umkm-product:';
  static const String contentPagePrefix = 'content:';
  static const String marketplacePrefix = 'marketplace:';

  /// Favorit pengguna. Bukan respons API, tapi memakai penyimpanan yang sama:
  /// isinya JSON dan tidak butuh skema Isar sendiri. Sengaja di luar
  /// [marketplacePrefix] supaya invalidasi daftar produk tidak ikut
  /// menghapusnya.
  static const String favorites = 'favorites';

  // ── Dashboard Pegawai Kopdes ──
  // Semuanya di bawah satu prefix supaya keluar dari akun staf bisa
  // membersihkan seluruh data operasional dengan satu panggilan.
  static const String employeePrefix = 'employee:';
  static const String employeeSummary = '${employeePrefix}summary';
  static const String employeeStockSummary = '${employeePrefix}stock-summary';
  static const String employeeStoreStatus = '${employeePrefix}store-status';
  static const String employeeTodayOrdersPrefix =
      '${employeePrefix}today-orders:';
  static const String employeeFinancePrefix = '${employeePrefix}finance:';
  static const String employeeStockListPrefix = '${employeePrefix}stock-list:';
  static const String employeeStockHistoryPrefix =
      '${employeePrefix}stock-history:';

  /// Notifikasi pengguna, tersimpan di perangkatnya sendiri.
  ///
  /// Dikunci per pemilik: tanpa itu, notifikasi orang sebelumnya masih
  /// terbaca oleh siapa pun yang masuk berikutnya di ponsel yang sama —
  /// keluar dari akun hanya menghapus token, bukan cache.
  static String notifications(String ownerId) => 'notifications:$ownerId';

  static String productList(String querySignature) =>
      '$productListPrefix$querySignature';

  static String productDetail(String id) => '$productDetailPrefix$id';
}

/// Umur cache per jenis data — seberapa sering data itu benar-benar berubah.
class CacheTtl {
  /// Kategori nyaris tidak pernah berubah.
  static const Duration long = Duration(hours: 12);

  /// Daftar produk: harga & stok bergerak, tapi tidak per detik.
  static const Duration short = Duration(minutes: 5);

  /// Angka operasional dashboard: pesanan masuk dan stok berubah semenit
  /// sekali saat toko ramai, jadi lima menit sudah terlalu lama untuk
  /// dipercaya oleh pegawai yang sedang melayani antrean.
  static const Duration veryShort = Duration(seconds: 45);

  /// Batas data basi masih boleh ditampilkan saat jaringan mati.
  static const Duration offlineGrace = Duration(days: 7);
}

final apiCacheProvider = Provider<ApiCache>(
  (ref) => ApiCache(ref.watch(isarProvider)),
);

/// Cache respons API di atas Isar.
class ApiCache {
  final Isar _isar;

  const ApiCache(this._isar);

  /// Mengembalikan entri cache beserta umurnya, atau null bila tidak ada.
  Future<CachedEntry?> read(String key) async {
    final row = await _isar.cachedResponses.where().keyEqualTo(key).findFirst();
    if (row == null) return null;
    try {
      return CachedEntry(
        data: jsonDecode(row.payload),
        age: DateTime.now().difference(row.cachedAt),
      );
    } catch (e) {
      // Payload rusak (mis. format berubah antar versi) — buang, jangan crash.
      if (kDebugMode) {
        debugPrint('ApiCache: payload rusak untuk "$key", dibuang. $e');
      }
      await invalidate(key);
      return null;
    }
  }

  Future<void> write(String key, Object? data) async {
    final row = CachedResponse()
      ..key = key
      ..payload = jsonEncode(data)
      ..cachedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.cachedResponses.put(row));
  }

  Future<void> invalidate(String key) async {
    await _isar.writeTxn(
      () => _isar.cachedResponses.where().keyEqualTo(key).deleteAll(),
    );
  }

  /// Buang semua entri yang kuncinya diawali [prefix].
  Future<void> invalidatePrefix(String prefix) async {
    await _isar.writeTxn(
      () => _isar.cachedResponses.filter().keyStartsWith(prefix).deleteAll(),
    );
  }
}

class CachedEntry {
  final dynamic data;
  final Duration age;

  const CachedEntry({required this.data, required this.age});
}

/// Ambil data dengan pola **cache-first, lalu segarkan**.
///
/// Alur:
/// 1. Cache masih dalam [ttl] → langsung kembalikan, TANPA menyentuh jaringan.
/// 2. Cache ada tapi sudah lewat [ttl] → kembalikan yang lama seketika, lalu
///    segarkan di latar belakang. Layar terisi instan; data terbaru menyusul
///    lewat [onRefreshed].
/// 3. Cache kosong → tunggu jaringan.
/// 4. Jaringan gagal → pakai cache basi selama masih dalam
///    [CacheTtl.offlineGrace]; kalau tidak ada, lempar errornya.
///
/// [decode] menerima JSON mentah — bentuknya sama persis baik dari cache
/// maupun dari jaringan, jadi tidak ada jalur kode terpisah yang bisa berbeda.
Future<T> cachedFetch<T>({
  required ApiCache cache,
  required String key,
  required Duration ttl,
  required Future<Object?> Function() fetch,
  required T Function(dynamic json) decode,
  bool forceRefresh = false,
  void Function(T fresh)? onRefreshed,
}) async {
  final cached = forceRefresh ? null : await cache.read(key);

  if (cached != null && cached.age <= ttl) {
    return decode(cached.data);
  }

  if (cached != null) {
    // Basi tapi masih berguna: tampilkan sekarang, segarkan di belakang layar.
    // Kegagalan penyegaran sengaja ditelan — pengguna sudah punya data yang
    // terpakai, memunculkan error di sini hanya membingungkan.
    unawaited(
      _refresh(cache, key, fetch, decode, onRefreshed),
      onError: (e) {
        if (kDebugMode) {
          if (kDebugMode) debugPrint('ApiCache: gagal menyegarkan "$key": $e');
        }
      },
    );
    return decode(cached.data);
  }

  try {
    final fresh = await fetch();
    await cache.write(key, fresh);
    return decode(fresh);
  } catch (e) {
    final stale = await cache.read(key);
    if (stale != null && stale.age <= CacheTtl.offlineGrace) {
      if (kDebugMode) {
        debugPrint('ApiCache: jaringan gagal, memakai cache basi "$key".');
      }
      return decode(stale.data);
    }
    rethrow;
  }
}

Future<void> _refresh<T>(
  ApiCache cache,
  String key,
  Future<Object?> Function() fetch,
  T Function(dynamic) decode,
  void Function(T)? onRefreshed,
) async {
  final fresh = await fetch();
  await cache.write(key, fresh);
  onRefreshed?.call(decode(fresh));
}

/// `unawaited` dengan penanganan error — versi dart:async membiarkan error
/// menjadi unhandled dan mematikan zone-nya.
void unawaited(Future<void> future, {required void Function(Object) onError}) {
  future.catchError(onError);
}
