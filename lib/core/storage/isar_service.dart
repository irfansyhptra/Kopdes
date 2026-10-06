import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/order_cache.dart';
import 'models/user_profile_cache.dart';
import 'models/cart_cache.dart';
import 'models/cached_response.dart';
import '../constants/app_constants.dart';
import 'isar_platform.dart';

final isarProvider = Provider<Isar>((ref) {
  return IsarService.instance;
});

class IsarService {
  static Isar? _instance;

  static Isar? get instanceOrNull => _instance;

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

    final directory = await isarDirectory();
    try {
      _instance = await _open(directory);
    } catch (e) {
      // Basis data ini murni cache. Kalau skemanya tidak lagi cocok dengan
      // versi aplikasi yang terpasang, membuangnya jauh lebih baik daripada
      // membiarkan Isar gagal dibuka dan mematikan seluruh lapisan data.
      if (kDebugMode) {
        debugPrint('Isar gagal dibuka ($e). Membangun ulang cache dari nol.');
      }
      await deleteIsarFiles(directory, AppConstants.isarDbName);
      _instance = await _open(directory);
    }
  }

  static Future<Isar> _open(String directory) =>
      Isar.open(_schemas, name: AppConstants.isarDbName, directory: directory);

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
