import 'package:flutter/foundation.dart';

/// Model dashboard Pegawai Kopdes.
///
/// Semua nominal disimpan sebagai [Rupiah] — bukan `double`. Backend mengirim
/// `Decimal` sebagai string justru supaya tidak melewati floating point, dan
/// mem-parse-nya ke `double` di sini akan membuang jaminan itu tepat di
/// perbatasan terakhir.

/// Nominal rupiah dalam satuan sen (integer), aman dari pembulatan biner.
@immutable
class Rupiah implements Comparable<Rupiah> {
  /// Disimpan dalam sen agar "1234.56" tetap utuh tanpa pecahan biner.
  final int cents;

  const Rupiah(this.cents);

  static const Rupiah zero = Rupiah(0);

  /// Membaca "3450000.00" / "3450000" / "" tanpa melewati `double`.
  factory Rupiah.parse(Object? value) {
    if (value == null) return zero;
    if (value is int) return Rupiah(value * 100);
    final text = value.toString().trim();
    if (text.isEmpty) return zero;

    final negative = text.startsWith('-');
    final digits = negative ? text.substring(1) : text;
    final parts = digits.split('.');
    final whole = int.tryParse(parts[0]) ?? 0;
    var fraction = 0;
    if (parts.length > 1) {
      final frac = parts[1].padRight(2, '0').substring(0, 2);
      fraction = int.tryParse(frac) ?? 0;
    }
    final total = whole * 100 + fraction;
    return Rupiah(negative ? -total : total);
  }

  bool get isZero => cents == 0;

  /// "Rp3.450.000" — pecahan sen dibuang karena harga koperasi bulat rupiah.
  String get formatted {
    final rupiah = cents ~/ 100;
    final digits = rupiah.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${rupiah < 0 ? '-' : ''}Rp$buffer';
  }

  @override
  int compareTo(Rupiah other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Rupiah && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => formatted;
}

/// KPI operasional — empat angka header dashboard.
@immutable
class DashboardSummary {
  final int newOrders;
  final int needProcessing;
  final int readyToShip;
  final int lowStockProducts;

  const DashboardSummary({
    required this.newOrders,
    required this.needProcessing,
    required this.readyToShip,
    required this.lowStockProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return DashboardSummary(
      newOrders: _int(data['newOrders']),
      needProcessing: _int(data['needProcessing']),
      readyToShip: _int(data['readyToShip']),
      lowStockProducts: _int(data['lowStockProducts']),
    );
  }
}

/// Status pesanan — cerminan `OrderStatus` di Prisma.
///
/// Enum, bukan string mentah: label, warna, dan tindakan lanjutan semuanya
/// diturunkan dari satu tempat, sehingga status yang belum dikenal tampil
/// apa adanya alih-alih menjatuhkan layar.
enum EmployeeOrderStatus {
  pending('PENDING', 'Baru'),
  paid('PAID', 'Baru'),
  processing('PROCESSING', 'Diproses'),
  readyForDelivery('READY_FOR_DELIVERY', 'Siap Dikirim'),
  outForDelivery('OUT_FOR_DELIVERY', 'Dalam Pengiriman'),
  delivered('DELIVERED', 'Diterima'),
  completed('COMPLETED', 'Selesai'),
  cancelled('CANCELLED', 'Dibatalkan');

  const EmployeeOrderStatus(this.wire, this.label);

  final String wire;
  final String label;

  static EmployeeOrderStatus fromWire(String? value) {
    return EmployeeOrderStatus.values.firstWhere(
      (s) => s.wire == value,
      orElse: () => EmployeeOrderStatus.pending,
    );
  }
}

/// Tindakan utama yang ditawarkan untuk sebuah status pesanan.
///
/// Peta ini kembar dari `ALLOWED_ORDER_TRANSITIONS` di backend. Yang di sini
/// hanya menentukan label tombol; penolakan lompatan status tetap dikerjakan
/// server, jadi kembaran yang tertinggal versi paling buruk membuat tombol
/// gagal — bukan membuat status melompat.
@immutable
class OrderAction {
  final String label;

