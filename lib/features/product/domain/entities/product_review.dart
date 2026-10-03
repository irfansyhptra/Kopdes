/// Satu ulasan pembeli atas sebuah produk.
class ProductReview {
  final String id;
  final int rating;
  final String? comment;
  final String reviewerName;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.rating,
    required this.reviewerName,
    required this.createdAt,
    this.comment,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ProductReview(
      id: json['id'] as String? ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      // Tanpa nama, ulasannya tetap ditampilkan sebagai "Warga Desa" — ulasan
      // anonim lebih berguna daripada ulasan yang disembunyikan.
      reviewerName: user?['name'] as String? ?? 'Warga Desa',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
