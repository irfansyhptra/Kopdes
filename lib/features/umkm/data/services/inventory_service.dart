import 'package:dio/dio.dart';
import '../models/inventory_model.dart';

class InventoryService {
  final Dio dio;
  InventoryService({required this.dio});

  Future<List<InventoryModel>> getInventoryList() async {
    final response = await dio.get('/seller/products', queryParameters: {'limit': 100});
    final responseMap = response.data as Map<String, dynamic>;
    final dataMap = responseMap['data'] as Map<String, dynamic>;
    final list = dataMap['products'] as List? ?? [];
    return list.map((p) => InventoryModel.fromJson(p as Map<String, dynamic>)).toList();
  }

  Future<void> updateStock(String id, int currentStock) async {
    await dio.put('/seller/products/$id', data: {'stock': currentStock});
  }
}
