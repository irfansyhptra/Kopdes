import 'package:dio/dio.dart';
import '../models/store_model.dart';
import '../store_scope.dart';

class StoreService {
  final Dio dio;
  final StoreScope scope;
  StoreService({required this.dio, this.scope = StoreScope.umkm});

  String get _path =>
      scope.isKopdes ? '/admin/kopdes/profile' : '/seller/profile';

  StoreModel _decode(Map<String, dynamic> data) => scope.isKopdes
      ? StoreModel.fromKopdesJson(data)
      : StoreModel.fromJson(data);

  Future<StoreModel> getStoreProfile() async {
    final response = await dio.get(_path);
    final responseMap = response.data as Map<String, dynamic>;
    return _decode(responseMap['data'] as Map<String, dynamic>);
  }

  Future<StoreModel> updateStoreProfile({
    String? businessName,
    String? description,
    String? address,
    String? phone,
    String? category,
    Map<String, DayHours?>? operatingHours,
  }) async {
    final body = {
      // Profil Kopdes menamai kolomnya `name` dan tidak punya kategori.
      (scope.isKopdes ? 'name' : 'businessName'): ?businessName,
      'description': ?description,
      'address': ?address,
      'phone': ?phone,
      if (!scope.isKopdes) 'category': ?category,
      if (operatingHours != null)
        'operatingHours': {
          for (final e in operatingHours.entries) e.key: e.value?.toJson(),
        },
    };
    final response = await dio.put(_path, data: body);
    final responseMap = response.data as Map<String, dynamic>;
    return _decode(responseMap['data'] as Map<String, dynamic>);
  }
}
