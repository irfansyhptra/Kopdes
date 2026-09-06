import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/api_cache.dart';
import '../../data/discovery_repository.dart';
import '../../domain/discovery.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(
    remote: DiscoveryRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(apiCacheProvider),
  );
});

/// Banner iklan utama. Tidak bergantung lokasi, jadi tidak ikut dimuat ulang
/// ketika koordinat pengguna berubah.
final bannersProvider = FutureProvider<List<PromoBanner>>((ref) {
  return ref.watch(discoveryRepositoryProvider).banners();
});

/// Produk UMKM pilihan — ditandai admin lewat `isFeatured`, bukan daftar
/// tetap di dalam widget.
final featuredUmkmProductsProvider = FutureProvider<List<DiscoveryProduct>>((
  ref,
) {
  return ref.watch(discoveryRepositoryProvider).featuredUmkmProducts(limit: 8);
});

/// Rentang waktu agregasi produk terlaris.
final bestSellerPeriodProvider = StateProvider<String>((_) => '30d');

/// Produk terlaris dari agregasi pesanan sah di server.
final bestSellersProvider = FutureProvider<List<DiscoveryProduct>>((ref) {
  return ref
      .watch(discoveryRepositoryProvider)
      .bestSellers(limit: 8, period: ref.watch(bestSellerPeriodProvider));
});

/// Detail satu produk Mitra UMKM.
final umkmProductDetailProvider =
    FutureProvider.family<UmkmProductDetail, String>((ref, id) {
      return ref.watch(discoveryRepositoryProvider).umkmProductDetail(id);
    });
