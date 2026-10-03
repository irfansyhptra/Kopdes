import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/shared/widgets/apple_feedback.dart';

/**
 * Overlay umpan balik tindakan.
 *
 * Yang diuji di sini urutannya, bukan tampilannya: memuat → hasil → tertutup.
 * Overlay yang tidak pernah tertutup mengunci seluruh layar, dan itu kegagalan
 * yang jauh lebih besar daripada pesan yang kurang rapi.
 */

Future<AppleFeedback> _open(WidgetTester tester, String message) async {
  late AppleFeedback feedback;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => feedback = AppleFeedback.show(context, message),
              child: const Text('mulai'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('mulai'));
  await tester.pump();
  return feedback;
}

void main() {
  testWidgets('menampilkan pesan dan indikator selama menunggu', (
    tester,
  ) async {
    final feedback = await _open(tester, 'Sedang masuk…');

    expect(find.text('Sedang masuk…'), findsOneWidget);
    expect(find.byType(AppleActivityIndicator), findsOneWidget);
    // Belum ada hasil, jadi belum ada ikon centang/silang.
    expect(find.byType(AppleStatusIcon), findsNothing);

    // Indikatornya berputar tanpa henti — itu memang tugasnya — jadi overlay
    // ditutup dulu sebelum `pumpAndSettle`, yang kalau tidak takkan pernah
    // menemukan keadaan diam.
    feedback.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('berhasil: berganti jadi centang lalu menutup sendiri', (
    tester,
  ) async {
    final feedback = await _open(tester, 'Sedang mendaftar…');

    final done = feedback.success('Pendaftaran berhasil', 'Selamat datang.');
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Pendaftaran berhasil'), findsOneWidget);
    expect(find.text('Selamat datang.'), findsOneWidget);
    expect(find.byType(AppleStatusIcon), findsOneWidget);
    expect(find.byType(AppleActivityIndicator), findsNothing);

    // Menutup sendiri setelah jeda baca, tanpa ketukan.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    await done;

    expect(find.byType(AppleStatusIcon), findsNothing);
    expect(find.text('Pendaftaran berhasil'), findsNothing);
  });

  testWidgets('gagal: bertahan sampai ditutup, tidak hilang sendiri', (
    tester,
  ) async {
    final feedback = await _open(tester, 'Sedang masuk…');

    final done = feedback.failure('Gagal masuk', 'Email atau password salah');
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Gagal masuk'), findsOneWidget);
    expect(find.text('Email atau password salah'), findsOneWidget);

    // Pesan gagal yang hilang sendiri sebelum sempat dibaca sama saja dengan
    // tidak ada, jadi ia harus masih di layar setelah jeda sukses lewat.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Gagal masuk'), findsOneWidget);

    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    await done;

    expect(find.text('Gagal masuk'), findsNothing);
  });

  testWidgets('dismiss menutup tanpa menampilkan hasil apa pun', (
    tester,
  ) async {
    final feedback = await _open(tester, 'Sedang memuat…');

    feedback.dismiss();
    await tester.pumpAndSettle();

    expect(find.text('Sedang memuat…'), findsNothing);
    expect(find.byType(AppleStatusIcon), findsNothing);
  });

  group('Modal hasil tindakan', () {
    Future<void> open(
      WidgetTester tester, {
      required void Function() onPrimary,
      void Function()? onSecondary,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAppleActionDialog<void>(
                    context,
                    title: 'Masuk keranjang',
                    message: 'Kopi Arabika Gayo sudah ditambahkan.',
                    primaryLabel: 'Lihat Keranjang',
                    onPrimary: onPrimary,
                    secondaryLabel: onSecondary == null
                        ? null
                        : 'Lanjut Belanja',
                    onSecondary: onSecondary,
                  ),
                  child: const Text('tambah'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('tambah'));
      await tester.pumpAndSettle();
    }

    testWidgets('menampilkan judul, pesan, dan kedua pilihan', (tester) async {
      await open(tester, onPrimary: () {}, onSecondary: () {});

      expect(find.text('Masuk keranjang'), findsOneWidget);
      expect(find.text('Kopi Arabika Gayo sudah ditambahkan.'), findsOneWidget);
      expect(find.text('Lihat Keranjang'), findsOneWidget);
      expect(find.text('Lanjut Belanja'), findsOneWidget);
      expect(find.byType(AppleStatusIcon), findsOneWidget);
    });

    testWidgets('tombol utama memanggil callback-nya', (tester) async {
      var tapped = false;
      await open(tester, onPrimary: () => tapped = true, onSecondary: () {});
      await tester.tap(find.text('Lihat Keranjang'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('tombol kedua memanggil callback-nya', (tester) async {
      var tapped = false;
      await open(tester, onPrimary: () {}, onSecondary: () => tapped = true);
      await tester.tap(find.text('Lanjut Belanja'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('tanpa pilihan kedua, hanya satu tombol digambar', (
      tester,
    ) async {
      await open(tester, onPrimary: () {});
      expect(find.text('Lihat Keranjang'), findsOneWidget);
      expect(find.text('Lanjut Belanja'), findsNothing);
    });
  });
}
