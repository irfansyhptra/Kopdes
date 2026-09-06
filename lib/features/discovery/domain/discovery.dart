/// Asal produk: milik Kopdes atau milik Mitra UMKM.
enum ProductSource {
  koperasi('KOPERASI', 'Kopdes'),
  umkm('UMKM', 'Mitra UMKM');

  final String wire;
  final String label;

  const ProductSource(this.wire, this.label);

  static ProductSource fromWire(String? value) => ProductSource.values
      .firstWhere((s) => s.wire == value, orElse: () => ProductSource.koperasi);
}

/// Produk yang tampil di section penemuan beranda.
///
/// Satu bentuk untuk "Produk UMKM Pilihan" dan "Produk Terlaris" — keduanya
/// menampilkan kartu yang sama, bedanya hanya ada tidaknya peringkat dan
/// jumlah terjual.
class DiscoveryProduct {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String? imageUrl;

  /// Nama Kopdes atau Mitra UMKM penjualnya.
  final String sellerName;
  final ProductSource source;

  /// Hanya terisi pada Produk Terlaris.
  final int? soldCount;
  final int? rank;

  const DiscoveryProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sellerName,
    required this.source,
    this.imageUrl,
    this.soldCount,
    this.rank,
  });

  bool get isOutOfStock => stock <= 0;

  /// "Terjual 240+" — dibulatkan ke bawah supaya tidak pernah melebih-lebihkan.
  String? get soldLabel {
    final sold = soldCount;
    if (sold == null || sold <= 0) return null;
    if (sold < 10) return 'Terjual $sold';
    final rounded = (sold ~/ 10) * 10;
    return 'Terjual $rounded+';
  }

  factory DiscoveryProduct.fromJson(Map<String, dynamic> json) =>
      DiscoveryProduct(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl'] as String?,
        sellerName: json['sellerName'] as String? ?? '',
        source: ProductSource.fromWire(json['source'] as String?),
        soldCount: (json['soldCount'] as num?)?.toInt(),
        rank: (json['rank'] as num?)?.toInt(),
      );
}

/// Banner promosi yang dikelola admin.
class PromoBanner {
  final String id;
  final String? badge;
  final String title;
  final String? highlight;
  final String? description;
  final String? ctaLabel;

  /// Rute dalam aplikasi yang dibuka saat ditekan.
  final String? ctaRoute;
  final String? imageUrl;

  const PromoBanner({
    required this.id,
    required this.title,
    this.badge,
    this.highlight,
    this.description,
    this.ctaLabel,
    this.ctaRoute,
    this.imageUrl,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) => PromoBanner(
    id: json['id'] as String,
    badge: json['badge'] as String?,
    title: json['title'] as String? ?? '',
    highlight: json['highlight'] as String?,
    description: json['description'] as String?,
    ctaLabel: json['ctaLabel'] as String?,
    ctaRoute: json['ctaRoute'] as String?,
    imageUrl: json['imageUrl'] as String?,
  );
}

/// Detail satu produk Mitra UMKM untuk pelanggan.
class UmkmProductDetail {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> imageUrls;
  final String? categoryName;

  final String umkmId;
  final String sellerName;
  final String sellerAddress;
  final String? sellerPhone;

  final double? ratingAverage;
  final int ratingCount;

  const UmkmProductDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrls,
    required this.umkmId,
    required this.sellerName,
    required this.sellerAddress,
    this.categoryName,
    this.sellerPhone,
    this.ratingAverage,
    this.ratingCount = 0,
  });

  bool get isOutOfStock => stock <= 0;
  String? get primaryImageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  factory UmkmProductDetail.fromJson(Map<String, dynamic> json) {
    final umkm = json['umkm'] as Map<String, dynamic>? ?? const {};
    final rating = json['rating'] as Map<String, dynamic>? ?? const {};

    return UmkmProductDetail(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrls: (json['images'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((i) => i['url'] as String? ?? '')
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
      categoryName:
          (json['category'] as Map<String, dynamic>?)?['name'] as String?,
      umkmId: umkm['id'] as String? ?? '',
      sellerName: umkm['businessName'] as String? ?? 'Mitra UMKM',
      sellerAddress: umkm['address'] as String? ?? '',
      sellerPhone: umkm['phone'] as String?,
      ratingAverage: (rating['average'] as num?)?.toDouble(),
      ratingCount: (rating['count'] as num?)?.toInt() ?? 0,
    );
  }
}