  /// Status tujuan, atau null bila tindakannya hanya membuka layar lain.
  final String? nextStatus;

  /// Rute yang dibuka alih-alih mengubah status.
  final String? route;

  const OrderAction({required this.label, this.nextStatus, this.route});

  static OrderAction? forStatus(
    EmployeeOrderStatus status, {
    required bool courierAssigned,
  }) {
    switch (status) {
      case EmployeeOrderStatus.pending:
      case EmployeeOrderStatus.paid:
        return const OrderAction(label: 'Proses', nextStatus: 'PROCESSING');
      case EmployeeOrderStatus.processing:
        return const OrderAction(
          label: 'Siapkan Barang',
          nextStatus: 'READY_FOR_DELIVERY',
        );
      case EmployeeOrderStatus.readyForDelivery:
        // Setelah kurir ditugaskan, tindakan berikutnya melihat kurirnya,
        // bukan menugaskan ulang.
        return courierAssigned
            ? const OrderAction(label: 'Lihat Kurir', route: '/pegawai/kurir')
            : const OrderAction(
                label: 'Kirim ke Kurir',
                route: '/pegawai/kurir',
              );
      case EmployeeOrderStatus.outForDelivery:
        return const OrderAction(label: 'Lacak', route: '/pegawai/lacak');
      case EmployeeOrderStatus.delivered:
      case EmployeeOrderStatus.completed:
      case EmployeeOrderStatus.cancelled:
        return const OrderAction(label: 'Lihat Detail');
    }
  }
}

/// Satu baris "Pesanan Hari Ini".
@immutable
class TodayOrder {
  final String id;
  final String reference;
  final String customerName;
  final int itemCount;
  final Rupiah total;
  final EmployeeOrderStatus status;
  final DateTime createdAt;
  final String? thumbnailUrl;
  final String? deliveryId;
  final bool courierAssigned;

  const TodayOrder({
    required this.id,
    required this.reference,
    required this.customerName,
    required this.itemCount,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.thumbnailUrl,
    required this.deliveryId,
    required this.courierAssigned,
  });

  factory TodayOrder.fromJson(Map<String, dynamic> json) {
    return TodayOrder(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      customerName: json['customerName'] as String? ?? 'Pelanggan',
      itemCount: _int(json['itemCount']),
      total: Rupiah.parse(json['totalAmount']),
      status: EmployeeOrderStatus.fromWire(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      deliveryId: json['deliveryId'] as String?,
      courierAssigned: json['courierAssigned'] as bool? ?? false,
    );
  }

  static List<TodayOrder> listFrom(Map<String, dynamic> json) {
    final data = json['data'] as List? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(TodayOrder.fromJson)
        .toList(growable: false);
  }

  /// "10:24" — jam pesanan masuk.
  String get timeLabel {
    final h = createdAt.hour.toString().padLeft(2, '0');
    final m = createdAt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  OrderAction? get action =>
      OrderAction.forStatus(status, courierAssigned: courierAssigned);
}

/// Ringkasan stok untuk kartu donut.
@immutable
class StockSummary {
  final int activeProducts;
  final int lowStock;
  final int outOfStock;

  const StockSummary({
    required this.activeProducts,
    required this.lowStock,
    required this.outOfStock,
  });

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return StockSummary(
      activeProducts: _int(data['activeProducts']),
      lowStock: _int(data['lowStock']),
      outOfStock: _int(data['outOfStock']),
    );
  }

  /// Produk yang stoknya aman — sisa setelah menipis dan habis.
  int get healthy => (activeProducts - lowStock - outOfStock).clamp(0, 1 << 30);

  bool get allHealthy => lowStock == 0 && outOfStock == 0;
}

/// Rekap keuangan satu periode.
@immutable
class FinanceSummary {
  final String period;
  final Rupiah grossSales;
  final int transactionCount;
  final Rupiah refundTotal;
  final Rupiah codTotal;
  final Rupiah qrisTotal;

