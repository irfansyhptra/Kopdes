import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/splash/presentation/screens/splash_loading_state.dart';
import 'package:kopdes/features/splash/presentation/screens/splash_sequence_manager.dart';

SplashSequenceManager _manager({
  Future<bool> Function()? checkHealth,
  Future<void> Function()? loadVillageData,
  Future<void> Function()? checkSession,
  Duration minimum = Duration.zero,
  Duration operationTimeout = const Duration(seconds: 1),
}) {
  return SplashSequenceManager(
    checkHealth: checkHealth ?? () async => true,
    loadVillageData: loadVillageData ?? () async {},
    checkSession: checkSession ?? () async {},
    warmupAI: () async {},
    prepareServices: () async {},
    minimumDisplayDuration: minimum,
    operationTimeout: operationTimeout,
  );
}

Future<void> _delayed([int ms = 120]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('SplashSequenceManager', () {
    // Inti P2: health, kategori, dan sesi tidak saling bergantung. Berantai
    // berarti total = penjumlahan; paralel berarti total = yang terlama.
    test('langkah 1-3 berjalan bersamaan, bukan berurutan', () async {
      final sw = Stopwatch()..start();

      final manager = _manager(
        checkHealth: () async {
          await _delayed();
          return true;
        },
        loadVillageData: _delayed,
        checkSession: _delayed,
      );

      await manager.start();
      await manager.done;
      sw.stop();

      // Berurutan ≈360ms, paralel ≈120ms. Ambang 300ms memberi ruang untuk
      // mesin CI yang lambat tanpa kehilangan daya bedanya.
      expect(
        sw.elapsedMilliseconds,
        lessThan(300),
        reason: 'total ${sw.elapsedMilliseconds}ms — masih terlihat berurutan',
      );
      expect(manager.finished, isTrue);
    });

    test('urutan pesan di layar tidak berubah', () async {
      final seen = <SplashLoadingState>[];
      final manager = _manager();
      manager.addListener(() => seen.add(manager.state));

      await manager.start();
      await manager.done;

      expect(seen.first, SplashLoadingState.connectingKoperasi);
      expect(
        seen,
        containsAllInOrder([
          SplashLoadingState.connectingKoperasi,
          SplashLoadingState.loadingVillageData,
          SplashLoadingState.checkingUserSession,
          SplashLoadingState.connectingAiAssistant,
          SplashLoadingState.preparingServices,
          SplashLoadingState.ready,
        ]),
      );
    });

    test('kegagalan health tidak menahan pengguna di splash', () async {
      final manager = _manager(
        checkHealth: () async {
          await _delayed(20);
          return false;
        },
        loadVillageData: () async {
          await _delayed(60);
          throw Exception('kategori gagal dimuat');
        },
        checkSession: () async {
          await _delayed(80);
          throw Exception('sesi gagal diperiksa');
        },
      );

      await manager.start();
      // Beri waktu future yang tersisa selesai dengan error.
      await _delayed(150);

      expect(manager.state, SplashLoadingState.ready);
      expect(manager.finished, isTrue);
    });

    test('gagal memuat kategori tetap melanjutkan aplikasi', () async {
      final manager = _manager(
        loadVillageData: () async => throw Exception('kategori gagal'),
      );

      await manager.start();

      expect(manager.state, SplashLoadingState.ready);
      expect(manager.finished, isTrue);
    });

    // Lantai durasi visual adalah keputusan desain — pastikan paralelisasi
    // tidak diam-diam memotongnya.
    test('durasi tampil minimum tetap dihormati', () async {
      final sw = Stopwatch()..start();
      final manager = _manager(minimum: const Duration(milliseconds: 400));

      await manager.start();
      await manager.done;
      sw.stop();

      expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(380));
    });

    test('future yang tidak selesai diputus oleh timeout', () async {
      final manager = _manager(
        checkHealth: () => Completer<bool>().future,
        loadVillageData: () => Completer<void>().future,
        checkSession: () => Completer<void>().future,
        operationTimeout: const Duration(milliseconds: 40),
      );

      await manager.start();
      await manager.done;
      expect(manager.finished, isTrue);
      expect(manager.state, SplashLoadingState.ready);
    });
  });
}
