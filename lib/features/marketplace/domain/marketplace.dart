/// Sumber produk di Marketplace.
enum SellerType {
  all('ALL', 'Semua'),
  kopdes('KOPDES', 'Kopdes'),
  umkm('UMKM', 'Mitra UMKM'),

  /// Bukan filter sumber, melainkan pengurutan berdasarkan jarak. Dijadikan
  /// satu segmented control karena bagi pengguna keempatnya adalah "dari mana
  /// produk ini" — pembedaannya di query, bukan di tampilan.
  nearest('ALL', 'Terdekat');

  final String wire;
  final String label;

  const SellerType(this.wire, this.label);
}

enum MarketplaceSort {
  newest('newest'),
  priceAsc('price_asc'),
  priceDesc('price_desc'),
  distance('distance');

  final String wire;

  const MarketplaceSort(this.wire);
}

/// Kelompok kategori: menentukan baris filter mana yang menampilkannya.
enum CategoryGroup {
  food('FOOD'),
  retail('RETAIL');

  final String wire;

  const CategoryGroup(this.wire);

  static CategoryGroup fromWire(String? value) =>
      value == 'FOOD' ? CategoryGroup.food : CategoryGroup.retail;
}

/// Produk pada katalog terpadu.
class MarketplaceProduct {
  final String id;
  final String name;
  final double price;

  /// Harga sebelum diskon. Null berarti produk tidak sedang diskon — bukan
  /// nol, yang akan terbaca sebagai "gratis" pada harga coret. Hanya produk
  /// Kopdes yang punya kolom ini di backend.
  final double? discountPrice;

  final int stock;
  final String? imageUrl;
  final String categoryId;
  final String? categoryName;

  final String? sellerId;
  final String sellerName;

  /// KOPDES atau UMKM. Menentukan rute detail dan parameter keranjang.
  final bool isUmkm;

  final int? distanceMeters;
  final String? distanceLabel;
  final double? ratingAverage;
  final int ratingCount;

  const MarketplaceProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.discountPrice,
    required this.categoryId,
    required this.sellerName,
    required this.isUmkm,
    this.imageUrl,
    this.categoryName,
    this.sellerId,
    this.distanceMeters,
    this.distanceLabel,
    this.ratingAverage,
    this.ratingCount = 0,
  });

  bool get isOutOfStock => stock <= 0;

  /// Diskon hanya diakui bila harga coretnya memang lebih tinggi. Data yang
  /// terbalik lebih baik tampil sebagai harga biasa daripada sebagai "diskon
  /// -0%" atau kenaikan harga yang dibungkus lencana merah.
  bool get hasDiscount => discountPrice != null && discountPrice! > price;

  /// Persentase potongan, dibulatkan. Dipakai pada lencana "-20%".
  int get discountPercent => hasDiscount
      ? (((discountPrice! - price) / discountPrice!) * 100).round()
      : 0;
  bool get hasRating => ratingAverage != null && ratingCount > 0;

  /// Format Indonesia, koma sebagai pemisah desimal.
  String get ratingLabel => ratingAverage == null
      ? '-'
      : ratingAverage!.toStringAsFixed(1).replaceAll('.', ',');

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'] as Map<String, dynamic>? ?? const {};
    return MarketplaceProduct(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPrice: (json['discountPrice'] as num?)?.toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      sellerId: json['sellerId'] as String?,
      sellerName: json['sellerName'] as String? ?? '',
      isUmkm: json['source'] == 'UMKM',
      distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
      distanceLabel: json['distanceLabel'] as String?,
      ratingAverage: (rating['average'] as num?)?.toDouble(),
      ratingCount: (rating['count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Bentuknya sama persis dengan yang dikirim server, sehingga produk yang
  /// disimpan sebagai favorit dibaca kembali lewat [fromJson] yang sama —
  /// tidak ada jalur pemetaan kedua yang bisa diam-diam berbeda.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'discountPrice': discountPrice,
    'stock': stock,
    'imageUrl': imageUrl,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'sellerId': sellerId,
    'sellerName': sellerName,
    'source': isUmkm ? 'UMKM' : 'KOPDES',
    'distanceMeters': distanceMeters,
    'distanceLabel': distanceLabel,
    'rating': {'average': ratingAverage, 'count': ratingCount},
  };
}

/// Seluruh kondisi filter Marketplace.
///
/// Disimpan sebagai satu objek nilai supaya provider produk cukup mengamati
/// satu hal — tetapi setiap perubahannya hanya memuat ulang daftar produk,
/// bukan banner maupun lokasi.
class MarketplaceFilter {
  final String search;
  final SellerType sellerType;

  /// Kategori terpilih dari baris Makanan; null berarti "Semua".
  final String? foodCategoryId;

  /// Kategori terpilih dari baris Barang Ritel; null berarti belum dipilih.
  final String? retailCategoryId;

  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;

  /// Hanya produk yang sedang diskon. Disaring server; produk mitra tidak
  /// punya harga coret sehingga ikut tersaring keluar di sana.
  final bool discountedOnly;

  /// Rating rata-rata minimum, 0 berarti tanpa batas bawah.
  final double minRating;

  final MarketplaceSort sort;

  /// Radius pencarian dalam kilometer. Hanya berlaku pada pengurutan jarak:
  /// tanpa koordinat, server tidak punya titik acuan untuk menyaringnya.
  /// `null` berarti memakai bawaan server (25 km).
  final double? radiusKm;

  const MarketplaceFilter({
    this.search = '',
    this.sellerType = SellerType.all,
    this.foodCategoryId,
    this.retailCategoryId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.discountedOnly = false,
    this.minRating = 0,
    this.sort = MarketplaceSort.newest,
    this.radiusKm,
  });

  /// Backend hanya menerima satu `categoryId`. Pilihan yang terakhir
  /// ditetapkan menang, dan memilih di satu baris mengosongkan baris lain
  /// lewat [copyWith] — sehingga kedua baris tidak pernah saling menimpa
  /// secara diam-diam.
  String? get categoryId => foodCategoryId ?? retailCategoryId;

  bool get isDistanceSort => sort == MarketplaceSort.distance;

  bool get hasActiveFilter =>
      search.isNotEmpty ||
      sellerType != SellerType.all ||
      foodCategoryId != null ||
      retailCategoryId != null ||
      minPrice != null ||
      maxPrice != null ||
      inStockOnly ||
      discountedOnly ||
      minRating > 0 ||
      radiusKm != null ||
      sort != MarketplaceSort.newest;

  MarketplaceFilter copyWith({
    String? search,
    SellerType? sellerType,
    String? foodCategoryId,
    String? retailCategoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? discountedOnly,
    double? minRating,
    MarketplaceSort? sort,
    double? radiusKm,
    bool clearFood = false,
    bool clearRetail = false,
    bool clearPrice = false,
    bool clearRadius = false,
  }) => MarketplaceFilter(
    search: search ?? this.search,
    sellerType: sellerType ?? this.sellerType,
    foodCategoryId: clearFood ? null : (foodCategoryId ?? this.foodCategoryId),
    retailCategoryId: clearRetail
        ? null
        : (retailCategoryId ?? this.retailCategoryId),
    minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
    maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
    inStockOnly: inStockOnly ?? this.inStockOnly,
    discountedOnly: discountedOnly ?? this.discountedOnly,
    minRating: minRating ?? this.minRating,
    sort: sort ?? this.sort,
    radiusKm: clearRadius ? null : (radiusKm ?? this.radiusKm),
  );
}
