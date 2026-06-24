import 'dart:async';
import 'package:flutter/foundation.dart';
import 'splash_loading_state.dart';

/// Drives the *content* side of the splash screen: which loading
/// message is shown and when initialization has actually finished.
/// This is intentionally separate from [SplashAnimationController],
/// which only drives the *visual* timeline. Keeping them independent
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
  });

  final Future<bool> Function() checkHealth;
  final Future<void> Function() loadVillageData;
  final Future<void> Function() checkSession;
  final Future<void> Function() warmupAI;
  final Future<void> Function() prepareServices;

  /// Splash will not finish before this, even if [initialize]
  /// resolves instantly -- this guarantees the full animation plays.
  final Duration minimumDisplayDuration;

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

    try {
      // 1. Menghubungkan Koperasi...
      final isHealthy = await checkHealth();
      if (!isHealthy) {
        throw Exception("Backend is unhealthy or connection failed");
      }

      // 2. Memuat Data Desa...
      _state = SplashLoadingState.loadingVillageData;
      notifyListeners();
      await loadVillageData();

      // 3. Memeriksa Sesi Pengguna...
      _state = SplashLoadingState.checkingUserSession;
      notifyListeners();
      await checkSession();

      // 4. Menghubungkan AI Assistant...
      _state = SplashLoadingState.connectingAiAssistant;
      notifyListeners();
      await warmupAI();

      // 5. Menyiapkan Layanan...
      _state = SplashLoadingState.preparingServices;
      notifyListeners();
      await prepareServices();

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
      debugPrint("Bootstrap error: $error\n$stack");
      _state = SplashLoadingState.unreachable;
      notifyListeners();
      // Do not call _complete() to prevent navigation.
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
