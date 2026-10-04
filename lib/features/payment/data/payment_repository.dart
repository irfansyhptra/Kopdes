import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Metode Midtrans yang ditawarkan (`PAYMENT_METHODS` di backend).
enum OnlineMethod {
  qris('QRIS', 'QRIS', 'Scan dengan aplikasi bank atau e-wallet apa pun'),
  gopay('GOPAY', 'GoPay', 'Dibuka di aplikasi Gojek'),
  shopeepay('SHOPEEPAY', 'ShopeePay', 'Dibuka di aplikasi Shopee'),
  bcaVa('BCA_VA', 'Virtual Account BCA', 'Transfer lewat m-BCA / ATM'),
  bniVa('BNI_VA', 'Virtual Account BNI', 'Transfer lewat BNI Mobile / ATM'),
  briVa('BRI_VA', 'Virtual Account BRI', 'Transfer lewat BRImo / ATM'),
  permataVa('PERMATA_VA', 'Virtual Account Permata', 'Transfer lewat Permata'),
  mandiri('MANDIRI_BILL', 'Mandiri Bill', 'Livin’ by Mandiri / ATM');

  final String wire;
  final String label;
  final String hint;
  const OnlineMethod(this.wire, this.label, this.hint);

  static OnlineMethod parse(Object? v) => OnlineMethod.values.firstWhere(
    (m) => m.wire == v,
    orElse: () => OnlineMethod.qris,
  );

  /// Metode yang boleh dipakai isi ulang saldo (`TOPUP_METHODS`).
  static const topUp = [qris, gopay, shopeepay];
}

/// Status tagihan, disatukan dari pembayaran pesanan dan isi ulang.
enum PayStatus { pending, paid, expired, failed }

PayStatus _status(Object? v) => switch ('$v'.toUpperCase()) {
  'PAID' || 'SETTLEMENT' => PayStatus.paid,
  'EXPIRED' => PayStatus.expired,
  'FAILED' || 'DENIED' || 'CANCELLED' || 'REFUNDED' => PayStatus.failed,
  _ => PayStatus.pending,
};

/// Apa yang harus dilakukan pembayar: QR, nomor VA, atau tautan e-wallet.
class PaymentInstructions {
  final PayStatus status;
  final int amount;
  final OnlineMethod method;
  final String? qrCodeUrl;
  final String? deeplinkUrl;
  final String? vaNumber;
  final String? bank;
  final String? billKey;
  final String? billerCode;
  final DateTime? expiresAt;

  const PaymentInstructions({
    required this.status,
    required this.amount,
    required this.method,
    this.qrCodeUrl,
    this.deeplinkUrl,
    this.vaNumber,
    this.bank,
    this.billKey,
    this.billerCode,
    this.expiresAt,
  });

  /// `PaymentSnapshot` dari `/payments/*`.
  factory PaymentInstructions.fromOrder(Map<String, dynamic> j) =>
      PaymentInstructions(
        status: _status(j['status']),
        amount: (j['grossAmount'] as num?)?.round() ?? 0,
        method: OnlineMethod.parse(j['method']),
        qrCodeUrl: j['qrCodeUrl'] as String?,
        deeplinkUrl: j['deeplinkUrl'] as String?,
        vaNumber: j['vaNumber'] as String?,
        bank: j['bank'] as String?,
        billKey: j['billKey'] as String?,
        billerCode: j['billerCode'] as String?,
        expiresAt: DateTime.tryParse('${j['expiryTime']}')?.toLocal(),
      );

  /// `WalletTopUp` dari `/wallet/topup*`.
  factory PaymentInstructions.fromTopUp(Map<String, dynamic> j) {
    final a = j['actions'] as Map<String, dynamic>? ?? const {};
    return PaymentInstructions(
      status: _status(j['status']),
      amount: (j['amount'] as num?)?.round() ?? 0,
      method: OnlineMethod.parse(j['paymentMethod']),
      qrCodeUrl: a['qrCodeUrl'] as String?,
      deeplinkUrl: a['deeplinkUrl'] as String?,
      vaNumber: a['vaNumber'] as String?,
      bank: a['bank'] as String?,
      billKey: a['billKey'] as String?,
      billerCode: a['billerCode'] as String?,
      expiresAt: DateTime.tryParse('${j['expiresAt']}')?.toLocal(),
    );
  }
}

/// Klien pembayaran Midtrans (pesanan & isi ulang). Tanpa cache: status
/// uang selalu ditanyakan ke server.
class PaymentRepository {
  final Dio dio;
  const PaymentRepository(this.dio);

  Map<String, dynamic> _data(Response<dynamic> r) =>
      (r.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;

  /// Idempoten di server: tagihan yang masih berlaku dipakai ulang.
  Future<PaymentInstructions> payOrder(String orderId, OnlineMethod m) async =>
      PaymentInstructions.fromOrder(
        _data(
          await dio.post(
            '/payments/create',
            data: {'orderId': orderId, 'paymentMethod': m.wire},
          ),
        ),
      );

  /// Menanyakan status terbaru ke Midtrans lewat server.
  Future<PaymentInstructions> checkOrder(String orderId) async =>
      PaymentInstructions.fromOrder(
        _data(await dio.post('/payments/$orderId/check-status')),
      );

  /// Membuat isi ulang; mengembalikan id-nya untuk dipantau.
  Future<({String id, PaymentInstructions pay})> topUp(
    int amount,
    OnlineMethod m,
  ) async {
    final d = _data(
      await dio.post(
        '/wallet/topup',
        data: {'amount': amount, 'paymentMethod': m.wire},
      ),
    );
    return (id: d['id'] as String, pay: PaymentInstructions.fromTopUp(d));
  }

  Future<PaymentInstructions> topUpStatus(String id) async =>
      PaymentInstructions.fromTopUp(_data(await dio.get('/wallet/topup/$id')));
}

final paymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => PaymentRepository(ref.watch(dioProvider)),
);
