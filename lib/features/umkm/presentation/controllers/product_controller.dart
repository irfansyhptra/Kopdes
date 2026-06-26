import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_category_model.dart';
import '../../domain/repositories/product_repository.dart';
import 'providers.dart';
import 'seller_dashboard_controller.dart';

class ProductSearchQuery {
  final String search;
  final String categoryId;
  final int page;
  final int limit;

  const ProductSearchQuery({
    this.search = '',
    this.categoryId = '',
    this.page = 1,
    this.limit = 20,
  });

  ProductSearchQuery copyWith({
    String? search,
    String? categoryId,
    int? page,
    int? limit,
  }) {
    return ProductSearchQuery(
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }
}

final sellerProductQueryProvider = StateProvider<ProductSearchQuery>((ref) {
  return const ProductSearchQuery();
});

final sellerCategoriesProvider = FutureProvider<List<ProductCategoryModel>>((ref) async {
  return ref.watch(productRepositoryProvider).getCategories();
});

final sellerProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(sellerProductQueryProvider);
  return ref.watch(productRepositoryProvider).getProducts(
        search: query.search.isEmpty ? null : query.search,
        categoryId: query.categoryId.isEmpty ? null : query.categoryId,
        page: query.page,
        limit: query.limit,
      );
});

class ProductController extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repository;
  final Ref _ref;

  ProductController({
    required ProductRepository repository,
    required Ref ref,
  })  : _repository = repository,
        _ref = ref,
        super(const AsyncValue.data(null));

  Future<bool> createProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required String categoryId,
    List<dynamic>? images,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createProduct(
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        images: images,
      );
      state = const AsyncValue.data(null);
      _refreshAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    bool? isActive,
    List<dynamic>? newImages,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateProduct(
        id: id,
        name: name,
        description: description,
        price: price,
        stock: stock,
        categoryId: categoryId,
        isActive: isActive,
        newImages: newImages,
      );
      state = const AsyncValue.data(null);
      _refreshAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteProduct(id);
      state = const AsyncValue.data(null);
      _refreshAll();
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void _refreshAll() {
    _ref.invalidate(sellerProductsProvider);
    _ref.read(sellerDashboardControllerProvider.notifier).refresh();
  }
}

final productControllerProvider = StateNotifierProvider<ProductController, AsyncValue<void>>((ref) {
  return ProductController(
    repository: ref.watch(productRepositoryProvider),
    ref: ref,
  );
});
