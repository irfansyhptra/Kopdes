import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kopdes/core/theme/theme.dart';
import 'package:kopdes/features/umkm/data/models/store_model.dart';
import 'package:kopdes/features/umkm/data/payout_repository.dart';
import 'package:kopdes/features/umkm/presentation/controllers/store_controller.dart';
import 'package:kopdes/features/umkm/presentation/screens/account_security_screen.dart';
import 'package:kopdes/features/umkm/presentation/screens/bank_account_screen.dart';
import 'package:kopdes/features/umkm/presentation/screens/store_edit_screen.dart';
import 'package:kopdes/features/umkm/presentation/screens/store_profile_screen.dart';
import 'package:kopdes/features/umkm/presentation/screens/store_settings_screen.dart';
import 'package:kopdes/features/umkm/presentation/screens/payout_history_screen.dart';
import 'package:kopdes/features/admin/presentation/screens/payout_queue_screen.dart';
import 'package:kopdes/features/umkm/presentation/widgets/withdraw_sheet.dart';

StoreModel _store({
  String status = 'ACTIVE',
  String name = 'Aceh Meutuah Swalayan',
  String description = 'Swalayan kebutuhan harian warga.',
  String address = 'Kec. Syiah Kuala, Banda Aceh',
  String phone = '081360000203',
  bool? isOpen = true,
  Map<String, DayHours?>? hours,
  bool noHours = false,
}) => StoreModel(
  id: 'umkm-1',
  businessName: name,
  description: description,
  address: address,
  phone: phone,
  status: status,
  isOpen: isOpen,
  operatingHours: noHours
      ? null
      : hours ??
            {for (final d in weekDays) d: const DayHours('07:00', '21:00')},
  kopdesName: 'Kopdes Lamgugop',
);

PayoutSummary _summary({
  double available = 0,
  bool bank = true,
  bool canWithdraw = false,
  List<PayoutBlocker> blockers = const [
    PayoutBlocker(
      'BELOW_MINIMUM',
      'Saldo tersedia minimal Rp50.000 untuk ditarik.',
    ),
  ],
}) => PayoutSummary(
  available: available,
  held: 38000,
  pendingPayout: 0,
  paidOut: 0,
  completedGross: 0,
  completedFee: 0,
  openOrderCount: 2,
  openOrderAmount: 57000,
  feePercent: 5,
  minWithdrawal: 50000,
  bankAccount: bank
      ? const BankAccountInfo(
          bankName: 'BSI',
          accountNumber: '•••• 6789',
          accountHolder: 'Siti',
        )
      : null,
  canWithdraw: canWithdraw,
  blockers: canWithdraw ? const [] : blockers,
);

