import 'package:flutter/foundation.dart';

/// Komponen uang satu pesanan, dalam rupiah bulat.
///
/// Rumusnya kembar dari `composeOrderTotals` di
/// `backend/src/modules/order/order-money.ts`, dan **backend yang berwenang**:
/// nilai yang ditagihkan selalu dihitung ulang di server, angka di layar
/// hanya menampilkannya.
///
/// Kelas ini ada karena sebelumnya tiap layar menyusun totalnya sendiri —
/// layar checkout bahkan menambahkan ongkir Rp10.000 dan biaya layanan
/// Rp2.000 yang tidak pernah ditagihkan, sehingga pemesan melihat total
/// Rp12.000 lebih besar daripada yang benar-benar dibayarnya.
@immutable
class OrderTotals {
  final int subtotal;
  final int shippingFee;
  final int discountAmount;

  const OrderTotals({
    required this.subtotal,
    this.shippingFee = 0,
    this.discountAmount = 0,
  });

  /// Diskon dipotong sampai nilai barang — total negatif berarti koperasi
  /// membayar pembeli, dan tidak ada jalur pengembalian uang untuk itu.
  int get effectiveDiscount =>
      discountAmount > subtotal ? subtotal : discountAmount;

  int get total => subtotal + shippingFee - effectiveDiscount;

  bool get hasShipping => shippingFee > 0;
  bool get hasDiscount => effectiveDiscount > 0;

  /// Ongkir gratis ditulis sebagai kata, bukan "Rp0" — itu yang dibaca
  /// pemesan sebagai kabar baik, bukan sebagai nominal.
  String get shippingLabel =>
      hasShipping ? formatRupiah(shippingFee) : 'Gratis';
}

/// "Rp3.450.000" — pemisah ribuan Indonesia, dari integer.
///
/// Integer, bukan `double`: total keranjang dijumlahkan dari nilai baris yang
/// sudah dibulatkan, dan `toStringAsFixed` pada `double` mulai menggeser
/// angka terakhir jauh sebelum nominalnya tidak masuk akal.
String formatRupiah(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  return '${negative ? '-' : ''}Rp$buffer';
}
