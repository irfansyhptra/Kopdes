import 'package:dio/dio.dart';

/// Mengembalikan JSON mentah, bukan model — sesuai pola di CLAUDE.md.
/// Cache menyimpan payload apa adanya sehingga data dari jaringan dan dari
/// cache melewati `fromJson` yang sama.
class KoperasiRemoteDataSource {
  final Dio dio;

  const KoperasiRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> fetchNearbyKoperasi({
    required double latitude,
    required double longitude,
    double radius = 10,
    int page = 1,
    int limit = 10,
    String? search,
    bool? openNow,
  }) async {
    final response = await dio.get<dynamic>(
      '/koperasi/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (openNow != null) 'openNow': openNow,
      },
    );
    return _unwrap(response.data, 'koperasi');
  }

  Future<Map<String, dynamic>> fetchKoperasiList({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    final response = await dio.get<dynamic>(
      '/koperasi',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return _unwrap(response.data, 'koperasi');
  }

  Future<Map<String, dynamic>> fetchKoperasiDetail(String id) async {
    final response = await dio.get<dynamic>('/koperasi/$id');
    final map = response.data as Map<String, dynamic>;
    return map['data'] as Map<String, dynamic>? ?? map;
  }

  Future<Map<String, dynamic>> fetchNearbyMitra({
    required double latitude,
    required double longitude,
    double radius = 10,
    int page = 1,
    int limit = 10,
    String? category,
    String? search,
    bool? openNow,
  }) async {
    final response = await dio.get<dynamic>(
      '/umkm/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
        if (openNow != null) 'openNow': openNow,
      },
    );
    return _unwrap(response.data, 'umkm');
  }

  Future<Map<String, dynamic>> fetchMitraDetail(String id) async {
    final response = await dio.get<dynamic>('/umkm/$id');
    final map = response.data as Map<String, dynamic>;
    return map['data'] as Map<String, dynamic>? ?? map;
  }

  /// Backend mengirim `{ success, data: { [itemsKey]: [...], total, page,
  /// limit, totalPages } }` — metadata paginasi **datar di dalam `data`**,
  /// bukan bersarang di `meta`. Dinormalkan di sini supaya `Paginated`
  /// melihat bentuk yang sama untuk semua endpoint.
  Map<String, dynamic> _unwrap(dynamic raw, String itemsKey) {
    final map = raw as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>? ?? map;
    return {
      itemsKey: data[itemsKey] ?? const [],
      'meta': {
        'total': data['total'] ?? 0,
        'page': data['page'] ?? 1,
        'limit': data['limit'] ?? 10,
        'totalPages': data['totalPages'] ?? 1,
      },
    };
  }
}
