import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/umkm/data/models/seller_model.dart';
import 'package:kopdes/features/umkm/data/models/store_model.dart';

/// Muatan `/seller/dashboard` apa adanya, disalin dari bentuk yang benar-benar
/// dikirim `SellerService.getDashboard` — termasuk kenyataan bahwa `storeInfo`
/// TIDAK memuat `userId`.
const _dashboardPayload = {
  'storeInfo': {
    'id': 'umkm-1',
    'businessName': 'AR Kopi',
    'description': 'Kopi Aceh seduh dan biji kopi Gayo.',
    'address': 'Kec. Syiah Kuala, Banda Aceh',
    'phone': '081360000202',
    'status': 'ACTIVE',
    'verifiedAt': '2026-10-02T00:00:00.000Z',
  },
  'stats': {
    'totalProducts': 3,
    'totalOrders': 0,
    'productsSold': 0,
    'todayEarnings': 0,
    'monthlyEarnings': 0,
    'storeRating': 0,
    'lowStockCount': 0,
    'newOrdersCount': 0,
  },
  'lowStockProducts': [],
  'recentActivities': [],
};

void main() {
  group('SellerModel dari respons server sungguhan', () {
    // Inilah bug-nya: `userId` dibaca `as String` padahal dasbor tidak
    // mengirimnya, jadi seluruh halaman gagal dengan "Data toko belum
    // berhasil dimuat" meski API menjawab 200.
    test('dasbor terbaca walau storeInfo tanpa userId', () {
      final model = SellerModel.fromJson(
        Map<String, dynamic>.from(_dashboardPayload),
      );

      expect(model.storeInfo.businessName, 'AR Kopi');
      expect(model.storeInfo.status, 'ACTIVE');
      expect(model.stats.totalProducts, 3);
    });

    test('produk stok menipis dengan rating yang tidak dikirim', () {
      final payload = Map<String, dynamic>.from(_dashboardPayload);
      payload['lowStockProducts'] = [
        {
          'id': 'p1',
          'name': 'Kopi Sanger Panas',
          'description': 'x',
          'price': 12000,
          'stock': 2,
          'categoryId': 'c1',
          'isApproved': true,
          'isActive': true,
        },
      ];

      final model = SellerModel.fromJson(payload);
      expect(model.lowStockProducts.single.stock, 2);
      // UMKMProduct tidak punya kolom rating; nol, bukan lemparan.
      expect(model.lowStockProducts.single.rating, 0.0);
    });

    test('aktivitas terbaru terbaca', () {
      final payload = Map<String, dynamic>.from(_dashboardPayload);
      payload['recentActivities'] = [
        {
          'type': 'ORDER',
          'title': 'Pesanan Baru Masuk',
          'description': 'Budi membeli 2x Kopi Sanger',
          'timestamp': '2026-10-03T08:00:00.000Z',
        },
      ];

      final model = SellerModel.fromJson(payload);
      expect(model.recentActivities.single.type, 'ORDER');
    });
  });

  group('StoreModel', () {
    test('profil lengkap dari /seller/profile tetap terbaca', () {
      final store = StoreModel.fromJson(const {
        'id': 'umkm-1',
        'userId': 'user-1',
        'businessName': 'AR Kopi',
        'description': 'Kopi',
        'address': 'Lamgugop',
        'phone': '0813',
        'status': 'ACTIVE',
      });

      expect(store.id, 'umkm-1');
      expect(store.businessName, 'AR Kopi');
    });

    test('kolom yang hilang jadi nilai bawaan, bukan lemparan', () {
      final store = StoreModel.fromJson(const {'id': 'umkm-1'});

      expect(store.businessName, 'Toko UMKM');
      expect(store.status, 'PENDING_VERIFICATION');
      expect(store.phone, '');
    });
  });
}
