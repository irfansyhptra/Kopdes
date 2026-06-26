import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/services/seller_service.dart';
import '../../data/services/product_service.dart';
import '../../data/services/inventory_service.dart';
import '../../data/services/order_service.dart';
import '../../data/services/store_service.dart';
import '../../data/repositories/seller_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/repositories/seller_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/repositories/order_repository.dart';

// Services Providers
final sellerServiceProvider = Provider<SellerService>((ref) {
  return SellerService(dio: ref.watch(dioProvider));
});

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService(dio: ref.watch(dioProvider));
});

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(dio: ref.watch(dioProvider));
});

final inventoryServiceProvider = Provider<InventoryService>((ref) {
  return InventoryService(dio: ref.watch(dioProvider));
});

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(dio: ref.watch(dioProvider));
});

// Repositories Providers
final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  return SellerRepositoryImpl(
    service: ref.watch(sellerServiceProvider),
    storeService: ref.watch(storeServiceProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(service: ref.watch(productServiceProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(service: ref.watch(inventoryServiceProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepositoryImpl(service: ref.watch(orderServiceProvider));
});
