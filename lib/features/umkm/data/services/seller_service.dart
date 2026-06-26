import 'package:dio/dio.dart';
import '../models/seller_model.dart';

class SellerService {
  final Dio dio;
  SellerService({required this.dio});

  Future<SellerModel> getDashboard() async {
    final response = await dio.get('/seller/dashboard');
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>;
    return SellerModel.fromJson(dataMap);
  }

  Future<List<dynamic>> getStatistics() async {
    final response = await dio.get('/seller/statistics');
    final responseMap = response.data as Map<String, dynamic>;
    return responseMap['data'] as List? ?? [];
  }
}
