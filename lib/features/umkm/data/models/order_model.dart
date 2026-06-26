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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List? ?? [];
    final parsedItems = itemList
        .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customer: CustomerInfo.fromJson(json['customer'] as Map<String, dynamic>),
      totalAmount: json['totalAmount'] is num
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse(json['totalAmount'].toString()) ?? 0.0,
      status: json['status'] as String? ?? 'PENDING',
      paymentMethod: json['paymentMethod'] as String? ?? 'COD',
      paymentStatus: json['paymentStatus'] as String? ?? 'PENDING',
      deliveryAddress: AddressInfo.fromJson(json['deliveryAddress'] as Map<String, dynamic>),
      items: parsedItems,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
