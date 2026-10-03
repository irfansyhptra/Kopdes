import 'category.dart';

class ProductImage {
  final String id;
  final String url;
  final bool isPrimary;

  const ProductImage({
    required this.id,
    required this.url,
    this.isPrimary = false,
  });
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;
  final Category? category;
  final List<ProductImage> images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Harga coret. Null berarti tidak sedang diskon.
  final double? discountPrice;

  /// Satuan jual yang tampil di samping harga — "kg", "pcs", "liter".
  final String unit;

  /// Unit yang benar-benar sampai ke pembeli. Pesanan berjalan dan batal
  /// tidak dihitung, jadi angkanya tidak pernah naik lalu turun lagi.
  final int soldCount;

  final double? ratingAverage;
  final int ratingCount;

  /// Toko penjualnya. Null pada produk lama yang belum terikat Kopdes.
  final ProductStore? store;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.category,
    required this.images,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.discountPrice,
    this.unit = 'pcs',
    this.soldCount = 0,
    this.ratingAverage,
    this.ratingCount = 0,
    this.store,
  });

  /// Diskon hanya diakui bila harganya memang turun — data terbalik lebih baik
  /// tampil sebagai harga biasa daripada sebagai kenaikan berlencana merah.
  bool get hasDiscount =>
      discountPrice != null && discountPrice! > 0 && discountPrice! < price;

  double get effectivePrice => hasDiscount ? discountPrice! : price;

  int get discountPercent =>
      hasDiscount ? (((price - discountPrice!) / price) * 100).round() : 0;

  bool get hasRating => ratingAverage != null && ratingCount > 0;

  /// Format Indonesia: koma sebagai pemisah desimal.
  String get ratingLabel => ratingAverage == null
      ? '-'
      : ratingAverage!.toStringAsFixed(1).replaceAll('.', ',');

  String get primaryImageUrl {
    if (images.isEmpty) return '';
    for (final img in images) {
      if (img.isPrimary) return img.url;
    }
    return images.first.url;
  }
}

/// Toko penjual, seperlunya untuk kartu toko di halaman detail produk.
class ProductStore {
  final String id;
  final String name;
  final String? logoUrl;
  final String? imageUrl;
  final String village;
  final String district;
  final double? latitude;
  final double? longitude;

  /// Jumlah barang aktif yang dijual toko ini.
  final int productCount;

  const ProductStore({
    required this.id,
    required this.name,
    this.logoUrl,
    this.imageUrl,
    this.village = '',
    this.district = '',
    this.latitude,
    this.longitude,
    this.productCount = 0,
  });

  String get shortAddress =>
      [village, district].where((p) => p.isNotEmpty).join(', ');

  static ProductStore? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return ProductStore(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      village: json['village'] as String? ?? '',
      district: json['district'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      productCount:
          ((json['_count'] as Map<String, dynamic>?)?['products'] as num?)
              ?.toInt() ??
          0,
    );
  }
}
