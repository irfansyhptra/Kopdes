/// Jam buka satu hari, "HH:MM".
class DayHours {
  final String open;
  final String close;

  const DayHours(this.open, this.close);

  Map<String, String> toJson() => {'open': open, 'close': close};

  @override
  bool operator ==(Object other) =>
      other is DayHours && other.open == open && other.close == close;

  @override
  int get hashCode => Object.hash(open, close);
}

/// Kunci hari seperti di backend (`opening-hours.util.ts`), Senin dulu.
const weekDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const weekDayLabels = {
  'mon': 'Senin',
  'tue': 'Selasa',
  'wed': 'Rabu',
  'thu': 'Kamis',
  'fri': 'Jumat',
  'sat': 'Sabtu',
  'sun': 'Minggu',
};

/// Kategori usaha UMKM (`enum UMKMCategory`).
const umkmCategories = {
  'KULINER': 'Kuliner',
  'SWALAYAN': 'Swalayan',
  'MINUMAN': 'Minuman',
  'KERAJINAN': 'Kerajinan',
  'JASA': 'Jasa',
  'LAINNYA': 'Lainnya',
};

/// Profil toko mitra UMKM.
///
/// Dipakai dua bentuk respons sekaligus: `/seller/profile` mengirim profil
/// lengkap, sedangkan `storeInfo` di `/seller/dashboard` hanya mengirim
/// kolom yang perlu ditampilkan. Semua kolom selain yang dimiliki keduanya
/// boleh kosong.
class StoreModel {
  final String id;
  final String businessName;
  final String description;
  final String address;
  final String phone;

  /// `UMKMStatus`: PENDING_VERIFICATION, ACTIVE, REJECTED, SUSPENDED.
  final String status;
  final String? rejectionReason;
  final String category;
  final String? photoUrl;
  final String? bannerUrl;

  /// null = jam buka belum pernah diisi; hari bernilai null = tutup.
  final Map<String, DayHours?>? operatingHours;

  /// Dihitung server dari [operatingHours]: null bila belum diisi.
  final bool? isOpen;
  final String? kopdesName;

  const StoreModel({
    required this.id,
    required this.businessName,
    required this.description,
    required this.address,
    required this.phone,
    required this.status,
    this.rejectionReason,
    this.category = 'LAINNYA',
    this.photoUrl,
    this.bannerUrl,
    this.operatingHours,
    this.isOpen,
    this.kopdesName,
  });

  bool get isVerified => status == 'ACTIVE';

  /// `userId` sengaja TIDAK ada di sini.
  ///
  /// Dulu ada, dan dibaca `json['userId'] as String` — padahal `storeInfo`
  /// pada respons dasbor tidak pernah memuatnya. Hasilnya `null as String`
  /// melempar TypeError, FutureProvider-nya gagal, dan seluruh dasbor penjual
  /// menampilkan "Data toko belum berhasil dimuat" meski API-nya menjawab
  /// 200. Kolomnya juga tidak pernah dipakai di mana pun.
  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String? ?? '',
      businessName: json['businessName'] as String? ?? 'Toko UMKM',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING_VERIFICATION',
      rejectionReason: json['rejectionReason'] as String?,
      category: json['category'] as String? ?? 'LAINNYA',
      photoUrl: json['photoUrl'] as String?,
      bannerUrl: json['bannerUrl'] as String?,
      operatingHours: _hours(json['operatingHours']),
      isOpen: json['isOpen'] as bool?,
      kopdesName: (json['kopdes'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }

  static Map<String, DayHours?>? _hours(Object? raw) {
    if (raw is! Map || raw.isEmpty) return null;
    return {
      for (final d in weekDays)
        d: switch (raw[d]) {
          {'open': final String o, 'close': final String c} => DayHours(o, c),
          _ => null,
        },
    };
  }

  /// Profil Kopdes (`/admin/kopdes/profile`) dalam bentuk profil toko, supaya
  /// tab, form edit, dan pengaturan jam buka dipakai bersama. Kopdes tidak
  /// melewati verifikasi mitra: "ACTIVE" berarti sudah diverifikasi
  /// pengelola sistem.
  factory StoreModel.fromKopdesJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String? ?? '',
      businessName: json['name'] as String? ?? 'Kopdes',
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['isVerified'] == true ? 'ACTIVE' : 'PENDING_VERIFICATION',
      photoUrl: json['logoUrl'] as String?,
      bannerUrl: json['imageUrl'] as String?,
      operatingHours: _hours(json['operatingHours']),
      isOpen: json['isOpen'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessName': businessName,
      'description': description,
      'address': address,
      'phone': phone,
      'status': status,
      'photoUrl': photoUrl,
      'bannerUrl': bannerUrl,
    };
  }
}
