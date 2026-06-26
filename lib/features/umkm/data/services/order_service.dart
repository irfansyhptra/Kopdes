import 'package:dio/dio.dart';
import '../models/order_model.dart';

class OrderService {
  final Dio dio;
  OrderService({required this.dio});

  Future<List<OrderModel>> getOrders() async {
    final response = await dio.get('/seller/orders');
    final responseMap = response.data as Map<String, dynamic>;
    final list = responseMap['data'] as List? ?? [];
    return list.map((o) => OrderModel.fromJson(o as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> getOrderDetail(String id) async {
    final response = await dio.get('/seller/orders/$id');
    final responseMap = response.data as Map<String, dynamic>;
    return OrderModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    final response = await dio.put('/seller/orders/$id/status', data: {'status': status});
    final responseMap = response.data as Map<String, dynamic>;
    return OrderModel.fromJson(responseMap['data'] as Map<String, dynamic>);
  }
}
