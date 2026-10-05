import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';

/// Toko siapa yang sedang dikelola: mitra UMKM atau Kopdes.
///
/// Halaman Produk, form Tambah Produk, Atur Stok, dan Aktivitas stok dipakai
/// keduanya; yang berbeda hanya alamat API dan rutenya. Diturunkan dari peran
/// akun yang masuk — satu akun hanya mengelola satu jenis toko.
enum StoreScope {
  umkm(
    productsTitle: 'Produk Toko',
    list: '/seller/products',
    categories: '/seller/products/categories',
    item: '/seller/products',
    write: '/seller/products',
    adjust: '/seller/inventory/adjust',
    adjustKey: 'umkmProductId',
    live: '/seller/inventory/live',
    routes: '/umkm/products',
    store: '/umkm/store',
  ),
  kopdes(
    productsTitle: 'Produk Kopdes',
    list: '/admin/kopdes/products',
    categories: '/admin/kopdes/products/categories',
    item: '/admin/kopdes/products',
    write: '/products',
    adjust: '/admin/inventory/adjust',
    adjustKey: 'productId',
    live: '/admin/inventory/live',
    // Di bawah `/admin` supaya penjaga peran router ikut melindunginya.
    routes: '/admin/kopdes/products',
    store: '/admin/kopdes/store',
  );

  final String productsTitle;

  /// Daftar berhalaman + ringkasan stok.
  final String list;
  final String categories;

  /// Satu produk: `$item/:id`.
  final String item;

  /// Tambah (POST), ubah & tambah foto (PUT `$write/:id`), hapus (DELETE).
  final String write;
  final String adjust;

  /// Nama kolom id produk di badan penyesuaian stok.
  final String adjustKey;
  final String live;

  /// Awalan rute aplikasi: `/new`, `/edit/:id`, `/detail/:id`.
  final String routes;

  /// Awalan halaman turunan profil toko: `/edit`, `/settings`, `/security`.
  final String store;

  const StoreScope({
    required this.productsTitle,
    required this.list,
    required this.categories,
    required this.item,
    required this.write,
    required this.adjust,
    required this.adjustKey,
    required this.live,
    required this.routes,
    required this.store,
  });

  bool get isKopdes => this == StoreScope.kopdes;

  String get newProductRoute => '$routes/new';
  String editRoute(String id) => '$routes/edit/$id';
  String detailRoute(String id) => '$routes/detail/$id';
}

const _kopdesRoles = {'ADMIN_KOPDES', 'PEGAWAI_KOPDES', 'SUPER_ADMIN'};

final storeScopeProvider = Provider<StoreScope>((ref) {
  final role = ref.watch(authProvider.select((s) => s.user?.role));
  return _kopdesRoles.contains(role) ? StoreScope.kopdes : StoreScope.umkm;
});
