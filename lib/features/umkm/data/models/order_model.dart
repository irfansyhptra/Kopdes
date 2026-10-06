import 'order_item_model.dart';

class CustomerInfo {
  final String id;
  final String name;
  final String email;
  final String phone;

  const CustomerInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class AddressInfo {
  final String recipientName;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String postalCode;

  const AddressInfo({
    required this.recipientName,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      recipientName: json['recipientName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
    );
  }
}

class CourierInfo {
  final String id;
  final String name;
  final String phone;

  const CourierInfo({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory CourierInfo.fromJson(Map<String, dynamic> json) => CourierInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Kurir',
    phone: json['phone'] as String? ?? '',
  );
}

class OrderModel {
  final String id;
  final String customerId;
  final CustomerInfo customer;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final AddressInfo deliveryAddress;
  final List<OrderItemModel> items;
  final DateTime createdAt;
  final CourierInfo? courier;

  /// `PICKUP` atau `DELIVERY`. Menentukan tombol yang ditawarkan ke penjual:
  /// UMKM tidak memerintah kurir, ia hanya menyatakan barang siap diantar.
  final String fulfillment;

  /// Status pengantaran bila pesanan sudah masuk kolam tugas kurir Kopdes.
  final String? deliveryStatus;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customer,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.items,
    required this.createdAt,
    this.fulfillment = 'DELIVERY',
    this.courier,
    this.deliveryStatus,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];
    final parsedItems = itemList
        .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    final delivery = json['delivery'] as Map<String, dynamic>?;
    final courier = delivery?['courier'] as Map<String, dynamic>?;

    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String? ?? '',
      // Respons sebagian — mis. setelah ubah status — tidak selalu memuat
      // pembeli dan alamat. Dulu cast ini melempar, jadi penjual melihat
      // "gagal" padahal statusnya sudah tersimpan di server.
      customer: CustomerInfo.fromJson(
        json['customer'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      totalAmount: json['totalAmount'] is num
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String? ?? 'COD',
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      deliveryAddress: AddressInfo.fromJson(
        json['deliveryAddress'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      items: parsedItems,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      fulfillment: json['fulfillment'] as String? ?? 'DELIVERY',
      courier: courier == null ? null : CourierInfo.fromJson(courier),
      deliveryStatus: delivery?['status'] as String?,
    );
  }
}
