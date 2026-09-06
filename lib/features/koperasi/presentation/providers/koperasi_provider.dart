import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/storage/api_cache.dart';
import '../../../location/domain/user_location.dart';
import '../../../location/presentation/providers/location_provider.dart';
import '../../data/koperasi_remote_data_source.dart';
import '../../data/koperasi_repository.dart';
import '../../domain/koperasi.dart';

final koperasiRepositoryProvider = Provider<KoperasiRepository>((ref) {
  return KoperasiRepository(
    remote: KoperasiRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(apiCacheProvider),
  );
});

/// Koordinat pengguna saja, tanpa status izin.
///
/// Section terdekat hanya perlu tahu koordinatnya. Dengan `select`, berpindah
/// dari `requestingPermission` ke `loadingLocation` tidak ikut membangun ulang
/// daftar Kopdes — hanya perubahan koordinat yang memicunya.
final userCoordinatesProvider = Provider<UserLocation?>((ref) {
  return ref.watch(locationProvider.select((s) => s.location));
});

/// Kopdes terdekat. `null` bila koordinat belum ada — bukan daftar kosong,
/// supaya UI bisa membedakan "belum tahu lokasi" dari "tidak ada Kopdes".
final nearbyKoperasiProvider = FutureProvider<Paginated<Koperasi>?>((
  ref,
) async {
  final location = ref.watch(userCoordinatesProvider);
  if (location == null) return null;

  return ref
      .watch(koperasiRepositoryProvider)
      .nearbyKoperasi(
        latitude: location.latitude,
        longitude: location.longitude,
        // Beranda hanya menampilkan tiga card; sisanya di halaman "Lihat
        // Lainnya" yang punya paginasinya sendiri.
        limit: 3,
      );
});

/// Daftar Kopdes tanpa jarak — jalan keluar saat izin lokasi ditolak.
final koperasiListProvider = FutureProvider<Paginated<Koperasi>>((ref) {
  return ref.watch(koperasiRepositoryProvider).allKoperasi(limit: 3);
});

/// Filter kategori pada section Mitra UMKM. `null` berarti "Semua".
final mitraCategoryFilterProvider = StateProvider<MitraCategory?>((_) => null);

final nearbyMitraProvider = FutureProvider<Paginated<Mitra>?>((ref) async {
  final location = ref.watch(userCoordinatesProvider);
  if (location == null) return null;

  return ref
      .watch(koperasiRepositoryProvider)
      .nearbyMitra(
        latitude: location.latitude,
        longitude: location.longitude,
        limit: 3,
        category: ref.watch(mitraCategoryFilterProvider),
      );
});

final koperasiDetailProvider = FutureProvider.family<Koperasi, String>((
  ref,
  id,
) {
  return ref.watch(koperasiRepositoryProvider).detail(id);
});

/// Filter halaman "Lihat Lainnya".
class KoperasiFilter {
  final String search;
  final double radiusKm;
  final double minRating;
  final bool openOnly;

  const KoperasiFilter({
    this.search = '',
    this.radiusKm = 10,
    this.minRating = 0,
    this.openOnly = false,
  });

  KoperasiFilter copyWith({
    String? search,
    double? radiusKm,
    double? minRating,
    bool? openOnly,
  }) => KoperasiFilter(
    search: search ?? this.search,
    radiusKm: radiusKm ?? this.radiusKm,
    minRating: minRating ?? this.minRating,
    openOnly: openOnly ?? this.openOnly,
  );
}

final koperasiFilterProvider = StateProvider<KoperasiFilter>(
  (_) => const KoperasiFilter(),
);

class KoperasiListState {
  final List<Koperasi> items;
  final bool hasMore;
  final bool isLoadingMore;
  final int total;

  const KoperasiListState({
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.total = 0,
  });

  KoperasiListState copyWith({
    List<Koperasi>? items,
    bool? hasMore,
    bool? isLoadingMore,
    int? total,
  }) => KoperasiListState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    total: total ?? this.total,
  );
}

