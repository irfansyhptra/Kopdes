import '../../../../core/network/paginated.dart';
import 'product_model.dart';

/// Status stok satu produk, menurut ambang dari backend.
enum StockLevel {
  out('out', 'Habis'),
  low('low', 'Menipis'),
  safe('safe', 'Aman');

  /// Nilai `stockStatus` di `GET /seller/products`.
  final String wire;
  final String label;

  const StockLevel(this.wire, this.label);

  /// [threshold] datang dari respons (`lowStockThreshold`), bukan angka
  /// yang ditulis di widget — aturannya milik backend.
  static StockLevel of(int stock, int threshold) => stock <= 0
      ? StockLevel.out
      : stock <= threshold
      ? StockLevel.low
      : StockLevel.safe;
}

/// Hitungan stok seluruh produk yang cocok dengan pencarian + kategori.
///
/// Dihitung server, bukan dari halaman yang sudah dimuat: menghitung 20
/// baris pertama memberi "2 menipis" di toko yang punya 30.
class StockSummary {
  final int safe;
  final int low;
  final int out;

  const StockSummary({this.safe = 0, this.low = 0, this.out = 0});

  int get total => safe + low + out;

  factory StockSummary.fromJson(Map<String, dynamic>? json) => StockSummary(
    safe: (json?['safe'] as num?)?.toInt() ?? 0,
    low: (json?['low'] as num?)?.toInt() ?? 0,
    out: (json?['out'] as num?)?.toInt() ?? 0,
  );

  int of(StockLevel level) => switch (level) {
    StockLevel.safe => safe,
    StockLevel.low => low,
    StockLevel.out => out,
  };

  StockSummary _with(StockLevel level, int delta) => StockSummary(
    safe: level == StockLevel.safe ? safe + delta : safe,
    low: level == StockLevel.low ? low + delta : low,
    out: level == StockLevel.out ? out + delta : out,
  );

  /// Satu produk pindah status — hasil penyesuaian stok yang sudah diterima
  /// server. Menghitung ulang tanpa memuat ulang seluruh daftar.
  StockSummary move(StockLevel from, StockLevel to) =>
      from == to ? this : _with(from, -1)._with(to, 1);

  /// Satu produk dihapus.
  StockSummary remove(StockLevel level) => _with(level, -1);
}

/// Satu halaman `GET /seller/products`.
class SellerProductPage {
  final Paginated<ProductModel> page;
  final StockSummary summary;
  final int lowStockThreshold;

  const SellerProductPage({
    required this.page,
    required this.summary,
    required this.lowStockThreshold,
  });

  /// Cerminan `LOW_STOCK_THRESHOLD` di backend, hanya untuk respons lama
  /// yang belum mengirim `lowStockThreshold`.
  static const int _legacyThreshold = 5;

  factory SellerProductPage.fromJson(Map<String, dynamic> json) =>
      SellerProductPage(
        page: Paginated.fromJson(json, 'products', ProductModel.fromJson),
        summary: StockSummary.fromJson(
          json['summary'] as Map<String, dynamic>?,
        ),
        lowStockThreshold:
            (json['lowStockThreshold'] as num?)?.toInt() ?? _legacyThreshold,
      );
}
