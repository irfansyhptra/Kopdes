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
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: _geoKey(
        CacheKeys.koperasiNearbyPrefix,
        latitude,
        longitude,
        'r$radius:p$page:l$limit',
      ),
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchNearbyKoperasi(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        page: page,
        limit: limit,
      ),
      decode: (json) => Paginated.fromJson(json, 'koperasi', Koperasi.fromJson),
    );
  }

  /// Dipakai saat pengguna menolak izin lokasi — daftar tanpa jarak.
  Future<Paginated<Koperasi>> allKoperasi({
    int page = 1,
    int limit = 10,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.koperasiListPrefix}p$page:l$limit',
      ttl: CacheTtl.long,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchKoperasiList(page: page, limit: limit),
      decode: (json) => Paginated.fromJson(json, 'koperasi', Koperasi.fromJson),
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
    MitraCategory? category,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: _geoKey(
        CacheKeys.mitraNearbyPrefix,
        latitude,
        longitude,
        'r$radius:p$page:l$limit:c${category?.wire ?? ''}',
      ),
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchNearbyMitra(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        page: page,
        limit: limit,
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
