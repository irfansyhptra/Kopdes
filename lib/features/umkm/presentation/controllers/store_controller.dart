import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/store_model.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';

final storeProfileProvider = FutureProvider<StoreModel>((ref) async {
  return ref.watch(sellerRepositoryProvider).getStoreProfile();
});

/// Menyimpan profil toko. Melempar bila gagal — pemanggil (lewat
/// `runWithFeedback`) menampilkan alasannya.
Future<void> saveStoreProfile(
  WidgetRef ref, {
  String? businessName,
  String? description,
  String? address,
  String? phone,
  String? category,
  Map<String, DayHours?>? operatingHours,
}) async {
  await ref
      .read(sellerRepositoryProvider)
      .updateStoreProfile(
        businessName: businessName,
        description: description,
        address: address,
        phone: phone,
        category: category,
        operatingHours: operatingHours,
      );
  ref.invalidate(storeProfileProvider);
  ref.read(sellerDashboardControllerProvider.notifier).refresh();
}
