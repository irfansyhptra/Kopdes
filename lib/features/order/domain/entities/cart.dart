import '../../../product/domain/entities/product.dart';
import 'seller_ref.dart';

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

  /// Toko asal produk ini. Dipakai untuk mengelompokkan keranjang per penjual.
  final SellerRef seller;

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
    this.seller = const SellerRef(),
  });

  bool get isUmkm => umkmProductId != null;

  /// Stok tersisa — batas atas quantity stepper. Nol berarti jumlahnya tidak
  /// bisa ditambah lagi, bukan bahwa barisnya harus hilang dari keranjang.
  int get stock {
    if (product != null) return product!.stock;
    final value = umkmProduct is Map ? umkmProduct['stock'] : null;
    return value is num ? value.toInt() : 0;
  }

  /// Total baris dalam rupiah bulat. Ringkasan menjumlahkan nilai bulat ini
  /// supaya galat pembulatan floating point tidak menumpuk antar baris.
  int get lineTotal => (price * quantity).round();

  /// Salinan dengan jumlah baru — dipakai pembaruan optimistis, yang harus
  /// bisa dikembalikan bila permintaan ke server gagal.
  CartItem copyWithQuantity(int newQuantity) => CartItem(
    id: id,
    cartId: cartId,
    productId: productId,
    product: product,
    umkmProductId: umkmProductId,
    umkmProduct: umkmProduct,
    quantity: newQuantity,
    createdAt: createdAt,
    updatedAt: updatedAt,
    seller: seller,
  );

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

  /// Salinan dengan daftar baris yang diganti. Dipakai pembaruan optimistis
  /// agar satu jumlah bisa berubah tanpa menunggu respons `/cart`, dan bisa
  /// dikembalikan bila permintaan itu gagal.
  Cart copyWithItems(List<CartItem> newItems) => Cart(
    id: id,
    userId: userId,
    items: newItems,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
