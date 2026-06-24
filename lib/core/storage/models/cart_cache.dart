import 'package:isar/isar.dart';

part 'cart_cache.g.dart';

@collection
class CartCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String userId;

  late List<CartItemCache> items;
  late DateTime updatedAt;
}

@embedded
class CartItemCache {
  String? productId;
  String? umkmProductId;
  late String name;
  late double price;
  late int quantity;
  String? imageUrl;
}
