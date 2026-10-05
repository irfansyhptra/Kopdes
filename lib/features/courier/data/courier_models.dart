import 'package:flutter/material.dart';

import '../../../core/theme/theme.dart';

/// Status pengantaran (`enum DeliveryStatus` di backend) dalam kata-kata
/// kurir, bukan konstanta basis data.
///
/// Warna hanya penegas: setiap keadaan punya ikon dan teksnya sendiri,
/// supaya terbaca juga oleh mata yang sulit membedakan warna.
enum TaskStage {
  /// Ditugaskan pengurus, kurirnya belum menyanggupi.
  assigned('ASSIGNED', 'Tugas baru dari pengurus', Icons.inbox_rounded),

  /// Sudah dipegang kurir, barang belum diambil dari toko.
  accepted('ACCEPTED', 'Siap diambil di toko', Icons.storefront_rounded),

  pickedUp('PICKED_UP', 'Barang sudah diambil', Icons.inventory_2_rounded),
  inTransit('IN_TRANSIT', 'Dalam perjalanan', Icons.local_shipping_rounded),
  delivered(
    'COURIER_DELIVERED',
    'Menunggu konfirmasi pembeli',
    Icons.hourglass_top_rounded,
  ),
  confirmed('CUSTOMER_CONFIRMED', 'Diterima pembeli', Icons.task_alt_rounded),
  completed('COMPLETED', 'Selesai', Icons.check_circle_rounded);

  final String wire;
  final String label;
  final IconData icon;

  const TaskStage(this.wire, this.label, this.icon);

  /// Status yang tidak dikenal diperlakukan sebagai tugas baru: lebih baik
  /// muncul di daftar dan bisa ditindak daripada hilang tanpa jejak.
  static TaskStage of(String wire) => values.firstWhere(
    (s) => s.wire == wire,
    orElse: () => TaskStage.assigned,
  );

  bool get isDone =>
      this == delivered || this == confirmed || this == completed;

  /// Barang sudah di tangan kurir — tidak bisa dilepas lagi.
  bool get carrying => this == pickedUp || this == inTransit;

  Color get tint => switch (this) {
    assigned => AppColors.primary,
    accepted => AppColors.warning,
    pickedUp || inTransit => const Color(0xFF2F6FDB),
    delivered => AppColors.warning,
    confirmed || completed => AppColors.success,
  };

  Color get textTint => switch (this) {
    assigned => AppColors.primaryText,
    accepted || delivered => AppColors.warningText,
    pickedUp || inTransit => const Color(0xFF1F4FA3),
    confirmed || completed => AppColors.successText,
  };
}

/// Tempat kurir mengambil barang: toko Kopdes atau toko mitra UMKM.
class TaskPickup {
  final String id;
  final String kind;
  final String name;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;

  const TaskPickup({
    required this.id,
    required this.kind,
    required this.name,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
  });

  bool get isKopdes => kind == 'KOPDES';
  bool get hasPoint => latitude != null && longitude != null;

  factory TaskPickup.fromJson(Map<String, dynamic> j) => TaskPickup(
    id: j['id'] as String? ?? '',
    kind: j['kind'] as String? ?? 'KOPDES',
    name: j['name'] as String? ?? 'Toko',
    address: j['address'] as String? ?? '',
    phone: j['phone'] as String?,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
  );
}

/// Tujuan pengantaran. [latitude]/[longitude] null bila pembeli belum pernah
/// menyimpan titik rumahnya — alamatnya tetap terbaca sebagai teks.
class TaskDestination {
  final String title;
  final String recipientName;
  final String? phone;
  final String street;
  final String city;
  final double? latitude;
  final double? longitude;

  const TaskDestination({
    required this.title,
    required this.recipientName,
    required this.street,
    required this.city,
    this.phone,
    this.latitude,
    this.longitude,
  });

  bool get hasPoint => latitude != null && longitude != null;
  String get fullAddress =>
      [street, city].where((s) => s.isNotEmpty).join(', ');

  factory TaskDestination.fromJson(Map<String, dynamic> j) => TaskDestination(
    title: j['title'] as String? ?? 'Alamat',
    recipientName: j['recipientName'] as String? ?? '',
    phone: j['phone'] as String?,
    street: j['street'] as String? ?? '',
    city: j['city'] as String? ?? '',
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
  );
}

class TaskItem {
  final String name;
  final String? variantName;
  final int quantity;

