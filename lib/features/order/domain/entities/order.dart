import '../../../product/domain/entities/product.dart';
import 'address.dart';
import 'invoice.dart';
import 'seller_ref.dart';

class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final Product? product;
  final String? umkmProductId;
  final dynamic umkmProduct;
  final int quantity;
  final double price;

  /// Toko asal baris ini — dipakai kartu pesanan untuk menyebut penjualnya.
  final SellerRef seller;

  const OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    this.product,
    this.umkmProductId,
    this.umkmProduct,
    required this.quantity,
    required this.price,
    this.seller = const SellerRef(),
  });

  int get lineTotal => (price * quantity).round();

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

class Order {
  final String id;
  final String customerId;

  /// Nilai barang sebelum ongkir dan diskon, dalam rupiah bulat.
  ///
  /// Datang dari kolomnya sendiri di backend. Sebelumnya hanya total yang
  /// tersimpan, sehingga rincian pembayaran tidak bisa menunjukkan ongkir
  /// maupun potongan — dan pemesan hanya melihat satu angka tanpa asal-usul.
  final int subtotal;
  final int shippingFee;
  final int discountAmount;

  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String deliveryAddressId;
  final Address? deliveryAddress;
  final List<OrderItem> items;
  final Invoice? invoice;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.customerId,
    this.subtotal = 0,
    this.shippingFee = 0,
    this.discountAmount = 0,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.deliveryAddressId,
    this.deliveryAddress,
    required this.items,
    this.invoice,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Nomor yang ditunjukkan ke pemesan: nomor invoice bila sudah terbit,
  /// kalau belum potongan id pesanan — bukan UUID penuh yang tak terbaca.
  String get displayNumber {
    final number = invoice?.invoiceNumber;
    if (number != null && number.isNotEmpty) return number;
    return '#${id.substring(0, id.length < 8 ? id.length : 8).toUpperCase()}';
  }

  /// Satu pesanan bisa memuat produk dari beberapa toko. Kartu ringkas
  /// menyebut toko pertama dan menghitung sisanya, bukan menyembunyikannya.
  SellerRef? get primarySeller => items.isEmpty ? null : items.first.seller;

  int get sellerCount =>
      items.map((item) => item.seller.groupKey).toSet().length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Rincian pembayaran hanya layak ditampilkan bila ada komponennya.
  /// Pesanan lama (sebelum kolom ini ada) memakai subtotal nol; di situ
  /// rinciannya disembunyikan alih-alih menampilkan "Subtotal Rp0".
  bool get hasPaymentBreakdown => subtotal > 0;

  int get totalRounded => totalAmount.round();
}
