import 'package:isar/isar.dart';

part 'cached_response.g.dart';

/// Satu koleksi cache untuk seluruh aplikasi.
///
/// Sebelumnya tiap fitur butuh skema Isar sendiri (ProductCache, OrderCache,
/// …) lengkap dengan kode pemetaan manual model→skema. Pemetaan itu bocor:
/// ProductCache membuang `categoryId` dan memaksa `isActive = true`, jadi data
/// yang keluar dari cache tidak sama dengan yang masuk.
///
/// Di sini payload disimpan sebagai JSON mentah dari respons API, lalu
/// di-decode memakai `fromJson` model yang sudah ada. Tidak ada pemetaan kedua
/// yang bisa menyimpang, dan fitur baru tidak perlu skema baru.
@collection
class CachedResponse {
  Id id = Isar.autoIncrement;

  /// Kunci cache, biasanya path + query. Lihat [CacheKeys].
  @Index(unique: true, replace: true)
  late String key;

  /// Respons API apa adanya, sudah di-encode JSON.
  late String payload;

  late DateTime cachedAt;
}
