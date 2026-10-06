class CachedCartItem {
  final String? productId;
  final String? umkmProductId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  const CachedCartItem({
    this.productId,
    this.umkmProductId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'umkmProductId': umkmProductId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'imageUrl': imageUrl,
  };

  factory CachedCartItem.fromJson(Map<String, dynamic> json) => CachedCartItem(
    productId: json['productId'] as String?,
    umkmProductId: json['umkmProductId'] as String?,
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    imageUrl: json['imageUrl'] as String?,
  );
}

class CachedOrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  const CachedOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'price': price,
  };

  factory CachedOrderItem.fromJson(Map<String, dynamic> json) =>
      CachedOrderItem(
        productId: json['productId'] as String? ?? '',
        productName: json['productName'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}

class CachedOrder {
  final String orderId;
  final String customerId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final List<CachedOrderItem> items;

  const CachedOrder({
    required this.orderId,
    required this.customerId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'customerId': customerId,
    'totalAmount': totalAmount,
    'status': status,
    'paymentMethod': paymentMethod,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
  };

  factory CachedOrder.fromJson(Map<String, dynamic> json) => CachedOrder(
    orderId: json['orderId'] as String? ?? '',
    customerId: json['customerId'] as String? ?? '',
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    status: json['status'] as String? ?? '',
    paymentMethod: json['paymentMethod'] as String? ?? '',
    createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CachedOrderItem.fromJson)
        .toList(),
  );
}