/// Daftar Kopdes berhalaman untuk layar "Lihat Lainnya".
///
/// Saat koordinat tersedia, hasil diurutkan berdasarkan jarak oleh server.
/// Tanpa koordinat, jatuh ke daftar biasa — layar tetap berguna meski izin
/// lokasi ditolak.
class KoperasiListNotifier
    extends StateNotifier<AsyncValue<KoperasiListState>> {
  final KoperasiRepository _repository;
  final UserLocation? _location;
  final KoperasiFilter _filter;

  KoperasiListNotifier(this._repository, this._location, this._filter)
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
        KoperasiListState(
          items: _applyLocalFilters(result.items),
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
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(_page + 1);
      _page += 1;
      state = AsyncValue.data(
        KoperasiListState(
          items: [...current.items, ..._applyLocalFilters(next.items)],
          hasMore: next.hasMore,
          total: next.total,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  /// Rating disaring di klien karena backend belum menerimanya sebagai
  /// parameter query; jarak dan status buka tetap disaring server.
  List<Koperasi> _applyLocalFilters(List<Koperasi> items) {
    if (_filter.minRating <= 0) return items;
    return items
        .where((k) => (k.rating.average ?? 0) >= _filter.minRating)
        .toList(growable: false);
  }

  Future<Paginated<Koperasi>> _fetch(int page, {bool forceRefresh = false}) {
    final location = _location;
    if (location == null) {
      return _repository.allKoperasi(
        page: page,
        limit: 10,
        forceRefresh: forceRefresh,
      );
    }
    return _repository.nearbyKoperasi(
      latitude: location.latitude,
      longitude: location.longitude,
      radius: _filter.radiusKm,
      page: page,
      limit: 10,
      forceRefresh: forceRefresh,
    );
  }
}

final koperasiListPagedProvider =
    StateNotifierProvider<KoperasiListNotifier, AsyncValue<KoperasiListState>>((
      ref,
    ) {
      return KoperasiListNotifier(
        ref.watch(koperasiRepositoryProvider),
        ref.watch(userCoordinatesProvider),
        ref.watch(koperasiFilterProvider),
      );
    });

/// Filter halaman "Lihat Semua" Mitra UMKM.
class MitraFilter {
  final String search;
  final double radiusKm;
  final double minRating;
  final bool openOnly;
  final MitraCategory? category;

  const MitraFilter({
    this.search = '',
    this.radiusKm = 10,
    this.minRating = 0,
    this.openOnly = false,
    this.category,
  });

  MitraFilter copyWith({
    String? search,
    double? radiusKm,
    double? minRating,
    bool? openOnly,
    MitraCategory? category,
    bool clearCategory = false,
  }) => MitraFilter(
    search: search ?? this.search,
    radiusKm: radiusKm ?? this.radiusKm,
    minRating: minRating ?? this.minRating,
    openOnly: openOnly ?? this.openOnly,
    category: clearCategory ? null : (category ?? this.category),
  );
}

final mitraFilterProvider = StateProvider<MitraFilter>(
  (_) => const MitraFilter(),
);

class MitraListState {
  final List<Mitra> items;
  final bool hasMore;
  final bool isLoadingMore;
  final int total;

  const MitraListState({
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.total = 0,
  });

  MitraListState copyWith({
    List<Mitra>? items,
    bool? hasMore,
    bool? isLoadingMore,
    int? total,
  }) => MitraListState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    total: total ?? this.total,
  );
}

/// Daftar Mitra UMKM berhalaman.
///
/// Berbeda dari Kopdes, tidak ada jalur "tanpa lokasi": pencarian mitra
/// memang berbasis kedekatan. Tanpa koordinat, layar menampilkan ajakan
/// memilih lokasi, bukan daftar kosong.
class MitraListNotifier extends StateNotifier<AsyncValue<MitraListState>> {
  final KoperasiRepository _repository;
  final UserLocation? _location;
  final MitraFilter _filter;

  MitraListNotifier(this._repository, this._location, this._filter)
    : super(const AsyncValue.loading()) {
    load();
  }

  int _page = 1;

  bool get hasLocation => _location != null;

  Future<void> load({bool forceRefresh = false}) async {
    _page = 1;
    if (_location == null) {
      state = const AsyncValue.data(MitraListState());
      return;
    }
    if (forceRefresh) state = const AsyncValue.loading();
    try {
      final result = await _fetch(1, forceRefresh: forceRefresh);
      state = AsyncValue.data(
        MitraListState(
          items: _applyLocalFilters(result.items),
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
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final next = await _fetch(_page + 1);
      _page += 1;
      state = AsyncValue.data(
        MitraListState(
          items: [...current.items, ..._applyLocalFilters(next.items)],
          hasMore: next.hasMore,
          total: next.total,
        ),
      );
    } catch (_) {
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }

  /// Rating disaring di klien; backend belum menerimanya sebagai parameter.
  /// Jarak, kategori, dan status buka tetap disaring server.
  List<Mitra> _applyLocalFilters(List<Mitra> items) {
    if (_filter.minRating <= 0) return items;
    return items
        .where((m) => (m.rating.average ?? 0) >= _filter.minRating)
        .toList(growable: false);
  }

  Future<Paginated<Mitra>> _fetch(int page, {bool forceRefresh = false}) {
    final location = _location!;
    return _repository.nearbyMitra(
      latitude: location.latitude,
      longitude: location.longitude,
      radius: _filter.radiusKm,
      page: page,
      limit: 10,
      category: _filter.category,
      forceRefresh: forceRefresh,
    );
  }
}

final mitraListPagedProvider =
    StateNotifierProvider<MitraListNotifier, AsyncValue<MitraListState>>((ref) {
      return MitraListNotifier(
        ref.watch(koperasiRepositoryProvider),
        ref.watch(userCoordinatesProvider),
        ref.watch(mitraFilterProvider),
      );
    });

final mitraDetailProvider = FutureProvider.family<Mitra, String>((ref, id) {
  return ref.watch(koperasiRepositoryProvider).mitraDetail(id);
});
