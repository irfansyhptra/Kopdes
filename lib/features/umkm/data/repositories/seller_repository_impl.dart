import '../../domain/repositories/seller_repository.dart';
import '../services/seller_service.dart';
import '../services/store_service.dart';
import '../models/seller_model.dart';
import '../models/store_model.dart';

class SellerRepositoryImpl implements SellerRepository {
  final SellerService service;
  final StoreService storeService;

  SellerRepositoryImpl({required this.service, required this.storeService});

  @override
  Future<SellerModel> getDashboard() => service.getDashboard();

  @override
  Future<List<dynamic>> getStatistics() => service.getStatistics();

  @override
  Future<StoreModel> getStoreProfile() => storeService.getStoreProfile();

  @override
  Future<StoreModel> updateStoreProfile({
    String? businessName,
    String? description,
    String? address,
    String? phone,
    String? category,
    Map<String, DayHours?>? operatingHours,
  }) => storeService.updateStoreProfile(
    businessName: businessName,
    description: description,
    address: address,
    phone: phone,
    category: category,
    operatingHours: operatingHours,
  );
}
