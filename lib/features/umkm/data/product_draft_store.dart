import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../auth/presentation/providers/auth_provider.dart';

/// Isian form "Tambah Produk" yang disimpan di perangkat.
class ProductDraft {
  final String name;
  final String? categoryId;
  final String description;
  final String price;
  final String stock;

  /// Path absolut foto — salinan milik draf, bukan berkas sementara pemilih
  /// gambar yang bisa dibersihkan sistem kapan saja.
  final List<String> photos;
  final DateTime savedAt;

  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.stock,
    required this.photos,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'v': 1,
    'name': name,
    'categoryId': categoryId,
    'description': description,
    'price': price,
    'stock': stock,
    'photos': photos,
    'savedAt': savedAt.toIso8601String(),
  };

  factory ProductDraft.fromJson(Map<String, dynamic> j) => ProductDraft(
    name: j['name'] as String? ?? '',
    categoryId: j['categoryId'] as String?,
    description: j['description'] as String? ?? '',
    price: j['price'] as String? ?? '',
    stock: j['stock'] as String? ?? '',
    photos: (j['photos'] as List? ?? const []).whereType<String>().toList(),
    savedAt: DateTime.tryParse('${j['savedAt']}') ?? DateTime.now(),
  );
}

/// Satu draf produk baru per akun, di folder dokumen aplikasi.
///
/// Backend belum mengenal draf, jadi draf hidup di perangkat: JSON isian
/// plus salinan fotonya. Dipisah per akun supaya dua penjual yang bergantian
/// memakai satu ponsel tidak saling melihat draf.
class ProductDraftStore {
  final String ownerId;
  final Future<Directory> Function() _root;

  ProductDraftStore({required this.ownerId, Future<Directory> Function()? root})
    : _root = root ?? getApplicationDocumentsDirectory;

  Future<Directory> _dir() async {
    final base = await _root();
    // Id akun dari server; dibersihkan supaya tidak bisa keluar folder.
    final safe = ownerId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return Directory('${base.path}/product_drafts/$safe');
  }

  Future<ProductDraft?> load() async {
    final file = File('${(await _dir()).path}/draft.json');
    if (!await file.exists()) return null;
    try {
      final draft = ProductDraft.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      // Foto yang hilang (dihapus pengguna lewat pengelola berkas, mis.)
      // dibuang dari draf, bukan membuat pratinjau rusak.
      final alive = <String>[
        for (final p in draft.photos)
          if (await File(p).exists()) p,
      ];
      return ProductDraft(
        name: draft.name,
        categoryId: draft.categoryId,
        description: draft.description,
        price: draft.price,
        stock: draft.stock,
        photos: alive,
        savedAt: draft.savedAt,
      );
    } catch (_) {
      // Draf rusak tidak boleh menghalangi orang mengisi form baru.
      return null;
    }
  }

  /// Menyimpan [draft] dan mengembalikannya dengan path foto milik draf.
  Future<ProductDraft> save(ProductDraft draft) async {
    final dir = await _dir();
    await dir.create(recursive: true);

    final kept = <String>[];
    for (var i = 0; i < draft.photos.length; i++) {
      final src = draft.photos[i];
      if (src.startsWith(dir.path)) {
        kept.add(src);
        continue;
      }
      final ext = src.contains('.') ? src.substring(src.lastIndexOf('.')) : '';
      final dest =
          '${dir.path}/photo_${DateTime.now().microsecondsSinceEpoch}_$i$ext';
      await File(src).copy(dest);
      kept.add(dest);
    }

    // Foto yang sudah dilepas dari draf ikut dihapus dari disk.
    await for (final f in dir.list()) {
      if (f is File && f.path.contains('/photo_') && !kept.contains(f.path)) {
        await f.delete();
      }
    }

    final saved = ProductDraft(
      name: draft.name,
      categoryId: draft.categoryId,
      description: draft.description,
      price: draft.price,
      stock: draft.stock,
      photos: kept,
      savedAt: draft.savedAt,
    );
    // Tulis ke berkas sementara lalu ganti nama: aplikasi yang mati di
    // tengah penulisan tidak meninggalkan JSON setengah jadi.
    final tmp = File('${dir.path}/draft.json.tmp');
    await tmp.writeAsString(jsonEncode(saved.toJson()), flush: true);
    await tmp.rename('${dir.path}/draft.json');
    return saved;
  }

  Future<void> clear() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

final productDraftStoreProvider = Provider<ProductDraftStore>((ref) {
  final ownerId = ref.watch(authProvider.select((s) => s.user?.id)) ?? 'anon';
  return ProductDraftStore(ownerId: ownerId);
});
