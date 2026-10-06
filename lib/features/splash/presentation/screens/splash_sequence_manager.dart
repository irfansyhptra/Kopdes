import 'dart:async';
import 'package:flutter/foundation.dart';
import 'splash_loading_state.dart';

/// Drives the *content* side of the splash screen: which loading
/// message is shown and when initialization has actually finished.
/// This is intentionally separate from the Lottie controller in the splash
/// screen, which only drives the *visual* timeline. Keeping them independent
/// means a slow backend never forces the logo animation to stall or
/// skip frames, and a fast backend never feels rushed -- the splash
/// always plays its minimum cinematic duration.
class SplashSequenceManager extends ChangeNotifier {
  SplashSequenceManager({
    required this.checkHealth,
    required this.loadVillageData,
    required this.checkSession,
    required this.warmupAI,
    required this.prepareServices,
    this.minimumDisplayDuration = const Duration(milliseconds: 3400),
    this.operationTimeout = const Duration(seconds: 8),
  });

  final Future<bool> Function() checkHealth;
  final Future<void> Function() loadVillageData;
  final Future<void> Function() checkSession;
  final Future<void> Function() warmupAI;
  final Future<void> Function() prepareServices;

  /// Splash will not finish before this, even if [initialize]
  /// resolves instantly -- this guarantees the full animation plays.
  final Duration minimumDisplayDuration;

  /// Batas tegas untuk setiap dependency bootstrap. Splash adalah presentasi,
  /// bukan health gate: jaringan atau layanan tambahan yang mati tidak boleh
  /// mengunci pengguna di layar pembuka.
  final Duration operationTimeout;

  SplashLoadingState _state = SplashLoadingState.connectingKoperasi;
  SplashLoadingState get state => _state;

  bool _finished = false;
  bool get finished => _finished;

  Completer<void> _doneCompleter = Completer<void>();
  Future<void> get done => _doneCompleter.future;

  Future<void> start() async {
    // Defers execution to the next event tick, preventing modifications
    // of provider states during the widget tree's build/initState cycle.
    await Future.delayed(Duration.zero);

    // Reset state on start (or restart)
    _state = SplashLoadingState.connectingKoperasi;
    _finished = false;
    if (_doneCompleter.isCompleted) {
      _doneCompleter = Completer<void>();
    }
    notifyListeners();
    final stopwatch = Stopwatch()..start();

    // Langkah 1-3 dijalankan BERSAMAAN, bukan berantai.
    //
    // Ketiganya tidak saling bergantung: health check, pengambilan kategori,
    // dan pembacaan token dari secure storage bisa berjalan sendiri-sendiri.
    // Sebelumnya masing-masing menunggu yang sebelumnya selesai, sehingga
    // total waktunya adalah PENJUMLAHAN — sekarang yang TERLAMA saja.
    //
    // Urutan pesan di layar tidak berubah sedikit pun: tiap `await` di bawah
    // langsung kembali kalau future-nya sudah selesai duluan.
    //
    // Setiap operasi dibungkus timeout dan penanganan error sendiri. Karena
    // future dimulai sebelum await pertama, ketiganya tetap paralel sekaligus
    // tidak dapat meninggalkan error tak tertangani.
    final healthFuture = _bestEffort(checkHealth, 'health');
    final villageFuture = _bestEffort(loadVillageData, 'kategori');
    final sessionFuture = _bestEffort(checkSession, 'sesi');

    try {
      // 1. Menghubungkan Koperasi...
      await healthFuture;

      // 2. Memuat Data Desa...
      _state = SplashLoadingState.loadingVillageData;
      notifyListeners();
      await villageFuture;

      // 3. Memeriksa Sesi Pengguna...
      _state = SplashLoadingState.checkingUserSession;
      notifyListeners();
      await sessionFuture;

      // 4. Menghubungkan AI Assistant...
      _state = SplashLoadingState.connectingAiAssistant;
      notifyListeners();
      await _bestEffort(warmupAI, 'AI');

      // 5. Menyiapkan Layanan...
      _state = SplashLoadingState.preparingServices;
      notifyListeners();
      await _bestEffort(prepareServices, 'layanan');

      // 6. Selamat Datang di KOPDES
      _state = SplashLoadingState.ready;
      notifyListeners();

      final elapsed = stopwatch.elapsed;
      final remaining = minimumDisplayDuration - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
      _complete();
    } catch (error, stack) {
      // Pertahanan terakhir. Semua operasi eksternal di atas sudah dibuat
      // best-effort, jadi kegagalan tak terduga pun tetap harus melepas splash.
      if (kDebugMode) debugPrint('Bootstrap internal error: $error\n$stack');
      _complete();
    }
  }

  Future<T?> _bestEffort<T>(
    Future<T> Function() operation,
    String label,
  ) async {
    try {
      return await operation().timeout(operationTimeout);
    } catch (error) {
      if (kDebugMode) debugPrint('Bootstrap $label dilewati: $error');
      return null;
    }
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    _state = SplashLoadingState.ready;
    notifyListeners();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }
}
