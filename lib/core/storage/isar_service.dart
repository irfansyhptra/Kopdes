import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/order_cache.dart';
import 'models/user_profile_cache.dart';
import 'models/cart_cache.dart';
import 'models/cached_response.dart';
import '../constants/app_constants.dart';

final isarProvider = Provider<Isar>((ref) {
  return IsarService.instance;
});

class IsarService {
  static Isar? _instance;

  static Isar get instance {
    if (_instance == null) {
      throw StateError('Isar is not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static const List<CollectionSchema<dynamic>> _schemas = [
    OrderCacheSchema,
    UserProfileCacheSchema,
    CartCacheSchema,
    CachedResponseSchema,
  ];

  static Future<void> initialize() async {
    if (_instance != null) return;

    final dir = await getApplicationDocumentsDirectory();
    try {
      _instance = await _open(dir.path);
    } catch (e) {
      // Basis data ini murni cache. Kalau skemanya tidak lagi cocok dengan
      // versi aplikasi yang terpasang, membuangnya jauh lebih baik daripada
      // membiarkan Isar gagal dibuka dan mematikan seluruh lapisan data.
      if (kDebugMode) {
        debugPrint('Isar gagal dibuka ($e). Membangun ulang cache dari nol.');
      }
      await _deleteDatabaseFiles(dir.path);
      _instance = await _open(dir.path);
    }
  }

  static Future<Isar> _open(String directory) =>
      Isar.open(_schemas, name: AppConstants.isarDbName, directory: directory);

  static Future<void> _deleteDatabaseFiles(String directory) async {
    for (final suffix in const ['.isar', '.isar.lock']) {
      final file = File('$directory/${AppConstants.isarDbName}$suffix');
      if (file.existsSync()) await file.delete();
    }
  }

  static Future<void> clearAllCaches() async {
    final isar = instance;
    await isar.writeTxn(() async {
      await isar.orderCaches.clear();
      await isar.userProfileCaches.clear();
      await isar.cartCaches.clear();
      await isar.cachedResponses.clear();
    });
  }
}
