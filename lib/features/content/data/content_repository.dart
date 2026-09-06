import 'package:dio/dio.dart';

import '../../../core/storage/api_cache.dart';
import '../domain/content_page.dart';

class ContentRemoteDataSource {
  final Dio dio;

  const ContentRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> fetchPage(String slug) async {
    final response = await dio.get<dynamic>('/content/$slug');
    final map = response.data as Map<String, dynamic>;
    return map['data'] as Map<String, dynamic>? ?? map;
  }
}

class ContentRepository {
  final ContentRemoteDataSource remote;
  final ApiCache cache;

  const ContentRepository({required this.remote, required this.cache});

  /// Halaman informasi jarang berubah — TTL panjang, dan tetap terbaca saat
  /// jaringan mati.
  Future<ContentPage> page(String slug, {bool forceRefresh = false}) {
    return cachedFetch(
      cache: cache,
      key: '${CacheKeys.contentPagePrefix}$slug',
      ttl: CacheTtl.long,
      forceRefresh: forceRefresh,
      fetch: () => remote.fetchPage(slug),
      decode: (json) => ContentPage.fromJson(json as Map<String, dynamic>),
    );
  }
}
