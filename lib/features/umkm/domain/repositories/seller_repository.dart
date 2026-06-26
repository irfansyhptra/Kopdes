import '../../data/models/seller_model.dart';
import '../../data/models/store_model.dart';

abstract class SellerRepository {
  Future<SellerModel> getDashboard();
  Future<List<dynamic>> getStatistics();
  Future<StoreModel> getStoreProfile();
  Future<StoreModel> updateStoreProfile({
    required String businessName,
    required String description,
    required String address,
    required String phone,
  });
}

