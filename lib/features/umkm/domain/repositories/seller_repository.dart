import '../../data/models/seller_model.dart';
import '../../data/models/store_model.dart';

abstract class SellerRepository {
  Future<SellerModel> getDashboard();
  Future<List<dynamic>> getStatistics();
  Future<StoreModel> getStoreProfile();

  /// Hanya kolom yang diisi yang dikirim.
  Future<StoreModel> updateStoreProfile({
    String? businessName,
    String? description,
    String? address,
    String? phone,
    String? category,
    Map<String, DayHours?>? operatingHours,
  });
}
