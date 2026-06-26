import '../../data/models/order_model.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> getOrders();
  Future<OrderModel> getOrderDetail(String id);
  Future<OrderModel> updateOrderStatus(String id, String status);
}
