import 'package:isar/isar.dart';

part 'product_cache.g.dart';

@collection
class ProductCache {
  Id id = Isar.autoIncrement;

  @Index()
  late String productId;
  late String name;
  late String description;
  late double price;
  late int stock;
  late String category;
  late List<String> imageUrls;
  late DateTime cachedAt;
}
