import 'package:dio/dio.dart';

import '../../../core/storage/api_cache.dart';
import '../domain/discovery.dart';

/// Data source mengembalikan JSON mentah sesuai pola di CLAUDE.md, sehingga
/// data dari jaringan dan dari cache melewati `fromJson` yang sama.
class DiscoveryRemoteDataSource {
  final Dio dio;

  const DiscoveryRemoteDataSource(this.dio);

  Future<List<dynamic>> fetchBestSellers({
    int limit = 10,
    String period = '30d',
  }) async {
    final response = await dio.get<dynamic>(
      '/products/best-sellers',
      queryParameters: {'limit': limit, 'period': period},
    );
    return _items(response.data, 'products');
  }

  Future<List<dynamic>> fetchFeaturedUmkmProducts({int limit = 10}) async {
    final response = await dio.get<dynamic>(
      '/umkm/products/featured',
      queryParameters: {'limit': limit},
    );
    return _items(response.data, 'products');
  }

  Future<Map<String, dynamic>> fetchUmkmProductDetail(String id) async {
    final response = await dio.get<dynamic>('/umkm/products/$id');
    final map = response.data as Map<String, dynamic>;
    return map['data'] as Map<String, dynamic>? ?? map;
  }

  Future<List<dynamic>> fetchBanners() async {
    final response = await dio.get<dynamic>('/banners');
    return _items(response.data, 'banners');
  }

  List<dynamic> _items(dynamic raw, String key) {
    final map = raw as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? map;
    return data[key] as List? ?? const [];
  }
}

class DiscoveryRepository {
  final DiscoveryRemoteDataSource remote;
  final ApiCache cache;

  const DiscoveryRepository({required this.remote, required this.cache});

  /// Terlaris berubah lambat — server sudah men-cache 10 menit, klien
  /// menyimpannya juga agar beranda terisi seketika saat dibuka ulang.
  Future<List<DiscoveryProduct>> bestSellers({
    int limit = 10,
    String period = '30d',
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.bestSellersPrefix}$period:$limit',
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchBestSellers(limit: limit, period: period),
      decode: _decodeProducts,
    );
  }

  Future<List<DiscoveryProduct>> featuredUmkmProducts({
    int limit = 10,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.featuredUmkmPrefix}$limit',
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchFeaturedUmkmProducts(limit: limit),
      decode: _decodeProducts,
    );
  }

  /// Banner jarang berubah; TTL panjang supaya beranda tidak menunggu
  /// jaringan hanya untuk tiga iklan.
  Future<List<PromoBanner>> banners({bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: CacheKeys.banners,
      ttl: CacheTtl.long,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchBanners(),
      decode: (json) => (json as List)
          .whereType<Map<String, dynamic>>()
          .map(PromoBanner.fromJson)
          .toList(growable: false),
    );
  }

  Future<UmkmProductDetail> umkmProductDetail(
    String id, {
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.umkmProductPrefix}$id',
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchUmkmProductDetail(id),
      decode: (json) =>
          UmkmProductDetail.fromJson(json as Map<String, dynamic>),
    );
  }

  List<DiscoveryProduct> _decodeProducts(dynamic json) => (json as List)
      .whereType<Map<String, dynamic>>()
      .map(DiscoveryProduct.fromJson)
      .toList(growable: false);
}
