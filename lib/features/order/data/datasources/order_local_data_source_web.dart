import 'dart:convert';

import 'package:web/web.dart' as web;

import '../../../../core/storage/cache_records.dart';

abstract class OrderLocalDataSource {
  Future<void> saveDraftCart(String userId, List<CachedCartItem> items);
  Future<List<CachedCartItem>> getDraftCart(String userId);
  Future<void> clearDraftCart(String userId);
  Future<void> cacheOrderHistory(String customerId, List<CachedOrder> orders);
  Future<List<CachedOrder>> getCachedOrderHistory(String customerId);
  Future<void> cacheOrderDetail(CachedOrder order);
  Future<CachedOrder?> getCachedOrderDetail(String orderId);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  static const _prefix = 'komit.orders.';

  String _cartKey(String id) => '${_prefix}cart.${Uri.encodeComponent(id)}';
  String _historyKey(String id) =>
      '${_prefix}history.${Uri.encodeComponent(id)}';
  String _detailKey(String id) => '${_prefix}detail.${Uri.encodeComponent(id)}';

  @override
  Future<void> saveDraftCart(String userId, List<CachedCartItem> items) async {
    web.window.localStorage.setItem(
      _cartKey(userId),
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<List<CachedCartItem>> getDraftCart(String userId) async =>
      _readList(_cartKey(userId), CachedCartItem.fromJson);

  @override
  Future<void> clearDraftCart(String userId) async {
    web.window.localStorage.removeItem(_cartKey(userId));
  }

  @override
  Future<void> cacheOrderHistory(
    String customerId,
    List<CachedOrder> orders,
  ) async {
    web.window.localStorage.setItem(
      _historyKey(customerId),
      jsonEncode(orders.map((order) => order.toJson()).toList()),
    );
  }

  @override
  Future<List<CachedOrder>> getCachedOrderHistory(String customerId) async =>
      _readList(_historyKey(customerId), CachedOrder.fromJson);

  @override
  Future<void> cacheOrderDetail(CachedOrder order) async {
    web.window.localStorage.setItem(
      _detailKey(order.orderId),
      jsonEncode(order.toJson()),
    );
  }

  @override
  Future<CachedOrder?> getCachedOrderDetail(String orderId) async {
    final raw = web.window.localStorage.getItem(_detailKey(orderId));
    if (raw == null) return null;
    try {
      return CachedOrder.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      web.window.localStorage.removeItem(_detailKey(orderId));
      return null;
    }
  }

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) decode) {
    final raw = web.window.localStorage.getItem(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(decode)
          .toList();
    } catch (_) {
      web.window.localStorage.removeItem(key);
      return [];
    }
  }
}
