// Model ringan (tanpa Freezed) untuk fitur Admin Kopdes.
// Parsing defensif: backend membungkus payload di dalam { success, data }.

double _toDouble(dynamic v) =>
    v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
int _toInt(dynamic v) =>
    v == null ? 0 : (v is num ? v.toInt() : int.tryParse('$v') ?? 0);

/// Mitra UMKM (model UMKM di backend).
class Mitra {
  final String id;
  final String businessName;
  final String description;
  final String address;
  final String phone;
  final String status; // PENDING_VERIFICATION | ACTIVE | REJECTED | SUSPENDED
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final int productCount;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;

  /// Null berarti koordinat belum diisi — UMKM ini tidak akan muncul di
  /// pencarian terdekat sampai admin mengisinya.
  final double? latitude;
  final double? longitude;
  final String category;

  Mitra({
    required this.id,
    required this.businessName,
    required this.description,
    required this.address,
    required this.phone,
    required this.status,
    required this.rejectionReason,
    required this.verifiedAt,
    required this.productCount,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    this.latitude,
    this.longitude,
    this.category = 'LAINNYA',
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory Mitra.fromJson(Map<String, dynamic> j) {
    final user = j['user'] as Map<String, dynamic>?;
    return Mitra(
      id: j['id'] as String,
      businessName: j['businessName'] as String? ?? '-',
      description: j['description'] as String? ?? '',
      address: j['address'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      status: j['status'] as String? ?? 'PENDING_VERIFICATION',
      rejectionReason: j['rejectionReason'] as String?,
      verifiedAt: j['verifiedAt'] != null
          ? DateTime.tryParse('${j['verifiedAt']}')
          : null,
      productCount: _toInt(j['productCount']),
      ownerId: user?['id'] as String? ?? '',
      ownerName: user?['name'] as String? ?? '-',
      ownerEmail: user?['email'] as String? ?? '',
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      category: j['category'] as String? ?? 'LAINNYA',
    );
  }
}

/// Produk milik UMKM (untuk halaman takedown).
class UmkmProductAdmin {
  final String id;
  final String name;
  final double price;
  final int stock;
  final bool isActive;
  final bool isApproved;
  final String umkmName;
  final String? primaryImageUrl;

  UmkmProductAdmin({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.isApproved,
    required this.umkmName,
    required this.primaryImageUrl,
  });

  factory UmkmProductAdmin.fromJson(Map<String, dynamic> j) {
    final umkm = j['umkm'] as Map<String, dynamic>?;
    final images = j['images'] as List?;
    String? img;
    if (images != null && images.isNotEmpty) {
      img = (images.first as Map<String, dynamic>)['url'] as String?;
    }
    return UmkmProductAdmin(
      id: j['id'] as String,
      name: j['name'] as String? ?? '-',
      price: _toDouble(j['price']),
      stock: _toInt(j['stock']),
      isActive: j['isActive'] as bool? ?? true,
      isApproved: j['isApproved'] as bool? ?? false,
      umkmName: umkm?['businessName'] as String? ?? '-',
      primaryImageUrl: img,
    );
  }
}

/// Pesanan koperasi (sisi admin).
class AdminOrder {
  final String id;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;
  final int itemCount;
  final String? deliveryStatus;
  final String? courierName;

  AdminOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
    required this.itemCount,
    required this.deliveryStatus,
    required this.courierName,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> j) {
    final customer = j['customer'] as Map<String, dynamic>?;
    final items = j['items'] as List?;
    final delivery = j['delivery'] as Map<String, dynamic>?;
    final courier = delivery?['courier'] as Map<String, dynamic>?;
    return AdminOrder(
      id: j['id'] as String,
      customerId: customer?['id'] as String? ?? '',
      customerName: customer?['name'] as String? ?? '-',
      totalAmount: _toDouble(j['totalAmount']),
      status: j['status'] as String? ?? 'PENDING',
      paymentMethod: j['paymentMethod'] as String? ?? '-',
      paymentStatus: j['paymentStatus'] as String? ?? 'PENDING',
      createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
      itemCount: items?.length ?? 0,
      deliveryStatus: delivery?['status'] as String?,
      courierName: courier?['name'] as String?,
    );
  }
}

/// Kurir koperasi.
class Courier {
  final String id;
  final String name;
  final String phone;
  final String email;
  final int activeCount;

  Courier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.activeCount,
  });

  factory Courier.fromJson(Map<String, dynamic> j) => Courier(
    id: j['id'] as String,
    name: j['name'] as String? ?? '-',
    phone: j['phone'] as String? ?? '',
    email: j['email'] as String? ?? '',
    activeCount: _toInt(j['activeCount']),
  );
}

/// Pengantaran untuk penugasan kurir.
class AdminDelivery {
  final String id;
  final String status;
  final String orderId;
  final String customerName;
  final String? courierName;
  final String address;

  AdminDelivery({
    required this.id,
    required this.status,
    required this.orderId,
    required this.customerName,
    required this.courierName,
    required this.address,
  });

  factory AdminDelivery.fromJson(Map<String, dynamic> j) {
    final courier = j['courier'] as Map<String, dynamic>?;
    final order = j['order'] as Map<String, dynamic>?;
    final customer = order?['customer'] as Map<String, dynamic>?;
    final addr = order?['deliveryAddress'] as Map<String, dynamic>?;
    final addrStr = addr == null
        ? '-'
        : '${addr['street'] ?? ''}, ${addr['city'] ?? ''}'.trim();
    return AdminDelivery(
      id: j['id'] as String,
      status: j['status'] as String? ?? 'ASSIGNED',
      orderId: j['orderId'] as String? ?? order?['id'] as String? ?? '',
      customerName: customer?['name'] as String? ?? '-',
      courierName: courier?['name'] as String?,
      address: addrStr,
    );
  }
}
