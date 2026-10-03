import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/network/error_message.dart';
import '../../../../core/network/paginated.dart';
import '../../../../core/storage/api_cache.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/employee_repository.dart';
import '../../domain/employee_dashboard.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    remote: EmployeeRemoteDataSource(ref.watch(dioProvider)),
    cache: ref.watch(apiCacheProvider),
  );
});

/// Pengguna yang sedang masuk, diamati sebagai satu objek.
///
/// Header, tombol, dan penjaga permission membaca provider ini lewat
/// `select()` masing-masing supaya perubahan satu field tidak membangun ulang
/// seluruh dashboard.
final currentStaffProvider = Provider<User?>((ref) {
  return ref.watch(authProvider.select((s) => s.user));
});

/// True bila pengguna punya sebuah permission. Family agar tiap tombol hanya
/// dibangun ulang ketika permission-nya sendiri berubah.
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final user = ref.watch(currentStaffProvider);
  return user?.can(permission) ?? false;
});

// ── Satu provider per bagian dashboard ───────────────────────────────────
// Dipisah dengan sengaja: kalau rekap keuangan gagal, KPI, pesanan, dan stok
// tetap tampil. Satu provider besar akan menjatuhkan seluruh halaman karena
// satu endpoint yang lambat.

final employeeSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) {
  return ref.watch(employeeRepositoryProvider).summary();
});

final todayOrdersProvider = FutureProvider.autoDispose<List<TodayOrder>>((ref) {
  return ref.watch(employeeRepositoryProvider).todayOrders();
});

final stockSummaryProvider = FutureProvider.autoDispose<StockSummary>((ref) {
  return ref.watch(employeeRepositoryProvider).stockSummary();
});

/// Periode rekap keuangan yang sedang dilihat: today | week | month.
final financePeriodProvider = StateProvider<String>((_) => 'today');

final financeSummaryProvider = FutureProvider.autoDispose<FinanceSummary>((
  ref,
) {
  final period = ref.watch(financePeriodProvider);
  return ref.watch(employeeRepositoryProvider).finance(period);
});

final storeStatusProvider = FutureProvider.autoDispose<StoreStatus?>((ref) {
  return ref.watch(employeeRepositoryProvider).storeStatus();
});

// ── Manajemen stok ───────────────────────────────────────────────────────

/// Filter halaman stok: all | low | out.
final stockFilterProvider = StateProvider<String>((_) => 'all');

/// Daftar stok berhalaman.
///
/// Memuat-lebih-banyak dijaga [isLoadingMore] supaya scroll cepat tidak
/// meminta halaman yang sama dua kali.
class StockListState {
  final List<StockItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final int total;

  const StockListState({
    this.items = const [],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.total = 0,
  });

  StockListState copyWith({
    List<StockItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    int? total,
  }) => StockListState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    total: total ?? this.total,
  );
}

class StockListNotifier extends StateNotifier<AsyncValue<StockListState>> {
  StockListNotifier(this._repository, this._filter)
    : super(const AsyncValue.loading()) {
    load();
  }

  final EmployeeRepository _repository;
  final String _filter;
  int _page = 1;

  Future<void> load({bool forceRefresh = false}) async {
    _page = 1;
    try {
      final result = await _repository.stockList(
        filter: _filter,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      state = AsyncValue.data(
        StockListState(
          items: result.items,
          hasMore: result.hasMore,
          total: result.total,
        ),
      );
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    try {
      final next = await _repository.stockList(
        filter: _filter,
        page: _page + 1,
      );
      _page += 1;
      if (!mounted) return;
      state = AsyncValue.data(
        StockListState(
          items: [...current.items, ...next.items],
          hasMore: next.hasMore,
          total: next.total,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      state = AsyncValue.data(current.copyWith(isLoadingMore: false));
    }
  }
}

final stockListProvider =
    StateNotifierProvider.autoDispose<
      StockListNotifier,
      AsyncValue<StockListState>
    >((ref) {
      return StockListNotifier(
        ref.watch(employeeRepositoryProvider),
        ref.watch(stockFilterProvider),
      );
    });

final stockHistoryProvider =
    FutureProvider.autoDispose<Paginated<StockMovement>>((ref) {
      return ref.watch(employeeRepositoryProvider).stockHistory();
    });

// ── Aksi ─────────────────────────────────────────────────────────────────

/// Pesanan yang sedang diproses — mencegah ketukan ganda pada tombol tindakan.
final processingOrdersProvider = StateProvider<Set<String>>((_) => const {});

/// Menjalankan aksi operasional lalu menyegarkan hanya yang terdampak.
///
/// Memproses satu pesanan tidak boleh memuat ulang produk, riwayat stok, dan
/// AI sekaligus — yang berubah hanya pesanan itu dan KPI di atasnya.
class EmployeeActions {
  EmployeeActions(this._ref);

  final Ref _ref;

  Future<String?> advanceOrder(String orderId, String nextStatus) async {
    final busy = _ref.read(processingOrdersProvider);
    if (busy.contains(orderId)) return null;
    _ref.read(processingOrdersProvider.notifier).state = {...busy, orderId};

    try {
      await _ref
          .read(employeeRepositoryProvider)
          .updateOrderStatus(orderId, nextStatus);
      _ref.invalidate(todayOrdersProvider);
      _ref.invalidate(employeeSummaryProvider);
      return null;
    } catch (e) {
      return _message(e);
    } finally {
      final now = _ref.read(processingOrdersProvider);
      _ref.read(processingOrdersProvider.notifier).state = now
          .where((id) => id != orderId)
          .toSet();
    }
  }

  Future<String?> adjustStock({
    required String productId,
    required String type,
    required int quantity,
    required String reason,
  }) async {
    try {
      await _ref
          .read(employeeRepositoryProvider)
          .adjustStock(
            productId: productId,
            type: type,
            quantity: quantity,
            reason: reason,
          );
      _refreshStock();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> stockOpname({
    required String productId,
    required int countedStock,
    String? note,
  }) async {
    try {
      await _ref
          .read(employeeRepositoryProvider)
          .stockOpname(
            productId: productId,
            countedStock: countedStock,
            note: note,
          );
      _refreshStock();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  void _refreshStock() {
    _ref.invalidate(stockListProvider);
    _ref.invalidate(stockHistoryProvider);
    _ref.invalidate(stockSummaryProvider);
    _ref.invalidate(employeeSummaryProvider);
  }

  String _message(Object error) =>
      extractDioMessage(error, fallback: 'Tindakan gagal, coba lagi');
}

final employeeActionsProvider = Provider<EmployeeActions>(
  (ref) => EmployeeActions(ref),
);
