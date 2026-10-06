import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kopdes/features/koperasi/domain/koperasi.dart';
import 'package:kopdes/features/koperasi/presentation/widgets/koperasi_card.dart';
import 'package:kopdes/features/koperasi/presentation/widgets/mitra_card.dart';
import 'package:kopdes/shared/widgets/product_image_loader.dart';

const _logoKopdes = 'https://res.cloudinary.com/demo/kopdes/logo.jpg';
const _bannerKopdes = 'https://res.cloudinary.com/demo/kopdes/banner.jpg';
const _logoMitra = 'https://res.cloudinary.com/demo/mitra/logo.jpg';
const _bannerMitra = 'https://res.cloudinary.com/demo/mitra/banner.jpg';

Koperasi _kopdes({String? logo = _logoKopdes, String? banner = _bannerKopdes}) =>
    Koperasi.fromJson({
      'id': 'kop-1',
      'name': 'Kopdes Lamgugop',
      'description': 'Toko ritel dan marketplace desa.',
      'logoUrl': logo,
      'imageUrl': banner,
      'address': 'Jl. Lamgugop No. 1',
      'village': 'Lamgugop',
      'district': 'Syiah Kuala',
      'city': 'Banda Aceh',
      'province': 'Aceh',
      'latitude': 5.57,
      'longitude': 95.35,
      'serviceCategories': ['Sembako'],
      'isVerified': true,
    });

Map<String, dynamic> _mitraJson({
  String? photo = _logoMitra,
  String? banner = _bannerMitra,
}) => {
  'id': 'umkm-1',
  'businessName': 'Warung Nasi Mami Yose',
  'description': 'Masakan rumahan Aceh.',
  'address': 'Jl. Prada Utama',
  'phone': '081300000001',
  'photoUrl': photo,
  'bannerUrl': banner,
  'category': 'KULINER',
  'latitude': 5.56,
  'longitude': 95.34,
};

/// URL yang benar-benar diminta widget, dalam urutan munculnya.
List<String> _requestedUrls(WidgetTester tester) => tester
    .widgetList<ProductImageLoader>(find.byType(ProductImageLoader))
    .map((w) => w.imageUrl)
    .toList();

Widget _host(Widget child, {double width = 390, double scale = 1.0}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 900),
          textScaler: TextScaler.linear(scale),
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: child,
          ),
        ),
      ),
    );

void main() {
  group('Mitra.fromJson', () {
    test('membaca bannerUrl yang dikirim backend', () {
      // Backend mengirim bannerUrl sejak lama (mitra.service.ts). Model dulu
      // membuangnya, jadi sampul mitra tidak pernah bisa tampil di mana pun.
      expect(Mitra.fromJson(_mitraJson()).bannerUrl, _bannerMitra);
    });

    test('bannerUrl null bila toko belum mengunggah sampul', () {
      expect(Mitra.fromJson(_mitraJson(banner: null)).bannerUrl, isNull);
    });
  });

  group('Kartu Kopdes', () {
    testWidgets('menampilkan sampul DAN logo, bukan salah satu saja', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(KoperasiCard(koperasi: _kopdes(), onOpen: () {}, onDirections: () {})),
      );
      final urls = _requestedUrls(tester);
      expect(urls, contains(_bannerKopdes));
      expect(urls, contains(_logoKopdes));
    });

    testWidgets('tanpa sampul, logo yang dipakai sebagai gambar kartu', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(KoperasiCard(koperasi: _kopdes(banner: null), onOpen: () {}, onDirections: () {})),
      );
      // Satu gambar saja: menumpuk logo di atas logo hanya menggandakannya.
      expect(_requestedUrls(tester), [_logoKopdes]);
    });
  });

  group('Kartu Mitra UMKM', () {
    testWidgets('menampilkan sampul DAN logo toko', (tester) async {
      await tester.pumpWidget(
        _host(
          MitraCard(mitra: Mitra.fromJson(_mitraJson()), onVisit: () {}),
        ),
      );
      final urls = _requestedUrls(tester);
      expect(urls, contains(_bannerMitra));
      expect(urls, contains(_logoMitra));
    });

    testWidgets('belum ada gambar apa pun: inisial toko, bukan kotak rusak', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MitraCard(
            mitra: Mitra.fromJson(_mitraJson(photo: null, banner: null)),
            onVisit: () {},
          ),
        ),
      );
      // Tidak ada permintaan gambar sama sekali, dan kartunya tetap
      // menyebut toko mana — bukan ikon abu-abu yang terbaca gagal muat.
      expect(_requestedUrls(tester), isEmpty);
      expect(find.text('WN'), findsOneWidget);
      expect(find.text('Warung Nasi Mami Yose'), findsOneWidget);
    });
  });

  testWidgets('kedua kartu tidak luber pada 320–768dp dan teks 1,0–2,0×', (
    tester,
  ) async {
    for (final width in [320.0, 390.0, 768.0]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          _host(
            KoperasiCard(koperasi: _kopdes(), onOpen: () {}, onDirections: () {}),
            width: width,
            scale: scale,
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'kartu Kopdes luber pada $width dp × $scale×',
        );

        await tester.pumpWidget(
          _host(
            MitraCard(mitra: Mitra.fromJson(_mitraJson()), onVisit: () {}),
            width: width,
            scale: scale,
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'kartu Mitra luber pada $width dp × $scale×',
        );
      }
    }
  });
}
