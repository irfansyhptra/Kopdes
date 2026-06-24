import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/product_cache.dart';
import 'models/order_cache.dart';
import 'models/user_profile_cache.dart';
import 'models/cart_cache.dart';
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

  static Future<void> initialize() async {
    if (_instance != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        ProductCacheSchema,
        OrderCacheSchema,
        UserProfileCacheSchema,
        CartCacheSchema,
      ],
      name: AppConstants.isarDbName,
      directory: dir.path,
    );
  }

  static Future<void> clearAllCaches() async {
    final isar = instance;
    await isar.writeTxn(() async {
      await isar.productCaches.clear();
      await isar.orderCaches.clear();
      await isar.userProfileCaches.clear();
      await isar.cartCaches.clear();
    });
  }
}
