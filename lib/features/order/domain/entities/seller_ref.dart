/// Penjual di balik satu baris keranjang atau pesanan.
///
/// Keranjang dan pesanan sama-sama memuat dua jenis produk — milik Kopdes
/// (`product`) dan milik Mitra UMKM (`umkmProduct`) — dengan relasi penjual
/// yang berbeda nama. Kelas ini menyatukan keduanya sehingga UI tidak perlu
/// tahu dari relasi mana nama toko itu datang.
class SellerRef {
  final String? id;
  final String? name;

  /// True untuk produk Mitra UMKM, false untuk produk Kopdes.
  final bool isUmkm;

  /// Kopdes selalu resmi. Mitra UMKM hanya terverifikasi setelah admin Kopdes
  /// desanya menyetujui pendaftaran (`UMKMStatus.ACTIVE`).
  final bool verified;

  const SellerRef({
    this.id,
    this.name,
    this.isUmkm = false,
    this.verified = false,
  });

  /// Nama toko dari backend selalu didahulukan. Teks cadangan hanya muncul
  /// bila relasi penjual belum ikut terkirim — lebih baik menyebut jenis
  /// tokonya daripada menampilkan grup tanpa judul.
  String get label => name ?? (isUmkm ? 'Mitra UMKM' : 'Kopdes');

  /// Lencana ditulis, bukan sekadar diwarnai — hijau dan ungu saja tidak
  /// cukup membedakan bagi pengguna yang sulit membedakan warna.
  String get badge => isUmkm ? 'MITRA UMKM' : 'KOPDES';

  /// Kunci pengelompokan. Tanpa `id`, seluruh produk yang penjualnya tidak
  /// diketahui berkumpul menjadi satu grup — bukan satu grup per produk.
  String get groupKey => id ?? (isUmkm ? '_umkm' : '_kopdes');

  /// Dibaca dari `product.kopdes` atau `umkmProduct.umkm`. Keduanya baru ada
  /// setelah backend menyertakan relasi penjual pada respons `/cart`,
  /// `/orders/history`, dan `/orders/:id`.
  factory SellerRef.fromItemJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final umkmProduct = json['umkmProduct'] as Map<String, dynamic>?;

    final kopdes = product?['kopdes'] as Map<String, dynamic>?;
    if (kopdes != null) {
      return SellerRef(
        id: kopdes['id'] as String?,
        name: kopdes['name'] as String?,
        verified: true,
      );
    }

    final umkm = umkmProduct?['umkm'] as Map<String, dynamic>?;
    if (umkm != null) {
      return SellerRef(
        id: umkm['id'] as String?,
        name: umkm['businessName'] as String?,
        isUmkm: true,
        verified: umkm['status'] == 'ACTIVE',
      );
    }

    return SellerRef(isUmkm: json['umkmProductId'] != null);
  }
}
