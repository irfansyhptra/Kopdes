/// Field katalog tambahan pada form Input Barang.
///
/// Dikumpulkan dalam satu objek, bukan delapan parameter bernama yang harus
/// diulang di form → provider → repository → data source. Serialisasinya jadi
/// `Map<String, String>` karena endpoint produk memakai multipart/form-data
/// (ada berkas gambar di request yang sama).
class ProductDraft {
  final double? discountPrice;
  final int? minStock;
  final String? unit;
  final String? sku;
  final bool? isPreOrderAllowed;
  final DateTime? preOrderAvailableAt;
  final bool? isActive;

  const ProductDraft({
    this.discountPrice,
    this.minStock,
    this.unit,
    this.sku,
    this.isPreOrderAllowed,
    this.preOrderAvailableAt,
    this.isActive,
  });

  /// Hanya field yang benar-benar diisi yang dikirim.
  ///
  /// Mengirim string kosong untuk field yang tidak disentuh akan menimpa nilai
  /// lama saat mengedit — SKU yang sudah ada akan terhapus hanya karena
  /// formnya dibuka dan disimpan lagi.
  Map<String, String> toFields() {
    return {
      if (discountPrice != null) 'discountPrice': discountPrice!.toString(),
      if (minStock != null) 'minStock': minStock!.toString(),
      if (unit != null && unit!.isNotEmpty) 'unit': unit!,
      if (sku != null && sku!.isNotEmpty) 'sku': sku!,
      if (isPreOrderAllowed != null)
        'isPreOrderAllowed': isPreOrderAllowed!.toString(),
      if (preOrderAvailableAt != null)
        'preOrderAvailableAt': preOrderAvailableAt!.toUtc().toIso8601String(),
      if (isActive != null) 'isActive': isActive!.toString(),
    };
  }

  bool get isEmpty => toFields().isEmpty;
}
