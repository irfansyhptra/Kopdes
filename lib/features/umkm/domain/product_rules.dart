/// Batas isian produk UMKM — cerminan `PRODUCT_RULES` di backend
/// (`backend/src/modules/seller/dto/product-rules.ts`). Ubah keduanya
/// bersamaan.
class ProductRules {
  static const int nameMin = 3;
  static const int nameMax = 120;
  static const int descriptionMax = 500;
  static const int priceMin = 1;
  static const int priceMax = 9999999999;
  static const int stockMax = 9999999;
  static const int maxPhotos = 5;

  /// Batas per foto setelah dikompres. Backend menolak di atas 4 MB, dan
  /// Vercel menolak badan permintaan di atas 4,5 MB.
  static const int maxPhotoBytes = 4 * 1024 * 1024;

  static String? name(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Nama produk wajib diisi.';
    if (v.length < nameMin) return 'Nama produk minimal $nameMin huruf.';
    if (v.length > nameMax) return 'Nama produk maksimal $nameMax huruf.';
    return null;
  }

  static String? category(String? id) =>
      (id == null || id.isEmpty) ? 'Pilih kategori produknya.' : null;

  static String? description(String value) =>
      value.trim().length > descriptionMax
      ? 'Deskripsi maksimal $descriptionMax huruf.'
      : null;

  /// [digits] hanya angka — pemisah ribuan sudah dibuang formatter.
  static String? price(String digits) {
    if (digits.isEmpty) return 'Harga jual wajib diisi.';
    final v = int.tryParse(digits);
    if (v == null) return 'Harga harus berupa angka.';
    if (v < priceMin) return 'Harga minimal Rp$priceMin.';
    if (v > priceMax) return 'Harga terlalu besar — periksa lagi angkanya.';
    return null;
  }

  static String? stock(String digits) {
    if (digits.isEmpty) return 'Stok awal wajib diisi — isi 0 bila belum ada.';
    final v = int.tryParse(digits);
    if (v == null) return 'Stok harus angka bulat.';
    if (v < 0) return 'Stok tidak boleh negatif.';
    if (v > stockMax) return 'Stok maksimal $stockMax.';
    return null;
  }
}
