import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/paginated.dart';

double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class PayoutBlocker {
  /// NOT_VERIFIED, NO_BANK_ACCOUNT, PENDING_REQUEST, BELOW_MINIMUM.
  final String code;
  final String message;

  const PayoutBlocker(this.code, this.message);
}

class BankAccountInfo {
  final String bankName;

  /// Lengkap di halaman rekening, tersamar ("•••• 6789") di ringkasan.
  final String accountNumber;
  final String accountHolder;

  const BankAccountInfo({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  static BankAccountInfo? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return BankAccountInfo(
      bankName: json['bankName'] as String? ?? '',
      accountNumber:
          (json['accountNumber'] ?? json['accountNumberMasked']) as String? ??
          '',
      accountHolder: json['accountHolder'] as String? ?? '',
    );
  }
}

/// Saldo toko — dihitung server dari pesanan, tidak pernah di aplikasi.
class PayoutSummary {
  /// Bisa ditarik: pesanan selesai − fee − pencairan diajukan/dibayar.
  final double available;

  /// Sudah dibayar pembeli, menunggu pesanannya selesai.
  final double held;

  /// Pencairan yang sedang diproses pengurus.
  final double pendingPayout;
  final double paidOut;
  final double completedGross;
  final double completedFee;
  final int openOrderCount;
  final double openOrderAmount;
  final double feePercent;
  final double minWithdrawal;
  final BankAccountInfo? bankAccount;
  final bool canWithdraw;
  final List<PayoutBlocker> blockers;

  const PayoutSummary({
    required this.available,
    required this.held,
    required this.pendingPayout,
    required this.paidOut,
    required this.completedGross,
    required this.completedFee,
    required this.openOrderCount,
    required this.openOrderAmount,
    required this.feePercent,
    required this.minWithdrawal,
    required this.bankAccount,
    required this.canWithdraw,
    required this.blockers,
  });

  bool blockedBy(String code) => blockers.any((b) => b.code == code);

  factory PayoutSummary.fromJson(Map<String, dynamic> j) {
    final open = j['openOrders'] as Map<String, dynamic>? ?? const {};
    return PayoutSummary(
      available: _num(j['available']),
      held: _num(j['held']),
      pendingPayout: _num(j['pendingPayout']),
      paidOut: _num(j['paidOut']),
      completedGross: _num(j['completedGross']),
      completedFee: _num(j['completedFee']),
      openOrderCount: (open['count'] as num?)?.toInt() ?? 0,
      openOrderAmount: _num(open['amount']),
      feePercent: _num(j['feePercent']),
      minWithdrawal: _num(j['minWithdrawal']),
      bankAccount: BankAccountInfo.fromJson(j['bankAccount']),
      canWithdraw: j['canWithdraw'] == true,
      blockers: [
        for (final b in (j['blockers'] as List? ?? const []))
          if (b is Map<String, dynamic>)
            PayoutBlocker(
              b['code'] as String? ?? '',
              b['message'] as String? ?? '',
            ),
      ],
    );
  }
}

enum PayoutStatus {
  requested('REQUESTED', 'Diproses'),
  paid('PAID', 'Sudah ditransfer'),
  rejected('REJECTED', 'Ditolak');

  final String wire;
  final String label;
  const PayoutStatus(this.wire, this.label);

  static PayoutStatus parse(Object? v) => PayoutStatus.values.firstWhere(
    (s) => s.wire == v,
    orElse: () => PayoutStatus.requested,
  );
}

class Payout {
  final String id;
  final double amount;
  final PayoutStatus status;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? transferRef;
  final String? rejectionReason;

  /// Hanya di antrean admin.
  final String? umkmName;
  final String? umkmPhone;

  const Payout({
    required this.id,
    required this.amount,
    required this.status,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    required this.requestedAt,
    this.processedAt,
    this.transferRef,
    this.rejectionReason,
    this.umkmName,
    this.umkmPhone,
  });

  factory Payout.fromJson(Map<String, dynamic> j) {
    final umkm = j['umkm'] as Map<String, dynamic>?;
    return Payout(
      id: j['id'] as String? ?? '',
      amount: _num(j['amount']),
      status: PayoutStatus.parse(j['status']),
      bankName: j['bankName'] as String? ?? '',
      accountNumber: j['accountNumber'] as String? ?? '',
      accountHolder: j['accountHolder'] as String? ?? '',
      requestedAt:
          DateTime.tryParse('${j['requestedAt']}')?.toLocal() ?? DateTime.now(),
      processedAt: DateTime.tryParse('${j['processedAt']}')?.toLocal(),
      transferRef: j['transferRef'] as String?,
      rejectionReason: j['rejectionReason'] as String?,
      umkmName: umkm?['businessName'] as String?,
      umkmPhone: umkm?['phone'] as String?,
    );
  }
}

/// Klien saldo & pencairan penjual, serta antrean admin Kopdes.
///
/// Tanpa `cachedFetch`, sengaja — sama alasannya dengan dompet: saldo basi
/// yang tampil seolah terkini adalah angka yang dipakai orang untuk
/// memutuskan menarik uang.
class PayoutRepository {
  final Dio dio;
  const PayoutRepository(this.dio);

