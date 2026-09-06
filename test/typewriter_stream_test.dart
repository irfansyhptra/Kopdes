import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/ai_assistant/presentation/controllers/typewriter_stream.dart';

TypewriterStream _stream({int charsPerTick = 4}) => TypewriterStream(
  charsPerTick: charsPerTick,
  // Interval dipercepat supaya test tidak ikut menunggu 15ms per tick.
  interval: const Duration(milliseconds: 1),
);

void main() {
  group('TypewriterStream', () {
    test('mengeluarkan teks bertahap sampai utuh', () async {
      final stream = _stream();
      addTearDown(stream.dispose);

      const full = 'Halo, ini jawaban dari asisten KOPDES.';
      final snapshots = <String>[];
      stream.text.addListener(() => snapshots.add(stream.text.value));

      final done = Completer<void>();
      stream.start(full, onDone: done.complete);
      await done.future;

      expect(stream.text.value, full);
      expect(snapshots.length, greaterThan(1), reason: 'harus bertahap');
      // Tiap potongan adalah awalan dari teks penuh, tidak pernah melampaui.
      for (final s in snapshots) {
        expect(full.startsWith(s), isTrue, reason: 'potongan tak valid: "$s"');
      }
      expect(stream.isRunning, isFalse);
    });

    test('onTick dipanggil sekali per penambahan', () async {
      final stream = _stream(charsPerTick: 5);
      addTearDown(stream.dispose);

      var ticks = 0;
      final done = Completer<void>();
      stream.start(
        'a' * 20, // 20 karakter / 5 per tick = 4 tick
        onTick: () => ticks++,
        onDone: done.complete,
      );
      await done.future;

      expect(ticks, 4);
    });

    test('teks kosong langsung selesai tanpa menjalankan timer', () {
      final stream = _stream();
      addTearDown(stream.dispose);

      var doneCalled = false;
      stream.start('', onDone: () => doneCalled = true);

      expect(doneCalled, isTrue);
      expect(stream.isRunning, isFalse);
      expect(stream.text.value, '');
    });

    // Layar memanggil stop() saat percakapan dibersihkan atau mode diganti.
    // Kalau timer tetap hidup, ia akan menulis ke notifier pesan yang sudah
    // tidak ada lagi.
    test('stop() menghentikan aliran di tengah jalan', () async {
      final stream = _stream();
      addTearDown(stream.dispose);

      stream.start('a' * 400);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      stream.stop();

      final terhenti = stream.text.value;
      expect(stream.isRunning, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(stream.text.value, terhenti, reason: 'tidak boleh jalan lagi');
    });

    test('start() baru menggantikan aliran sebelumnya', () async {
      final stream = _stream();
      addTearDown(stream.dispose);

      stream.start('a' * 400);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final done = Completer<void>();
      stream.start('halo', onDone: done.complete);
      await done.future;

      expect(stream.text.value, 'halo');
      expect(stream.isRunning, isFalse);
    });

    test('stop() aman dipanggil saat tidak ada yang berjalan', () {
      final stream = _stream();
      addTearDown(stream.dispose);

      stream.stop();
      stream.stop();
      expect(stream.isRunning, isFalse);
    });

    test('dispose() mematikan timer yang masih berjalan', () async {
      final stream = _stream();
      stream.start('a' * 400);
      await Future<void>.delayed(const Duration(milliseconds: 5));

      stream.dispose();
      expect(stream.isRunning, isFalse);
      // Kalau timer masih hidup, ia akan menulis ke notifier yang sudah
      // dibuang dan test ini gagal dengan error.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  });
}
