import 'entities/order.dart';

/// Tab pada halaman Pesanan.
enum OrdersTab {
  cart('Keranjang'),
  active('Diproses'),
  done('Selesai');

  final String label;

  const OrdersTab(this.label);
}

/// Filter kecil pada tab Selesai.
enum DoneFilter {
  all('Semua'),
  completed('Selesai'),
  cancelled('Dibatalkan');

  final String label;

  const DoneFilter(this.label);
}

/// Tampilan satu status `OrderStatus` bagi pemesan.
///
/// Status di database ditulis untuk operator gudang (`READY_FOR_DELIVERY`,
/// `OUT_FOR_DELIVERY`). Yang dilihat pemesan harus menjawab satu pertanyaan:
/// "pesanan saya sekarang di mana". Pemetaan itu terjadi di sini saja, supaya
/// tidak ada layar yang diam-diam memakai istilah gudang.
class OrderStatusView {
  final String label;

  /// True bila pesanan masih berjalan — menentukan tab mana yang memuatnya.
  final bool isActive;

  /// True bila pesanan berakhir tanpa diterima pemesan.
  final bool isCancelled;

  const OrderStatusView({
    required this.label,
    required this.isActive,
    this.isCancelled = false,
  });

  static const _map = <String, OrderStatusView>{
    'PENDING': OrderStatusView(label: 'Menunggu pembayaran', isActive: true),
    'PAID': OrderStatusView(label: 'Pembayaran diterima', isActive: true),
    'PROCESSING': OrderStatusView(label: 'Sedang disiapkan', isActive: true),
    'READY_FOR_DELIVERY': OrderStatusView(
      label: 'Siap diambil kurir',
      isActive: true,
    ),
    'OUT_FOR_DELIVERY': OrderStatusView(
      label: 'Dalam pengiriman',
      isActive: true,
    ),
    // Sudah sampai, tetapi belum dikonfirmasi pemesan — masih perlu tindakan,
    // jadi tetap di tab Diproses.
    'DELIVERED': OrderStatusView(label: 'Sudah sampai', isActive: true),
    'COMPLETED': OrderStatusView(label: 'Selesai', isActive: false),
    'CANCELLED': OrderStatusView(
      label: 'Dibatalkan',
      isActive: false,
      isCancelled: true,
    ),
  };

  /// Status yang tidak dikenal diperlakukan sebagai masih berjalan: lebih baik
  /// pesanan muncul di tab Diproses daripada hilang dari kedua tab.
  factory OrderStatusView.of(String status) =>
      _map[status] ?? OrderStatusView(label: _humanise(status), isActive: true);

  static String _humanise(String status) {
    final words = status.toLowerCase().split('_');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

extension OrderStatusX on Order {
  OrderStatusView get statusView => OrderStatusView.of(status);

  /// Tagihan online yang belum dibayar. COD dibayar saat barang tiba dan
  /// saldo KOMIT lunas saat pesanan dibuat — keduanya tidak punya tagihan
  /// untuk dibayar dari aplikasi.
  bool get isAwaitingPayment =>
      paymentStatus == 'PENDING' &&
      status == 'PENDING' &&
      paymentMethod != 'COD' &&
      paymentMethod != 'WALLET';

  /// Konfirmasi penerimaan hanya masuk akal setelah barang benar-benar sampai.
  bool get canConfirmReceipt => status == 'DELIVERED';

  /// Pelacakan baru berguna setelah pesanan diserahkan ke kurir.
  bool get canTrack =>
      status == 'OUT_FOR_DELIVERY' || status == 'READY_FOR_DELIVERY';

  String get paymentLabel => switch (paymentMethod) {
    'QRIS' => 'QRIS',
    'COD' => 'Bayar di tempat',
    _ => paymentMethod,
  };
}
