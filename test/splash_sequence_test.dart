import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/splash/presentation/screens/splash_loading_state.dart';
import 'package:kopdes/features/splash/presentation/screens/splash_sequence_manager.dart';

SplashSequenceManager _manager({
  Future<bool> Function()? checkHealth,
  Future<void> Function()? loadVillageData,
  Future<void> Function()? checkSession,
  Duration minimum = Duration.zero,
}) {
  return SplashSequenceManager(
    checkHealth: checkHealth ?? () async => true,
    loadVillageData: loadVillageData ?? () async {},
    checkSession: checkSession ?? () async {},
    warmupAI: () async {},
    prepareServices: () async {},
    minimumDisplayDuration: minimum,
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

    // Kalau health gagal duluan, dua future lain sudah terlanjur berjalan dan
    // bisa ikut gagal. Tanpa penanganan, error mereka jadi unhandled dan
    // mematikan zone-nya. Test ini gagal kalau itu terjadi.
    test('kegagalan health tidak meninggalkan error tak tertangani', () async {
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

      expect(manager.state, SplashLoadingState.unreachable);
      expect(manager.finished, isFalse, reason: 'tidak boleh navigasi');
    });

    test('gagal memuat kategori juga berakhir di unreachable', () async {
      final manager = _manager(
        loadVillageData: () async => throw Exception('kategori gagal'),
      );

      await manager.start();

      expect(manager.state, SplashLoadingState.unreachable);
      expect(manager.finished, isFalse);
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

    test('start() bisa dipanggil ulang untuk tombol coba lagi', () async {
      var attempt = 0;
      final manager = _manager(
        checkHealth: () async {
          attempt++;
          return attempt > 1; // gagal sekali, lalu berhasil
        },
      );

      await manager.start();
      expect(manager.state, SplashLoadingState.unreachable);

      await manager.start();
      await manager.done;
      expect(manager.finished, isTrue);
      expect(attempt, 2);
    });
  });
}
