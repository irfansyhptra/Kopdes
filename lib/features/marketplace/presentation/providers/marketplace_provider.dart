import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/storage/api_cache.dart';
import '../../../koperasi/presentation/providers/koperasi_provider.dart';
import '../../../location/domain/user_location.dart';
import '../../../product/domain/entities/category.dart';
import '../../../product/presentation/providers/product_provider.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/marketplace.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(
    remote: MarketplaceRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(apiCacheProvider),
  );
});

/// Filter Marketplace. Dipertahankan selama sesi, sehingga membuka detail
/// produk lalu kembali tidak menghapus pilihan pengguna.
final marketplaceFilterProvider = StateProvider<MarketplaceFilter>(
  (_) => const MarketplaceFilter(),
);

/// Kategori dipecah menjadi dua baris filter berdasarkan `group` dari backend.
///
/// Memakai kembali [categoriesProvider] yang sudah ada dan sudah di-cache —
/// tidak ada permintaan jaringan tambahan untuk ini.
final foodCategoriesProvider = Provider<List<Category>>((ref) {
  return _categoriesIn(ref, CategoryGroup.food);
});

final retailCategoriesProvider = Provider<List<Category>>((ref) {
  return _categoriesIn(ref, CategoryGroup.retail);
});

List<Category> _categoriesIn(Ref ref, CategoryGroup group) {
  final all = ref.watch(categoriesProvider).asData?.value ?? const [];
  return all
      .where((c) => CategoryGroup.fromWire(c.group) == group)
      .toList(growable: false);
}

class MarketplaceListState {
  final List<MarketplaceProduct> items;
  final bool hasMore;
  final bool isLoadingMore;

  /// Kegagalan saat memuat halaman berikutnya. Produk lama tetap ditampilkan
  /// dan pengguna diberi tombol coba lagi, bukan daftar yang mendadak kosong.
  final bool loadMoreFailed;
  final int total;

  const MarketplaceListState({
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.total = 0,
  });

  MarketplaceListState copyWith({
    List<MarketplaceProduct>? items,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    int? total,
  }) => MarketplaceListState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    total: total ?? this.total,
  );
}

/// Daftar produk Marketplace dengan infinite scrolling.
class MarketplaceListNotifier
    extends StateNotifier<AsyncValue<MarketplaceListState>> {
  final MarketplaceRepository _repository;
  final MarketplaceFilter _filter;
  final UserLocation? _location;

  MarketplaceListNotifier(this._repository, this._filter, this._location)
    : super(const AsyncValue.loading()) {
    load();
  }

  int _page = 1;

  Future<void> load({bool forceRefresh = false}) async {
    _page = 1;
    if (forceRefresh) state = const AsyncValue.loading();
    try {
      final result = await _fetch(1, forceRefresh: forceRefresh);
      state = AsyncValue.data(
        MarketplaceListState(
          items: result.items,
          hasMore: result.hasMore,
          total: result.total,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    // Penjaga ganda: scroll cepat tidak boleh memicu dua permintaan untuk
    // halaman yang sama.
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await _fetch(_page + 1);
      _page += 1;
      state = AsyncValue.data(
        MarketplaceListState(
          items: [...current.items, ...next.items],
          hasMore: next.hasMore,
          total: next.total,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }

  Future<Paginated<MarketplaceProduct>> _fetch(
    int page, {
    bool forceRefresh = false,
  }) {
    return _repository.products(
      filter: _filter,
      latitude: _location?.latitude,
      longitude: _location?.longitude,
      page: page,
      limit: 20,
      forceRefresh: forceRefresh,
    );
  }
}

final marketplaceProductsProvider =
    StateNotifierProvider<
      MarketplaceListNotifier,
      AsyncValue<MarketplaceListState>
    >((ref) {
      return MarketplaceListNotifier(
        ref.watch(marketplaceRepositoryProvider),
        ref.watch(marketplaceFilterProvider),
        // Hanya koordinatnya yang diamati: berpindah dari `requestingPermission`
        // ke `loadingLocation` tidak ikut memuat ulang daftar produk.
        ref.watch(userCoordinatesProvider),
      );
    });

/// Produk favorit, bertahan setelah aplikasi ditutup.
///
/// Disimpan lewat [ApiCache] yang sudah ada — isinya JSON, jadi tidak perlu
/// koleksi Isar baru. Yang disimpan adalah seluruh produknya, bukan hanya id:
/// tanpa endpoint "ambil produk berdasarkan daftar id", menyimpan id saja
/// berarti daftar favorit tidak bisa dirender sama sekali saat offline.
class FavoriteNotifier extends StateNotifier<List<MarketplaceProduct>> {
  /// `null` berarti tanpa penyimpanan: favorit tetap berfungsi selama sesi
  /// berjalan. Dipakai di uji widget, dan menjaga grid tetap tampil kalau
  /// cache lokal tidak bisa dibuka.
  final ApiCache? _cache;

  FavoriteNotifier(this._cache) : super(const []) {
    _load();
  }

  /// Batas atas supaya satu baris cache tidak tumbuh tanpa henti.
  /// ponytail: seluruh daftar ditulis ulang setiap kali ditekan — murah pada
  /// puluhan baris. Kalau batasnya perlu jauh lebih besar, pindahkan ke
  /// koleksi Isar tersendiri dengan satu baris per produk.
  static const int _maxItems = 200;

  Future<void> _load() async {
    try {
      final entry = await _cache?.read(CacheKeys.favorites);
      final raw = entry?.data as List<dynamic>? ?? const [];
      if (!mounted) return;
      state = raw
          .map((e) => MarketplaceProduct.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      // Favorit bukan data kritis: gagal membaca berarti daftar kosong,
      // bukan layar error.
    }
  }

  void toggle(MarketplaceProduct product) {
    final next = state.any((p) => p.id == product.id)
        ? state.where((p) => p.id != product.id).toList(growable: false)
        // Yang terbaru di depan, dan yang terlama dibuang saat penuh.
        : [product, ...state].take(_maxItems).toList(growable: false);
    state = next;
    final cache = _cache;
    if (cache == null) return;
    unawaited(
      cache.write(
        CacheKeys.favorites,
        next.map((p) => p.toJson()).toList(growable: false),
      ),
      onError: (_) {},
    );
  }
}

final favoriteProductsProvider =
    StateNotifierProvider<FavoriteNotifier, List<MarketplaceProduct>>(
      (ref) => FavoriteNotifier(ref.watch(apiCacheProvider)),
    );

/// True bila produk tertentu difavoritkan. Kartu mengamati provider ini saja,
/// sehingga perubahan favorit produk lain tidak membangun ulang kartunya.
final isFavoriteProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(
    favoriteProductsProvider.select((s) => s.any((p) => p.id == id)),
  );
});

/// Menampilkan daftar favorit sebagai ganti hasil pencarian.
final showFavoritesProvider = StateProvider<bool>((_) => false);

/// Produk yang sedang diproses ke keranjang — mencegah ketukan ganda.
final addingToCartProvider = StateProvider<Set<String>>((_) => const {});
