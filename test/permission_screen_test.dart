import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/onboarding/presentation/providers/permission_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kopdes/features/onboarding/presentation/screens/permission_screen.dart';

/**
 * Layar izin pertama.
 *
 * Yang diuji bukan tampilannya, melainkan dua hal yang bisa mengunci orang di
 * luar aplikasi: layar ini harus bisa dilewati tanpa mengizinkan apa pun, dan
 * setelah dilewati ia tidak boleh muncul lagi.
 */

const _channel = MethodChannel('flutter.baseflow.com/permissions/methods');

/// Status permission_handler: 0 = ditolak, 1 = diizinkan.
int _checkResult = 0;
int _requestResult = 1;
int _requestCount = 0;

void _mockPermissions() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, (call) async {
        switch (call.method) {
          case 'checkPermissionStatus':
            return _checkResult;
          case 'requestPermissions':
            _requestCount++;
            final ids = (call.arguments as List).cast<int>();
            return {for (final id in ids) id: _requestResult};
          case 'shouldShowRequestPermissionRationale':
            return false;
          case 'openAppSettings':
            return true;
          default:
            return null;
        }
      });
}

/// Layar tinggi supaya keempat kartu ikut terbentuk: `ListView` hanya membuat
/// elemen untuk bagian yang terlihat, jadi pada layar uji bawaan dua kartu
/// terakhir tidak pernah ada di pohon widget.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(420, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _app() => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const PermissionScreen(),
  ),
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
    _checkResult = 0;
    _requestResult = 1;
    _requestCount = 0;
    _mockPermissions();
  });

  testWidgets('menjelaskan ketiga izin, dan semuanya bisa dilewati', (
    tester,
  ) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final title in ['Notifikasi', 'Lokasi', 'Galeri']) {
      expect(find.text(title), findsOneWidget);
    }

    // Tidak ada satu pun dialog sistem yang muncul hanya karena layar dibuka:
    // membuka layar hanya membaca keadaan, tidak meminta.
    expect(_requestCount, 0);

    // Tombol lanjut selalu ada, tanpa syarat mengizinkan apa pun.
    expect(find.text('Lanjutkan'), findsOneWidget);
  });

  testWidgets('menekan Izinkan hanya meminta izin kartunya sendiri', (
    tester,
  ) async {
    _tallScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Izinkan'), findsNWidgets(3));

    await tester.tap(find.text('Izinkan').first);
    await tester.pumpAndSettle();

    expect(_requestCount, 1);
    // Yang sudah diizinkan kehilangan tombolnya; sisanya tetap ada.
    expect(find.text('Izinkan'), findsNWidgets(2));
  });

  testWidgets('Lanjutkan menutup layar, bukan menahan orang di dalamnya', (
    tester,
  ) async {
    _tallScreen(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PermissionScreen(),
                  ),
                ),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionScreen), findsOneWidget);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();
    expect(find.byType(PermissionScreen), findsNothing);
  });

  testWidgets('izin yang sudah diberikan tidak diminta ulang', (tester) async {
    _checkResult = 1;
    _tallScreen(tester);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Izinkan'), findsNothing);
    expect(_requestCount, 0);
  });

  /// Permintaan yang dijalankan begitu beranda terbuka — tanpa layar apa pun
  /// lebih dulu.
  group('requestStartupPermissions', () {
    test(
      'mengembalikan yang ditolak, dan kosong bila semuanya diberikan',
      () async {
        _requestResult = 1;
        expect(await requestStartupPermissions(), isEmpty);
        // Tiga izin, tiga permintaan.
        expect(_requestCount, 3);
      },
    );

    test('yang sudah diberikan tidak diminta ulang', () async {
      _checkResult = 1;
      expect(await requestStartupPermissions(), isEmpty);
      expect(_requestCount, 0);
    });

    test('yang ditolak dikembalikan sebagai daftar', () async {
      _requestResult = 0;
      final denied = await requestStartupPermissions();
      expect(denied, hasLength(3));
      expect(denied, containsAll(startupPermissions));
    });

    /// 4 = `PermissionStatus.permanentlyDenied`. `request()` pada keadaan ini
    /// kembali seketika tanpa dialog, jadi memanggilnya hanya menambah
    /// bolak-balik ke platform.
    test(
      'yang ditolak permanen tidak diminta ulang, tapi tetap terdata',
      () async {
        _checkResult = 4;
        final denied = await requestStartupPermissions();
        expect(denied, hasLength(3));
        expect(_requestCount, 0);
      },
    );
  });
}
