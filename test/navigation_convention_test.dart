import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Rute yang menjadi branch [StatefulShellRoute] di `core/routing/router.dart`.
///
/// Menuju branch dengan `context.push()` menumpuk halaman penuh di root
/// navigator alih-alih berpindah branch: bilah navigasi mengambang hilang, dan
/// Marketplace muncul sebagai halaman terpisah yang tampak seperti beranda
/// desain lama karena memakai header dan kartu anggota yang sama.
///
/// Ini pernah terjadi, jadi dikunci di sini.
const _branchRoutes = [
  '/home',
  '/products',
  '/ai-assistant',
  '/cart',
  '/profile',
];

Iterable<File> _dartFiles(Directory dir) => dir
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where((f) => !f.path.endsWith('.g.dart'))
    .where((f) => !f.path.endsWith('.freezed.dart'));

void main() {
  test('branch shell dituju dengan go(), bukan push()', () {
    final offenders = <String>[];

    for (final file in _dartFiles(Directory('lib'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final route in _branchRoutes) {
          if (lines[i].contains("push('$route')")) {
            offenders.add('${file.path}:${i + 1} → $route');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Rute berikut adalah branch StatefulShellRoute dan harus memakai '
          'context.go(), bukan context.push():\n${offenders.join('\n')}',
    );
  });

  test('daftar branch di test ini masih cocok dengan router', () {
    final router = File('lib/core/routing/router.dart').readAsStringSync();

    // Kalau branch baru ditambahkan tanpa memperbarui _branchRoutes, penjaga
    // di atas diam-diam berhenti melindungi rute itu.
    final branchCount = 'StatefulShellBranch('.allMatches(router).length;
    expect(
      branchCount,
      _branchRoutes.length,
      reason:
          'router.dart punya $branchCount branch, tapi _branchRoutes berisi '
          '${_branchRoutes.length}. Perbarui daftarnya.',
    );

    for (final route in _branchRoutes) {
      expect(
        router.contains("path: '$route'"),
        isTrue,
        reason: '$route tidak ditemukan di router.dart',
      );
    }
  });
}
