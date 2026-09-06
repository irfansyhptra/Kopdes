import 'dart:async';

import 'package:flutter/foundation.dart';

/// Mengalirkan teks karakter demi karakter untuk efek mengetik.
///
/// Dipisahkan dari layarnya karena dua alasan:
///
/// 1. **Rebuild.** Teks berjalan lewat [text] sebagai [ValueNotifier], jadi
///    hanya widget yang mendengarkannya yang dibangun ulang. Sebelumnya ini
///    `setState()` di dalam `Timer.periodic(15ms)`, yang membangun ulang
///    seluruh layar AI Assistant ±66 kali per detik.
/// 2. **Pengujian.** Logika maju-karakter, penghentian, dan pembersihan timer
///    bisa diuji tanpa perlu merender layar 2.000 baris beserta jaringannya.
class TypewriterStream {
  TypewriterStream({
    this.charsPerTick = 4,
    this.interval = const Duration(milliseconds: 15),
  }) : assert(charsPerTick > 0);

  /// Karakter yang ditambahkan tiap tick.
  final int charsPerTick;

  /// Jeda antar tick.
  final Duration interval;

  /// Teks yang sudah tampil sejauh ini.
  final ValueNotifier<String> text = ValueNotifier<String>('');

  Timer? _timer;
  bool _disposed = false;

  /// True selama masih ada teks yang mengalir.
  bool get isRunning => _timer != null;

  /// Mulai mengalirkan [full].
  ///
  /// [onTick] dipanggil tiap kali teks bertambah — dipakai untuk mengikuti
  /// dasar daftar. [onDone] dipanggil sekali setelah karakter terakhir.
  /// Memanggil ini saat aliran lain berjalan akan menggantikannya.
  void start(String full, {VoidCallback? onTick, VoidCallback? onDone}) {
    assert(!_disposed, 'TypewriterStream sudah dibuang');
    stop();

    if (full.isEmpty) {
      text.value = '';
      onDone?.call();
      return;
    }

    var index = 0;
    text.value = '';

    _timer = Timer.periodic(interval, (timer) {
      index += charsPerTick;
      final done = index >= full.length;
      if (done) index = full.length;

      text.value = full.substring(0, index);
      onTick?.call();

      if (done) {
        stop();
        onDone?.call();
      }
    });
  }

  /// Hentikan aliran. Teks yang sudah tampil dibiarkan apa adanya.
  ///
  /// Aman dipanggil berkali-kali, termasuk saat tidak ada yang berjalan.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    text.dispose();
    _disposed = true;
  }
}
