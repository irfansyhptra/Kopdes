import '../../domain/repositories/order_repository.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderService service;
  OrderRepositoryImpl({required this.service});

  @override
  Future<List<OrderModel>> getOrders() => service.getOrders();

  @override
  Future<OrderModel> getOrderDetail(String id) => service.getOrderDetail(id);

  @override
  Future<OrderModel> updateOrderStatus(String id, String status) => service.updateOrderStatus(id, status);
}
