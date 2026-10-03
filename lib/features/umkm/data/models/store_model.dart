/// Profil toko mitra UMKM.
///
/// Dipakai dua bentuk respons sekaligus: `/seller/profile` mengirim baris
/// UMKM lengkap, sedangkan `storeInfo` di `/seller/dashboard` hanya mengirim
/// kolom yang perlu ditampilkan. Model ini harus memuat irisan keduanya.
class StoreModel {
  final String id;
  final String businessName;
  final String description;
  final String address;
  final String phone;
  final String status;

  const StoreModel({
    required this.id,
    required this.businessName,
    required this.description,
    required this.address,
    required this.phone,
    required this.status,
  });

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
    };
  }
}
