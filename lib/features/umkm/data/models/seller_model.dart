import 'store_model.dart';
import 'product_model.dart';

class SellerActivity {
  final String type; // ORDER, REVIEW, STOCK_WARN
  final String title;
  final String description;
  final DateTime timestamp;

  const SellerActivity({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
  });

  factory SellerActivity.fromJson(Map<String, dynamic> json) {
    return SellerActivity(
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }
}

class SellerDashboardStats {
  final int totalProducts;
  final int totalOrders;
  final int productsSold;
  final double todayEarnings;
  final double monthlyEarnings;
  final double storeRating;
  final int lowStockCount;
  final int newOrdersCount;

  const SellerDashboardStats({
    required this.totalProducts,
    required this.totalOrders,
    required this.productsSold,
    required this.todayEarnings,
    required this.monthlyEarnings,
    required this.storeRating,
    required this.lowStockCount,
    required this.newOrdersCount,
  });

  factory SellerDashboardStats.fromJson(Map<String, dynamic> json) {
    return SellerDashboardStats(
      totalProducts: json['totalProducts'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      productsSold: json['productsSold'] as int? ?? 0,
      todayEarnings: json['todayEarnings'] is num
          ? (json['todayEarnings'] as num).toDouble()
          : double.tryParse(json['todayEarnings'].toString()) ?? 0.0,
      monthlyEarnings: json['monthlyEarnings'] is num
          ? (json['monthlyEarnings'] as num).toDouble()
          : double.tryParse(json['monthlyEarnings'].toString()) ?? 0.0,
      storeRating: json['storeRating'] is num
          ? (json['storeRating'] as num).toDouble()
          : double.tryParse(json['storeRating'].toString()) ?? 0.0,
      lowStockCount: json['lowStockCount'] as int? ?? 0,
      newOrdersCount: json['newOrdersCount'] as int? ?? 0,
    );
  }
}

class SellerModel {
  final StoreModel storeInfo;
  final SellerDashboardStats stats;
  final List<ProductModel> lowStockProducts;
  final List<SellerActivity> recentActivities;

  const SellerModel({
    required this.storeInfo,
    required this.stats,
    required this.lowStockProducts,
    required this.recentActivities,
  });

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    final lowStockList = json['lowStockProducts'] as List? ?? [];
    final parsedLowStock = lowStockList
        .map((p) => ProductModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final activityList = json['recentActivities'] as List? ?? [];
    final parsedActivities = activityList
        .map((act) => SellerActivity.fromJson(act as Map<String, dynamic>))
        .toList();

    return SellerModel(
      storeInfo: StoreModel.fromJson(json['storeInfo'] as Map<String, dynamic>),
      stats: SellerDashboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      lowStockProducts: parsedLowStock,
      recentActivities: parsedActivities,
    );
  }
}
