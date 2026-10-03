/// Ringkasan rating hasil agregasi ulasan pengguna.
///
/// [average] bernilai null bila belum ada yang menilai — bukan 0. Nol terbaca
/// sebagai "dinilai sangat buruk", dan UI harus bisa membedakan keduanya.
class RatingSummary {
  final double? average;
  final int count;

  const RatingSummary({this.average, this.count = 0});

  bool get hasRating => average != null && count > 0;

  /// Format Indonesia: koma sebagai pemisah desimal.
  String get label =>
      average == null ? '-' : average!.toStringAsFixed(1).replaceAll('.', ',');

  factory RatingSummary.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) return const RatingSummary();
    return RatingSummary(
      average: (json['average'] as num?)?.toDouble(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Koperasi Desa Merah Putih.
class Koperasi {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? imageUrl;
  final String address;
  final String village;
  final String district;
  final String city;
  final String province;
  final double latitude;
  final double longitude;
  final String? phone;
  final List<String> serviceCategories;
  final bool isVerified;

  /// Jarak dari pengguna. Selalu dihitung server — jarak yang dikirim klien
  /// tidak pernah dipercaya. Null bila pencarian tanpa konteks lokasi.
  final int? distanceMeters;
  final String? distanceLabel;

  /// `null` berarti jam operasional belum diisi, bukan "tutup".
  final bool? isOpen;

  /// Dihitung server dari ulasan pengguna.
  final RatingSummary rating;

  /// Pengurus yang bisa dihubungi warga — tujuan tombol "Chat Toko".
  /// `null` bila koperasinya belum punya pengurus; tombolnya tidak digambar.
  final String? adminUserId;

  const Koperasi({
    required this.id,
    required this.name,
    required this.address,
    required this.village,
    required this.district,
    required this.city,
    required this.province,
    required this.latitude,
    required this.longitude,
    required this.serviceCategories,
    required this.isVerified,
    this.description,
    this.logoUrl,
    this.imageUrl,
    this.phone,
    this.distanceMeters,
    this.distanceLabel,
    this.isOpen,
    this.rating = const RatingSummary(),
    this.adminUserId,
  });

  /// Alamat singkat untuk card.
  String get shortAddress => '$village, $district';

  factory Koperasi.fromJson(Map<String, dynamic> json) => Koperasi(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    logoUrl: json['logoUrl'] as String?,
    imageUrl: json['imageUrl'] as String?,
    address: json['address'] as String? ?? '',
    village: json['village'] as String? ?? '',
    district: json['district'] as String? ?? '',
    city: json['city'] as String? ?? '',
    province: json['province'] as String? ?? '',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    phone: json['phone'] as String?,
    serviceCategories:
        (json['serviceCategories'] as List?)?.whereType<String>().toList() ??
        const [],
    isVerified: json['isVerified'] as bool? ?? false,
    distanceMeters: (json['distanceMeters'] as num?)?.round(),
    distanceLabel: json['distanceLabel'] as String?,
    isOpen: json['isOpen'] as bool?,
    rating: RatingSummary.fromJson(json['rating']),
    adminUserId: json['adminUserId'] as String?,
  );
}

/// Kategori usaha Mitra UMKM. Nilainya mengikuti enum `UMKMCategory` backend.
enum MitraCategory {
  kuliner('KULINER', 'Kuliner'),
  swalayan('SWALAYAN', 'Swalayan'),
  minuman('MINUMAN', 'Minuman'),
  kerajinan('KERAJINAN', 'Kerajinan'),
  jasa('JASA', 'Jasa'),
  lainnya('LAINNYA', 'Lainnya');

  final String wire;
  final String label;

  const MitraCategory(this.wire, this.label);

  static MitraCategory fromWire(String? value) => MitraCategory.values
      .firstWhere((c) => c.wire == value, orElse: () => MitraCategory.lainnya);
}

/// Mitra UMKM di bawah naungan sebuah Kopdes.
class Mitra {
  final String id;
  final String businessName;
  final String description;
  final String address;
  final String? phone;
  final String? photoUrl;
  final MitraCategory category;
  final double? latitude;
  final double? longitude;
  final int? distanceMeters;
  final String? distanceLabel;
  final bool? isOpen;
  final RatingSummary rating;

  /// Pemilik tokonya — tujuan tombol "Chat Toko".
  final String? ownerUserId;

  /// Kopdes yang menaungi mitra ini. Mitra tidak bisa berjualan tanpa
  /// diverifikasi salah satu Kopdes, jadi namanya selalu layak ditampilkan.
  final String? kopdesName;

  const Mitra({
    required this.id,
    required this.businessName,
    required this.description,
    required this.address,
    required this.category,
    this.phone,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.distanceLabel,
    this.isOpen,
    this.rating = const RatingSummary(),
    this.ownerUserId,
    this.kopdesName,
  });

  factory Mitra.fromJson(Map<String, dynamic> json) => Mitra(
    id: json['id'] as String,
    businessName: json['businessName'] as String? ?? '',
    description: json['description'] as String? ?? '',
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String?,
    photoUrl: json['photoUrl'] as String?,
    category: MitraCategory.fromWire(json['category'] as String?),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    distanceMeters: (json['distanceMeters'] as num?)?.round(),
    distanceLabel: json['distanceLabel'] as String?,
    isOpen: json['isOpen'] as bool?,
    rating: RatingSummary.fromJson(json['rating']),
    ownerUserId: json['userId'] as String?,
    kopdesName: (json['kopdes'] as Map<String, dynamic>?)?['name'] as String?,
  );
}
