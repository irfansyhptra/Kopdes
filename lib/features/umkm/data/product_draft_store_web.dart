import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import '../../auth/presentation/providers/auth_provider.dart';

class ProductDraft {
  final String name;
  final String? categoryId;
  final String description;
  final String price;
  final String stock;
  final String minStock;
  final List<String> photos;
  final DateTime savedAt;

  const ProductDraft({
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.stock,
    this.minStock = '',
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
    'minStock': minStock,
    'photos': const <String>[],
    'savedAt': savedAt.toIso8601String(),
  };

  factory ProductDraft.fromJson(Map<String, dynamic> json) => ProductDraft(
    name: json['name'] as String? ?? '',
    categoryId: json['categoryId'] as String?,
    description: json['description'] as String? ?? '',
    price: json['price'] as String? ?? '',
    stock: json['stock'] as String? ?? '',
    minStock: json['minStock'] as String? ?? '',
    photos: const [],
    savedAt: DateTime.tryParse('${json['savedAt']}') ?? DateTime.now(),
  );
}

/// Draf web disimpan di localStorage. Object URL foto hanya berlaku selama
/// tab aktif, jadi teks bertahan setelah refresh dan foto harus dipilih ulang.
class ProductDraftStore {
  final String ownerId;

  ProductDraftStore({required this.ownerId});

  String get _key {
    final safe = ownerId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'komit.product-draft.$safe';
  }

  Future<ProductDraft?> load() async {
    final raw = web.window.localStorage.getItem(_key);
    if (raw == null) return null;
    try {
      return ProductDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<ProductDraft> save(ProductDraft draft) async {
    web.window.localStorage.setItem(_key, jsonEncode(draft.toJson()));
    return draft;
  }

  Future<void> clear() async => web.window.localStorage.removeItem(_key);
}

final productDraftStoreProvider = Provider<ProductDraftStore>((ref) {
  final ownerId =
      ref.watch(authProvider.select((state) => state.user?.id)) ?? 'anon';
  return ProductDraftStore(ownerId: ownerId);
});
