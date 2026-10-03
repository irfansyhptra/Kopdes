import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

/// Produk pada sebuah pesanan yang belum diulas pengguna ini.
class ReviewableItem {
  final String? productId;
  final String? umkmProductId;
  final String name;

  const ReviewableItem({
    this.productId,
    this.umkmProductId,
    required this.name,
  });

  factory ReviewableItem.fromJson(Map<String, dynamic> json) {
    return ReviewableItem(
      productId: json['productId'] as String?,
      umkmProductId: json['umkmProductId'] as String?,
      name: json['name'] as String? ?? '',
    );
  }

  /// Kunci stabil untuk daftar pilihan produk di lembar ulasan.
  String get key => productId ?? umkmProductId ?? name;
}

/// Klien endpoint ulasan.
///
/// Daftar "yang boleh diulas" datang dari server, bukan disimpulkan di layar:
/// syaratnya adalah pesanan itu milik pengguna, sudah diterima, dan produknya
/// belum pernah ia ulas — tiga hal yang hanya diketahui backend.
class ReviewRepository {
  final Dio dio;

  const ReviewRepository(this.dio);

  Future<List<ReviewableItem>> reviewableItems(String orderId) async {
    final res = await dio.get<dynamic>('/reviews/reviewable/$orderId');
    final data = res.data as Map<String, dynamic>;
    final items = data['items'] as List? ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(ReviewableItem.fromJson)
        .toList(growable: false);
  }

  Future<void> submit({
    required String orderId,
    String? productId,
    String? umkmProductId,
    required int rating,
    String? comment,
  }) {
    return dio.post(
      '/reviews',
      data: {
        'orderId': orderId,
        if (productId != null) 'productId': productId,
        if (umkmProductId != null) 'umkmProductId': umkmProductId,
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewRepository(ref.watch(dioProvider)),
);

/// Produk yang masih bisa diulas pada satu pesanan.
///
/// `autoDispose` dan `family`: hanya diminta saat kartu pesanan selesai
/// benar-benar tampil, dan dibuang begitu kartunya lepas dari layar.
final reviewableItemsProvider = FutureProvider.autoDispose
    .family<List<ReviewableItem>, String>((ref, orderId) {
      return ref.watch(reviewRepositoryProvider).reviewableItems(orderId);
    });

/// Satu ulasan yang sudah tayang.
class ProductReview {
  final String id;
  final String reviewerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return ProductReview(
      id: json['id'] as String? ?? '',
      reviewerName: user?['name'] as String? ?? 'Pembeli',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] as String?)?.trim(),
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    );
  }
}

/// Daftar ulasan sebuah produk beserta rata-ratanya.
class ProductReviewPage {
  final List<ProductReview> items;
  final double? averageRating;
  final int total;

  const ProductReviewPage({
    required this.items,
    required this.averageRating,
    required this.total,
  });

  static const ProductReviewPage empty = ProductReviewPage(
    items: [],
    averageRating: null,
    total: 0,
  );
}

/// Produk yang ulasannya diminta — tepat satu dari keduanya, sesuai aturan
/// endpoint: mengirim dua-duanya atau tidak sama sekali dijawab 400.
class ReviewTarget {
  final String? productId;
  final String? umkmProductId;

  const ReviewTarget.kopdes(String id) : productId = id, umkmProductId = null;
  const ReviewTarget.umkm(String id) : productId = null, umkmProductId = id;

  @override
  bool operator ==(Object other) =>
      other is ReviewTarget &&
      other.productId == productId &&
      other.umkmProductId == umkmProductId;

  @override
  int get hashCode => Object.hash(productId, umkmProductId);
}

/// Ulasan nyata sebuah produk.
///
/// Menggantikan daftar ulasan karangan di halaman detail produk penjual, yang
/// dipilih dengan `productId.hashCode % 2 == 0` — separuh produk selalu punya
/// dua ulasan bintang lima dari nama yang sama, separuh lagi selalu kosong.
final productReviewsProvider =
    FutureProvider.family<ProductReviewPage, ReviewTarget>((ref, target) async {
      final dio = ref.watch(dioProvider);
      final res = await dio.get<dynamic>(
        '/reviews',
        queryParameters: {
          if (target.productId != null) 'productId': target.productId,
          if (target.umkmProductId != null)
            'umkmProductId': target.umkmProductId,
          'limit': 5,
        },
      );

      final map = res.data as Map<String, dynamic>;
      final items = (map['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProductReview.fromJson)
          .toList(growable: false);
      final meta = map['meta'] as Map<String, dynamic>?;

      return ProductReviewPage(
        items: items,
        averageRating: (map['averageRating'] as num?)?.toDouble(),
        total: (meta?['total'] as num?)?.toInt() ?? items.length,
      );
    });
