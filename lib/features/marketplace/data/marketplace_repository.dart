import 'package:dio/dio.dart';

import '../../../core/network/paginated.dart';
import '../../../core/storage/api_cache.dart';
import '../domain/marketplace.dart';

class MarketplaceRemoteDataSource {
  final Dio dio;

  const MarketplaceRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> fetchProducts({
    required MarketplaceFilter filter,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get<dynamic>(
      '/marketplace/products',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sellerType': filter.sellerType.wire,
        'sort': filter.sort.wire,
        if (filter.search.isNotEmpty) 'search': filter.search,
        if (filter.categoryId != null) 'categoryId': filter.categoryId,
        if (filter.minPrice != null) 'minPrice': filter.minPrice,
        if (filter.maxPrice != null) 'maxPrice': filter.maxPrice,
        if (filter.inStockOnly) 'inStock': true,
        // Koordinat hanya dikirim saat pengurutan jarak diminta — server
        // menolak sort=distance tanpa koordinat yang sah.
        if (filter.isDistanceSort && latitude != null) 'latitude': latitude,
        if (filter.isDistanceSort && longitude != null) 'longitude': longitude,
        // Radius baru berarti bersama koordinat: server menyaringnya dari
        // jarak yang dihitung, jadi mengirimnya sendirian tidak menyaring
        // apa pun dan hanya mencabangkan kunci cache tanpa guna.
        if (filter.isDistanceSort && filter.radiusKm != null)
          'radius': filter.radiusKm,
      },
    );

    final map = response.data as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? map;
    return {
      'products': data['products'] ?? const [],
      'meta': {
        'total': data['total'] ?? 0,
        'page': data['page'] ?? 1,
        'limit': data['limit'] ?? limit,
        'totalPages': data['totalPages'] ?? 1,
      },
    };
  }
}

class MarketplaceRepository {
  final MarketplaceRemoteDataSource remote;
  final ApiCache cache;

  const MarketplaceRepository({required this.remote, required this.cache});

  Future<Paginated<MarketplaceProduct>> products({
    required MarketplaceFilter filter,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) {
    return cachedFetch(
      cache: cache,
      key: _key(filter, latitude, longitude, page, limit),
      ttl: CacheTtl.short,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchProducts(
        filter: filter,
        latitude: latitude,
        longitude: longitude,
        page: page,
        limit: limit,
      ),
      decode: (json) =>
          Paginated.fromJson(json, 'products', MarketplaceProduct.fromJson),
    );
  }

  /// Kunci cache harus memuat SETIAP filter — kalau tidak, hasil pencarian
  /// "beras" bisa tersaji untuk pencarian "gula". Koordinat dibulatkan ke
  /// ±100 m supaya pergeseran GPS beberapa meter tetap kena cache.
  String _key(
    MarketplaceFilter f,
    double? lat,
    double? lng,
    int page,
    int limit,
  ) {
    final geo = f.isDistanceSort && lat != null && lng != null
        ? '${(lat * 1000).round()}:${(lng * 1000).round()}'
        : '';
    return '${CacheKeys.marketplacePrefix}'
        'p$page:l$limit:s${f.search}:c${f.categoryId ?? ''}:'
        't${f.sellerType.wire}:o${f.sort.wire}:'
        'min${f.minPrice ?? ''}:max${f.maxPrice ?? ''}:'
        'stock${f.inStockOnly}:r${f.radiusKm ?? ''}:$geo';
  }
}
