import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stock_live_repository.dart';
import 'product_controller.dart';

/// Keadaan pemantauan stok.
class StockLiveState {
  /// Terbaru lebih dulu.
  final List<StockMovement> movements;
  final bool connected;
  final String? error;
  final DateTime? lastUpdate;

  const StockLiveState({
    this.movements = const [],
    this.connected = false,
    this.error,
    this.lastUpdate,
  });

  StockLiveState copyWith({
    List<StockMovement>? movements,
    bool? connected,
    String? error,
    bool clearError = false,
    DateTime? lastUpdate,
  }) => StockLiveState(
    movements: movements ?? this.movements,
    connected: connected ?? this.connected,
    error: clearError ? null : (error ?? this.error),
    lastUpdate: lastUpdate ?? this.lastUpdate,
  );
}

/// Pemantauan stok dengan penarikan berkala.
///
/// Bukan WebSocket: backend berjalan sebagai fungsi serverless di Vercel,
/// yang tidak menahan koneksi hidup-hidup. Yang bisa diandalkan adalah klien
/// bertanya berkala "apa yang berubah sejak penanda ini" — dan karena
/// jawabannya hampir selalu kosong, permintaannya murah.
///
/// Berhenti sendiri saat aplikasi ke latar belakang. Tanpa itu, ponsel di
/// saku menarik data tiap beberapa detik seharian — mahal di desa yang
/// kuotanya dihitung.
class StockLiveNotifier extends StateNotifier<StockLiveState>
    with WidgetsBindingObserver {
  final StockLiveRepository _repository;
  final Ref _ref;

  /// Sepuluh detik: cukup cepat untuk terasa hidup di layar yang sedang
  /// ditonton, cukup lambat untuk tidak menghabiskan kuota.
  static const Duration interval = Duration(seconds: 10);

  /// Riwayat yang ditahan di layar. Selebihnya ada di halaman riwayat.
  static const int maxMovements = 100;

  Timer? _timer;
  String? _cursor;
  bool _fetching = false;

  StockLiveNotifier(this._repository, this._ref)
    : super(const StockLiveState()) {
    WidgetsBinding.instance.addObserver(this);
    start();
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tick());
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      start();
    } else {
      stop();
    }
  }

  /// Satu putaran tarik.
  ///
  /// Dijaga [_fetching]: jaringan desa bisa membuat satu permintaan lebih
  /// lama dari jedanya, dan dua permintaan yang tumpang tindih akan memajukan
  /// penanda dua kali sehingga ada baris yang terlewat.
  Future<void> _tick() async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      var drained = 0;
      while (mounted && drained < 5) {
        final chunk = await _repository.fetch(since: _cursor);
        _cursor = chunk.cursor.isEmpty ? _cursor : chunk.cursor;

        if (chunk.movements.isNotEmpty) {
          _absorb(chunk.movements);
        }
        drained++;
        // Sisa yang terpotong batas ditarik segera, bukan menunggu putaran
        // berikutnya — kalau tidak, lonjakan penjualan tertinggal berjam-jam.
        if (!chunk.hasMore) break;
      }

      if (!mounted) return;
      state = state.copyWith(
        connected: true,
        clearError: true,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      // Daftar yang sudah ada dipertahankan: satu tarikan gagal bukan alasan
      // mengosongkan layar.
      state = state.copyWith(connected: false, error: e.toString());
    } finally {
      _fetching = false;
    }
  }

  void _absorb(List<StockMovement> incoming) {
    final seen = state.movements.map((m) => m.id).toSet();
    final fresh = incoming.where((m) => !seen.contains(m.id)).toList();
    if (fresh.isEmpty) return;

    // Terbaru di atas, lalu dipotong. Diurutkan menurut waktu, bukan
    // dibalik: tarikan pertama (tanpa penanda) datang terbaru-dulu, tarikan
    // susulan datang terlama-dulu — membalik keduanya sama rata menaruh
    // riwayat awal dalam urutan terbalik.
    final merged = [...fresh, ...state.movements]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = state.copyWith(
      movements: merged.length > maxMovements
          ? merged.sublist(0, maxMovements)
          : merged,
    );

    // Angka stok di daftar produk ikut menyusul — hanya baris yang
    // bergerak, terlama dulu supaya yang tersisa adalah angka terakhir.
    final list = _ref.read(sellerProductListProvider.notifier);
    for (final m
        in fresh.reversed.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt))) {
      if (m.productId != null && m.stockAfter != null) {
        list.applyStock(m.productId!, m.stockAfter!);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final stockLiveProvider =
    StateNotifierProvider<StockLiveNotifier, StockLiveState>((ref) {
      return StockLiveNotifier(ref.watch(stockLiveRepositoryProvider), ref);
    });
