import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/discovery/domain/discovery.dart';

DiscoveryProduct _product({
  String source = 'KOPERASI',
  int? soldCount,
  int stock = 10,
}) => DiscoveryProduct.fromJson({
  'id': 'p1',
  'name': 'Kue Adee',
  'price': 25000,
  'stock': stock,
  'sellerName': 'Dapur Kak Nur',
  'source': source,
  if (soldCount != null) 'soldCount': soldCount,
});

void main() {
  group('ProductSource', () {
    // Menentukan parameter keranjang mana yang dipakai dan rute mana yang
    // dibuka. Salah baca di sini berarti setiap produk UMKM gagal 404.
    test('membaca sumber dari backend', () {
      expect(_product(source: 'UMKM').source, ProductSource.umkm);
      expect(_product(source: 'KOPERASI').source, ProductSource.koperasi);
    });

    test('sumber tak dikenal jatuh ke koperasi, bukan melempar', () {
      expect(_product(source: 'ENTAH').source, ProductSource.koperasi);
      expect(
        DiscoveryProduct.fromJson({
          'id': 'p1',
          'name': 'x',
          'price': 1,
          'stock': 1,
          'sellerName': 's',
        }).source,
        ProductSource.koperasi,
      );
    });
  });

  group('soldLabel', () {
    // Dibulatkan ke bawah supaya angkanya tidak pernah melebih-lebihkan.
    test('membulatkan ke bawah pada kelipatan sepuluh', () {
      expect(_product(soldCount: 48).soldLabel, 'Terjual 40+');
      expect(_product(soldCount: 240).soldLabel, 'Terjual 240+');
      expect(_product(soldCount: 249).soldLabel, 'Terjual 240+');
    });

    test('di bawah sepuluh ditampilkan apa adanya', () {
      expect(_product(soldCount: 7).soldLabel, 'Terjual 7');
    });

    test('null bila tidak ada penjualan', () {
      expect(_product().soldLabel, isNull);
      expect(_product(soldCount: 0).soldLabel, isNull);
    });
  });

  group('stok', () {
    test('stok nol atau kurang dianggap habis', () {
      expect(_product(stock: 0).isOutOfStock, isTrue);
      expect(_product(stock: -1).isOutOfStock, isTrue);
      expect(_product(stock: 1).isOutOfStock, isFalse);
    });
  });

  group('UmkmProductDetail', () {
    test('membaca relasi umkm, gambar, dan rating', () {
      final detail = UmkmProductDetail.fromJson({
        'id': 'up1',
        'name': 'Kue Adee',
        'description': 'Kue khas Aceh',
        'price': 25000,
        'stock': 40,
        'images': [
          {'url': 'https://x/1.jpg'},
          {'url': 'https://x/2.jpg'},
        ],
        'category': {'name': 'Makanan'},
        'umkm': {
          'id': 'u1',
          'businessName': 'Dapur Kak Nur',
          'address': 'Desa Lamteh',
          'phone': '0811',
        },
        'rating': {'average': 4.8, 'count': 4},
      });

      expect(detail.umkmId, 'u1');
      expect(detail.sellerName, 'Dapur Kak Nur');
      expect(detail.primaryImageUrl, 'https://x/1.jpg');
      expect(detail.imageUrls.length, 2);
      expect(detail.ratingAverage, 4.8);
      expect(detail.categoryName, 'Makanan');
      expect(detail.isOutOfStock, isFalse);
    });

    test('relasi kosong tidak membuat parsing gagal', () {
      final detail = UmkmProductDetail.fromJson({
        'id': 'up1',
        'name': 'Tanpa relasi',
        'price': 1000,
        'stock': 0,
      });

      expect(detail.umkmId, '');
      expect(detail.sellerName, 'Mitra UMKM');
      expect(detail.primaryImageUrl, isNull);
      expect(detail.ratingAverage, isNull);
      expect(detail.ratingCount, 0);
      expect(detail.isOutOfStock, isTrue);
    });

    test('gambar dengan url kosong dibuang', () {
      final detail = UmkmProductDetail.fromJson({
        'id': 'up1',
        'name': 'x',
        'price': 1,
        'stock': 1,
        'images': [
          {'url': ''},
          {'url': 'https://x/ok.jpg'},
        ],
      });

      expect(detail.imageUrls, ['https://x/ok.jpg']);
    });
  });
}
