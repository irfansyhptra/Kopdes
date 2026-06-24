import '../../../product/domain/entities/product.dart';

class CartItem {
  final String id;
  final String cartId;
  final String? productId;
  final Product? product;
  final String? umkmProductId;
  final dynamic umkmProduct;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CartItem({
    required this.id,
    required this.cartId,
    this.productId,
    this.product,
    this.umkmProductId,
    this.umkmProduct,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  double get price {
    if (product != null) return product!.price;
    if (umkmProduct != null) {
      final p = umkmProduct['price'];
      return p is num ? p.toDouble() : (double.tryParse(p.toString()) ?? 0.0);
    }
    return 0.0;
  }

  String get name {
    if (product != null) return product!.name;
    if (umkmProduct != null) return umkmProduct['name'] as String;
    return '';
  }

  String get imageUrl {
    if (product != null) return product!.primaryImageUrl;
    if (umkmProduct != null &&
        umkmProduct['images'] != null &&
        (umkmProduct['images'] as List).isNotEmpty) {
      return umkmProduct['images'][0]['url'] as String;
    }
    return '';
  }
}

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get totalItems {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}
