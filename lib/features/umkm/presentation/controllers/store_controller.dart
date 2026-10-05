import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/store_model.dart';
import '../../../admin/data/kopdes_console.dart';
import '../../data/store_scope.dart';
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
  // Dasbor milik pihak lain tidak disentuh: membaca pengendali dasbor
  // penjual dari akun Kopdes akan memanggil `/seller/dashboard` dan ditolak.
  if (ref.read(storeScopeProvider).isKopdes) {
    ref.invalidate(kopdesDashboardProvider);
  } else {
    ref.read(sellerDashboardControllerProvider.notifier).refresh();
  }
}
