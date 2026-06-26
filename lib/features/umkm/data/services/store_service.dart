import 'package:dio/dio.dart';
import '../models/store_model.dart';

class StoreService {
  final Dio dio;
  StoreService({required this.dio});

  Future<StoreModel> getStoreProfile() async {
    final response = await dio.get('/seller/profile');
    final responseMap = response.data as Map<String, dynamic>;
    return StoreModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<StoreModel> updateStoreProfile({
    required String businessName,
    required String description,
    required String address,
    required String phone,
  }) async {
    final body = {
      'businessName': businessName,
      'description': description,
      'address': address,
      'phone': phone,
    };
    final response = await dio.put('/seller/profile', data: body);
    final responseMap = response.data as Map<String, dynamic>;
    return StoreModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }
}
