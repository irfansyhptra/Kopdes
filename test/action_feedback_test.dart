import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/core/error/failures.dart';
import 'package:kopdes/features/order/presentation/cart_feedback.dart';
import 'package:kopdes/shared/widgets/apple_feedback.dart';

/// Membangun satu tombol yang menjalankan [onTap] — persis bentuk pemakaian
/// di aplikasi: pengguna menekan sesuatu, lalu menunggu jaringan.
Future<void> _pumpButton(
  WidgetTester tester,
  Future<void> Function(BuildContext context) onTap,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => onTap(context),
              child: const Text('Tekan'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _tap(WidgetTester tester) async {
  await tester.tap(find.text('Tekan'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('runWithFeedback', () {
    testWidgets('modal tunggu muncul seketika dan bertahan selama menunggu', (
      tester,
    ) async {
      final gate = Completer<bool>();
      await _pumpButton(
        tester,
        (context) => runWithFeedback(
          context,
          waiting: 'Menambahkan ke keranjang…',
          action: () => gate.future,
        ),
      );
      await _tap(tester);

      expect(find.byType(AppleActivityIndicator), findsOneWidget);
      expect(find.text('Menambahkan ke keranjang…'), findsOneWidget);

      gate.complete(true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('berhasil: modal sukses lalu menutup sendiri', (tester) async {
      await _pumpButton(
        tester,
        (context) => runWithFeedback(
          context,
          waiting: 'Memproses…',
          action: () async => true,
          successTitle: 'Berhasil',
          successMessage: 'Sudah tersimpan.',
        ),
      );
      await _tap(tester);

      expect(find.text('Berhasil'), findsOneWidget);
      expect(find.text('Sudah tersimpan.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Berhasil'), findsNothing);
    });

    // Gagal TIDAK menutup sendiri: pesan yang hilang sebelum sempat dibaca
    // sama saja dengan tidak ada.
    testWidgets('gagal: modal bertahan sampai ditutup pengguna', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        (context) => runWithFeedback(
          context,
          waiting: 'Memproses…',
          action: () async => false,
          failureTitle: 'Gagal menambahkan',
          failureMessage: 'Beras Premium belum masuk keranjang.',
        ),
      );
      await _tap(tester);
      await tester.pumpAndSettle();

      expect(find.text('Gagal menambahkan'), findsOneWidget);
      expect(find.text('Beras Premium belum masuk keranjang.'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(
        find.text('Gagal menambahkan'),
        findsOneWidget,
        reason: 'bertahan',
      );

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Gagal menambahkan'), findsNothing);
    });

    testWidgets('lemparan jaringan jadi kalimat, bukan DioException', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        (context) => runWithFeedback(
          context,
          waiting: 'Memproses…',
          action: () async => throw DioException(
            requestOptions: RequestOptions(path: '/cart'),
            type: DioExceptionType.connectionError,
          ),
          failureTitle: 'Gagal',
        ),
      );
      await _tap(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('koneksi'), findsOneWidget);
      expect(find.textContaining('DioException'), findsNothing);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });

    testWidgets('pesan dari Failure dipakai apa adanya', (tester) async {
      await _pumpButton(
        tester,
        (context) => runWithFeedback(
          context,
          waiting: 'Memproses…',
          action: () async => throw const AuthFailure('Kata sandi salah.'),
          failureTitle: 'Gagal masuk',
        ),
      );
      await _tap(tester);
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi salah.'), findsOneWidget);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });

    testWidgets('onSuccess jalan setelah modal tunggu ditutup', (tester) async {
      var ran = false;
      await _pumpButton(
        tester,
        (context) => runWithFeedback(
          context,
          waiting: 'Memproses…',
          action: () async => true,
          onSuccess: () async => ran = true,
        ),
      );
      await _tap(tester);
      await tester.pumpAndSettle();

      expect(ran, isTrue);
      expect(find.byType(AppleActivityIndicator), findsNothing);
    });

    testWidgets('gagal tidak menjalankan onSuccess', (tester) async {
      var ran = false;
      await _pumpButton(
        tester,
        (context) => runWithFeedback(
          context,
          waiting: 'Memproses…',
          action: () async => false,
          failureTitle: 'Gagal',
          onSuccess: () async => ran = true,
        ),
      );
      await _tap(tester);
      await tester.pumpAndSettle();

      expect(ran, isFalse);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });
  });

  group('addToCartWithFeedback', () {
    testWidgets('menunggu, lalu menawarkan lihat keranjang', (tester) async {
      final gate = Completer<bool>();
      await _pumpButton(
        tester,
        (context) => addToCartWithFeedback(
          context,
          productName: 'Beras Premium',
          add: () => gate.future,
        ),
      );
      await _tap(tester);

      expect(find.text('Menambahkan ke keranjang…'), findsOneWidget);

      gate.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('Masuk keranjang'), findsOneWidget);
      expect(find.text('Beras Premium sudah ditambahkan.'), findsOneWidget);
      expect(find.text('Lihat Keranjang'), findsOneWidget);
      expect(find.text('Lanjut Belanja'), findsOneWidget);

      await tester.tap(find.text('Lanjut Belanja'));
      await tester.pumpAndSettle();
    });

    testWidgets('gagal menyebut produknya, bukan SnackBar yang lewat', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        (context) => addToCartWithFeedback(
          context,
          productName: 'Beras Premium',
          add: () async => false,
        ),
      );
      await _tap(tester);
      await tester.pumpAndSettle();

      expect(find.text('Gagal menambahkan'), findsOneWidget);
      expect(
        find.text('Beras Premium belum masuk keranjang. Coba lagi.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
    });
  });
}
