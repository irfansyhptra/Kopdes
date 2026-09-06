import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/api_cache.dart';
import '../../data/content_repository.dart';
import '../../domain/content_page.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository(
    remote: ContentRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(apiCacheProvider),
  );
});

final contentPageProvider = FutureProvider.family<ContentPage, String>((
  ref,
  slug,
) {
  return ref.watch(contentRepositoryProvider).page(slug);
});