  Map<String, dynamic> _data(Response<dynamic> r) =>
      ((r.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?) ??
      const {};

  Future<PayoutSummary> summary() async =>
      PayoutSummary.fromJson(_data(await dio.get('/seller/payouts/summary')));

  Future<Paginated<Payout>> history({int page = 1, int limit = 20}) async =>
      Paginated.fromJson(
        _data(
          await dio.get(
            '/seller/payouts',
            queryParameters: {'page': page, 'limit': limit},
          ),
        ),
        'payouts',
        Payout.fromJson,
      );

  /// POST tidak diulang diam-diam (lihat RetryInterceptor): timeout bukan
  /// berarti ditolak, dan backend menolak pengajuan kedua selama yang
  /// pertama masih diproses.
  Future<Payout> request(int amount) async => Payout.fromJson(
    _data(await dio.post('/seller/payouts', data: {'amount': amount})),
  );

  Future<BankAccountInfo?> bankAccount() async {
    final r = await dio.get('/seller/bank-account');
    return BankAccountInfo.fromJson((r.data as Map<String, dynamic>)['data']);
  }

  Future<BankAccountInfo> saveBankAccount({
    required String bankName,
    required String accountNumber,
    required String accountHolder,
  }) async => BankAccountInfo.fromJson(
    _data(
      await dio.put(
        '/seller/bank-account',
        data: {
          'bankName': bankName,
          'accountNumber': accountNumber,
          'accountHolder': accountHolder,
        },
      ),
    ),
  )!;

  // ── Admin Kopdes ──

  Future<Paginated<Payout>> adminList({
    required PayoutStatus? status,
    int page = 1,
    int limit = 20,
  }) async => Paginated.fromJson(
    _data(
      await dio.get(
        '/admin/payouts',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status.wire,
        },
      ),
    ),
    'payouts',
    Payout.fromJson,
  );

  Future<void> markPaid(String id, String transferRef) =>
      dio.patch('/admin/payouts/$id/paid', data: {'transferRef': transferRef});

  Future<void> reject(String id, String reason) =>
      dio.patch('/admin/payouts/$id/reject', data: {'reason': reason});
}

final payoutRepositoryProvider = Provider<PayoutRepository>(
  (ref) => PayoutRepository(ref.watch(dioProvider)),
);

final payoutSummaryProvider = FutureProvider<PayoutSummary>(
  (ref) => ref.watch(payoutRepositoryProvider).summary(),
);

final bankAccountProvider = FutureProvider<BankAccountInfo?>(
  (ref) => ref.watch(payoutRepositoryProvider).bankAccount(),
);

// ─────────────────────────────────────────────────────────────
// Daftar berhalaman (riwayat penjual & antrean admin)
// ─────────────────────────────────────────────────────────────

class PayoutListState {
  final List<Payout> items;
  final bool hasMore;
  final bool isLoadingMore;

  const PayoutListState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
  });
}

/// (admin?, status) — null status = semua.
typedef PayoutListKey = ({bool admin, PayoutStatus? status});

class PayoutListNotifier extends StateNotifier<AsyncValue<PayoutListState>> {
  final PayoutRepository _repo;
  final PayoutListKey _key;
  int _page = 1;

  PayoutListNotifier(this._repo, this._key)
    : super(const AsyncValue.loading()) {
    load();
  }

  Future<Paginated<Payout>> _fetch(int page) => _key.admin
      ? _repo.adminList(status: _key.status, page: page)
      : _repo.history(page: page);

  Future<void> load() async {
    _page = 1;
    try {
      final p = await _fetch(1);
      if (mounted) {
        state = AsyncValue.data(
          PayoutListState(items: p.items, hasMore: p.hasMore),
        );
      }
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> retry() {
    state = const AsyncValue.loading();
    return load();
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.isLoadingMore) return;
    state = AsyncValue.data(
      PayoutListState(items: cur.items, hasMore: true, isLoadingMore: true),
    );
    try {
      final next = await _fetch(_page + 1);
      if (!mounted) return;
      _page++;
      state = AsyncValue.data(
        PayoutListState(
          items: [...cur.items, ...next.items],
          hasMore: next.hasMore,
        ),
      );
    } catch (_) {
      if (mounted) state = AsyncValue.data(cur);
    }
  }
}

final payoutListProvider = StateNotifierProvider.autoDispose
    .family<PayoutListNotifier, AsyncValue<PayoutListState>, PayoutListKey>(
      (ref, key) =>
          PayoutListNotifier(ref.watch(payoutRepositoryProvider), key),
    );