  const TaskItem({
    required this.name,
    required this.quantity,
    this.variantName,
  });

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    name: j['name'] as String? ?? 'Barang',
    variantName: j['variantName'] as String?,
    quantity: (j['quantity'] as num?)?.toInt() ?? 0,
  );
}

/// Satu tugas pengantaran sebagaimana dibaca aplikasi kurir.
class CourierTask {
  final String id;
  final TaskStage stage;
  final String orderId;
  final String orderStatus;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  final String paymentMethod;
  final String paymentStatus;
  final double totalAmount;
  final double shippingFee;

  /// Uang yang harus ditagih kurir di depan pintu. Nol untuk pesanan yang
  /// sudah dibayar — menagih dua kali adalah kesalahan yang tidak bisa
  /// ditarik kembali.
  final double codAmount;

  final String customerName;
  final String? customerPhone;
  final String customerId;
  final TaskDestination destination;
  final List<TaskPickup> pickups;
  final List<TaskItem> items;
  final int itemCount;

  const CourierTask({
    required this.id,
    required this.stage,
    required this.orderId,
    required this.orderStatus,
    required this.createdAt,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totalAmount,
    required this.shippingFee,
    required this.codAmount,
    required this.customerId,
    required this.customerName,
    required this.destination,
    required this.pickups,
    required this.items,
    required this.itemCount,
    this.customerPhone,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.confirmedAt,
  });

  bool get isCod => codAmount > 0;

  /// Nomor pendek untuk dibaca di jalan — id penuh tidak terhafal siapa pun.
  String get shortCode => orderId.length <= 8
      ? orderId.toUpperCase()
      : orderId.substring(0, 8).toUpperCase();

  factory CourierTask.fromJson(Map<String, dynamic> j) {
    final o = (j['order'] as Map<String, dynamic>?) ?? const {};
    final c = (j['customer'] as Map<String, dynamic>?) ?? const {};
    DateTime? at(Object? v) =>
        v == null ? null : DateTime.tryParse(v as String)?.toLocal();

    return CourierTask(
      id: j['id'] as String? ?? '',
      stage: TaskStage.of(j['status'] as String? ?? ''),
      orderId: o['id'] as String? ?? '',
      orderStatus: o['status'] as String? ?? '',
      acceptedAt: at(j['acceptedAt']),
      pickedUpAt: at(j['pickedUpAt']),
      deliveredAt: at(j['courierMarkedDeliveredAt']),
      confirmedAt: at(j['customerConfirmedAt']),
      createdAt: at(j['createdAt']) ?? DateTime.now(),
      paymentMethod: o['paymentMethod'] as String? ?? '',
      paymentStatus: o['paymentStatus'] as String? ?? '',
      totalAmount: (o['totalAmount'] as num?)?.toDouble() ?? 0,
      shippingFee: (o['shippingFee'] as num?)?.toDouble() ?? 0,
      codAmount: (o['codAmount'] as num?)?.toDouble() ?? 0,
      customerId: c['id'] as String? ?? '',
      customerName: c['name'] as String? ?? 'Pembeli',
      customerPhone: c['phone'] as String?,
      destination: TaskDestination.fromJson(
        (j['destination'] as Map<String, dynamic>?) ?? const {},
      ),
      pickups: ((j['pickups'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(TaskPickup.fromJson)
          .toList(),
      items: ((j['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(TaskItem.fromJson)
          .toList(),
      itemCount: (j['itemCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Angka dasbor kurir.
class CourierSummary {
  final int availableTasks;
  final int activeTasks;
  final int deliveredToday;
  final int deliveredTotal;
  final double codCollectedToday;

  const CourierSummary({
    required this.availableTasks,
    required this.activeTasks,
    required this.deliveredToday,
    required this.deliveredTotal,
    required this.codCollectedToday,
  });

  factory CourierSummary.fromJson(Map<String, dynamic> j) => CourierSummary(
    availableTasks: (j['availableTasks'] as num?)?.toInt() ?? 0,
    activeTasks: (j['activeTasks'] as num?)?.toInt() ?? 0,
    deliveredToday: (j['deliveredToday'] as num?)?.toInt() ?? 0,
    deliveredTotal: (j['deliveredTotal'] as num?)?.toInt() ?? 0,
    codCollectedToday: (j['codCollectedToday'] as num?)?.toDouble() ?? 0,
  );
}
