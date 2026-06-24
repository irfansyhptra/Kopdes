import '../../domain/entities/cart.dart';
import '../../../product/data/models/product_model.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.cartId,
    super.productId,
    super.product,
    super.umkmProductId,
    super.umkmProduct,
    required super.quantity,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      cartId: json['cartId'] as String? ?? '',
      productId: json['productId'] as String?,
      product: json['product'] != null
          ? ProductModel.fromJson(
              json['product'] as Map<String, dynamic>,
            ).toEntity()
          : null,
      umkmProductId: json['umkmProductId'] as String?,
      umkmProduct: json['umkmProduct'],
      quantity: json['quantity'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cartId': cartId,
      'productId': productId,
      'umkmProductId': umkmProductId,
      'quantity': quantity,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  CartItem toEntity() {
    return CartItem(
      id: id,
      cartId: cartId,
      productId: productId,
      product: product,
      umkmProductId: umkmProductId,
      umkmProduct: umkmProduct,
      quantity: quantity,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class CartModel extends Cart {
  const CartModel({
    required super.id,
    required super.userId,
    required List<CartItemModel> super.items,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<CartItemModel> parsedItems = list
        .map((item) => CartItemModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return CartModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      items: parsedItems,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Cart toEntity() {
    return Cart(
      id: id,
      userId: userId,
      items: items,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
