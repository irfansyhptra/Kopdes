import '../../../core/network/paginated.dart';
import '../../../core/storage/api_cache.dart';
import '../domain/koperasi.dart';
import 'koperasi_remote_data_source.dart';

class KoperasiRepository {
  final KoperasiRemoteDataSource remote;
  final ApiCache cache;

  const KoperasiRepository({required this.remote, required this.cache});

  /// Kunci cache dibulatkan ke ±100 m.
  ///
  /// Tanpa pembulatan, setiap pembacaan GPS menghasilkan koordinat sedikit
  /// berbeda dan cache tidak pernah kena — padahal hasil "terdekat" untuk
  /// pergeseran beberapa meter praktis identik.
  String _geoKey(String prefix, double lat, double lng, Object? extra) {
    final rLat = (lat * 1000).round();
    final rLng = (lng * 1000).round();
    return '$prefix$rLat:$rLng:${extra ?? ''}';
  }

  Future<Paginated<Koperasi>> nearbyKoperasi({
    required double latitude,
    required double longitude,
    double radius = 10,
    int page = 1,
    int limit = 10,
    String? search,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: _geoKey(
        CacheKeys.koperasiNearbyPrefix,
        latitude,
        longitude,
        'r$radius:p$page:l$limit:q${search ?? ''}',
      ),
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchNearbyKoperasi(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        page: page,
        limit: limit,
        search: search,
      ),
      decode: (json) => Paginated.fromJson(json, 'koperasi', Koperasi.fromJson),
    );
  }

  /// Dipakai saat pengguna menolak izin lokasi — daftar tanpa jarak.
  /// Seluruh Kopdes aktif, terdekat lebih dulu bila koordinatnya diketahui.
  ///
  /// Koordinat ikut ke kunci cache — dibulatkan ke ±100 m supaya pergeseran
  /// GPS beberapa meter tetap kena cache, tetapi berpindah desa tidak
  /// menyajikan urutan desa sebelumnya.
  Future<Paginated<Koperasi>> allKoperasi({
    int page = 1,
    int limit = 10,
    String? search,
    double? latitude,
    double? longitude,
    bool withProductsOnly = false,
    bool forceRefresh = false,
  }) {
    final geo = latitude != null && longitude != null
        ? '${(latitude * 1000).round()}:${(longitude * 1000).round()}'
        : '';
    return cachedFetch(
      cache: cache,
      key:
          '${CacheKeys.koperasiListPrefix}p$page:l$limit:'
          'q${search ?? ''}:g$geo:w$withProductsOnly',
      // Pendek, bukan panjang: urutannya bergantung posisi pengguna, dan
      // posisi itu berubah jauh lebih sering daripada daftar Kopdes-nya.
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchKoperasiList(
        page: page,
        limit: limit,
        search: search,
        latitude: latitude,
        longitude: longitude,
        withProductsOnly: withProductsOnly,
      ),
      decode: (json) => Paginated.fromJson(json, 'koperasi', Koperasi.fromJson),
    );
  }

  /// Seluruh Mitra UMKM aktif, dengan aturan yang sama.
  Future<Paginated<Mitra>> allMitra({
    int page = 1,
    int limit = 10,
    String? search,
    MitraCategory? category,
    double? latitude,
    double? longitude,
    bool withProductsOnly = false,
    bool forceRefresh = false,
  }) {
    final geo = latitude != null && longitude != null
        ? '${(latitude * 1000).round()}:${(longitude * 1000).round()}'
        : '';
    return cachedFetch(
      cache: cache,
      key:
          '${CacheKeys.mitraListPrefix}p$page:l$limit:'
          'q${search ?? ''}:c${category?.wire ?? ''}:g$geo:w$withProductsOnly',
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchMitraList(
        page: page,
        limit: limit,
        search: search,
        category: category?.wire,
        latitude: latitude,
        longitude: longitude,
        withProductsOnly: withProductsOnly,
      ),
      decode: (json) => Paginated.fromJson(json, 'umkm', Mitra.fromJson),
    );
  }

  Future<Koperasi> detail(String id, {bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.koperasiDetailPrefix}$id',
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchKoperasiDetail(id),
      decode: (json) => Koperasi.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Paginated<Mitra>> nearbyMitra({
    required double latitude,
    required double longitude,
    double radius = 10,
    int page = 1,
    int limit = 10,
    String? search,
    MitraCategory? category,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: _geoKey(
        CacheKeys.mitraNearbyPrefix,
        latitude,
        longitude,
        'r$radius:p$page:l$limit:q${search ?? ''}:c${category?.wire ?? ''}',
      ),
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchNearbyMitra(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        page: page,
        limit: limit,
        search: search,
        category: category?.wire,
      ),
      decode: (json) => Paginated.fromJson(json, 'umkm', Mitra.fromJson),
    );
  }

  Future<Mitra> mitraDetail(String id, {bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.mitraDetailPrefix}$id',
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchMitraDetail(id),
      decode: (json) => Mitra.fromJson(json as Map<String, dynamic>),
    );
  }
}
