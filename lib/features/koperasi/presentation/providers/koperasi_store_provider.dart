import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/storage/api_cache.dart';
import '../../../marketplace/data/marketplace_repository.dart';
import '../../../marketplace/domain/marketplace.dart';
import '../../data/koperasi_remote_data_source.dart';
import '../../domain/membership.dart';

/// Etalase satu toko — Kopdes maupun Mitra UMKM.
///
/// Keduanya memakai provider yang sama, dibedakan oleh [StoreRef]: bentuk
/// halamannya identik, jadi menyalin enam provider hanya untuk mengganti satu
/// nama parameter akan menghasilkan dua salinan yang diam-diam menyimpang.
///
/// Produknya lewat endpoint Marketplace yang sama, hanya dengan `kopdesId`
/// atau `umkmId` terkunci — bukan endpoint kedua yang bisa berbeda aturan
/// stok, diskon, atau ratingnya.

/// Toko yang sedang dibuka. Record, bukan kelas: kunci `family` butuh
/// persamaan nilai, dan record sudah memilikinya tanpa boilerplate.
typedef StoreRef = ({String id, bool isUmkm});

final _marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(
    remote: MarketplaceRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(apiCacheProvider),
  );
});

/// Kata kunci pencarian di dalam toko. Terpisah per Kopdes supaya membuka toko
/// lain tidak mewarisi pencarian toko sebelumnya.
final storeSearchProvider = StateProvider.family<String, StoreRef>(
  (_, __) => '',
);

/// Kategori terpilih di dalam toko; null berarti "Semua".
final storeCategoryProvider = StateProvider.family<String?, StoreRef>(
  (_, __) => null,
);

/// Hanya yang sedang ada stoknya.
final storeInStockOnlyProvider = StateProvider.family<bool, StoreRef>(
  (_, __) => false,
);

/// Urutan tampilan produk di dalam toko.
final storeSortProvider = StateProvider.family<MarketplaceSort, StoreRef>(
  (_, __) => MarketplaceSort.newest,
);

/// Filter gabungan — satu objek supaya daftar produk cukup mengamati satu hal.
final storeFilterProvider = Provider.family<MarketplaceFilter, StoreRef>((
  ref,
  store,
) {
  return MarketplaceFilter(
    kopdesId: store.isUmkm ? null : store.id,
    umkmId: store.isUmkm ? store.id : null,
    search: ref.watch(storeSearchProvider(store)),
    foodCategoryId: ref.watch(storeCategoryProvider(store)),
    inStockOnly: ref.watch(storeInStockOnlyProvider(store)),
    sort: ref.watch(storeSortProvider(store)),
    // Etalase hanya berisi barang toko itu sendiri; toko lain punya
    // halamannya masing-masing.
    sellerType: store.isUmkm ? SellerType.umkm : SellerType.kopdes,
  );
});

/// Produk yang dijual Kopdes ini.
final storeProductsProvider =
    FutureProvider.family<Paginated<MarketplaceProduct>, StoreRef>((
      ref,
      store,
    ) {
      return ref
          .watch(_marketplaceRepositoryProvider)
          .products(filter: ref.watch(storeFilterProvider(store)));
    });

/// Keanggotaan pengguna pada Kopdes ini.
///
/// `null` berarti belum pernah mendaftar. Permintaannya butuh sesi; tamu
/// mendapat `null` juga, dan ajakan mendaftar tetap digambar — menekannya yang
/// akan mengantar ke layar masuk.
final storeMembershipProvider = FutureProvider.family<Membership?, String>((
  ref,
  koperasiId,
) async {
  final remote = KoperasiRemoteDataSource(ref.watch(dioProvider));
  try {
    return Membership.fromJson(await remote.fetchMembership(koperasiId));
  } catch (_) {
    // Belum masuk, atau jaringan gagal. Keduanya digambar sama: belum
    // terdaftar. Halaman toko tidak boleh gagal hanya karena status
    // keanggotaan tidak terbaca.
    return null;
  }
});