  /// Null bila periode pembanding kosong — pembagian nol tidak menghasilkan
  /// persentase yang bermakna, dan "0%" akan terbaca sebagai "tidak berubah".
  final int? changePercent;

  /// Null selama backend belum mencatat komponennya secara terpisah.
  /// Ditampilkan hanya bila ada nilainya, bukan sebagai nol palsu.
  final Rupiah? discountTotal;
  final Rupiah? shippingTotal;

  const FinanceSummary({
    required this.period,
    required this.grossSales,
    required this.transactionCount,
    required this.refundTotal,
    required this.codTotal,
    required this.qrisTotal,
    required this.changePercent,
    required this.discountTotal,
    required this.shippingTotal,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return FinanceSummary(
      period: data['period'] as String? ?? 'today',
      grossSales: Rupiah.parse(data['grossSales']),
      transactionCount: _int(data['transactionCount']),
      refundTotal: Rupiah.parse(data['refundTotal']),
      codTotal: Rupiah.parse(data['codTotal']),
      qrisTotal: Rupiah.parse(data['qrisTotal']),
      changePercent: data['changePercent'] as int?,
      discountTotal: data['discountTotal'] == null
          ? null
          : Rupiah.parse(data['discountTotal']),
      shippingTotal: data['shippingTotal'] == null
          ? null
          : Rupiah.parse(data['shippingTotal']),
    );
  }
}

/// Status operasional Kopdes untuk header.
@immutable
class StoreStatus {
  final String kopdesId;
  final String name;
  final String village;
  final String? logoUrl;

  /// Null berarti jadwal operasional belum diatur — bukan "tutup".
  final bool? isOpen;
  final String? opensAt;
  final String? closesAt;

  const StoreStatus({
    required this.kopdesId,
    required this.name,
    required this.village,
    required this.logoUrl,
    required this.isOpen,
    required this.opensAt,
    required this.closesAt,
  });

  static StoreStatus? fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) return null;
    return StoreStatus(
      kopdesId: data['kopdesId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      village: data['village'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      isOpen: data['isOpen'] as bool?,
      opensAt: data['opensAt'] as String?,
      closesAt: data['closesAt'] as String?,
    );
  }

  String get label => switch (isOpen) {
    true => 'Toko Buka',
    false => 'Toko Tutup',
    null => 'Jadwal belum diatur',
  };
}

/// Satu baris pada halaman Manajemen Stok.
@immutable
class StockItem {
  final String id;
  final String name;
  final int stock;
  final int minStock;
  final String unit;
  final String? sku;
  final Rupiah price;

  const StockItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.minStock,
    required this.unit,
    required this.sku,
    required this.price,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      stock: _int(json['stock']),
      minStock: _int(json['minStock']),
      unit: json['unit'] as String? ?? 'pcs',
      sku: json['sku'] as String?,
      price: Rupiah.parse(json['price']),
    );
  }

  bool get isOut => stock == 0;
  bool get isLow => stock > 0 && stock <= minStock;
}

/// Satu baris riwayat pergerakan stok.
@immutable
class StockMovement {
  final String id;
  final String type; // IN, OUT, ADJUSTMENT
  final int quantity;
  final int stockAfter;
  final String productName;
  final String reason;
  final String actorName;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.type,
    required this.quantity,
    required this.stockAfter,
    required this.productName,
    required this.reason,
    required this.actorName,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final umkmProduct = json['umkmProduct'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    return StockMovement(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'ADJUSTMENT',
      quantity: _int(json['quantity']),
      stockAfter: _int(json['stockAfter']),
      productName:
          product?['name'] as String? ??
          umkmProduct?['name'] as String? ??
          'Produk',
      reason: json['reason'] as String? ?? '',
      actorName: user?['name'] as String? ?? 'Sistem',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  String get typeLabel => switch (type) {
    'IN' => 'Stok Masuk',
    'OUT' => 'Stok Keluar',
    _ => 'Penyesuaian',
  };
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
