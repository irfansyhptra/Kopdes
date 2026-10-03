import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/product_review.dart';

/// Ulasan terbaru sebuah produk.
///
/// Dibatasi lima: halaman detail menampilkannya sebagai cuplikan, bukan
/// sebagai daftar lengkap. Memuat semuanya membuat produk populer menarik
/// ratusan baris yang tidak pernah tergulir.
const int productReviewPreviewLimit = 5;

final productReviewsProvider =
    FutureProvider.family<List<ProductReview>, String>((ref, productId) async {
      final dio = ref.watch(dioProvider);
      try {
        final response = await dio.get<dynamic>(
          '/reviews',
          queryParameters: {
            'productId': productId,
            'limit': productReviewPreviewLimit,
          },
        );

        final map = response.data as Map<String, dynamic>;
        // Controller ulasan menyebar hasilnya di akar (`{ success, ...data }`)
        // dengan kunci `items`, bukan di dalam `data` seperti endpoint lain.
        final list = (map['items'] ?? const []) as List;

        return list
            .whereType<Map<String, dynamic>>()
            .map(ProductReview.fromJson)
            .toList(growable: false);
      } on DioException {
        // Ulasan yang gagal dimuat tidak boleh menjatuhkan halaman produk —
        // bagiannya saja yang kosong.
        return const [];
      }
    });