Future<GoRouter> _pump(
  WidgetTester tester, {
  required Future<StoreModel> Function() store,
  required Future<PayoutSummary> Function() summary,
  double width = 390,
  double scale = 1.0,
}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Widget stub(String name) => Scaffold(body: Text('rute $name'));
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const StoreProfileScreen()),
      GoRoute(
        path: '/umkm/store/:page',
        builder: (_, s) => stub(s.pathParameters['page']!),
      ),
      GoRoute(
        path: '/info/:slug',
        builder: (_, s) => stub('info ${s.pathParameters['slug']}'),
      ),
      GoRoute(
        path: '/mitra/:id',
        builder: (_, s) => stub('mitra ${s.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storeProfileProvider.overrideWith((ref) => store()),
        payoutSummaryProvider.overrideWith((ref) => summary()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return router;
}

DioException _offline() => DioException(
  requestOptions: RequestOptions(path: '/seller/payouts/summary'),
  type: DioExceptionType.connectionError,
);

void main() {
  group('data & aturan', () {
    test('ringkasan saldo dibaca dari server, termasuk alasan & rekening', () {
      final s = PayoutSummary.fromJson({
        'available': 45000,
        'held': '38000',
        'pendingPayout': 0,
        'openOrders': {'count': 2, 'amount': 57000},
        'feePercent': 5,
        'minWithdrawal': 50000,
        'bankAccount': {
          'bankName': 'BSI',
          'accountNumberMasked': '•••• 6789',
          'accountHolder': 'Siti',
        },
        'canWithdraw': false,
        'blockers': [
          {'code': 'BELOW_MINIMUM', 'message': 'min'},
        ],
      });
      expect(s.available, 45000);
      expect(s.held, 38000);
      expect(s.openOrderCount, 2);
      expect(s.bankAccount!.accountNumber, '•••• 6789');
      expect(s.blockedBy('BELOW_MINIMUM'), isTrue);
    });

    test('jam buka & status buka dari profil', () {
      final s = StoreModel.fromJson({
        'id': 'u',
        'businessName': 'AR Kopi',
        'status': 'ACTIVE',
        'isOpen': false,
        'operatingHours': {
          'mon': {'open': '07:00', 'close': '21:00'},
          'sun': null,
        },
        'kopdes': {'name': 'Kopdes Prada'},
      });
      expect(s.isOpen, isFalse);
      expect(s.operatingHours!['mon'], const DayHours('07:00', '21:00'));
      expect(s.operatingHours!['sun'], isNull);
      expect(s.kopdesName, 'Kopdes Prada');
      expect(StoreModel.fromJson({'id': 'u'}).operatingHours, isNull);
    });

    test('ringkasan kontak: hari ini, atau null bila kosong semua', () {
      final monday = DateTime(2026, 10, 5);
      expect(
        contactSummary(_store(), now: monday),
        '081360000203 · Buka 07.00–21.00 hari ini',
      );
      expect(
        contactSummary(_store(hours: {'mon': null}), now: monday),
        '081360000203 · Tutup hari ini',
      );
      expect(contactSummary(_store(phone: '', noHours: true)), isNull);
    });

    test('nominal tarik: minimum, maksimum, angka', () {
      final s = _summary(available: 120000, canWithdraw: true);
      expect(validateWithdrawal('', s), isNotNull);
      expect(validateWithdrawal('40000', s), contains('Minimal'));
      expect(validateWithdrawal('130000', s), contains('hanya'));
      expect(validateWithdrawal('120000', s), isNull);
    });

    test('profil, rekening, dan kata sandi', () {
      expect(StoreProfileRules.name('ab'), isNotNull);
      expect(StoreProfileRules.phone('0812 3456 789'), isNull);
      expect(StoreProfileRules.phone('12345'), isNotNull);
      expect(BankAccountRules.number('7123-456-789'), isNull);
      expect(BankAccountRules.number('12ab'), isNotNull);
      expect(validateNewPassword('pendek1'), isNotNull);
      expect(validateNewPassword('hanyahuruf'), isNotNull);
      expect(validateNewPassword('Kopdes123'), isNull);
    });
  });

  group('halaman Toko Anda', () {
    testWidgets('toko terverifikasi: badge, status buka, Lihat toko', (
      t,
    ) async {
      await _pump(
        t,
        store: () async => _store(),
        summary: () async => _summary(),
      );
      expect(find.text('Toko terverifikasi'), findsOneWidget);
      expect(find.text('Buka sekarang'), findsOneWidget);
      await t.tap(find.text('Lihat toko'));
      await t.pumpAndSettle();
      expect(find.text('rute mitra umkm-1'), findsOneWidget);
    });

    testWidgets(
      'belum terverifikasi: tidak ada badge "terverifikasi" atau Lihat toko',
      (t) async {
        await _pump(
          t,
          store: () async => _store(status: 'PENDING_VERIFICATION'),
          summary: () async => _summary(),
        );
        expect(find.text('Menunggu verifikasi'), findsOneWidget);
        expect(find.text('Toko terverifikasi'), findsNothing);
        expect(find.text('Lihat toko'), findsNothing);
      },
    );

    testWidgets(
      'saldo nol tanpa rekening: tombol mati + alasan + jalan keluar',
      (t) async {
        await _pump(
          t,
          store: () async => _store(),
          summary: () async => _summary(
            bank: false,
            blockers: const [
              PayoutBlocker(
                'NO_BANK_ACCOUNT',
                'Isi rekening pencairan lebih dulu.',
              ),
              PayoutBlocker(
                'BELOW_MINIMUM',
                'Saldo tersedia minimal Rp50.000 untuk ditarik.',
              ),
            ],
          ),
        );
        expect(find.text('Rp0'), findsOneWidget);
        final button = t.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Tarik saldo'),
        );
        expect(button.onPressed, isNull);
        expect(find.text('Isi rekening pencairan lebih dulu.'), findsOneWidget);
        expect(
          find.text('Rp38.000'),
          findsOneWidget,
          reason: 'tertahan terpisah',
        );
        await t.tap(find.text('Isi rekening'));
        await t.pumpAndSettle();
        expect(find.text('rute bank-account'), findsOneWidget);
      },
    );

    testWidgets(
      'saldo cukup: Tarik membuka lembar dengan nominal tervalidasi',
      (t) async {
        await _pump(
          t,
          store: () async => _store(),
          summary: () async => _summary(available: 120000, canWithdraw: true),
        );
        await t.tap(find.widgetWithText(FilledButton, 'Tarik saldo'));
        await t.pumpAndSettle();
        expect(find.text('Ajukan Pencairan'), findsOneWidget);
        expect(find.text('120.000'), findsOneWidget, reason: 'terisi saldo');
        await t.enterText(find.byType(TextField), '40000');
        await t.pump();
        expect(find.text('Minimal Rp50.000.'), findsOneWidget);
      },
    );

    testWidgets('profil belum lengkap → "Lengkapi informasi"', (t) async {
      await _pump(
        t,
        store: () async =>
            _store(description: '', address: '', phone: '', noHours: true),
        summary: () async => _summary(),
      );
      expect(find.text('Lengkapi informasi'), findsNWidgets(3));
    });

    testWidgets('saldo gagal dimuat: profil tetap tampil, saldo bukan Rp0', (
      t,
    ) async {
      await _pump(
        t,
        store: () async => _store(),
        summary: () => Future.error(_offline()),
      );
      expect(find.text('Aceh Meutuah Swalayan'), findsOneWidget);
      expect(find.textContaining('Saldo belum termuat'), findsOneWidget);
      expect(find.text('Rp0'), findsNothing);
      expect(find.text('Coba Lagi'), findsOneWidget);
    });

    testWidgets('tiap menu Kelola toko menuju rutenya', (t) async {
      final router = await _pump(
        t,
        store: () async => _store(),
        summary: () async => _summary(),
      );
      final expected = {
        'Rekening pencairan': '/umkm/store/bank-account',
        'Pengaturan toko': '/umkm/store/settings',
        'Pusat bantuan': '/info/bantuan-penjual',
        'Keamanan akun': '/umkm/store/security',
        'Riwayat': '/umkm/store/payouts',
        'Edit': '/umkm/store/edit',
      };
      for (final e in expected.entries) {
        await t.scrollUntilVisible(find.text(e.key), 200);
        await t.tap(find.text(e.key));
        await t.pumpAndSettle();
        expect(router.state.uri.path, e.value, reason: e.key);
        router.pop();
        await t.pumpAndSettle();
      }
    });

    for (final w in [320.0, 360.0, 390.0, 430.0, 768.0]) {
      for (final s in [1.0, 1.5, 2.0]) {
        testWidgets('tidak meluber ${w.toInt()}dp ${s}x', (t) async {
          await _pump(
            t,
            width: w,
            scale: s,
            store: () async => _store(
              status: 'REJECTED',
              name:
                  'Usaha Dagang Keluarga Besar Teungku Haji Abdullah Syiah Kuala',
              address:
                  'Jl. Teuku Nyak Arief No. 441, Gampong Lamgugop, Kec. Syiah '
                  'Kuala, Kota Banda Aceh, Aceh 23115',
              isOpen: null,
            ),
            summary: () async => _summary(
              available: 1234567890,
              bank: false,
              blockers: const [
                PayoutBlocker(
                  'NO_BANK_ACCOUNT',
                  'Isi rekening pencairan lebih dulu.',
                ),
              ],
            ),
          );
          expect(t.takeException(), isNull);
        });
      }
    }
  });

  group('halaman turunan', () {
    final payout = Payout(
      id: 'p1',
      amount: 1250000,
      status: PayoutStatus.rejected,
      bankName: 'Bank Aceh Syariah',
      accountNumber: '7123456789012345',
      accountHolder: 'Teungku Haji Abdullah bin Muhammad Syiah Kuala',
      requestedAt: DateTime(2026, 10, 4, 16, 20),
      rejectionReason: 'Nama pemilik rekening tidak sesuai dengan nama usaha',
      umkmName: 'Usaha Dagang Keluarga Besar Teungku Haji Abdullah',
    );

    Widget host(Widget page) => ProviderScope(
      overrides: [
        storeProfileProvider.overrideWith((ref) async => _store()),
        bankAccountProvider.overrideWith((ref) async => null),
        payoutListProvider.overrideWith(
          (ref, key) => _FixedList([payout, payout]),
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: page),
    );

    final pages = <String, Widget Function()>{
      'pengaturan': () => const StoreSettingsScreen(),
      'edit': () => const StoreEditScreen(),
      'rekening': () => const BankAccountScreen(),
      'keamanan': () => const AccountSecurityScreen(),
      'riwayat': () => const PayoutHistoryScreen(),
      'antrean admin': () => const Scaffold(body: PayoutQueueScreen()),
      'lembar tarik': () => Scaffold(
        body: WithdrawSheet(
          summary: _summary(available: 1234567890, canWithdraw: true),
        ),
      ),
    };

    for (final e in pages.entries) {
      for (final (w, sc) in [(320.0, 2.0), (360.0, 1.5), (390.0, 1.0)]) {
        testWidgets('${e.key} tidak meluber ${w.toInt()}dp ${sc}x', (t) async {
          t.view.physicalSize = Size(w, 1400);
          t.view.devicePixelRatio = 1.0;
          addTearDown(t.view.reset);
          await t.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: Size(w, 1400),
                textScaler: TextScaler.linear(sc),
              ),
              child: host(e.value()),
            ),
          );
          await t.pump();
          await t.pump();
          expect(t.takeException(), isNull);
        });
      }
    }

    testWidgets('jam buka: hari tutup disebut dengan kata', (t) async {
      await t.pumpWidget(host(const StoreSettingsScreen()));
      await t.pump();
      await t.tap(find.byType(Switch).first);
      await t.pump();
      expect(find.text('Tutup'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
    });
  });
}

/// Daftar pencairan tetap — tanpa jaringan.
class _FixedList extends PayoutListNotifier {
  _FixedList(List<Payout> items)
    : super(const PayoutRepository(_NoDio()), (admin: false, status: null)) {
    state = AsyncValue.data(PayoutListState(items: items, hasMore: false));
  }

  @override
  Future<void> load() async {}
}

class _NoDio implements Dio {
  const _NoDio();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
